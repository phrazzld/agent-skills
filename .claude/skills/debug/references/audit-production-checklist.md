# Production Readiness Audit Checklist

## Checks

### 1. Error Tracking
```bash
grep -qE '@sentry|sentry' package.json 2>/dev/null && echo "OK: Sentry" || echo "FAIL: No error tracking"
```

### 2. Health Endpoint
```bash
[ -f "app/api/health/route.ts" ] || [ -f "src/app/api/health/route.ts" ] && echo "OK" || echo "FAIL: No health endpoint"
grep -rqE "database|redis|external|dependency|upstream" app/api/health/ src/app/api/health/ 2>/dev/null && echo "OK: Validates deps" || echo "WARN: Shallow health check"
```

### 3. CI Status
```bash
gh run list --branch main --status failure --limit 1 --json conclusion 2>/dev/null | grep -q '\[\]' && echo "OK" || echo "FAIL: Main CI failing"
```

### 4. Silent Failures
```bash
grep -rcE 'catch\s*\(\s*\)' --include='*.ts' --include='*.tsx' src/ app/ 2>/dev/null  # empty catch blocks
```

### 5. Analytics
```bash
grep -qE 'posthog|posthog-js|posthog-node' package.json 2>/dev/null && echo "OK: PostHog" || echo "FAIL: No analytics"
```

### 6. Structured Logging
```bash
grep -qE 'pino|winston|bunyan|@logtail' package.json 2>/dev/null && echo "OK" || echo "FAIL: No structured logging"
```

### 7. Rate Limiting
```bash
grep -rqE 'rate.?limit|ratelimit|throttle|upstash.*ratelimit' --include='*.ts' src/ app/ lib/ middleware* 2>/dev/null && echo "OK" || echo "FAIL: No rate limiting"
```

### 8. Environment Config
```bash
[ -f ".env.example" ] && echo "OK: .env.example" || echo "FAIL: No .env.example"
grep -rqE "SENTRY_DSN|NEXT_PUBLIC_SENTRY" .env.example .env.local 2>/dev/null && echo "OK: Sentry DSN" || echo "WARN: No Sentry DSN"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| Main branch CI failing | P0 |
| No error tracking | P0 |
| No health endpoint | P1 |
| No analytics | P1 |
| Health endpoint doesn't validate deps | P2 |
| Empty catch blocks | P2 |
| No structured logging | P2 |
| No rate limiting | P2 |
| Missing .env.example | P2 |
| Monitoring improvements | P3 |
