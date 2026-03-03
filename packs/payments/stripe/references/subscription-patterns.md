# Subscription Lifecycle Patterns

**Stripe is the source of truth for billing. Your database caches state for access decisions.**

## Trial-to-Paid Flow

### Preferred: Credit Card Upfront
Collect payment method at signup. Stripe auto-charges when trial ends.

```typescript
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  payment_method_collection: 'always',
  subscription_data: { trial_period_days: 14, metadata: { userId } },
});
```

### Subscribe During Trial (honor remaining days)
```typescript
const trialEndSeconds = hasRemainingTrial ? Math.floor(trialEndMs / 1000) : undefined;
const session = await stripe.checkout.sessions.create({
  subscription_data: {
    metadata: { userId },
    ...(trialEndSeconds && { trial_end: trialEndSeconds }),
  },
});
```

### Prevent Zombie Trials
Clear trial when subscription activates:
```typescript
await db.patch(user._id, {
  subscriptionStatus: status,
  ...(status === "active" && { trialEndsAt: 0 }),
});
```

## Access Control Priority

Check states in order (first match wins):
1. Active subscription -> access
2. Canceled but in paid period -> access
3. Past due with grace period -> access
4. Locked states (incomplete, unpaid, expired) -> deny
5. Trial active -> access
6. Default -> deny

## Webhook Event Handling

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Link customer, initial status |
| `customer.subscription.created` | Set status, period end |
| `customer.subscription.updated` | Update status, period end |
| `customer.subscription.deleted` | Set status to canceled/expired |
| `invoice.payment_succeeded` | Update period end |
| `invoice.payment_failed` | Set status to past_due |

### Idempotency Pattern
```typescript
if (user.lastStripeEventId === eventId) return { success: false, reason: "duplicate_event" };
if (eventTimestamp < user.lastStripeEventTimestamp) return { success: false, reason: "stale_event" };
```

## Edge Cases
- **Cancel during trial**: Access continues until `currentPeriodEnd`
- **Resubscribe after cancel**: New checkout, billing starts immediately
- **Never had trial**: `trial_end` not passed, billing starts immediately
- **Out-of-order webhooks**: Use `eventTimestamp` comparison, `eventId` for dedup
