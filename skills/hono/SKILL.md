---
name: hono
user-invocable: false
description: "Hono web framework patterns: app structure, router composition, middleware, request validation, JSX rendering, cookie auth, testing with app.request(), and Node.js server adapter. Invoke when writing Hono routes, middleware, or tests."
---

# Hono

Patterns for building web services with the Hono framework.

## Triggers

Invoke this skill when:
- Code imports from `hono`, `hono/*`, or `@hono/*`
- File defines HTTP routes or middleware
- Writing tests that use `app.request()`
- Configuring `@hono/node-server`, `@hono/cloudflare-workers`, etc.

## Core Principle

> Hono is a thin routing layer with composable middleware. Keep routes shallow — validation, business logic, and persistence belong in separate modules.

Hono handlers should read input, call domain functions, and return responses.
No business logic in route files.

## App Structure

### Initialization

```typescript
import { Hono } from "hono";
import { serve } from "@hono/node-server";

const app = new Hono();

// Global middleware first
app.use("*", logger());

// Mount routers
app.route("/api/users", userRouter);
app.route("/api/orders", orderRouter);
app.route("/health", healthRouter);

serve({ fetch: app.fetch, port: 8080 });
```

### Router Factory Pattern

Each route group is a factory function returning a `new Hono()`. This enables
dependency injection and testability without mocking.

```typescript
// routes/webhook.ts
export function createWebhookRouter(onEvent: EventHandler) {
  const router = new Hono();

  router.post("/ingest", async (c) => {
    const body = await c.req.json();
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

**Why factories:** Testing creates a fresh router with stub dependencies.
No module-level singletons to mock.

### Route Ordering

```
1. Public routes (health, landing)
2. Auth middleware (applied to path prefix)
3. Protected API routes
4. Dashboard/UI routes (separate auth)
```

Middleware applied to a path prefix covers all routes mounted under it.

## Request Handling

### Reading Input

```typescript
// JSON body
const body = await c.req.json();

// Form data
const form = await c.req.parseBody();
const email = typeof form["email"] === "string" ? form["email"] : "";

// Query params
const limit = parseInt(c.req.query("limit") ?? "50", 10);
const status = c.req.query("status");  // string | undefined

// Path params
const id = c.req.param("id");  // always string
const numId = Number(c.req.param("id"));
if (!Number.isFinite(numId)) return c.notFound();
```

### Response Types

```typescript
// JSON (most common)
return c.json({ users, count: users.length }, 200);

// HTML / JSX
return c.html(<Layout><Dashboard data={data} /></Layout>);

// Plain text
return c.text("OK", 200);

// Redirect
return c.redirect("/dashboard");

// Not found
return c.notFound();

// Empty with status
return c.body(null, 204);
```

### HTTP Status Conventions

| Code | When |
|------|------|
| 200 | Successful read or sync operation |
| 202 | Webhook accepted (async processing) |
| 302 | Redirect after form submission |
| 400 | Invalid input (validation failed) |
| 401 | Missing or invalid auth |
| 404 | Resource not found |
| 500 | Internal error (log and re-throw) |
| 503 | Service unavailable (dependency down) |

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

  if (typeof obj.type !== "string") {
    return { ok: false, error: "Missing required field: type" };
  }
  if (!VALID_TYPES.has(obj.type)) {
    return { ok: false, error: `Invalid type: ${obj.type}` };
  }

  return { ok: true, event: obj as WebhookEvent };
}
```

**In the route handler:**

```typescript
router.post("/events", async (c) => {
  let body: unknown;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: "Invalid JSON body" }, 400);
  }

  const result = validateWebhookEvent(body);
  if (!result.ok) return c.json({ error: result.error }, 400);

  await processEvent(result.event);
  return c.json({ accepted: true }, 202);
});
```

## Middleware

### Built-in Middleware

```typescript
import { logger } from "hono/logger";
import { bearerAuth } from "hono/bearer-auth";
import { getCookie, setCookie } from "hono/cookie";

// Global request logging
app.use("*", logger());

// Bearer auth on path prefix
app.use("/api/*", bearerAuth({ token: env.API_SECRET }));
```

### Path-Scoped Middleware

Apply middleware to specific prefixes, not globally:

```typescript
// Only /api/* requires bearer auth
app.use("/api/*", bearerAuth({ token: SECRET }));

// /health is public
app.get("/health", (c) => c.json({ status: "ok" }));

// /dashboard has separate cookie auth
app.use("/dashboard/*", cookieAuthMiddleware);
```

### Cookie-Based Auth

```typescript
import { getCookie, setCookie, deleteCookie } from "hono/cookie";

function isAuthenticated(c: Context): boolean {
  return getCookie(c, "session") === expectedToken;
}

// Login
router.post("/login", async (c) => {
  const form = await c.req.parseBody();
  const password = typeof form["password"] === "string" ? form["password"] : "";

  if (password !== expected) {
    return c.redirect("/login?error=invalid");
  }

  setCookie(c, "session", token, {
    httpOnly: true,
    secure: true,
    sameSite: "Lax",
    maxAge: 60 * 60 * 24 * 7,  // 7 days
    path: "/dashboard",
  });
  return c.redirect("/dashboard");
});

// Logout
router.post("/logout", (c) => {
  deleteCookie(c, "session", { path: "/dashboard" });
  return c.redirect("/login");
});
```

## JSX Rendering

Hono supports JSX natively for server-rendered HTML.

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "hono/jsx"
  }
}
```

```typescript
// components/layout.tsx
import type { FC } from "hono/jsx";

export const Layout: FC = ({ children }) => (
  <html>
    <head><title>Dashboard</title></head>
    <body>{children}</body>
  </html>
);
```

```typescript
// route handler
router.get("/", (c) => {
  if (!isAuthenticated(c)) return c.redirect("/login");

  const data = db.getStats();
  return c.html(
    <Layout>
      <Dashboard stats={data} />
    </Layout>
  );
});
```

## Testing

### Setup

Hono's `app.request()` creates a test request without starting a server.

```typescript
import { describe, it, expect } from "vitest";
import { Hono } from "hono";

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
    const body = await res.json();
    expect(body.error).toContain("type");
  });
});
```

### Auth Testing

```typescript
const SECRET = "test-secret";
const app = new Hono();
app.use("/api/*", bearerAuth({ token: SECRET }));
app.route("/api", createApiRouter(deps));

// Authenticated request
const res = await app.request("/api/data", {
  headers: { Authorization: `Bearer ${SECRET}` },
});
expect(res.status).toBe(200);

// Unauthenticated request
const res2 = await app.request("/api/data");
expect(res2.status).toBe(401);
```

### Cookie/Redirect Testing

```typescript
// Use redirect: "manual" to capture redirects
const res = await app.request("/dashboard/login", {
  method: "POST",
  body: new URLSearchParams({ password: "correct" }).toString(),
  headers: { "Content-Type": "application/x-www-form-urlencoded" },
  redirect: "manual",
});

expect(res.status).toBe(302);
expect(res.headers.get("location")).toBe("/dashboard");
expect(res.headers.get("set-cookie")).toContain("session=");
```

```typescript
// Send cookies in subsequent requests
const res = await app.request("/dashboard", {
  headers: { Cookie: `session=${token}` },
});
expect(res.status).toBe(200);
```

### Pattern: Test the Router, Not the App

Create the router with test dependencies, mount it on a fresh `Hono()`.
No need to replicate the full app middleware stack.

```typescript
const db = createTestDb();
const router = createMetricsRouter({ db });
const app = new Hono();
app.route("/metrics", router);

// Tests exercise the router in isolation
```

## Server Adapters

Hono is runtime-agnostic. Pick the adapter for your platform:

```typescript
// Node.js
import { serve } from "@hono/node-server";
serve({ fetch: app.fetch, port: 8080 });

// Bun
export default { fetch: app.fetch, port: 8080 };

// Cloudflare Workers
export default app;

// Deno
Deno.serve(app.fetch);
```

## Conditional Route Acceptance

Guard routes with readiness checks for dependencies that may not be available:

```typescript
export function createRouter(
  handler: Handler,
  canAccept?: () => { ok: true } | { ok: false; error: string },
) {
  const router = new Hono();

  router.post("/process", async (c) => {
    if (canAccept) {
      const ready = canAccept();
      if (!ready.ok) return c.json({ error: ready.error }, 503);
    }
    // ... handle request ...
  });

  return router;
}
```

## Anti-Patterns

```typescript
// BAD: Business logic in route handler
router.post("/users", async (c) => {
  const body = await c.req.json();
  // 50 lines of validation, db calls, email sending...
});

// BAD: Global middleware for path-specific auth
app.use("*", bearerAuth({ token: SECRET }));  // blocks /health too

// BAD: Module-level app singleton (untestable)
export const app = new Hono();  // can't inject test deps

// BAD: Catching json() errors silently
const body = await c.req.json().catch(() => ({}));  // masks invalid input

// BAD: Testing against the full app instead of isolated routers
// Couples tests to unrelated middleware and routes
```
