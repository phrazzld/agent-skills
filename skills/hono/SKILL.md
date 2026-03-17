---
name: hono
user-invocable: false
description: "Hono web framework patterns, production gotchas, and runtime-specific quirks. Body double-read trap, middleware ordering, TypeScript type inference limits, Context Storage, streaming pitfalls, router selection, RPC type performance, security advisories. Invoke when writing Hono routes, middleware, tests, or deploying Hono apps."
---

# Hono

Production patterns and gotchas for the Hono web framework.

## Triggers

Invoke when:
- Code imports from `hono`, `hono/*`, or `@hono/*`
- File defines HTTP routes or middleware
- Writing tests with `app.request()` or `testClient()`
- Configuring `@hono/node-server`, Bun, Cloudflare Workers, or Deno adapters

## Core Principle

> Hono is a thin routing layer with composable middleware. Handlers read
> input, call domain functions, and return responses. No business logic
> in route files.

Hono uses Web Standard `Request`/`Response`. You *return* responses,
not mutate them. This is the fundamental shift from Express.

## Critical Gotchas (What the Docs Understate)

### Body Can Only Be Read Once

This is the Web Streams API constraint, but it bites hard in Hono.
**If `zValidator` reads the body for validation, you CANNOT read it again
in the handler** for webhook signature verification or raw body access.

```typescript
// BAD: body already consumed by zValidator
router.post("/webhook", zValidator("json", schema), async (c) => {
  const raw = await c.req.text(); // EMPTY — body already consumed
  verifySignature(raw, c.req.header("x-signature"));
});

// GOOD: clone before any read
router.post("/webhook", async (c) => {
  const raw = await c.req.raw.clone().text();   // clone preserves body
  verifySignature(raw, c.req.header("x-signature"));
  const body = JSON.parse(raw);
  // ... process body
});
```

**Also:** `c.req.json()` caches to `bodyCache[json]` but NOT to
`bodyCache[arrayBuffer]`. Downstream middleware expecting arrayBuffer
will fail silently with malformed data. And `c.req.json()` throws on
null bodies instead of returning null — guard optional request bodies.

### Middleware Ordering

**CORS middleware MUST come before routes.** If applied after, CORS
headers are missing from responses. The CORS middleware also invokes
`next()` twice (preflight + actual request), which can trigger wildcard
route handlers during OPTIONS preflight.

```typescript
// GOOD: CORS before routes
app.use("*", cors({ origin: "https://myapp.com" }));
app.route("/api", apiRouter);

// BAD: CORS after routes — headers missing
app.route("/api", apiRouter);
app.use("*", cors({ origin: "https://myapp.com" }));
```

**CORS Content-Type bug:** When clients send `Content-Type` in custom
headers (e.g., Vercel AI SDK), CORS middleware falls back to default
config instead of configured settings.

### TypeScript Inference Breaks with 3+ Middlewares

In a chain of `app.use(m1, m2, m3)`, intermediate middlewares lose their
custom context type and revert to `BlankEnv`. Only the last middleware
maintains correct typing.

```typescript
// BAD: m1's variables invisible in handler
app.get("/", m1, m2, m3, (c) => {
  c.var.fromM1; // TypeScript says this doesn't exist
});

// GOOD: use createFactory
import { createFactory } from "hono/factory";
const factory = createFactory();
const handlers = factory.createHandlers(m1, m2, m3, (c) => {
  c.var.fromM1; // correctly typed
});
app.get("/", ...handlers);
```

### Memory Leaks from Middleware Closures

Anonymous functions in middleware create new unique objects per request,
causing GC pressure. Use named functions. The CORS middleware specifically
had a memory leak on `@hono/node-server` from mutating options objects.
The JWT middleware had a similar leak.

### Context is Request-Scoped

`c.set()`/`c.get()` exist only within a single request. They cannot
be shared across requests. This is by design but surprises Express users.

**Context Storage Middleware (v4.6.0+):** Use `AsyncLocalStorage` to
access context outside handlers — in service layers, database modules:
```typescript
import { contextStorage, getContext } from "hono/context-storage";

app.use(contextStorage());

// In any module, not just handlers:
function getCurrentUser() {
  return getContext().var.user;
}
```
Requires `nodejs_compat` or `nodejs_als` flag on Cloudflare Workers.

## Security Advisories

| CVE | Severity | Fixed In | Detail |
|-----|----------|----------|--------|
| CVE-2026-29086 | Medium | 4.12.4 | `setCookie()` doesn't sanitize `;`, `\r`, `\n` in domain/path — cookie attribute injection |
| Vary header injection | Medium | 4.10.3 | CORS middleware reflected request Vary headers into response — cache poisoning |

**Always pin Hono ≥ 4.12.4.**

## App Structure

### Router Factory Pattern

Each route group is a factory function returning `new Hono()`. Enables
dependency injection and testability without mocking.

```typescript
// routes/webhook.ts
export function createWebhookRouter(onEvent: EventHandler) {
  const router = new Hono();

  router.post("/ingest", async (c) => {
    let body: unknown;
    try { body = await c.req.json(); }
    catch { return c.json({ error: "Invalid JSON" }, 400); }

    const result = validateEvent(body);
    if (!result.ok) return c.json({ error: result.error }, 400);

    await onEvent(result.event);
    return c.json({ accepted: true }, 202);
  });

  return router;
}
```

```typescript
// app.ts
const webhookRouter = createWebhookRouter(handleEvent);
app.use("/webhooks/*", bearerAuth({ token: SECRET }));
app.route("/webhooks", webhookRouter);
```

### Route Ordering

```
1. Global middleware (logger, contextStorage)
2. Public routes (health, landing)
3. Auth middleware (on path prefix)
4. Protected API routes
5. Dashboard/UI routes (separate auth)
```

## Request Validation

Validate with pure functions. Return discriminated unions, not exceptions.

```typescript
type ValidationResult =
  | { ok: true; event: WebhookEvent }
  | { ok: false; error: string };

export function validateWebhookEvent(body: unknown): ValidationResult {
  if (typeof body !== "object" || body === null) {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const obj = body as Record<string, unknown>;
  if (typeof obj.type !== "string" || !VALID_TYPES.has(obj.type)) {
    return { ok: false, error: `Invalid or missing type` };
  }
  return { ok: true, event: obj as WebhookEvent };
}
```

## Error Handling

**Default:** Without custom `onError`, Hono calls `err.getResponse()`
on `HTTPException` instances. **If you define custom `onError`, you must
handle HTTPException yourself:**

```typescript
app.onError((err, c) => {
  if (err instanceof HTTPException) return err.getResponse();
  console.error(err);
  return c.json({ error: "Internal error" }, 500);
});
```

Route-level `onError` (on sub-apps via `app.route()`) takes priority
over app-level.

## Router Selection

Most people never change this, but it matters for performance:

| Router | Best For | Trade-off |
|--------|----------|-----------|
| **SmartRouter** (default) | General use | Auto-selects RegExp or Trie |
| **RegExpRouter** | Max request-matching speed | **Slow registration** — bad for serverless cold starts |
| **LinearRouter** | Edge/serverless | Fast registration, slower matching |
| **PatternRouter** | Memory-constrained | Smallest bundle |

**For serverless/edge where app initializes per request, use LinearRouter.**
RegExpRouter's registration overhead hurts cold starts.

## Streaming and SSE Pitfalls

**Streams auto-close.** The stream callback resolves and the connection
closes immediately unless you explicitly keep it alive with `stream.sleep()`.

**HTTP/2 is incompatible** with Hono's streaming helpers. They use
`Transfer-Encoding: chunked`, which is forbidden in HTTP/2. This breaks
streaming on platforms that default to HTTP/2.

**SSE requires explicit headers** on some deployments:
```typescript
return streamSSE(c, async (stream) => {
  // stream.sleep() keeps connection alive between events
  while (running) {
    await stream.writeSSE({ data: JSON.stringify(event) });
    await stream.sleep(1000);
  }
});
```

## Runtime-Specific Gotchas

### Node.js (`@hono/node-server`)

- **Streaming doesn't work incrementally.** Responses send in full, not
  streamed. Known limitation of the Node adapter.
- Translates between Node's `IncomingMessage`/`ServerResponse` and Web
  Standard `Request`/`Response` — adds overhead vs native platforms.
- Memory leak was found in `Readable.toWeb()` body consumption (fixed).

### Bun

- Adding headers after context finalization → incorrect `content-type`.
- `c.executionCtx` getter **throws** instead of returning undefined.
- `stream.onAbort()` can crash the server.

### Cloudflare Workers

- `env()` reads from `wrangler.toml`, not `process.env`.
- `waitUntil()` has a 30-second shared limit across all calls in one request.
- Lambda@Edge adapter doesn't Base64-encode gzipped responses.

### Deno

Most compatible with Hono's Web Standards approach. Fewest quirks.

## Testing

### app.request() — The Foundation

```typescript
import { describe, it, expect } from "vitest";

describe("webhook routes", () => {
  const handler = vi.fn();
  const app = new Hono();
  app.route("/webhooks", createWebhookRouter(handler));

  it("accepts valid event", async () => {
    const res = await app.request("/webhooks/ingest", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ type: "bug", id: "123" }),
    });
    expect(res.status).toBe(202);
    expect(handler).toHaveBeenCalledOnce();
  });

  it("rejects invalid body", async () => {
    const res = await app.request("/webhooks/ingest", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ invalid: true }),
    });
    expect(res.status).toBe(400);
  });
});
```

### testClient() for Type Safety

```typescript
import { testClient } from "hono/testing";

const client = testClient(app);
const res = await client.api.users.$get();  // typed routes
```

### Testing Auth

```typescript
// Authenticated
const res = await app.request("/api/data", {
  headers: { Authorization: `Bearer ${SECRET}` },
});

// Unauthenticated
const res2 = await app.request("/api/data");
expect(res2.status).toBe(401);
```

### Cookie/Redirect Testing

```typescript
// Use redirect: "manual" to capture redirects
const res = await app.request("/login", {
  method: "POST",
  body: new URLSearchParams({ password: "correct" }).toString(),
  headers: { "Content-Type": "application/x-www-form-urlencoded" },
  redirect: "manual",
});
expect(res.status).toBe(302);
expect(res.headers.get("set-cookie")).toContain("session=");
```

### Mock Env Bindings (Cloudflare)

```typescript
app.request("/path", {}, { DB: mockDb, SECRET: "test" });
```

### Pattern: Test the Router, Not the App

Create the router with test dependencies, mount on fresh `Hono()`.
No need to replicate full app middleware stack.

## RPC and Type-Safe Client

**`hc()` type calculation is expensive.** For large route sets,
`hc<typeof app>` makes tsserver crawl. Pre-compute the type:

```typescript
export type Client = ReturnType<typeof hc<typeof app>>;
export const hcWithType = (...args: Parameters<typeof hc>): Client =>
  hc<typeof app>(...args);
```

**RPC error typing is weak.** `InferResponseType` works for success but
there's no built-in way to type error response bodies. Open RFC (#4270).

## OpenAPI Integration

**`@hono/zod-openapi` requires rewriting routes.** Can't retrofit onto
existing Hono routes — it's an extended Hono class with different syntax.
For large apps, this is significant migration cost.

**Alternative:** `hono-openapi` (rhinobase) is validator-agnostic
(Zod, Valibot, ArkType, TypeBox via Standard Schema). Less coupling.

## Anti-Patterns

- Business logic in route handlers — extract to domain functions
- Global middleware for path-specific auth — `app.use("*", bearerAuth(...))` blocks `/health`
- Module-level app singleton — can't inject test deps
- Catching `c.req.json()` errors silently — `catch(() => ({}))` masks invalid input
- Reading body twice — clone first if you need raw + parsed
- Chaining 3+ middlewares inline — use `createFactory().createHandlers()`
- Testing against the full app instead of isolated routers
- Using RegExpRouter on serverless — slow cold starts
- Relying on `c.executionCtx` cross-platform — throws on Bun, wrong on Next.js
- Streaming with HTTP/2 — Transfer-Encoding: chunked is forbidden
