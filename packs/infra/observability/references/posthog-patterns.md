# PostHog Integration Patterns

Reference patterns for adding PostHog product analytics to Next.js/Convex apps.

**When to use PostHog:** Only if you need product analytics (funnels, cohorts, feature flags). For error tracking, use Sentry via `/observability`.

## Stack Overview

```
Observability Stack:
├── Error Tracking: Sentry (@sentry/nextjs)
├── Product Analytics: PostHog (posthog-js) ← REQUIRED for user-facing apps
└── Structured Logging: Pino (pino)

NOT in our stack:
├── Vercel Analytics - NO API, NO CLI, NO MCP (unusable)
└── Any other analytics without programmatic access
```

## PostHog Integration

### 1. Install

```bash
pnpm add posthog-js
```

### 2. Create Analytics Module

```typescript
// lib/analytics/posthog.ts
import posthog from "posthog-js";

// STANDARD EVENTS (enforced across all projects)
// These event names are consistent across the portfolio for cross-product analytics
export type StandardEvent =
  | { name: "user_signed_up"; properties: Record<string, never> }
  | { name: "user_activated"; properties: { action: string } }
  | { name: "subscription_started"; properties: { plan: string; trial: boolean } }
  | { name: "subscription_cancelled"; properties: { reason?: string } }
  | { name: "feature_used"; properties: { feature: string } };

// PROJECT-SPECIFIC EVENTS (extend StandardEvent for your app)
// Example: Book tracking app
export type ProjectEvent =
  | StandardEvent
  | { name: "book_added"; properties: { source: "manual" | "import" | "search" } }
  | { name: "book_completed"; properties: { pages: number } };

// Combined type for your app (use this)
export type AnalyticsEvent = ProjectEvent;

export function initPostHog() {
  const key = process.env.NEXT_PUBLIC_POSTHOG_KEY;
  if (!key) {
    if (process.env.NODE_ENV === "development") {
      console.warn("[Analytics] PostHog key not configured");
    }
    return;
  }

  posthog.init(key, {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || "https://us.i.posthog.com",
    capture_pageview: true,
    capture_pageleave: true,
    autocapture: false, // Track explicitly
    respect_dnt: true,
    loaded: (ph) => {
      if (process.env.NODE_ENV === "development") ph.debug();
    },
  });
}

export function identifyUser(userId: string, properties?: Record<string, unknown>) {
  if (typeof window === "undefined" || !posthog.__loaded) return;
  posthog.identify(userId, properties);
}

export function resetUser() {
  if (typeof window === "undefined" || !posthog.__loaded) return;
  posthog.reset();
}

export function trackEvent<T extends AnalyticsEvent>(
  event: T["name"],
  properties: T["properties"]
) {
  if (typeof window === "undefined" || !posthog.__loaded) return;
  posthog.capture(event, properties);
}
```

### 3. Create Provider

```typescript
// components/providers/PostHogProvider.tsx
"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { useUser } from "@clerk/nextjs";
import { identifyUser, initPostHog, resetUser } from "@/lib/analytics/posthog";

export function PostHogProvider({ children }: { children: ReactNode }) {
  const { isLoaded, isSignedIn, user } = useUser();
  const wasSignedIn = useRef(false);

  useEffect(() => {
    initPostHog();
  }, []);

  useEffect(() => {
    if (!isLoaded) return;

    if (isSignedIn && user?.id) {
      identifyUser(user.id);
      wasSignedIn.current = true;
      return;
    }

    if (wasSignedIn.current) {
      resetUser();
      wasSignedIn.current = false;
    }
  }, [isLoaded, isSignedIn, user?.id]);

  return <>{children}</>;
}
```

### 4. Add to Layout

```typescript
// app/layout.tsx
import { PostHogProvider } from "@/components/providers/PostHogProvider";

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>
          <ConvexClientProvider>
            <PostHogProvider>
              {children}
            </PostHogProvider>
          </ConvexClientProvider>
        </body>
      </html>
    </ClerkProvider>
  );
}
```

### 5. Track Events

```typescript
// In component after successful mutation
import { trackEvent } from "@/lib/analytics/posthog";

// After book created
trackEvent("book_added", { source: "manual" });

// After subscription started
trackEvent("subscription_started", { plan: "pro", trial: true });
```

## Sentry Integration

### 1. Install & Configure

```bash
pnpm add @sentry/nextjs
npx @sentry/wizard@latest -i nextjs
```

### 2. PII Scrubbing

```typescript
// lib/sentry-config.ts
import * as Sentry from "@sentry/nextjs";

const REDACTED = "[REDACTED]";
const PII_PATTERNS = [/email/i, /password/i, /token/i, /secret/i, /key/i];

function scrubPII(obj: unknown): unknown {
  if (typeof obj !== "object" || obj === null) return obj;
  if (Array.isArray(obj)) return obj.map(scrubPII);

  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (PII_PATTERNS.some((p) => p.test(key))) {
      result[key] = REDACTED;
    } else {
      result[key] = scrubPII(value);
    }
  }
  return result;
}

export function initSentry() {
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
    environment: process.env.VERCEL_ENV || process.env.NODE_ENV,
    beforeSend(event) {
      if (event.extra) event.extra = scrubPII(event.extra) as Record<string, unknown>;
      if (event.contexts) event.contexts = scrubPII(event.contexts) as typeof event.contexts;
      return event;
    },
  });
}
```

### 3. Client-Safe Error Capture

```typescript
// lib/sentry.ts
import * as Sentry from "@sentry/nextjs";

type ErrorContext = {
  tags?: Record<string, string>;
  extra?: Record<string, unknown>;
};

export function captureError(error: unknown, context?: ErrorContext) {
  if (process.env.NODE_ENV === "development") {
    console.error("[Sentry]", error, context);
  }
  Sentry.captureException(error, {
    tags: context?.tags,
    extra: context?.extra,
  });
}
```

## Environment Variables

```bash
# .env.example

# Sentry [OPTIONAL] - Error tracking
NEXT_PUBLIC_SENTRY_DSN=

# PostHog [OPTIONAL] - Product analytics
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=
```

## What to Track

### High-Value Events (Always Track)

- `signup_completed` - User registration
- `subscription_started` - Payment conversion
- `subscription_cancelled` - Churn signal
- Key feature usage (import, export, etc.)

### Track Sparingly

- Status changes (can get noisy)
- Navigation (use autocapture or pageviews)

### Never Track

- PII (names, emails, IPs)
- Passwords or tokens
- High-frequency events (typing, scrolling)

## Build vs Buy Summary

| Approach | Setup | Maintenance | Parity |
|----------|-------|-------------|--------|
| Use Sentry/PostHog | 2 hours | 0.5 hr/mo | 100% |
| Custom MVP | 6 hours | 2-5 hr/mo | ~10% |
| Custom full parity | 800+ hours | 20+ hr/mo | 100% |

**Free tiers are generous. Don't build your own.**

## Terraform (Future)

PostHog is the only major analytics with Terraform support:

```hcl
resource "posthog_project" "app" {
  name = "my-app-production"
}

resource "posthog_feature_flag" "new_ui" {
  project_id = posthog_project.app.id
  key        = "new-ui-beta"
  active     = true
}
```

This enables agentic management of analytics infrastructure.
