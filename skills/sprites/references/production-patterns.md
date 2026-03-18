# Sprites Production Patterns

Patterns for running Sprites as infrastructure for automated agent workloads.

## Fleet Architecture

A fleet is a set of named Sprites, each dedicated to a workflow lane.
Each lane has: a Sprite, a checkpoint strategy, an ingress path, a
preparer, and a dispatcher.

```
orchestrator
  ├── lane: bug-fix     → sprite: vulcan   (checkpoint: latest)
  ├── lane: docs-gen    → sprite: minerva  (checkpoint: latest)
  └── lane: docs-sync   → sprite: clio     (checkpoint: v1 or override)
```

### Lane Checklist

Every Sprite-backed lane needs:

1. **Sprite name env var** — `SPRITE_NAME`, `MINERVA_SPRITE_NAME`, etc.
2. **Optional checkpoint override** — `SPRITE_CHECKPOINT` for pinning
3. **Dedicated client** — one `SpritesClient` per lane
4. **Preparer** — checkpoint restore + repo sync + credential setup
5. **Queue** — serialized job dispatch (one job per Sprite at a time)
6. **Health exposure** — readiness gate on webhook acceptance
7. **Setup script** — one-time provisioning
8. **Refresh script** — sync repos, install deps, create checkpoint
9. **Verify script** — validate tools, repos, credentials, network

### Client-Per-Lane Pattern

```typescript
function createLane(env: Env) {
  const sprites = createSpritesClient({
    token: env.SPRITES_TOKEN,
    spriteName: env.LANE_SPRITE_NAME,
  });

  const preparer = createSpritePreparer(sprites, {
    checkpointOverride: env.LANE_CHECKPOINT,
    repos: [{ name: "myapp", branch: "main" }],
  });

  return { sprites, preparer };
}
```

## Preparation Flow

Standard prepare sequence before every agent invocation:

```
1. Select checkpoint (latest non-Current, or override)
2. Restore checkpoint (streaming NDJSON, wait for complete)
3. Set up git credentials (store helper + EXIT trap)
4. Sync repos (fetch + reset --hard FETCH_HEAD per repo)
5. Run pre-exec setup (install deps, build, etc.)
```

### Checkpoint Selection

```typescript
async function selectCheckpoint(
  sprites: SpritesClient,
  override?: string,
): Promise<string> {
  if (override) return override;

  const checkpoints = await sprites.listCheckpoints();
  const usable = checkpoints
    .filter((cp) => cp.id !== "Current")
    .sort((a, b) =>
      new Date(b.create_time).getTime() - new Date(a.create_time).getTime()
    );

  if (usable.length === 0) {
    throw new Error("No usable checkpoints (all filtered as Current)");
  }
  return usable[0].id;
}
```

### Repo Sync Command Builder

```typescript
function buildSyncCommand(repo: SyncTarget): string {
  const { name, branch, commitSha } = repo;
  const dir = `/home/sprite/repos/${name}`;

  if (commitSha) {
    // Detached HEAD at specific commit (for event-driven sync)
    return `cd ${dir} && git fetch origin ${branch} && git checkout --detach ${commitSha}`;
  }
  // Branch HEAD (default)
  return `cd ${dir} && git fetch origin ${branch} && git checkout ${branch} && git reset --hard FETCH_HEAD`;
}
```

## Health Gating

Gate webhook acceptance on Sprite readiness. If the Sprite is not
verified, reject incoming work with a clear error instead of queuing
jobs that will fail during preparation.

```typescript
interface Readiness {
  ready: boolean;
  error?: string;
  lastCheck?: Date;
}

function createAcceptGuard(readiness: Readiness) {
  return (): { ok: true } | { ok: false; error: string } =>
    readiness.ready
      ? { ok: true }
      : { ok: false, error: `Lane not ready: ${readiness.error ?? "pending verification"}` };
}
```

### Boot-Time Verification

On orchestrator startup, verify all Sprites before accepting work:

```typescript
async function boot(lanes: Map<string, Lane>) {
  const tasks = [];
  for (const lane of lanes.values()) {
    tasks.push(ensureSpriteExists(lane.sprites));
    if (lane.verify) tasks.push(lane.verify());
  }
  await Promise.all(tasks);
}

async function ensureSpriteExists(sprites: SpritesClient) {
  try {
    const status = await sprites.getStatus();
    if (status === "running" || status === "warm" || status === "cold") return;
  } catch {
    // Sprite doesn't exist — create it
    await sprites.create();
  }
}
```

## Refresh Lifecycle

Refresh = update a Sprite's checkpoint with current repos and tools.

```
1. Authenticate git (store helper with EXIT trap)
2. Fetch + reset each tracked repo to origin/main
3. Install dependencies (npm/pnpm/bun install, dotnet build, etc.)
4. Copy skills/config to standard locations
5. Apply network policies (if lane requires isolation)
6. Create checkpoint with timestamped comment
7. Verify the fresh checkpoint (run verify script)
```

### Network Policy Application

For lanes that need outbound isolation:

```bash
sprite api -s "$SPRITE" /policy/network -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "rules": [
      {"action": "allow", "domain": "github.com"},
      {"action": "allow", "domain": "*.github.com"},
      {"action": "allow", "domain": "api.anthropic.com"},
      {"action": "deny", "domain": "*"}
    ]
  }'
```

Apply policies BEFORE creating the checkpoint so they persist.

### Skill Deployment

Copy agent skills to the Sprite's standard skill location:

```bash
# Copy skill directories to Sprite
for skill in bug-fixing test-generating code-review; do
  sprite exec -s "$SPRITE" -- mkdir -p "/home/sprite/.claude/skills/$skill"
  # Use filesystem API or tar+exec for bulk file transfer
  sprite exec -s "$SPRITE" --file "skills/$skill/SKILL.md:/home/sprite/.claude/skills/$skill/SKILL.md" -- true
done
```

## Monitoring

### Orchestrator Health Endpoint

Expose per-lane Sprite status:

```json
{
  "lanes": {
    "bug-fix": { "sprite": "vulcan", "status": "ready", "queue_depth": 0 },
    "docs-gen": { "sprite": "minerva", "status": "ready", "queue_depth": 1 },
    "docs-sync": { "sprite": "clio", "status": "verifying", "queue_depth": 0 }
  }
}
```

### Post-Deploy Checks

After deploying the orchestrator, verify Sprite connectivity:

```bash
# Check each lane's Sprite is reachable
for SPRITE in vulcan minerva clio; do
  STATUS=$(sprite api -o myorg -s "$SPRITE" /sprites/"$SPRITE" 2>/dev/null | jq -r '.status')
  echo "$SPRITE: $STATUS"
done
```

## Error Recovery

### Dead Letter Queue

Jobs that fail after retry exhaustion go to SQLite dead-letter storage.
Include the raw event payload for manual replay:

```typescript
interface DeadLetter {
  id: string;
  lane: string;
  event: unknown;      // Original webhook payload
  error: string;       // Last error message
  attempts: number;
  created_at: string;
}
```

Expose via API for operator recovery:
- `GET /dead-letters` — list failed jobs
- `POST /dead-letters/:id/retry` — re-enqueue

### Stale Run Recovery

On boot, find runs stuck in `running` state (orchestrator crashed mid-job).
Mark as `awaiting_recovery` for operator review rather than auto-retrying,
since Sprite state is unknown:

```typescript
async function recoverStaleRuns(db: Database) {
  const stale = db.findRunsByStatus("running");
  for (const run of stale) {
    db.updateRunStatus(run.id, "awaiting_recovery");
    log("warn", `Stale run ${run.id} marked for recovery`);
  }
}
```

## Cost Optimization

- **Auto-sleep is your friend.** Sprites sleep when idle, near-zero cost.
- **Checkpoint strategically.** Each checkpoint stores only changed blocks,
  but many small checkpoints still accumulate storage costs.
- **Don't leave Sprites running.** If your orchestrator is down, Sprites
  may stay warm/running and bill CPU hours. Monitor with `sprite list -w`.
- **Concurrency slots cost $1/month each.** Only pay for what you need.
- **Single region matters.** If your orchestrator is far from the Sprite
  region, every exec call adds network latency.
