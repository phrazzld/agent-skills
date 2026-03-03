# Billing & Security Integration Patterns

> "Configuration is not reality. Verification must be active, not passive."

Codified from 3 prod incidents where Stripe integrations failed despite passing code review.

## Critical Patterns

### 1. Environment Variable Hygiene
```typescript
// Always trim
const key = process.env.STRIPE_SECRET_KEY?.trim();
// Validate format
const STRIPE_KEY_PATTERN = /^sk_(test|live)_[a-zA-Z0-9]+$/;
if (!STRIPE_KEY_PATTERN.test(key)) throw new Error("Invalid STRIPE_SECRET_KEY format");
```

### 2. Webhook URL Validation
Stripe does NOT follow redirects for POST. Must return 4xx/5xx, NOT 3xx.
```bash
curl -s -o /dev/null -w "%{http_code}" -I -X POST "https://your-domain.com/api/webhooks/stripe"
```
Use canonical domain (if `example.com` redirects to `www.example.com`, use `www`).

### 3. Cross-Deployment Parity
Env vars must be set on BOTH Vercel and Convex (or equivalent). Use `--prod` flag.

### 4. Stripe Parameter Constraints
| Parameter | Valid Modes | Invalid Modes |
|-----------|-------------|---------------|
| `customer_creation` | payment, setup | subscription |
| `subscription_data` | subscription | payment, setup |

## Pre-Deployment Checklist
- [ ] All env vars trimmed at read time
- [ ] API key formats validated
- [ ] Webhook URL returns non-3xx
- [ ] Vercel and Convex have matching config
- [ ] Signature verification enabled
- [ ] Error handling returns 200 (prevent infinite retries)

## Debugging Workflow (OODA-V)
1. **Observe** - Check if request reaches server
2. **Orient** - If no logs, it's network/redirect, not code
3. **Decide** - Run `curl -I` on webhook URL
4. **Act** - Fix configuration
5. **Verify** - Resend event, watch `pending_webhooks` decrease
