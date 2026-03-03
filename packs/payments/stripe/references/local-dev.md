# Stripe Local Development

Ensure Stripe webhooks work locally by auto-syncing ephemeral secrets.

## The Problem
Stripe CLI generates a new webhook secret every time `stripe listen` starts. If your dev script auto-starts the listener but doesn't sync the secret, you get signature verification failures.

## The Solution
**Auto-start requires auto-sync.** Use `dev-stripe.sh`:
1. Extract secret via `stripe listen --print-secret`
2. Sync to environment (Convex env OR .env.local)
3. THEN start forwarding

## Architecture Decision
| Webhook Location | Secret Sync Target | Restart? | Recommendation |
|-----------------|-------------------|----------|----------------|
| Convex HTTP | `bunx convex env set` | No | Best |
| Next.js API Route | `.env.local` | Yes | Requires orchestration |

## Also Check
If checkout succeeds but access stays locked:
- `stripe_webhook_missing_convex_token` -> `CONVEX_WEBHOOK_TOKEN` missing/mismatched
- Ensure token parity between Next runtime and Convex
