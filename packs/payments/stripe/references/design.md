# Stripe Integration Design

Produce a clear, implementable design that follows business model preferences and current Stripe best practices.

## Process

1. **Understand Requirements**: Subscription billing, one-time payments, or both. Reference business-model-preferences for constraints.

2. **Research Current Patterns**: Use Gemini to check current Stripe Checkout best practices. Don't assume last year's patterns are optimal.

3. **Design the Integration** covering:
   - Checkout flow (embedded vs redirect, mode, customer creation, trial strategy)
   - Webhook events (which to handle, idempotency, error handling)
   - Subscription state (fields to store, access control, trial handling)
   - Price structure (monthly, annual, trial duration)

4. **Get Validation**: Run through Thinktank for multi-perspective review.

## Output
Architecture decisions with rationale, specific Stripe APIs, data model, webhook events, access control logic.
