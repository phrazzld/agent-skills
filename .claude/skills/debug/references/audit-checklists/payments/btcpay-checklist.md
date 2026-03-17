# BTCPay Server Audit Checklist

## Checks

### 1. Greenfield API Connectivity
```bash
curl -s -H "Authorization: token $BTCPAY_API_KEY" "$BTCPAY_URL/api/v1/health"
curl -s -H "Authorization: token $BTCPAY_API_KEY" "$BTCPAY_URL/api/v1/stores" | jq
```

### 2. Store Configuration
```bash
curl -s -H "Authorization: token $BTCPAY_API_KEY" "$BTCPAY_URL/api/v1/stores/$STORE_ID" | jq
curl -s -H "Authorization: token $BTCPAY_API_KEY" "$BTCPAY_URL/api/v1/stores/$STORE_ID/payment-methods" | jq
```

### 3. Webhook Endpoints + Signature Verification
```bash
curl -s -H "Authorization: token $BTCPAY_API_KEY" "$BTCPAY_URL/api/v1/stores/$STORE_ID/webhooks" | jq
find . -path "*/api/*webhook*" -name "*.ts" 2>/dev/null | head -5
grep -rE "btcpay|webhook.*signature|hmac" --include="*.ts" . 2>/dev/null | grep -v node_modules | head -5
```

### 4. Payment Notifications
```bash
grep -rE "invoice.*(paid|confirmed|expired)|payment.*(received|settled)" --include="*.ts" . 2>/dev/null | grep -v node_modules | head -5
grep -rE "BTCPAY_.*(NOTIFY|NOTIFICATION|WEBHOOK)" --include="*.env*" . 2>/dev/null | head -5
```

### 5. Lightning Node Connection
```bash
curl -s -H "Authorization: token $BTCPAY_API_KEY" "$BTCPAY_URL/api/v1/stores/$STORE_ID/payment-methods" | jq
grep -rE "lnd|lightning|lnurl|bolt11" --include="*.ts" . 2>/dev/null | grep -v node_modules | head -5
```

### 6. Wallet Hot/Cold Separation
```bash
grep -rE "xprv|seed|mnemonic|private key" --include="*.ts" --include="*.env*" . 2>/dev/null | grep -v node_modules | head -5
grep -rE "xpub|ypub|zpub|descriptor" --include="*.ts" --include="*.env*" . 2>/dev/null | grep -v node_modules | head -5
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| Greenfield API unreachable | P0 |
| No enabled payment methods | P0 |
| Webhooks not receiving events | P0 |
| Webhook signature not verified | P1 |
| Missing invoice status handling | P1 |
| Lightning node not connected | P1 |
| Notification URL missing | P1 |
| Missing retry/backoff | P2 |
| Config mismatch store vs app | P2 |
| Hot wallet without separation | P2 |
| Monitoring gaps | P2 |
| Optimization/analytics | P3 |

## Deep Audit Areas
- Invoice lifecycle handling (new, paid, confirmed, expired)
- Webhook signature verification and replay protection
- Store policies vs code expectations
- Lightning vs on-chain fallback behavior
- Wallet key custody and backup posture
