# PostHog Audit Checklist

## Checks

### 1. SDK Installation
```bash
grep -qE 'posthog-js|posthog-node|posthog' package.json 2>/dev/null && echo "OK" || echo "FAIL: PostHog not installed"
```

### 2. Provider Setup
```bash
grep -rqE "PostHogProvider|PostHogPageview" --include="*.tsx" app/ 2>/dev/null && echo "OK: Provider configured"
grep -rqE "NEXT_PUBLIC_POSTHOG_KEY|POSTHOG_API_KEY" .env.example .env.local 2>/dev/null && echo "OK: API key configured"
```

### 3. Event Tracking
```bash
grep -rqE "posthog\.capture|posthog\.identify" --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: Events tracked"
grep -rqE "capture.*sign|capture.*purchase|capture.*create" --include="*.ts" --include="*.tsx" . 2>/dev/null | head -5
```

### 4. User Identification
```bash
grep -rqE "posthog\.identify|posthog\.alias" --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: User identification"
grep -rqE "posthog\.reset" --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: Reset on logout"
```

### 5. Feature Flags
```bash
grep -rqE "useFeatureFlag|posthog\.isFeatureEnabled|getFeatureFlag" --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: Feature flags"
```

### 6. Proxy Setup (Ad Blocker Bypass)
```bash
grep -rqE "rewrites.*ingest|proxy.*posthog|/ingest" next.config* middleware* 2>/dev/null && echo "OK: Proxy configured"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| PostHog not installed | P0 |
| No API key configured | P0 |
| No Provider in app layout | P1 |
| No event tracking | P1 |
| No user identification | P1 |
| No reset on logout | P2 |
| No proxy (ad blockers kill data) | P2 |
| No feature flags | P2 |
| No group analytics | P3 |
| No session replay | P3 |

## Clerk Integration
```bash
# isLoaded guard (prevent premature reset)
grep -rqE "isLoaded.*isSignedIn|isLoaded.*reset" --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: isLoaded guard"
```
