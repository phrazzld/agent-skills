---
name: fly-io
user-invocable: false
description: "Fly.io deployment patterns, production gotchas, and operational knowledge. Volume lifecycle, auto_stop edge cases, secrets staging, health check tuning, SQLite backup (Litestream+Tigris), multi-region fly-replay, cost traps. Invoke when deploying to Fly.io, writing fly.toml, Dockerfiles for Fly, or debugging Fly infrastructure."
---

# Fly.io

Production patterns and gotchas for deploying on Fly.io Machines.

## Triggers

Invoke when:
- File contains `fly.toml`, `Dockerfile`, or Fly CLI references
- Code handles `SIGTERM` or graceful shutdown for containers
- Health check endpoints, structured logging, or volume mounts
- Deploying SQLite-backed services with persistent storage

## Core Principle

> Machines are ephemeral compute. Volumes are durable-ish storage.
> Design for restart, not uptime. Design for data loss, not permanence.

Machines restart on deploy, host migration, and OOM. Root filesystem is
wiped every time. Persistent state goes on volumes. Transient state drains
gracefully on SIGTERM (10 seconds default).

## Critical Gotchas (What the Docs Understate)

### auto_stop_machines Bugs

**`min_machines_running = 1` can scale to zero.** Known bug spanning 2023-2025.
Causes: missing `primary_region` in fly.toml, and the fact that
`min_machines_running` only applies to the primary region — replicas
in other regions still scale to zero.

**Streaming connections get killed.** Autostop only watches for *incoming*
HTTP requests. During long-running streams where the server pushes data,
autostop sees no new requests and suspends the Machine mid-stream.

**Flycast connections prevent autostop.** Machines connected to internal
Flycast addresses (e.g., database connections) stay "alive" indefinitely
even with zero user traffic.

### Volume Lifecycle Traps

**Volumes bill while machines are stopped.** The #1 surprise bill.
10GB volume in 3 regions = $4.50/month regardless of machine state.

**Orphaned volumes are hard to clean up.** Destroying a Machine does NOT
destroy its volume. Orphaned volumes can get stuck in `pending_destroy`
for hours/days. Some can't be deleted at all due to internal precondition
errors. They keep billing you silently.

**Snapshots are daily, non-deterministic timing.** Not a real backup
strategy. Default retention: 5 days (configurable 1-60). Volume snapshots
became billable starting January 2026.

**Bluegreen deploys cannot use volumes.** This is a hard constraint.
If your app has volumes, you're limited to `rolling` or `canary` strategy.

### Secrets Gotchas

**`fly secrets set` triggers a redeploy with OLD code.** Setting a secret
deploys immediately with the new secret but the currently-deployed app code.
If new code expects a new secret format, old code runs with new secrets
during the deploy window.

**Fix: Use `--stage` for atomic deploys.**
```bash
fly secrets set DATABASE_URL=postgres://... --stage  # stores, no deploy
fly deploy                                            # deploys code + staged secrets atomically
```

**Secrets are NOT available during Docker build.** Use build secrets:
```dockerfile
RUN --mount=type=secret,id=my_secret cat /run/secrets/my_secret
```
Build secrets don't leak into final image layers.

**Secrets don't hot-reload.** Injected at boot time only. Rotation
requires Machine restart. For frequent rotation, use a secrets manager
your app polls (Vault, AWS Secrets Manager).

### Networking

**6PN addresses change on host migration.** Use
`<machine_id>.vm.<appname>.internal` for stable addressing, not raw IPs.

**Stopped machines are invisible to DNS.** `.internal` AAAA queries only
return running Machines. Use Flycast if you need the proxy to wake machines.

**Internal DNS server is `fdaa::3`.** Tools like `dig` won't use it
automatically: `dig @fdaa::3 myapp.internal AAAA`.

**Use `Fly-Client-IP` header, not `X-Forwarded-For`.** XFF contains
multiple IPs when behind additional proxies (Cloudflare, etc.).

## fly.toml Patterns

### Stateless (Scale-to-Zero)

```toml
app = "my-service"
primary_region = "sjc"    # REQUIRED — min_machines_running breaks without this

[build]
  dockerfile = "Dockerfile"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"      # "suspend" for ~100ms resume (≤2GB RAM only)
  auto_start_machines = true
  min_machines_running = 0

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

### Stateful (SQLite + Volume)

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
  auto_stop_machines = "off"       # NEVER auto_stop with volumes
  auto_start_machines = true
  min_machines_running = 1

[[http_service.checks]]
  interval = "15s"
  timeout = "5s"
  grace_period = "10s"             # Increase for slow-booting apps
  method = "GET"
  path = "/health"

[deploy]
  strategy = "rolling"             # bluegreen CANNOT use volumes

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

### Key Decisions

| Setting | Stateless | Stateful | Why |
|---------|-----------|----------|-----|
| `auto_stop_machines` | `"stop"` or `"suspend"` | `"off"` | Autostop + volumes = data loss risk |
| `min_machines_running` | `0` | `1` | But verify `primary_region` is set |
| `mounts` | None | Required | Everything else is ephemeral |
| Health checks | Optional | Required | Stateful needs readiness gating |
| Deploy strategy | `bluegreen` | `rolling` | Bluegreen incompatible with volumes |

## SQLite Backup: Litestream + Tigris

**LiteFS Cloud was sunset October 2024.** Litestream + Tigris is the
recommended production pattern. Tigris is Fly's S3-compatible storage.

```yaml
# litestream.yml
dbs:
  - path: /data/app.db
    replicas:
      - type: s3
        bucket: ${BUCKET_NAME}
        path: app.db
        endpoint: ${AWS_ENDPOINT_URL_S3}
        region: ${AWS_REGION}
```

**Recovery pattern:** Delete machine and volume, run `fly deploy`,
Litestream auto-restores from backup on first boot.

**Defense in depth:** Volume for fast local I/O, Litestream for continuous
off-site backup, volume snapshots as last resort. Single-writer constraint
is absolute — one Machine writes, period.

## Graceful Shutdown

Fly sends SIGTERM before stopping. Default: 10 seconds.

```typescript
const server = serve({ fetch: app.fetch, port: 8080 });

function shutdown() {
  log("info", "SIGTERM received, draining");
  stopTimers();         // Clear intervals/timeouts
  drainQueue();         // Finish in-flight work
  server.close();       // Stop accepting new connections
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
```

Drain: in-flight HTTP requests, background job queues, polling loops.
Don't drain: database connections (close on exit is fine), log flushes
(stdout is unbuffered in containers).

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

### Native Modules (better-sqlite3, sharp, bcrypt)

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

### Build Gotchas

- **Remote builder cache is ephemeral.** Builder Machines get destroyed
  and recreated; all cached layers vanish. Builds then download everything.
- **Apple Silicon builds produce wrong arch.** Use `--platform linux/amd64`
  in Dockerfile or use the remote builder (which is amd64).
- **node-gyp needs Python.** Alpine images lack it. Use `-slim` Debian.
- **.dockerignore is critical.** Large `node_modules`, `.git`, media files
  sent to remote builder cause timeouts.
- **Alternative:** Use Depot for faster builds, or push pre-built images
  to Fly's registry.

## Machine Sizing

| VM Size | CPU | RAM | Use Case |
|---------|-----|-----|----------|
| `shared-cpu-1x` | Shared 1 vCPU | 256mb | API servers, webhooks, queues |
| `shared-cpu-2x` | Shared 2 vCPU | 512mb | Moderate compute |
| `performance-1x` | Dedicated 1 vCPU | 2gb | CPU-bound, databases |
| `performance-2x` | Dedicated 2 vCPU | 4gb | Heavy compute |

**Shared-cpu burst balance is finite (50 seconds).** CPU-heavy operations
(JVM startup, builds, heavy init) exhaust it, causing throttling. Health
checks then fail during deploys because the app boots too slowly.

**Suspend only works ≤2GB RAM, no swap, no schedule, no GPU.** Otherwise
it silently falls back to stop (~2+ seconds vs ~100ms resume).

## Multi-Region: fly-replay

**Write forwarding is NOT automatic.** Your app must implement it:

```typescript
app.use("*", async (c, next) => {
  if (isWriteRequest(c.req) && process.env.FLY_REGION !== PRIMARY_REGION) {
    return new Response(null, {
      status: 409,
      headers: { "fly-replay": `region=${PRIMARY_REGION}` },
    });
  }
  return next();
});
```

Fly Proxy replays the entire HTTP request to the primary region.
Not suitable for write-heavy apps or WebSocket workloads.

**Read-after-write consistency gap:** Replicas don't immediately reflect
writes forwarded to the primary. Design for eventual consistency.

## Cost Traps

| Trap | Detail |
|------|--------|
| Volumes bill 24/7 | Even when machine is stopped |
| Orphaned volumes | Keep billing after machine destruction |
| Managed services persist | Fly Postgres, Upstash Redis, Tigris survive app deletion |
| Regional pricing | sin/syd/gru cost more than iad/ams |
| Bluegreen doubles machines | Both old and new run during switchover |
| Snapshot billing | Volume snapshots billable since Jan 2026 |

**Always-on shared-cpu-1x: ~$1.80/mo.** Scale-to-zero: pay only during
active time. Cold start: ~5 seconds from stop, ~100ms from suspend.

## Anti-Patterns

- `auto_stop_machines` with volumes — data loss risk
- Multiple machines with SQLite — split-brain, no concurrent writers
- Secrets in fly.toml `[env]` — use `fly secrets set`
- `fly secrets set` without `--stage` when deploying new code simultaneously
- `bluegreen` strategy with volumes — hard incompatibility
- Missing `primary_region` — breaks `min_machines_running`
- Relying on volume snapshots as primary backup — use Litestream
- `process.exit(0)` without draining — connections drop on deploy
- Logging to files inside container — lost on restart, use stdout JSON
