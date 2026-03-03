# Stripe Webhook Patterns

Best practices for webhook handling, signature verification, and idempotency.

## Signature Verification

**ALWAYS verify webhook signatures in production.**

### Basic Pattern

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function handleWebhook(request: Request) {
  const body = await request.text();
  const sig = request.headers.get('stripe-signature');

  if (!sig) {
    return new Response('Missing signature', { status: 400 });
  }

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return new Response('Invalid signature', { status: 400 });
  }

  // Process the verified event
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object);
      break;
    // ...
  }

  return new Response('OK', { status: 200 });
}
```

### Convex HTTP Actions

```typescript
import { httpAction } from './_generated/server';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export const stripeWebhook = httpAction(async (ctx, request) => {
  const body = await request.text();
  const sig = request.headers.get('stripe-signature')!;

  const event = stripe.webhooks.constructEvent(
    body,
    sig,
    process.env.STRIPE_WEBHOOK_SECRET!
  );

  // Use ctx.runMutation for database updates
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    await ctx.runMutation(internal.subscriptions.activate, {
      userId: session.metadata?.userId,
      stripeCustomerId: session.customer as string,
    });
  }

  return new Response('OK');
});
```

## Idempotency

Webhooks can be delivered multiple times. Design handlers to be idempotent.

### Pattern: Check Before Update

```typescript
async function handleCheckoutComplete(session: Stripe.Checkout.Session) {
  const userId = session.metadata?.userId;

  // Check if already processed
  const existing = await db.query('subscriptions')
    .withIndex('by_stripe_session', q => q.eq('stripeSessionId', session.id))
    .first();

  if (existing) {
    console.log('Session already processed:', session.id);
    return; // Idempotent - already handled
  }

  // Process the new subscription
  await db.insert('subscriptions', {
    userId,
    stripeSessionId: session.id,
    stripeCustomerId: session.customer as string,
    status: 'active',
  });
}
```

### Pattern: Upsert by External ID

```typescript
// Use Stripe IDs as the source of truth
async function syncSubscription(subscription: Stripe.Subscription) {
  await db.upsert('subscriptions', {
    stripeSubscriptionId: subscription.id, // Unique key
    status: subscription.status,
    currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    // ...
  });
}
```

## Event Types to Handle

### Checkout Flow

| Event | When | Action |
|-------|------|--------|
| `checkout.session.completed` | Payment successful | Create/activate subscription |
| `checkout.session.expired` | Session timed out | Clean up pending state |

### Subscription Lifecycle

| Event | When | Action |
|-------|------|--------|
| `customer.subscription.created` | New subscription | Store subscription details |
| `customer.subscription.updated` | Plan change, renewal | Update stored state |
| `customer.subscription.deleted` | Cancelled | Mark as inactive |
| `invoice.payment_failed` | Payment failed | Notify user, retry logic |

### One-time Payments

| Event | When | Action |
|-------|------|--------|
| `payment_intent.succeeded` | Payment complete | Fulfill order |
| `payment_intent.payment_failed` | Payment failed | Notify user |

## Webhook Endpoint Registration

### Development (CLI)

```bash
# Forward webhooks to local server
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Get the webhook signing secret from output
# whsec_...
```

### Production (Dashboard)

1. Go to Developers > Webhooks
2. Add endpoint: `https://your-domain.com/api/webhooks/stripe`
3. Select events to receive
4. Copy signing secret to env vars

### Convex HTTP Routes

```typescript
// convex/http.ts
import { httpRouter } from 'convex/server';
import { stripeWebhook } from './stripe';

const http = httpRouter();

http.route({
  path: '/stripe/webhook',
  method: 'POST',
  handler: stripeWebhook,
});

export default http;
```

Webhook URL: `https://<deployment>.convex.site/stripe/webhook`

## Debugging Webhooks

### Stripe CLI

```bash
# View recent webhook deliveries
stripe events list --limit 10

# Trigger a test event
stripe trigger checkout.session.completed

# Resend a failed webhook
stripe events resend evt_xxx
```

### Dashboard

1. Developers > Webhooks > Select endpoint
2. View delivery attempts and responses
3. Check for 500 errors (usually missing env vars)
4. Resend failed events

## Common Issues

### 500 Errors in Production

Usually means:
1. `STRIPE_WEBHOOK_SECRET` not set in production env
2. Wrong webhook secret (dev vs prod)
3. Handler throws unhandled exception

**Debug steps:**
```bash
# Check env vars
CONVEX_DEPLOYMENT=prod:xxx npx convex env list | grep STRIPE

# Check logs
CONVEX_DEPLOYMENT=prod:xxx npx convex logs
```

### Signature Verification Failed

1. Ensure you're using raw request body (not parsed JSON)
2. Verify correct webhook secret for environment
3. Check for request body modifications by middleware
