---
name: business-model-preferences
description: |
  Pricing philosophy and business model constraints.
  Auto-invoke when: evaluating pricing, checkout flows, subscription logic, tier structures.
user-invocable: false
---

# Business Model Preferences

These are organizational preferences. Apply them when designing or reviewing any billing integration.

## Philosophy

Keep it simple. Complexity in pricing confuses customers and creates engineering debt.

## Pricing Model

**Single tier or nothing.** Either:
- Free and open source (no billing)
- One price point with full access

No multiple tiers. No Basic/Pro/Enterprise. No feature gating. No usage-based pricing.

If annual pricing exists, it's simply "2 months free" — same features, discounted rate.

## Free Trial, Not Free Tier

Offer a trial (14 days standard). After trial: pay or lose access.

No freemium. No "free forever with limits." Trial is the only free path.

## Credit Card Upfront

**Require payment method at trial signup.** This is the standard SaaS pattern:

1. User enters credit card during signup
2. Trial starts immediately (no charge)
3. If user cancels before trial ends → no charge
4. If trial ends without cancellation → automatic charge, subscription begins

**Why upfront:**
- Higher conversion (commitment at signup)
- Qualified leads (real intent to pay)
- Smoother UX (no second checkout flow)
- Less support burden (no "how do I upgrade?" questions)

**Stripe implementation:**
```typescript
await stripe.checkout.sessions.create({
  mode: 'subscription',
  payment_method_collection: 'always',  // Require card
  subscription_data: {
    trial_period_days: 14,  // Or use trial_end for specific date
  },
});
```

**UX messaging:**
- "Start your 14-day free trial"
- "You won't be charged until [date]"
- "Cancel anytime during trial"

## Trial Completion on Upgrade

When a user upgrades mid-trial, honor the remaining trial days.

Pass `trial_end` to Stripe with the remaining time. User finishes their trial, THEN billing starts. Never charge immediately on mid-trial upgrade — that's confusing and feels like a bait-and-switch.

## Simplicity Tests

When reviewing pricing or checkout:
- Can you explain the pricing in one sentence?
- Is there only one "upgrade" button?
- Does the pricing page have comparison tables? (It shouldn't.)
- Would upgrading mid-trial surprise a user with an immediate charge? (It shouldn't.)

## Application

Reference these preferences when:
- Designing new Stripe integrations
- Reviewing checkout flows
- Auditing subscription logic
- Evaluating pricing page designs
