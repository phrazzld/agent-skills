# Stripe Environment Variable Requirements

Where each environment variable should be configured for different architectures.

## Architecture: Next.js + Convex (Recommended)

In this architecture:
- **Stripe SDK runs in Next.js API routes** (Vercel)
- **Convex stores subscription state** (database)
- **Webhooks hit Next.js**, which calls Convex mutations

### Variable Map

| Variable | Local | Vercel | Convex |
|----------|:-----:|:------:|:------:|
| `STRIPE_SECRET_KEY` | ✅ | ✅ | ❌ |
| `STRIPE_WEBHOOK_SECRET` | ✅ | ✅ | ❌ |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | ✅ | ✅ | ❌ |
| `STRIPE_PRICE_ID` | ✅ | ✅ | ❌ |
| `CONVEX_WEBHOOK_SECRET` | ✅ | ✅ | ✅ |
| `CLERK_JWT_ISSUER_DOMAIN` | ❌ | ❌ | ✅ |

**Key insight:** Convex does NOT need Stripe keys because the Stripe SDK runs in Next.js.

### Critical Parity Requirement

```
CONVEX_WEBHOOK_SECRET must be IDENTICAL on:
├── Vercel Production
└── Convex Production
```

If these don't match, webhook calls from Next.js to Convex will fail authentication.

### Setup Commands

```bash
# === Local Development ===
# .env.local
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_PRICE_ID=price_...
CONVEX_WEBHOOK_SECRET=$(openssl rand -hex 32)

# === Vercel (all environments) ===
vercel env add STRIPE_SECRET_KEY production
vercel env add STRIPE_WEBHOOK_SECRET production
vercel env add NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY production
vercel env add STRIPE_PRICE_ID production
vercel env add CONVEX_WEBHOOK_SECRET production  # Must match Convex!

# === Convex ===
# Dev
npx convex env set CONVEX_WEBHOOK_SECRET "..."
npx convex env set CLERK_JWT_ISSUER_DOMAIN "https://your-instance.clerk.accounts.dev"

# Prod (use --prod flag, NOT env var)
npx convex env set --prod CONVEX_WEBHOOK_SECRET "..."  # Must match Vercel!
npx convex env set --prod CLERK_JWT_ISSUER_DOMAIN "https://clerk.yourdomain.com"
```

### Data Flow

```
User clicks Subscribe
    ↓
Next.js checkout API route (uses STRIPE_SECRET_KEY)
    ↓
Stripe Checkout Session
    ↓
User completes payment
    ↓
Stripe webhook → Next.js webhook route
    ↓ (uses STRIPE_WEBHOOK_SECRET to verify)
    ↓ (uses CONVEX_WEBHOOK_SECRET to authenticate)
    ↓
Convex mutation (validates CONVEX_WEBHOOK_SECRET)
    ↓
Database updated
```

## Architecture: Convex-Only (HTTP Actions)

If using Convex HTTP actions for Stripe webhooks:

| Variable | Local | Vercel | Convex |
|----------|:-----:|:------:|:------:|
| `STRIPE_SECRET_KEY` | ✅ | ❌ | ✅ |
| `STRIPE_WEBHOOK_SECRET` | ✅ | ❌ | ✅ |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | ✅ | ✅ | ❌ |

## Verification Commands

### Check Convex (use --prod flag!)

```bash
# Dev environment
npx convex env list

# Prod environment (CORRECT)
npx convex env list --prod

# WRONG - env var doesn't reliably switch environments
# CONVEX_DEPLOYMENT=prod:xxx npx convex env list
```

### Check Vercel

```bash
# All environments
pnpm dlx vercel env ls

# Production only
pnpm dlx vercel env ls --environment=production
```

### Verify Parity

```bash
# Pull Vercel prod to compare
pnpm dlx vercel env pull .env.vercel-check --environment=production --yes
grep CONVEX_WEBHOOK_SECRET .env.vercel-check
npx convex env get --prod CONVEX_WEBHOOK_SECRET
rm .env.vercel-check
```

## Test vs Live Keys

| Prefix | Environment |
|--------|-------------|
| `sk_test_`, `pk_test_` | Development, staging |
| `sk_live_`, `pk_live_` | Production |
| `whsec_` | Both (unique per endpoint) |

**Rule:** Never mix test and live keys in the same environment.

## Common Mistakes

### 1. Setting Stripe keys in Convex

```bash
# WRONG for Next.js + Convex architecture
npx convex env set STRIPE_SECRET_KEY "..."

# Stripe SDK runs in Next.js, not Convex!
```

### 2. Using env var for Convex prod

```bash
# UNRELIABLE - may return dev data
CONVEX_DEPLOYMENT=prod:xxx npx convex env list

# CORRECT - use --prod flag
npx convex env list --prod
```

### 3. Forgetting Vercel ↔ Convex parity

```bash
# Set in Vercel...
vercel env add CONVEX_WEBHOOK_SECRET production

# ...but forgot Convex prod!
# npx convex env set --prod CONVEX_WEBHOOK_SECRET "..."
```

### 4. Trailing whitespace in secrets

```bash
# WRONG - echo adds newline
echo 'sk_live_xxx' | vercel env add STRIPE_SECRET_KEY production

# CORRECT - printf preserves exact value
printf '%s' 'sk_live_xxx' | vercel env add STRIPE_SECRET_KEY production
```

## Pre-Deployment Checklist

```bash
# 1. Verify Vercel production vars
pnpm dlx vercel env ls --environment=production | grep -E "STRIPE|CONVEX"

# 2. Verify Convex production vars
npx convex env list --prod

# 3. Verify parity (critical!)
# CONVEX_WEBHOOK_SECRET must match between Vercel and Convex prod

# 4. Verify using live keys in production
# Should see sk_live_, pk_live_ prefixes

# 5. Run audit script
~/.claude/skills/stripe/scripts/stripe_audit.sh
```

## Security Rules

1. **Never commit secrets** - Add `.env.local` to `.gitignore`
2. **Never expose in frontend** - Only `NEXT_PUBLIC_*` vars are safe for client
3. **Never log secrets** - Mask in error messages
4. **Rotate on exposure** - Generate new keys immediately if leaked
