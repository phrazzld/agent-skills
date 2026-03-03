# Stripe Parameter Constraints

Mode-dependent parameters that TypeScript types don't enforce.

## Checkout Session Modes

### `payment` Mode (One-time purchases)

**Allowed parameters:**
- `payment_intent_data` - Configure the PaymentIntent
- `customer_creation: 'always' | 'if_required'` - When to create customer
- `invoice_creation` - Create invoice for the payment

**Example:**
```typescript
const session = await stripe.checkout.sessions.create({
  mode: 'payment',
  customer_creation: 'always', // ✅ Valid in payment mode
  payment_intent_data: {
    metadata: { orderId: '123' }
  },
  // ...
});
```

### `subscription` Mode (Recurring billing)

**Allowed parameters:**
- `subscription_data` - Configure the Subscription
- `trial_period_days` - Set trial period (via subscription_data)

**NOT allowed:**
- ❌ `customer_creation` - Subscription ALWAYS creates customer
- ❌ `payment_intent_data` - Use `subscription_data` instead

**Example:**
```typescript
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  // customer_creation: 'always', // ❌ INVALID - causes API error
  subscription_data: {
    trial_period_days: 14,
    metadata: { plan: 'pro' }
  },
  // ...
});
```

### `setup` Mode (Save payment method)

**Allowed parameters:**
- `setup_intent_data` - Configure the SetupIntent
- `customer_creation: 'always'` - Must be 'always' for setup mode

**Example:**
```typescript
const session = await stripe.checkout.sessions.create({
  mode: 'setup',
  customer_creation: 'always', // ✅ Required for setup mode
  setup_intent_data: {
    metadata: { purpose: 'subscription' }
  },
  // ...
});
```

## Common Mistakes

### 1. customer_creation in subscription mode

```typescript
// ❌ WRONG - causes Stripe API error
stripe.checkout.sessions.create({
  mode: 'subscription',
  customer_creation: 'always', // Invalid parameter for subscription mode
});

// ✅ CORRECT - omit customer_creation
stripe.checkout.sessions.create({
  mode: 'subscription',
  // Subscription mode always creates/uses a customer
});
```

### 2. payment_intent_data in subscription mode

```typescript
// ❌ WRONG
stripe.checkout.sessions.create({
  mode: 'subscription',
  payment_intent_data: { ... }, // Not valid for subscriptions
});

// ✅ CORRECT
stripe.checkout.sessions.create({
  mode: 'subscription',
  subscription_data: {
    metadata: { ... }
  },
});
```

## Why TypeScript Doesn't Catch This

Stripe's TypeScript types use union types that include all possible parameters:

```typescript
interface SessionCreateParams {
  mode: 'payment' | 'subscription' | 'setup';
  customer_creation?: 'always' | 'if_required'; // Appears valid for all modes
  // ...
}
```

The conditional constraint (customer_creation only valid when mode is 'payment' or 'setup') cannot be expressed in TypeScript without complex conditional types that Stripe doesn't implement.

**Solution:** Always verify against Stripe API documentation when using mode-specific parameters.
