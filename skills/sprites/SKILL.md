---
name: sprites
user-invocable: false
description: "Sprites stateful sandbox VM patterns, production gotchas, and operational knowledge. Checkpoint/restore semantics, exec binary protocol, credential hygiene, network policies, SDK patterns, fleet management. Invoke when writing code that interacts with Sprites API, managing Sprite VMs, writing refresh/verify scripts, or debugging Sprite infrastructure. NOT Fly.io Machines — Sprites are a separate product."
---

# Sprites

Production patterns and gotchas for Fly.io Sprites — stateful sandbox VMs
with checkpoint/restore, designed for AI coding agents.

## Triggers

Invoke when:
- Code imports `@fly/sprites`, `sprites-py`, `sprites-go`, or calls Sprites API
- Files reference `sprites.dev`, `SPRITES_TOKEN`, or `sprite exec`
- Scripts manage checkpoint lifecycle (create, restore, verify)
- Writing network policies, credential injection, or exec wrappers
- Deploying or provisioning Sprite-backed automation lanes

## What Sprites Are (and Are Not)

> Sprites are persistent, hardware-isolated Firecracker microVMs with
> 100GB durable filesystems and sub-second checkpoint/restore.
> They are NOT Fly.io Machines. Different product, different API,
> different billing, different lifecycle model.

| | Fly Machines | Sprites |
|---|---|---|
| **Lifecycle** | Ephemeral compute, wiped on restart | Persistent filesystem across restarts |
| **Storage** | Volume-attached, external | Built-in 100GB, S3-backed + NVMe cache |
| **State model** | Stateless (design for restart) | Stateful (design for checkpoint/restore) |
| **Scaling** | Multi-region, multi-instance | Single instance, single region |
| **Use case** | Production services | AI agent sandboxes, dev environments |
| **API** | `api.machines.dev` | `api.sprites.dev` |
| **GPU** | Yes | No |

## Core Mental Model

```
cold (S3) ──wake 1-2s──▶ running ◀──wake 100-500ms── warm (NVMe)
                             │
                    ┌────────┼────────┐
                    ▼        ▼        ▼
               checkpoint  exec   services
               (incremental, ~300ms)
```

**Lifecycle states:** `running` (actively executing), `warm` (recently idle,
NVMe-cached, fast resume), `cold` (extended idle, S3-backed, slower resume).

**Persistence model:** All files, packages, repos, and databases survive
sleep/wake cycles. Running processes and in-memory data do NOT survive.

**Checkpoints:** Capture entire filesystem state incrementally (~300ms).
Copy-on-write — only changed blocks are stored. Restore replaces the
entire filesystem; changes since the checkpoint are lost.

## Critical Gotchas

### "Current" Checkpoint Is Poison

Sprites auto-create a "Current" snapshot of live state. **Never restore it.**
Restoring "Current" restarts the VM and causes persistent 503 errors on
subsequent exec calls. Always filter it out when selecting checkpoints:

```typescript
const checkpoints = await sprites.listCheckpoints();
const usable = checkpoints
  .filter((cp) => cp.id !== "Current")
  .sort((a, b) => new Date(b.create_time).getTime() - new Date(a.create_time).getTime());
const latest = usable[0];
```

### Commas in Env Values Break Exec

The CLI uses comma as the env delimiter (`--env KEY=val,FOO=bar`).
**Values containing commas are silently split into garbage.**

```bash
# BAD: value gets truncated at the comma
sprite exec --env AUTH="Bearer token,extra" env

# GOOD: use the API directly for complex values, or encode
# The HTTP API accepts env as repeated query params: ?env=KEY=val&env=FOO=bar
```

Validate programmatically: reject any env value containing `,` before
passing to the CLI. The HTTP API's repeated `?env=` params are safer.

### 503 "Process Not Ready" Is Transient

After checkpoint restore, the VM needs a moment to boot. Exec calls
during this window return `503`. **Always retry with backoff:**

```typescript
async function execWithRetry(
  sprites: SpritesClient,
  cmd: string[],
  opts: ExecOptions,
  maxAttempts = 3,
  delayMs = 5000,
): Promise<ExecResult> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await sprites.exec(cmd, opts);
    } catch (err) {
      if (attempt < maxAttempts && isTransient503(err)) {
        await sleep(delayMs);
        continue;
      }
      throw err;
    }
  }
  throw new Error("unreachable");
}
```

### Performance Degrades Under Sustained Use

Community reports: after extended sessions, operations like `git status`
can take minutes. The workaround is checkpoint-restore to a clean state
between heavy workloads. This is why automation pipelines restore
checkpoints before each run — not just for reproducibility, but performance.

### Data Loss Is Possible

Users have reported Sprites resetting to empty state after days of work.
**Checkpoints are your only safety net.** Create them after any significant
setup work. Don't rely on the filesystem persisting indefinitely without
explicit checkpoints.

### Destruction Is Irreversible

`sprite destroy` permanently deletes all data, packages, and checkpoints
with no undo. There is no soft-delete or recovery period.

### Single Region

Sprites currently run in a single Fly.io region (not user-selectable).
This affects latency for exec calls from distant orchestrators.

## Credential Hygiene

> Secrets must NEVER persist to Sprite disk or checkpoints.
> Every credential is injected per-exec and cleaned on exit.

### Per-Exec Injection (Preferred)

Pass secrets via `--env` flag or API env params. They exist only in the
process environment of that exec call, not on disk:

```bash
sprite exec -s my-sprite --env "ANTHROPIC_API_KEY=$KEY,GITHUB_TOKEN=$PAT" \
  claude --dangerously-skip-permissions -p "fix the bug"
```

### Store-Based Git Helper (When Git Needs Persistent Auth)

For multi-step scripts where git commands need auth across subshells:

```bash
#!/usr/bin/env bash
set -euo pipefail

GH_CREDENTIALS_FILE="/tmp/.git-credentials-$$"
trap 'rm -f "$GH_CREDENTIALS_FILE"; git config --global --unset credential.helper 2>/dev/null || true' EXIT

git config --global credential.helper "store --file=$GH_CREDENTIALS_FILE"
echo "https://x-access-token:${GH_TOKEN}@github.com" > "$GH_CREDENTIALS_FILE"

# ... git operations ...
```

**The EXIT trap is non-negotiable.** Without it, credentials persist to disk
and get baked into the next checkpoint.

### HTTP Extraheader (Single-Command Auth)

For one-shot fetch operations, avoid the credential store entirely:

```bash
AUTH_HEADER="AUTHORIZATION: basic $(echo -n "x-access-token:${GITHUB_PAT}" | base64)"
git -c "http.https://github.com/.extraheader=${AUTH_HEADER}" fetch origin main
```

## Network Policies

DNS-based outbound filtering. Changes apply immediately — existing
connections to newly-blocked domains are terminated. Failed lookups
return REFUSED for fast failure.

```bash
# Set policy via API
curl -X POST "https://api.sprites.dev/v1/sprites/${NAME}/policy/network" \
  -H "Authorization: Bearer $SPRITES_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rules": [
      {"action": "allow", "domain": "github.com"},
      {"action": "allow", "domain": "*.github.com"},
      {"action": "allow", "domain": "api.openai.com"},
      {"action": "deny", "domain": "*"}
    ]
  }'
```

**UDP is blocked when any domain rules are set.** This breaks Tailscale,
WireGuard, and any UDP-based protocols. There is no workaround — if you
need UDP, you cannot use network policies.

## Exec Protocol

### HTTP POST (Non-Interactive)

```
POST /v1/sprites/{name}/exec
Query: ?cmd=bash&cmd=-c&cmd=echo+hello&dir=/home/sprite&env=KEY=val
```

Returns binary channel-multiplexed data:
- `0x01` — stdout
- `0x02` — stderr
- `0x03` — exit code

Each frame: `[channel_byte][4-byte big-endian length][payload]`

### WebSocket (Interactive/Persistent)

```
WSS /v1/sprites/{name}/exec?cmd=bash&tty=true
```

Sessions persist after disconnect. TTY sessions persist indefinitely;
non-TTY sessions timeout after 10 seconds by default. Configure with
`max_run_after_disconnect` query param.

## SDKs

| Language | Package | Exec Model |
|----------|---------|------------|
| JavaScript | `@fly/sprites` (npm) | Mirrors `child_process` |
| Python | `sprites-py` (pip) | — |
| Go | `github.com/superfly/sprites-go` | Mirrors `exec.Cmd` |
| Elixir | `{:sprites, github: "superfly/sprites-ex"}` | — |
| Rust | `sprites-rs` (community) | — |

## Checkpoint Patterns

### Automation Pipeline Pattern

Restore → sync → execute → discard. Each run starts clean:

```typescript
// 1. Pick latest non-Current checkpoint
const checkpoint = await selectLatestCheckpoint(sprites);

// 2. Restore (replaces entire filesystem)
await sprites.restoreCheckpoint(checkpoint.id);

// 3. Sync repos to desired state
await sprites.exec(["bash", "-c", `
  set -e
  cd /home/sprite/repos/myapp
  git fetch origin main
  git checkout main
  git reset --hard FETCH_HEAD
`], { env: { GH_TOKEN: token } });

// 4. Run agent workload
const result = await sprites.exec(
  ["claude", "--dangerously-skip-permissions", "-p", prompt],
  { env: { ANTHROPIC_API_KEY: key }, timeoutMs: 45 * 60_000 },
);
```

### Refresh Script Pattern

Provision tools, sync repos, create a reusable checkpoint:

```bash
#!/usr/bin/env bash
set -euo pipefail

SPRITE_NAME="${1:?Usage: refresh-checkpoint.sh <sprite-name>}"

# Sync repos
sprite exec -s "$SPRITE_NAME" --env "GH_TOKEN=$GITHUB_PAT" -- bash -c '
  set -euo pipefail
  GH_CREDENTIALS_FILE="/tmp/.git-creds-$$"
  trap "rm -f $GH_CREDENTIALS_FILE; git config --global --unset credential.helper 2>/dev/null || true" EXIT
  git config --global credential.helper "store --file=$GH_CREDENTIALS_FILE"
  echo "https://x-access-token:${GH_TOKEN}@github.com" > "$GH_CREDENTIALS_FILE"

  cd /home/sprite/repos/myapp
  git fetch origin main && git checkout main && git reset --hard FETCH_HEAD
  npm install
'

# Create checkpoint
sprite checkpoint create -s "$SPRITE_NAME" --comment "Pipeline checkpoint $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

### Verify Script Pattern

Validate a Sprite is ready for production workloads:

```bash
#!/usr/bin/env bash
set -euo pipefail

SPRITE_NAME="${1:?Usage: verify-sprite.sh <sprite-name>}"
ERRORS=0

check() {
  local desc="$1"; shift
  if ! sprite exec -s "$SPRITE_NAME" -- "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc"
    ERRORS=$((ERRORS + 1))
  else
    echo "PASS: $desc"
  fi
}

check "git identity" git config user.email
check "repos exist" test -d /home/sprite/repos/myapp/.git
check "gh cli" gh --version
check "node available" node --version

# Credential safety: ensure no leaked secrets
CRED_CHECK=$(sprite exec -s "$SPRITE_NAME" -- bash -c \
  'find /home/sprite -name ".git-credentials*" -o -name ".netrc" 2>/dev/null | head -1')
if [ -n "$CRED_CHECK" ]; then
  echo "FAIL: credential files found on disk: $CRED_CHECK"
  ERRORS=$((ERRORS + 1))
fi

exit $ERRORS
```

## Services

Long-running processes managed by the Sprites runtime. Auto-restart on wake.

```bash
# Create a service
sprite exec -s my-sprite -- sprite-env services create my-api \
  --cmd "node" --args "dist/server.js" --http-port 3000

# Services survive sleep/wake — they restart automatically
# Access via: https://my-sprite-abc123.sprites.app (routes to http-port)
```

Services can declare dependencies (`--needs other-service`) for ordered startup.

## Pricing

| Resource | Rate |
|----------|------|
| CPU | ~$0.07/hour |
| Memory | ~$0.04/GB-hour |
| Hot storage (NVMe) | Included |
| Cold storage (Tigris/S3) | $0.02/GB-month |
| Concurrency slot | $1/month per slot |

**Auto-sleep keeps costs low.** A 4-hour coding session ≈ $0.46.
Idle Sprites in cold storage cost only the storage fee.

**Watch for:** Sprites that don't shut off (reported bug), costing CPU
hours while appearing idle. Monitor billing if running production workloads.

## Anti-Patterns

- Restoring the "Current" checkpoint — causes 503 cascade
- Persisting secrets to Sprite disk — they survive in checkpoints
- Skipping EXIT trap for credential cleanup — credentials leak to next checkpoint
- Using commas in `--env` values — silently corrupts values
- Relying on filesystem persistence without explicit checkpoints — data loss risk
- Running GPU workloads — not supported, use Fly Machines instead
- Setting network policies when UDP is needed — blocks all UDP
- Single long-lived session without checkpoint-restore cycles — performance degrades
- Hardcoding checkpoint IDs — use latest-non-Current selection logic
- Ignoring 503 after restore — always retry with backoff
