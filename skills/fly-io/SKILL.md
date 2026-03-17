---
name: fly-io
user-invocable: false
description: "Fly.io deployment patterns: fly.toml configuration, Machine sizing, volumes, health checks, graceful shutdown, structured logging for log drains, and multi-stage Docker builds. Invoke when deploying to Fly.io, configuring Machines, or writing Dockerfiles for Fly."
---

# Fly.io

Patterns for deploying and operating services on Fly.io Machines.

## Triggers

Invoke this skill when:
- File path contains `fly.toml`, `Dockerfile`, or `Fly` references
- Code handles `SIGTERM` or graceful shutdown
- Health check endpoints are being written
- Structured JSON logging targets a log drain
- Deploying a service with persistent storage (SQLite, volumes)

## Core Principle

> Fly Machines are ephemeral compute with optional persistence. Design for restart, not uptime.

Machines restart on deploy, on host migration, and on OOM. Your service must
survive restarts with zero data loss. Persistent state goes on volumes.
Transient state drains gracefully on SIGTERM.

## fly.toml Configuration

### Minimal Stateless Service

```toml
app = "my-service"
primary_region = "sjc"

[build]
  dockerfile = "Dockerfile"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

### Stateful Service (SQLite + Volume)

```toml
app = "my-service"
primary_region = "sjc"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"
  DB_PATH = "/data/app.db"

[mounts]
  source = "app_data"
  destination = "/data"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "off"    # Always-on for stateful services
  auto_start_machines = true
  min_machines_running = 1

[[http_service.checks]]
  interval = "15s"
  timeout = "5s"
  grace_period = "10s"
  method = "GET"
  path = "/health"

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

### Key Decisions

| Setting | Stateless | Stateful |
|---------|-----------|----------|
| `auto_stop_machines` | `"stop"` (scale to zero) | `"off"` (always-on) |
| `min_machines_running` | `0` | `1` |
| `mounts` | None | Required for durable data |
| Health checks | Optional | Required |

## Machine Sizing

| VM Size | CPU | RAM | Use Case |
|---------|-----|-----|----------|
| `shared-cpu-1x` | Shared 1 vCPU | 256mb | API servers, webhooks, queues |
| `shared-cpu-2x` | Shared 2 vCPU | 512mb | Moderate compute, builds |
| `performance-1x` | Dedicated 1 vCPU | 2gb | CPU-bound work, databases |
| `performance-2x` | Dedicated 2 vCPU | 4gb | Heavy compute, large datasets |

**Rule of thumb:** Start with `shared-cpu-1x` / `256mb`. Upgrade only when
health checks show latency or OOM kills appear in logs.

## Health Checks

Fly uses health checks to determine Machine readiness and route traffic.

```typescript
app.get("/health", (c) => {
  const status = {
    status: "ok",
    version: process.env.FLY_ALLOC_ID ?? "local",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  };
  return c.json(status, 200);
});
```

**Rich health checks** include dependency status:

```typescript
app.get("/health", (c) => {
  const dbOk = checkDatabase();
  const queuesHealthy = checkQueues();
  const healthy = dbOk && queuesHealthy;

  return c.json({
    status: healthy ? "ok" : "degraded",
    db: dbOk,
    queues: queuesHealthy,
    uptime: process.uptime(),
  }, healthy ? 200 : 503);
});
```

**Health check settings:**
- `interval`: 10-30s (15s default is good)
- `timeout`: 2-5s (fail fast)
- `grace_period`: Time after deploy before checks start (10-30s)

## Graceful Shutdown

Fly sends SIGTERM before stopping a Machine. You get 10 seconds by default.

```typescript
const server = serve({ fetch: app.fetch, port: 8080 });

function shutdown() {
  log("info", "SIGTERM received, draining");
  stopTimers();         // Clear intervals/timeouts
  drainQueue();         // Finish in-flight work
  server.close();       // Stop accepting connections
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
```

**What to drain:**
- In-flight HTTP requests (handled by Node's `server.close()`)
- Background job queues (finish current, stop accepting)
- Timer-based polling loops (`clearInterval`)

**What NOT to drain:**
- Database connections (close on process exit is fine)
- Log flushes (stdout is unbuffered in containers)

## Structured Logging

Fly log drains ingest JSON lines from stdout/stderr. Structure logs for searchability.

```typescript
function log(
  level: "info" | "warn" | "error",
  message: string,
  data?: Record<string, unknown>,
): void {
  const entry: Record<string, unknown> = {
    level,
    message,
    service: "my-service",
    timestamp: new Date().toISOString(),
  };
  if (data) Object.assign(entry, data);
  const out = level === "error" ? process.stderr : process.stdout;
  out.write(JSON.stringify(entry) + "\n");
}
```

**Required fields:** `level`, `message`, `timestamp`, `service`.
**Optional context:** `traceId`, `userId`, `operation`, `durationMs`.

## Dockerfile Patterns

### Multi-Stage Build (Node.js)

```dockerfile
FROM node:22-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 8080
CMD ["node", "dist/index.js"]
```

**Native modules** (e.g., better-sqlite3): Build from source in the builder stage
to match the runtime architecture.

```dockerfile
FROM node:22-slim AS builder
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package*.json ./
RUN npm ci --build-from-source
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 8080
CMD ["node", "dist/index.js"]
```

### Image Size

- Use `node:22-slim` not `node:22` (saves ~600MB)
- Clean apt caches: `rm -rf /var/lib/apt/lists/*`
- Don't copy dev dependencies to runtime stage
- `.dockerignore`: `node_modules`, `.git`, `test/`, `*.md`

## Volumes

Fly volumes are persistent NVMe storage attached to a single Machine.

```bash
# Create volume (once)
fly volumes create app_data --region sjc --size 1

# Reference in fly.toml
[mounts]
  source = "app_data"
  destination = "/data"
```

**Critical constraints:**
- Volumes are per-Machine, per-region. No cross-Machine sharing.
- Volume survives Machine restarts but is lost if the Machine is destroyed.
- For SQLite: single-Machine deployments only (`min_machines_running = 1`).
- Backup strategy: Litestream replication or periodic `fly sftp get`.

## Secrets

```bash
# Set secrets (encrypted at rest)
fly secrets set API_KEY=sk_live_xxx WEBHOOK_SECRET=whsec_xxx

# List (values hidden)
fly secrets list

# Unset
fly secrets unset API_KEY
```

**Never** put secrets in `fly.toml` `[env]`. Use `fly secrets set`.
Secrets are injected as environment variables at runtime.

## Deploy

```bash
# Standard deploy
fly deploy

# Deploy from specific directory
fly deploy --dockerfile orchestrator/Dockerfile

# Deploy with build args
fly deploy --build-arg VERSION=1.2.3
```

**Pre-deploy checklist:**
- [ ] Health check endpoint returns 200
- [ ] SIGTERM handler drains gracefully
- [ ] Secrets set via `fly secrets set`
- [ ] Volume created if stateful
- [ ] `.dockerignore` excludes dev artifacts

## Debugging

```bash
# SSH into running Machine
fly ssh console

# View logs (real-time)
fly logs

# Check Machine status
fly status

# View Machine details
fly machines list
```

## Anti-Patterns

```toml
# BAD: Secrets in fly.toml [env]
[env]
  API_KEY = "sk_live_xxx"

# BAD: auto_stop with volumes (data loss risk on stop/start)
[mounts]
  source = "data"
  destination = "/data"
[http_service]
  auto_stop_machines = "stop"

# BAD: Multiple machines with SQLite (split-brain)
[[vm]]
  size = "shared-cpu-1x"
  count = 3  # SQLite can't handle concurrent writers across machines
```

```typescript
// BAD: No SIGTERM handler (connections drop on deploy)
// BAD: Logging to files inside container (lost on restart)
// BAD: Using process.exit(0) without draining
```

## Cost Model

| Resource | Pricing |
|----------|---------|
| shared-cpu-1x | ~$0.0025/hr when running |
| 256mb RAM | Included with shared CPU |
| 1GB volume | ~$0.15/mo |
| Outbound transfer | 100GB free, then $0.02/GB |

Always-on shared-cpu-1x: ~$1.80/mo. Scale-to-zero: pay only for active time.
