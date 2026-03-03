# Stripe Integration Patterns

Quick reference for Stripe integration gotchas and patterns.

## Key Verification Points

When touching Stripe code, always verify:
1. Runtime env validation present (fail-fast pattern)
2. Webhook signature verification present and FIRST
3. Error handling logs with context (userId, operation, error)
4. No hardcoded keys or test data in production paths
5. Health check endpoint for Stripe connectivity

## Manual Triggers

Invoke when user mentions:
- "Stripe integration", "payment checkout", "subscription mode"
- "customer_creation parameter", "webhook secret"
- "Stripe test vs live", "Stripe API error"
- Debugging checkout, subscription, or webhook issues

## Core Principles

### 1. TypeScript Types Are Necessary But Not Sufficient

Stripe's TypeScript types don't encode **conditional parameter constraints**:
- `customer_creation` only valid in `payment` or `setup` mode (NOT `subscription`)
- `subscription_data.trial_period_days` requires `subscription` mode
- `payment_intent_data` requires `payment` mode

**Always verify parameter combinations against Stripe API docs, not just TypeScript.**

### 2. Environment Variables: Dev ≠ Prod

For platforms with separate deployments (Convex, Serverless):
- Env vars must be set on **BOTH** dev and prod deployments
- Local `.env.local` doesn't propagate to production
- Use verification scripts before deploying

### 3. Check Config Before Code

When Stripe integrations fail in production:
1. Verify env vars are set (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`)
2. Check Stripe Dashboard for API errors
3. Review webhook logs for delivery failures
4. **Then** examine code

### 4. Webhook 500s = Usually Config

Production webhook 500 errors typically mean:
- Missing `STRIPE_WEBHOOK_SECRET` in production env
- Wrong webhook endpoint URL registered
- Missing handler for event type

Not usually code bugs.

### 5. Environment Variable Hygiene

**Trailing whitespace causes cryptic errors.** Env vars with `\n` or spaces break HTTP headers:
- "Invalid character in header content" → key has trailing newline
- Webhook signature mismatch → secret has trailing whitespace

**Rules:**
```bash
# ✅ Use printf, not echo, to avoid trailing newlines
printf '%s' 'sk_live_xxx' | vercel env add STRIPE_SECRET_KEY production

# ✅ Trim when setting via Convex CLI
npx convex env set --prod STRIPE_SECRET_KEY "$(echo 'sk_live_xxx' | tr -d '\n')"
```

**Cross-platform parity.** Shared tokens must match across Vercel and Convex:
- `CONVEX_WEBHOOK_TOKEN` must be identical on both platforms
- Missing on one → webhooks silently fail

### 6. CLI Environment Gotcha

**Warning:** `CONVEX_DEPLOYMENT=prod:xxx npx convex data` may return dev data.

Always use the explicit `--prod` flag:
```bash
# ❌ Unreliable
CONVEX_DEPLOYMENT=prod:xxx npx convex data subscriptions

# ✅ Reliable
npx convex run --prod subscriptions:checkAccess
```

When in doubt, verify via Convex Dashboard.

## Quick Reference

### Required Environment Variables

| Variable | Where | Purpose |
|----------|-------|---------|
| `STRIPE_SECRET_KEY` | Backend (Convex/Vercel) | API authentication |
| `STRIPE_WEBHOOK_SECRET` | Backend | Signature verification |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Frontend | Stripe.js initialization |
| `NEXT_PUBLIC_STRIPE_*_PRICE_ID` | Frontend | Checkout price selection |

### Checkout Session Modes

| Mode | Use Case | Special Params |
|------|----------|----------------|
| `payment` | One-time purchase | `payment_intent_data`, `customer_creation` |
| `subscription` | Recurring billing | `subscription_data`, NO `customer_creation` |
| `setup` | Save payment method | `setup_intent_data`, `customer_creation` |

### Webhook Verification Pattern

```typescript
// ALWAYS verify signatures in production
const sig = request.headers.get("stripe-signature");
const event = stripe.webhooks.constructEvent(
  body,
  sig,
  process.env.STRIPE_WEBHOOK_SECRET!
);
```

## Debugging Checklist

When Stripe integration fails:

1. **Environment Check**
   ```bash
   # Convex (use --prod flag, not env var)
   npx convex env list           # dev
   npx convex env list --prod    # prod (reliable)

   # Vercel
   vercel env ls --environment=production
   ```

2. **Stripe Dashboard**
   - Check Logs > API requests for errors
   - Check Developers > Webhooks for delivery status
   - Verify Products/Prices match env vars

3. **Code Audit**
   - No hardcoded keys (`sk_test_`, `sk_live_`)
   - Correct mode-dependent parameters
   - Webhook signature verification present

## References

See `references/` directory:
- `parameter-constraints.md` - Mode-dependent parameter rules
- `webhook-patterns.md` - Signature verification, idempotency
- `env-var-requirements.md` - Where each variable goes
- `common-pitfalls.md` - Lessons from production incidents

## Audit Script

Run `./scripts/stripe_audit.sh` for automated checks:
```bash
~/.claude/skills/stripe/scripts/stripe_audit.sh
```
