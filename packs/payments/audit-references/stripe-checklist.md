# Stripe Audit Checklist

## Checks

### 1. SDK & Keys
```bash
grep -q 'stripe' package.json 2>/dev/null && echo "OK: Stripe SDK" || echo "FAIL: No Stripe SDK"
! grep -rqE 'sk_live_|sk_test_|pk_live_|pk_test_' --include='*.ts' --include='*.tsx' . 2>/dev/null | grep -v node_modules | grep -v '.env' && echo "OK" || echo "FAIL: Hardcoded keys"
```

### 2. Webhook Security
```bash
grep -q 'STRIPE_WEBHOOK_SECRET' .env.local 2>/dev/null || [ -n "$STRIPE_WEBHOOK_SECRET" ] && echo "OK" || echo "FAIL: No webhook secret"
grep -rqE 'constructEvent|stripe\.webhooks\.constructEvent' --include='*.ts' . 2>/dev/null && echo "OK: Signature verified" || echo "FAIL: No webhook verification"
```

### 3. Subscription Handling
```bash
grep -rqE 'subscription\.status|active|canceled|past_due' --include='*.ts' . 2>/dev/null && echo "OK: Status checks"
grep -rqE 'createBillingPortalSession|billing.*portal' --include='*.ts' . 2>/dev/null && echo "OK: Customer portal"
```

### 4. Idempotency
```bash
grep -rqE 'idempotencyKey|idempotency_key' --include='*.ts' . 2>/dev/null && echo "OK" || echo "WARN: No idempotency keys"
```

### 5. Convex Integration
```bash
grep -q 'CONVEX_WEBHOOK_TOKEN' .env.local 2>/dev/null && echo "OK" || echo "FAIL: No CONVEX_WEBHOOK_TOKEN"
```

### 6. Sandbox vs Production
```bash
# Verify not using deprecated test mode keys on production infra
grep -rqE 'sk_test_' --include='*.env*' . 2>/dev/null && echo "WARN: test mode keys found (use sandbox account instead)"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| Stripe SDK not installed | P0 |
| Hardcoded Stripe keys | P0 |
| Missing webhook secret | P0 |
| Missing CONVEX_WEBHOOK_TOKEN | P0 |
| Webhook signature not verified | P1 |
| No customer portal | P1 |
| Subscription status not checked | P1 |
| No idempotency keys | P2 |
| Using deprecated test mode | P2 |
| No payment analytics | P3 |

## Key Rule
Stripe deprecated test mode. Use sandbox account (`acct_1SV2rGD4aITn8Hia`) for development.
Never set `sk_test_*` keys from production account on any infrastructure.
