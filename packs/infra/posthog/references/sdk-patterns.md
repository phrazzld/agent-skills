# PostHog SDK Patterns

## Standard Next.js + Clerk Integration

### 1. Analytics Module

```typescript
// lib/analytics/posthog.ts
import posthog from "posthog-js";

// STANDARD EVENTS (consistent across all projects)
export type StandardEvent =
  | { name: "user_signed_up"; properties: Record<string, never> }
  | { name: "user_activated"; properties: { action: string } }
  | { name: "subscription_started"; properties: { plan: string; trial: boolean } }
  | { name: "subscription_cancelled"; properties: { reason?: string } }
  | { name: "feature_used"; properties: { feature: string } };

// PROJECT-SPECIFIC EVENTS (extend for your app)
export type ProjectEvent =
  | StandardEvent
  | { name: "custom_event"; properties: { value: string } };

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
    // Use reverse proxy for ad blocker bypass
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || "/ingest",

    // Privacy settings (REQUIRED)
    person_profiles: "identified_only",
    mask_all_text: true,

    // Session recording privacy
    session_recording: {
      maskAllInputs: true,
      maskTextSelector: "*",
    },

    // Pageview handling
    capture_pageview: true,
    capture_pageleave: true,

    // Disable autocapture (track explicitly)
    autocapture: false,

    // Respect Do Not Track
    respect_dnt: true,

    // Debug in development
    loaded: (ph) => {
      if (process.env.NODE_ENV === "development") {
        ph.debug();
      }
    },
  });
}

export function identifyUser(userId: string, properties?: Record<string, unknown>) {
  if (typeof window === "undefined" || !posthog.__loaded) return;
  // Only send user ID, never PII
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

// Feature flags
export function isFeatureEnabled(key: string): boolean {
  if (typeof window === "undefined" || !posthog.__loaded) return false;
  return posthog.isFeatureEnabled(key) ?? false;
}

export function getFeatureFlagPayload(key: string): unknown {
  if (typeof window === "undefined" || !posthog.__loaded) return null;
  return posthog.getFeatureFlagPayload(key);
}
```

### 2. Provider Component

```typescript
// components/providers/PostHogProvider.tsx
"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { useUser } from "@clerk/nextjs";
import { identifyUser, initPostHog, resetUser } from "@/lib/analytics/posthog";

export function PostHogProvider({ children }: { children: ReactNode }) {
  const { isLoaded, isSignedIn, user } = useUser();
  const wasSignedIn = useRef(false);

  // Initialize PostHog once on mount
  useEffect(() => {
    initPostHog();
  }, []);

  // Handle auth state changes
  useEffect(() => {
    if (!isLoaded) return;

    if (isSignedIn && user?.id) {
      identifyUser(user.id);
      wasSignedIn.current = true;
      return;
    }

    // User signed out
    if (wasSignedIn.current) {
      resetUser();
      wasSignedIn.current = false;
    }
  }, [isLoaded, isSignedIn, user?.id]);

  return <>{children}</>;
}
```

### 3. Layout Integration

```typescript
// app/layout.tsx
import { ClerkProvider } from "@clerk/nextjs";
import { ConvexClientProvider } from "@/components/providers/ConvexClientProvider";
import { PostHogProvider } from "@/components/providers/PostHogProvider";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
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

### 4. Reverse Proxy Configuration

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      {
        source: "/ingest/static/:path*",
        destination: "https://us-assets.i.posthog.com/static/:path*",
      },
      {
        source: "/ingest/:path*",
        destination: "https://us.i.posthog.com/:path*",
      },
    ];
  },
  // Required to prevent CSP issues
  skipTrailingSlashRedirect: true,
};

module.exports = nextConfig;
```

**For EU region, use:**
- `https://eu.i.posthog.com/:path*`
- `https://eu-assets.i.posthog.com/static/:path*`

### 5. Event Tracking Examples

```typescript
// After successful signup
trackEvent("user_signed_up", {});

// After first meaningful action
trackEvent("user_activated", { action: "created_first_project" });

// After subscription purchase
trackEvent("subscription_started", { plan: "pro", trial: false });

// Feature usage tracking
trackEvent("feature_used", { feature: "export_pdf" });
```

## Server-Side Tracking (Node.js)

```typescript
// lib/analytics/posthog-server.ts
import { PostHog } from "posthog-node";

let posthogClient: PostHog | null = null;

export function getPostHogServer(): PostHog | null {
  if (posthogClient) return posthogClient;

  const key = process.env.POSTHOG_API_KEY;
  if (!key) return null;

  posthogClient = new PostHog(key, {
    host: process.env.POSTHOG_HOST || "https://us.i.posthog.com",
    flushAt: 1, // Send immediately in serverless
    flushInterval: 0,
  });

  return posthogClient;
}

export async function trackServerEvent(
  distinctId: string,
  event: string,
  properties?: Record<string, unknown>
) {
  const client = getPostHogServer();
  if (!client) return;

  client.capture({
    distinctId,
    event,
    properties,
  });

  // Flush in serverless to ensure event is sent
  await client.flush();
}
```

## Anti-Patterns

### DON'T: Send PII in identify()

```typescript
// ❌ WRONG - Sends PII
posthog.identify(user.id, {
  email: user.email,
  name: user.fullName,
});

// ✓ CORRECT - Only user ID
posthog.identify(user.id);
```

### DON'T: Initialize before checking window

```typescript
// ❌ WRONG - Crashes on server
posthog.init(key, { ... });

// ✓ CORRECT - Check window first
if (typeof window !== "undefined") {
  posthog.init(key, { ... });
}
```

### DON'T: Track sensitive events

```typescript
// ❌ WRONG - Tracks payment details
trackEvent("payment_submitted", {
  card_number: "4242...",
  amount: 99.99,
});

// ✓ CORRECT - Track success, not details
trackEvent("subscription_started", {
  plan: "pro",
  trial: false,
});
```

### DON'T: Use direct PostHog host in production

```typescript
// ❌ WRONG - Gets blocked by ad blockers
posthog.init(key, {
  api_host: "https://us.i.posthog.com",
});

// ✓ CORRECT - Use reverse proxy
posthog.init(key, {
  api_host: "/ingest",
});
```
