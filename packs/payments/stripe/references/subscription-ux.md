# Subscription Management UX

Every Stripe integration must include a world-class subscription management experience.

## Non-Negotiable Requirements

### 1. View Current Plan
- Plan name, subscription status (active, trialing, canceled, past_due)
- Clear visual indicator of status
- Trial remaining (if applicable)

### 2. See Billing Cycle
- Next billing date, amount, frequency (monthly/annual)
- Current period start/end dates

### 3. View Payment Method
- Card brand and last 4 digits
- Expiration date, update button

### 4. Manage Subscription
- Cancel, resume (if before period end), upgrade/downgrade, switch frequency

### 5. View Billing History
- Past invoices with dates and amounts
- Download invoice PDFs, payment status

## Recommended Approach: Hybrid

Custom settings page for display, Stripe Portal for mutations:

```tsx
<SettingsCard>
  <h2>Subscription</h2>
  <p>Plan: {planName}</p>
  <p>Status: <StatusBadge status={status} /></p>
  <p>Next billing: {formatDate(currentPeriodEnd)}</p>
  <p>Card: {cardBrand} ending in {cardLast4}</p>
  <Button onClick={openStripePortal}>Manage Subscription</Button>
</SettingsCard>
```

## Component Structure

```
components/billing/
├── SubscriptionCard.tsx
├── BillingCycleInfo.tsx
├── PaymentMethodDisplay.tsx
├── BillingHistory.tsx
├── ManageSubscriptionButton.tsx
└── TrialBanner.tsx
```

## Status Messaging

| Status | Message | Color |
|--------|---------|-------|
| active | "Your subscription is active" | Green |
| trialing | "Trial ends in X days" | Blue |
| canceled | "Cancels on [date]" | Yellow |
| past_due | "Payment failed - update card" | Red |
| incomplete | "Complete payment setup" | Red |

## Schema Requirements

```typescript
users: defineTable({
  subscriptionStatus: v.optional(v.string()),
  stripeCustomerId: v.optional(v.string()),
  stripeSubscriptionId: v.optional(v.string()),
  currentPeriodEnd: v.optional(v.number()),
  cancelAtPeriodEnd: v.optional(v.boolean()),
  trialEndsAt: v.optional(v.number()),
  paymentMethodSummary: v.optional(v.object({
    brand: v.string(), last4: v.string(),
    expMonth: v.number(), expYear: v.number(),
  })),
  planName: v.optional(v.string()),
  planInterval: v.optional(v.string()),
})
```

## Webhook Updates for Payment Method Cache

Handle `customer.subscription.updated`, `payment_method.attached`, `payment_method.updated` to keep payment method data fresh.
