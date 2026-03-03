# Stripe Configure

Set up Stripe Dashboard and deployment environment variables.

## Dashboard Setup
- Products & Prices (note price IDs for env vars)
- Webhook Endpoint (canonical domain, enable required events)
- Customer Portal (configure allowed actions, branding)

## Environment Variables

**Local Development** (sandbox account keys):
```bash
STRIPE_SECRET_KEY=sk_test_...  # from sandbox account
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
NEXT_PUBLIC_STRIPE_PRICE_ID=price_...
```

**Convex:** `npx convex env set [--prod] STRIPE_SECRET_KEY "sk_..."`
**Vercel:** `vercel env add STRIPE_SECRET_KEY production`

## Common Mistakes
- Setting env vars on dev but forgetting prod
- Using wrong domain (non-www when app is www)
- Trailing whitespace in secrets (use `printf '%s'` not `echo`)
- Using sk_test_* from production account (deprecated)
