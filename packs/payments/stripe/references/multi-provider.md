# Multi-Provider Payment Audit

Unified payment lifecycle across Stripe, Bitcoin, Lightning, BTCPay.

## Detect Active Providers
```bash
grep -q "stripe" package.json 2>/dev/null && echo "Stripe SDK"
command -v bitcoin-cli >/dev/null && echo "bitcoin-cli"
command -v lncli >/dev/null && echo "lncli (LND)"
[ -n "$BTCPAY_URL" ] && echo "BTCPay"
```

## Provider Lifecycle Skills
| Provider | Skill | Fallback |
|----------|-------|----------|
| Stripe | `/stripe` | `/check-stripe` |
| Bitcoin | `/bitcoin` | `/check-bitcoin` |
| Lightning | `/lightning` | `/check-lightning` |
| BTCPay | `/check-btcpay` | N/A |

## Consolidated Findings
Merge all provider findings into unified report with P0-P3 priority. Fix in priority order, respecting dependency chains (Lightning depends on Bitcoin node).
