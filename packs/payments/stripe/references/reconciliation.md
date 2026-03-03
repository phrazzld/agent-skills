# Reconciliation Patterns

**Webhooks for speed, reconciliation for correctness.**

## Pattern 1: Scheduled Reconciliation
Run cron to compare local state with Stripe. Hourly for subscriptions.

```typescript
export const reconcileSubscriptions = internalAction({
  handler: async (ctx) => {
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
    const stripeSubscriptions = await stripe.subscriptions.list({ status: 'all', limit: 100 });
    const users = await ctx.runQuery(internal.users.listWithStripeId);
    for (const user of users) {
      const stripeSub = stripeSubscriptions.data.find(s => s.customer === user.stripeCustomerId);
      const expectedStatus = stripeSub?.status ?? 'none';
      if (user.subscriptionStatus !== expectedStatus) {
        await ctx.runMutation(internal.users.updateSubscriptionStatus, {
          userId: user._id, status: expectedStatus, subscriptionId: stripeSub?.id,
        });
      }
    }
  },
});
```

## Pattern 2: On-Demand Reconciliation
Reconcile specific user when they report issues. Fetch from Stripe, compare, fix.

## Pattern 3: Event Replay
Fetch and replay missed events from `stripe.events.list()` with idempotency checks.

## Pattern 4: Idempotent Webhook Handler
Record event ID before processing. Check for duplicates on entry.

## When to Reconcile
- **Hourly**: Subscriptions, payments
- **On-demand**: User reports issues
- **Event-triggered**: After webhook failure alert, after deployment

## Best Practices
- Log all drift with before/after values
- Store event IDs for idempotency
- Paginate external API calls
- Rate limit reconciliation
- Alert on >5% mismatch
