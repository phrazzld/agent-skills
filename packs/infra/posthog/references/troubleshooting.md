# PostHog Troubleshooting Guide

## Events Not Appearing

### Check 1: SDK Initialized?

In browser console:
```javascript
posthog.__loaded // Should be true
posthog.get_distinct_id() // Should return an ID
```

If `__loaded` is false, SDK didn't initialize. Check:
- `NEXT_PUBLIC_POSTHOG_KEY` is set
- `initPostHog()` is called in provider
- No JavaScript errors before init

### Check 2: Network Requests?

1. Open DevTools → Network tab
2. Filter for `posthog` or `ingest`
3. Trigger an action
4. Look for POST requests

**If no requests:** SDK not initialized or blocked before sending.

**If requests fail (4xx/5xx):** Check API key and host configuration.

**If requests succeed but events don't appear:** Check PostHog project ID matches.

### Check 3: Ad Blockers?

Many ad blockers block `posthog.com` and `i.posthog.com`.

**Test:** Disable ad blocker → refresh → check if events appear.

**Fix:** Set up reverse proxy (see sdk-patterns.md).

### Check 4: Bot Detection?

PostHog filters bot traffic. Chrome launched from IDE debuggers is detected as bot.

**Symptoms:** Events work in production but not local dev.

**Fix:**
```typescript
posthog.init(key, {
  // Disable bot filtering in development
  bootstrap: { isIdentifiedAnonymous: true },
});
```

### Check 5: Using webhook.site

Isolate SDK from network issues:

1. Go to https://webhook.site
2. Copy your unique URL
3. Replace PostHog host temporarily:
   ```typescript
   posthog.init(key, {
     api_host: 'https://webhook.site/your-id',
   });
   ```
4. Trigger event → check webhook.site

If events appear on webhook.site but not PostHog, it's a PostHog configuration issue.

## User Not Linked to Events

### Symptoms
- Events appear but all from "anonymous" users
- Person profiles not created
- identify() seems to have no effect

### Causes

**1. identify() called before init completes**

```typescript
// ❌ WRONG
posthog.init(key, { ... });
posthog.identify(userId); // Too early!

// ✓ RIGHT
posthog.init(key, {
  loaded: (ph) => {
    if (userId) ph.identify(userId);
  },
});
```

**2. identify() not called on auth state change**

```typescript
// Must call identify when user signs in
useEffect(() => {
  if (isSignedIn && user?.id) {
    posthog.identify(user.id);
  }
}, [isSignedIn, user?.id]);
```

**3. reset() not called on sign out**

```typescript
// Must call reset when user signs out
if (wasSignedIn && !isSignedIn) {
  posthog.reset();
}
```

## Session Recordings Not Working

### Check 1: Recording enabled in PostHog?

Go to PostHog → Project Settings → Session Recording → Ensure enabled.

### Check 2: Recording started?

```javascript
posthog.sessionRecordingStarted() // Should be true
```

### Check 3: Quota exhausted?

Check PostHog billing → Session recordings usage.

### Check 4: Domain blocked?

Session recording requires additional assets. Ensure these aren't blocked:
- `us-assets.i.posthog.com`
- Your `/ingest` proxy path

## Feature Flags Not Evaluating

### Check 1: Flags loaded?

```javascript
posthog.isFeatureEnabled('your-flag') // Check in console
posthog.getFeatureFlag('your-flag') // Returns value or undefined
```

### Check 2: User identified?

Feature flags often target by user properties. Ensure `identify()` called.

### Check 3: Flag targeting?

Check PostHog → Feature Flags → Your flag → Targeting rules.

### Check 4: Local override?

```javascript
posthog.featureFlags.override({'your-flag': true}) // For testing
posthog.featureFlags.clearOverrides() // Remove overrides
```

## High-Frequency Events Flooding

### Symptoms
- Event quota exhausted quickly
- Dashboard shows millions of events
- Same event appearing rapidly

### Common Causes

**1. Tracking in useEffect without deps**

```typescript
// ❌ WRONG - fires on every render
useEffect(() => {
  trackEvent("page_viewed", {});
});

// ✓ RIGHT - fires once
useEffect(() => {
  trackEvent("page_viewed", {});
}, []);
```

**2. Tracking in render loop**

```typescript
// ❌ WRONG
function Component() {
  trackEvent("rendered", {}); // Fires every render!
  return <div />;
}

// ✓ RIGHT
function Component() {
  useEffect(() => {
    trackEvent("mounted", {});
  }, []);
  return <div />;
}
```

**3. Scroll/mouse events**

Never track high-frequency browser events directly.

## Server-Side Events Not Appearing

### Check 1: Flushing?

In serverless, events must be flushed:

```typescript
const client = getPostHogServer();
client.capture({ ... });
await client.flush(); // Required in serverless!
```

### Check 2: API key correct?

Server uses `POSTHOG_API_KEY`, not `NEXT_PUBLIC_POSTHOG_KEY`.

### Check 3: Host configured?

```typescript
new PostHog(key, {
  host: process.env.POSTHOG_HOST || 'https://us.i.posthog.com',
});
```

## Debug Mode

Enable comprehensive logging:

```typescript
// In browser console
posthog.debug()

// Or in init
posthog.init(key, {
  loaded: (ph) => {
    if (process.env.NODE_ENV === 'development') {
      ph.debug();
    }
  },
});
```

This shows:
- All events being captured
- API requests and responses
- Feature flag evaluations
- Session recording status

## PostHog MCP Debugging

Use MCP tools to investigate issues:

```
# Check what events are defined
mcp__posthog__event-definitions-list

# Run a query to see recent events
mcp__posthog__query-run with TrendsQuery for last 24h

# Check for errors
mcp__posthog__list-errors

# Search logs
mcp__posthog__logs-query with severityLevels: ["error", "warn"]
```

## Common Error Messages

### "PostHog is not initialized"

SDK init failed or called before init completed.

### "Quota exceeded"

Check billing. Consider sampling or reducing event volume.

### "Invalid API key"

Key doesn't match project. Check `NEXT_PUBLIC_POSTHOG_KEY`.

### "CORS error"

Using direct PostHog host instead of reverse proxy. Set up `/ingest` rewrite.
