# Stripe Scaffold

Turn a design document into working code. Delegate to Codex aggressively.

## Components to Generate (Next.js + Convex)

**Backend:**
- `src/lib/stripe.ts` -- Client initialization
- `src/app/api/stripe/checkout/route.ts` -- Checkout session creation
- `src/app/api/stripe/webhook/route.ts` -- Webhook receiver
- `convex/stripe.ts` -- Event processing
- `convex/subscriptions.ts` -- State management
- `convex/billing.ts` -- Billing queries and portal
- `convex/schema.ts` updates -- Subscription fields

**Subscription Management UX (Required):**
See `subscription-ux.md` for full component list.

## Don't Forget
- Trial handling: pass `trial_end` when user upgrades mid-trial
- Access control: check subscription status before gated features
- Error handling: webhook returns 200 even on processing errors
- Signature verification: MUST be first thing in webhook handler
