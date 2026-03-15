# Observability Audit Checklist

## Checks

### 1. Error Tracking (Sentry)
```bash
grep -qE '@sentry|sentry' package.json 2>/dev/null && echo "OK: Sentry installed" || echo "FAIL: No Sentry"
[ -f "sentry.client.config.ts" ] && echo "OK: Client config" || echo "FAIL: No client config"
[ -f "sentry.server.config.ts" ] && echo "OK: Server config" || echo "FAIL: No server config"
[ -f "sentry.edge.config.ts" ] && echo "OK: Edge config" || echo "WARN: No edge config"
grep -rqE "captureException|captureMessage" --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: Active capture" || echo "WARN: No manual error capture"
```

### 2. Analytics (PostHog)
```bash
grep -qE 'posthog|posthog-js|posthog-node' package.json 2>/dev/null && echo "OK: PostHog installed" || echo "FAIL: No PostHog"
grep -rqE 'posthog\.capture|usePostHog|PostHogProvider' --include="*.ts" --include="*.tsx" . 2>/dev/null && echo "OK: Events tracked" || echo "WARN: PostHog installed but no events"
```

### 3. Uptime Monitoring
```bash
[ -f "app/api/health/route.ts" ] || [ -f "src/app/api/health/route.ts" ] && echo "OK: Health endpoint" || echo "FAIL: No health endpoint"
grep -rqE "UptimeRobot|statuspage|uptime|healthcheck" . 2>/dev/null && echo "OK: Monitoring configured" || echo "WARN: No uptime monitoring"
```

### 4. Structured Logging
```bash
grep -qE 'pino|winston|bunyan|@logtail' package.json 2>/dev/null && echo "OK: Structured logging" || echo "FAIL: No structured logging"
grep -rqcE 'console\.(log|error|warn)' --include="*.ts" --include="*.tsx" src/ app/ lib/ 2>/dev/null
```

### 5. Error Boundaries
```bash
[ -f "app/error.tsx" ] || [ -f "src/app/error.tsx" ] && echo "OK: Error boundary" || echo "FAIL: No error boundary"
[ -f "app/global-error.tsx" ] || [ -f "src/app/global-error.tsx" ] && echo "OK: Global error boundary" || echo "FAIL: No global error boundary"
grep -rqE "captureException" app/error.tsx app/global-error.tsx 2>/dev/null && echo "OK: Error boundary reports to Sentry" || echo "FAIL: Error boundary silent"
```

### 6. Source Maps
```bash
grep -qE "hideSourceMaps|sourceMaps" next.config* sentry.* 2>/dev/null && echo "OK: Source maps configured" || echo "WARN: Source maps not configured"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| No error tracking (Sentry) | P0 |
| No health endpoint | P0 |
| Error boundaries don't report to Sentry | P0 |
| No analytics (PostHog) | P1 |
| No global error boundary | P1 |
| Missing Sentry configs (client/server) | P1 |
| No structured logging | P1 |
| No uptime monitoring | P2 |
| Using console.log in production | P2 |
| Source maps not configured | P2 |
| No custom dashboards | P3 |
| No alerting rules | P3 |
