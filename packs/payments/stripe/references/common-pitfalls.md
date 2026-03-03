# Common Stripe Integration Pitfalls

Lessons from production incidents and API gotchas.

## Pitfall #1: Dev ≠ Prod Environment Variables

**Symptom:** Integration works locally, fails in production with 500 errors.

**Root Cause:** Env vars set in development but not in production.

**Platforms affected:**
- Convex (separate dev/prod deployments)
- Vercel (separate environment scopes)
- Any platform with environment isolation

**Prevention:**
```bash
# Always verify prod env vars before deploying
CONVEX_DEPLOYMENT=prod:xxx npx convex env list | grep STRIPE
vercel env ls --environment=production | grep STRIPE
```

**Detection:**
- Health endpoint returns Stripe status
- Pre-push hooks verify prod env vars

---

## Pitfall #2: customer_creation in Subscription Mode

**Symptom:** Stripe API error when creating checkout session.

**Root Cause:** `customer_creation` parameter is invalid in `subscription` mode.

**Why it happens:** TypeScript types don't encode mode-dependent constraints.

**The fix:**
```typescript
// ❌ WRONG
stripe.checkout.sessions.create({
  mode: 'subscription',
  customer_creation: 'always', // Invalid!
});

// ✅ CORRECT
stripe.checkout.sessions.create({
  mode: 'subscription',
  // Subscription mode automatically handles customer creation
});
```

**Prevention:** Always verify mode-specific parameters against Stripe docs.

---

## Pitfall #3: Webhook 500s = Config, Not Code

**Symptom:** Webhook endpoint returns 500 in production, works locally.

**Root Cause:** Usually missing `STRIPE_WEBHOOK_SECRET` in production.

**Debug order:**
1. Check env vars first
2. Check Stripe Dashboard webhook logs
3. Then review code

**Not the cause:**
- Code bugs (usually)
- Race conditions (rarely)
- Complex async issues (almost never)

---

## Pitfall #4: Wrong Webhook Secret

**Symptom:** Signature verification fails: "No signatures found matching..."

**Root Cause:** Using dev webhook secret in production (or vice versa).

**Each environment has unique webhook secret:**
- `stripe listen` generates a local secret
- Dashboard webhook generates a different secret
- Test mode and live mode have different secrets

**Prevention:**
```bash
# Verify correct secret for each environment
# Dev: from `stripe listen` output
# Prod: from Stripe Dashboard > Developers > Webhooks > Signing secret
```

---

## Pitfall #5: Trusting TypeScript for API Constraints

**Symptom:** Code compiles but API returns error.

**Root Cause:** Stripe TypeScript types are permissive, not restrictive.

**Examples of uncaught constraints:**
- `customer_creation` only valid in `payment`/`setup` mode
- `trial_period_days` requires `subscription` mode
- Some `payment_method_types` incompatible with certain modes

**Prevention:**
- Always verify against API documentation
- Add unit tests for parameter shapes
- Test with real API in test mode

---

## Pitfall #6: Over-Engineering Under Pressure

**Symptom:** Adding complex code (race condition handling, retry logic) when the real issue is configuration.

**Root Cause:** Debugging code before checking config.

**The pattern:**
1. See 500 error in production
2. Assume code bug
3. Add complex fixes
4. Real issue was missing env var

**Prevention:** Follow "Check Config Before Code" principle:
1. Verify env vars
2. Check Stripe Dashboard
3. Review webhook logs
4. THEN examine code

---

## Pitfall #7: Raw Body Not Preserved

**Symptom:** Webhook signature verification always fails.

**Root Cause:** Middleware parsed JSON before webhook handler.

**The issue:**
```typescript
// Some frameworks auto-parse JSON
app.use(express.json()); // This breaks webhook verification!

// Stripe needs raw body for signature verification
const sig = req.headers['stripe-signature'];
stripe.webhooks.constructEvent(req.rawBody, sig, secret); // Needs raw!
```

**Prevention:**
- Exclude webhook route from body parsing middleware
- Use raw body parser for webhook endpoint
- Next.js App Router: Use `request.text()` not `request.json()`

---

## Pitfall #8: Hardcoded Test Keys in Code

**Symptom:** Test transactions appear in production, or production keys exposed.

**Root Cause:** Keys committed to code instead of env vars.

**Detection:**
```bash
# Scan for hardcoded keys
grep -r "sk_test_\|sk_live_\|pk_test_\|pk_live_" src/ --include="*.ts" --include="*.tsx"
```

**Prevention:**
- Pre-commit hook to scan for key patterns
- Always use `process.env.STRIPE_*`
- Never commit `.env.local`

---

## Pitfall #9: Webhook Endpoint Not Registered

**Symptom:** Events never reach your handler; no webhook logs in Stripe Dashboard.

**Root Cause:** Forgot to register production webhook endpoint.

**Checklist:**
1. Development: `stripe listen --forward-to localhost:3000/api/webhooks`
2. Staging: Dashboard webhook pointing to staging URL
3. Production: Dashboard webhook pointing to production URL

**Each needs its own webhook endpoint registration!**

---

## Pitfall #10: Price IDs Mismatch

**Symptom:** Checkout fails with "No such price" error.

**Root Cause:** Env var contains wrong price ID (test vs live, or old ID).

**Prevention:**
```bash
# Verify price IDs match Stripe Dashboard
stripe prices list --limit 10

# Compare with env vars
echo $NEXT_PUBLIC_STRIPE_MONTHLY_PRICE_ID
echo $NEXT_PUBLIC_STRIPE_ANNUAL_PRICE_ID
```

---

## Debugging Flowchart

```
Production Stripe Error
         │
         ▼
    ┌─────────────┐
    │ Check Env   │──No──► Set missing env vars
    │ Vars Set?   │
    └─────────────┘
         │ Yes
         ▼
    ┌─────────────┐
    │ Check Stripe│──Errors──► Fix API params
    │ Dashboard   │
    └─────────────┘
         │ OK
         ▼
    ┌─────────────┐
    │ Check       │──Failed──► Fix webhook config
    │ Webhooks    │
    └─────────────┘
         │ OK
         ▼
    Now examine code
```

---

## Pitfall #11: Trailing Newlines in Environment Variables

**Symptom:** "Invalid character in header content" or "ERR_INVALID_CHAR" errors.

**Root Cause:** Env var contains literal `\n` or trailing whitespace.

**How it happens:**
```bash
# ❌ echo adds newline, some tools don't strip it
echo "sk_live_xxx" | vercel env add STRIPE_SECRET_KEY production

# ❌ Copy-paste from files/editors can include invisible chars
export STRIPE_SECRET_KEY="sk_live_xxx
"
```

**Why it breaks:** HTTP headers cannot contain newlines. The Authorization header becomes `Bearer sk_live_xxx\n` which is invalid.

**The fix:**
```bash
# ✅ Use printf to avoid trailing newline
printf '%s' 'sk_live_xxx' | vercel env add STRIPE_SECRET_KEY production

# ✅ Or explicitly trim when setting
npx convex env set --prod STRIPE_SECRET_KEY "$(echo 'sk_live_xxx' | tr -d '\n')"
```

**Detection:**
```bash
# Check for trailing whitespace in current env
env | grep STRIPE | while read line; do
  if [[ "$line" =~ [[:space:]]$ ]]; then
    echo "WARNING: $line has trailing whitespace"
  fi
done
```

---

## Pitfall #12: Vercel-Convex Token Parity

**Symptom:** Webhooks silently fail. No errors in logs, but data never syncs.

**Root Cause:** Shared token (like `CONVEX_WEBHOOK_TOKEN`) set on one platform but not the other.

**Why it happens:**
- Vercel and Convex have separate env var management
- Easy to set on one and forget the other
- No built-in cross-platform verification

**Example scenario:**
1. Set `CONVEX_WEBHOOK_TOKEN` on Vercel
2. Forget to set it on Convex production
3. Webhook handler validates token → fails silently
4. Subscription data never updates

**Prevention:**
```bash
# Always verify parity for shared tokens
vercel env ls --environment=production | grep CONVEX_WEBHOOK_TOKEN
npx convex env list --prod | grep CONVEX_WEBHOOK_TOKEN

# Both should exist and match
```

**Detection:**
Add parity check to pre-deploy script or CI pipeline.

---

## Pitfall #13: CLI Environment Confusion

**Symptom:** Investigation shows wrong data, leading to wild goose chase.

**Root Cause:** `CONVEX_DEPLOYMENT=prod:xxx npx convex data` may still query dev deployment.

**Why it happens:**
- The `CONVEX_DEPLOYMENT` env var is unreliable for some commands
- CLI may ignore it or use cached config
- No warning when querying wrong environment

**Real impact:** Wasted 45+ minutes investigating a non-existent "clerkId mismatch" that only existed in dev data.

**The fix:**
```bash
# ❌ Don't rely on CONVEX_DEPLOYMENT env var
CONVEX_DEPLOYMENT=prod:xxx npx convex data subscriptions

# ✅ Use the explicit --prod flag
npx convex run --prod subscriptions:checkAccess

# ✅ Or always verify via Dashboard
# Convex Dashboard shows deployment name clearly
```

**Prevention:**
1. Use `--prod` flag, not env var
2. Always verify environment in Dashboard before trusting CLI output
3. Read `npx convex --help` before attempting workarounds
