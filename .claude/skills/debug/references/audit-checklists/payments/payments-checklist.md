# Payments Audit Checklist

Multi-provider payment audit covering Stripe, Bitcoin, Lightning, and BTCPay.

## Checks

### 1. Payment Provider Detection
```bash
grep -qE "stripe" package.json 2>/dev/null && echo "Stripe detected"
grep -rqE "bitcoin-cli|bitcoinjs" --include="*.ts" . 2>/dev/null && echo "Bitcoin detected"
grep -rqE "lncli|lnrpc|bolt11" --include="*.ts" . 2>/dev/null && echo "Lightning detected"
grep -rqE "btcpay|BTCPAY" --include="*.ts" --include="*.env*" . 2>/dev/null && echo "BTCPay detected"
```

### 2. Webhook Security (All Providers)
```bash
# Stripe
grep -rqE "constructEvent|stripe\.webhooks" --include="*.ts" . 2>/dev/null && echo "OK: Stripe webhook verified"
# BTCPay
grep -rqE "btcpay.*signature|hmac.*btcpay" --include="*.ts" . 2>/dev/null && echo "OK: BTCPay webhook verified"
```

### 3. Idempotency
```bash
grep -rqE "idempotencyKey|idempotency_key" --include="*.ts" . 2>/dev/null && echo "OK: Idempotency keys" || echo "FAIL: No idempotency"
```

### 4. Reconciliation
```bash
grep -rqE "reconcil|sync.*payment|payment.*sync" --include="*.ts" . 2>/dev/null && echo "OK: Reconciliation" || echo "WARN: No reconciliation"
```

### 5. Error Handling
```bash
grep -rqE "StripeError|PaymentError|payment.*error|charge.*failed" --include="*.ts" . 2>/dev/null | head -5
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| No payment provider configured | P0 |
| Webhook signatures not verified | P0 |
| Hardcoded payment keys in code | P0 |
| No idempotency on payment ops | P1 |
| Missing payment status handling | P1 |
| No reconciliation process | P2 |
| No payment error recovery | P2 |
| No payment analytics | P3 |

## Cross-Provider Consistency
- All providers must verify webhook signatures
- All providers must handle payment status transitions
- All providers must have idempotent operations
- Reconciliation cron should cover all providers
