# Sprites API Reference

Base URL: `https://api.sprites.dev/v1`
API Version: `v0.0.1-rc30`
Auth: `Authorization: Bearer $SPRITES_TOKEN`

Tokens created at sprites.dev/account or via `sprite org auth`.

## Sprites CRUD

### Create Sprite

```
POST /v1/sprites
```

```json
{
  "name": "my-sprite",
  "wait_for_capacity": false,
  "url_settings": { "auth": "sprite" }
}
```

| Status | Meaning |
|--------|---------|
| 201 | Created |
| 400 | Invalid name or name exists |
| 401 | Invalid/missing token |

Response includes: `id`, `name`, `organization`, `url`, `status`, timestamps.

### List Sprites

```
GET /v1/sprites?prefix=dev&max_results=50&continuation_token=...
```

Paginated. `max_results` 1-50, default 50.

### Get Sprite

```
GET /v1/sprites/{name}
```

Status field values: `running`, `cold`, `warm`.

### Update Sprite

```
PUT /v1/sprites/{name}
```

Currently only updates `url_settings.auth` (`"sprite"` or `"public"`).

### Delete Sprite

```
DELETE /v1/sprites/{name}
```

Returns 204. **Irreversible — all data, checkpoints permanently deleted.**

## Exec

### HTTP POST (Non-Interactive)

```
POST /v1/sprites/{name}/exec?cmd=ls&cmd=-la&dir=/home/sprite&env=KEY=val
```

Query params:
- `cmd` (repeatable) — command and args
- `dir` — working directory
- `env` (repeatable) — `KEY=VALUE` format
- `timeout` — execution timeout

Returns binary channel-multiplexed response:

```
[channel: 1 byte][length: 4 bytes big-endian][payload: N bytes]
```

| Channel | Meaning |
|---------|---------|
| `0x01` | stdout |
| `0x02` | stderr |
| `0x03` | exit code |

### WebSocket (Interactive)

```
WSS /v1/sprites/{name}/exec?cmd=bash&tty=true&cols=80&rows=24
```

Additional query params:
- `tty` — enable terminal emulation
- `stdin` — enable input stream
- `cols`, `rows` — terminal dimensions (default 80x24)
- `max_run_after_disconnect` — session persistence timeout
  (TTY default: indefinite, non-TTY default: 10s)
- `id` — session ID for reattachment

Server messages (JSON):

```json
{"type": "session_info", "session_id": 12345, "command": "bash", "tty": true, "is_owner": true}
{"type": "exit", "exit_code": 0}
{"type": "port_notification", "port": 3000, "address": "https://...sprites.app"}
```

Client messages:

```json
{"type": "resize", "cols": 120, "rows": 40}
```

### List Sessions

```
GET /v1/sprites/{name}/exec
```

### Attach to Session

```
WSS /v1/sprites/{name}/exec/{session_id}
```

Buffered output replayed on reattachment.

### Kill Session

```
POST /v1/sprites/{name}/exec/{session_id}/kill?signal=SIGTERM&timeout=10s
```

Returns streaming NDJSON with events: `signal`, `timeout`, `exited`, `killed`, `error`, `complete`.

## Checkpoints

### Create

```
POST /v1/sprites/{name}/checkpoint
```

```json
{ "comment": "Before migration" }
```

Returns streaming NDJSON: `info` → `complete` or `error`.

Captures: entire filesystem, file permissions/ownership.
Running processes stop during creation (milliseconds).
Incremental — only changed blocks stored.

### List

```
GET /v1/sprites/{name}/checkpoints
```

```json
[
  { "id": "v7", "create_time": "2026-01-05T10:30:00Z", "comment": "Before migration" },
  { "id": "v6", "create_time": "2026-01-04T09:00:00Z", "comment": "Initial setup" }
]
```

**Warning:** List may include auto-generated "Current" checkpoint.
Always filter it out before restore operations.

### Get

```
GET /v1/sprites/{name}/checkpoints/{checkpoint_id}
```

### Restore

```
POST /v1/sprites/{name}/checkpoints/{checkpoint_id}/restore
```

Returns streaming NDJSON: `info` → `complete` or `error`.

**Restore semantics:**
1. Stops all running services
2. Replaces entire filesystem with checkpoint state
3. Restarts services
4. Changes since checkpoint are permanently lost

**Post-restore:** VM may return 503 on immediate exec calls.
Retry with backoff (3 attempts, 5s delay).

### Delete

```
DELETE /v1/sprites/{name}/checkpoints/{checkpoint_id}
```

Last 5 checkpoints also accessible at `/.sprite/checkpoints` on the Sprite filesystem.

## Network Policy

### Get Policy

```
GET /v1/sprites/{name}/policy/network
```

### Set Policy

```
POST /v1/sprites/{name}/policy/network
```

```json
{
  "rules": [
    { "action": "allow", "domain": "github.com" },
    { "action": "allow", "domain": "*.github.com" },
    { "action": "deny", "domain": "*" }
  ]
}
```

Rule matching: exact domains, wildcard subdomains (`*.domain`), catch-all (`*`).
Changes apply immediately. Blocked connections terminated.
Failed DNS returns REFUSED.

**Setting ANY domain rules blocks ALL UDP traffic.**

## Filesystem

### Browse

```
GET /v1/sprites/{name}/filesystem?path=/home/sprite
```

### Read File

```
GET /v1/sprites/{name}/filesystem/{path}
```

### Write File

```
PUT /v1/sprites/{name}/filesystem/{path}
```

## Services

### Create/Update

```
PUT /v1/sprites/{name}/services/{service_name}
```

```json
{
  "cmd": "node",
  "args": ["dist/server.js"],
  "needs": ["database"],
  "http_port": 3000
}
```

### Start / Stop

```
POST /v1/sprites/{name}/services/{service_name}/start
POST /v1/sprites/{name}/services/{service_name}/stop
```

Both return streaming NDJSON with lifecycle events.

### Logs

```
GET /v1/sprites/{name}/services/{service_name}/logs
```

Streams `stdout`/`stderr` events with timestamps.

### List

```
GET /v1/sprites/{name}/services
```

## Proxy

```
POST /v1/sprites/{name}/proxy
```

Tunnels TCP connections to services inside the Sprite.
URL routing: `https://{name}-{hash}.sprites.app` → `http_port` or port 8080.

## Rate Limits

GitHub-style: unauthenticated 60 req/hour, authenticated 5000/hour.
Use `SPRITES_TOKEN` for all programmatic access.

## Error Patterns

| Status | Cause | Action |
|--------|-------|--------|
| 401 | Invalid/expired token | Re-authenticate via `sprite login` or refresh org token |
| 404 | Sprite doesn't exist | Create it, or check org context |
| 503 | VM not ready (post-restore) | Retry with backoff, 3 attempts, 5s delay |
| 500 | Internal error | Retry once, then report to Fly.io community |
