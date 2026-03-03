# Stripe Multi-Environment Setup

## Sandboxes vs Test Mode

**Stripe Sandboxes** are isolated test environments (recommended for development):
- Completely separate account ID, API keys, and data
- Isolated from production - no cross-contamination
- Created from Dashboard: Settings → Sandboxes → Create sandbox

**Test Mode** is a toggle within an account (legacy approach):
- Same account ID, different key prefix (sk_test_ vs sk_live_)
- Shares some configuration with live mode
- Can cause confusion when switching

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MAIN ACCOUNT (Production)                   │
│                     acct_1SV2rAD...                             │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │      Test Mode       │    │      Live Mode       │          │
│  │   sk_test_51SV2rAD.. │    │   sk_live_51SV2rAD.. │          │
│  └──────────────────────┘    └──────────────────────┘          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  SANDBOX (Development)                    │  │
│  │                  acct_1SV2rGD...                          │  │
│  │                  sk_test_51SV2rGD... (different!)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## CLI Profile Configuration

Located at `~/.config/stripe/config.toml`:

```toml
project-name = 'sandbox'  # Default to safer environment

[sandbox]
account_id = 'acct_SANDBOX_ID'
display_name = 'Your App sandbox'

[production]
account_id = 'acct_PRODUCTION_ID'
display_name = 'Your App'
```

**Key principle:** Default to sandbox. Forgetting `-p` hits sandbox (safe), not production.

## CLI Commands Pattern

```bash
# ALWAYS use explicit profile AND mode flag for production
stripe -p sandbox prices list              # Development (test mode is fine)
stripe -p production prices list --live    # Production (MUST use --live)

# Safe commands (no profile needed)
stripe config --list                       # Check current profiles
stripe login -p sandbox                    # Login to sandbox
stripe login -p production                 # Login to production
stripe --help                              # Help
```

**CRITICAL: Production requires `--live` flag**

The Stripe CLI defaults to test mode. Without `--live`, you'll query test data even on the production account:

```bash
# WRONG - returns test mode product IDs (prod_Tq7S...)
stripe -p production products list

# CORRECT - returns live mode product IDs (prod_TrIw...)
stripe -p production products list --live
```

Sandboxes are isolated test environments, so test mode is appropriate. Production accounts handle real money, so always use `--live`.

## Environment Mapping

| Context | CLI Profile | API Keys | Purpose |
|---------|-------------|----------|---------|
| `.env.local` | sandbox | `sk_test_*` (sandbox) | Local development |
| Vercel Preview | sandbox | `sk_test_*` (sandbox) | PR testing |
| Vercel Production | production | `sk_live_*` | Real customers |

## Common Failure Modes

### 1. CLI vs App Environment Mismatch
**Symptom:** Resources created via CLI can't be found by app
**Cause:** CLI logged into main account, app using sandbox keys
**Fix:** Use `stripe -p sandbox` for CLI operations

### 2. Stale Customer ID
**Symptom:** "No such customer" errors during checkout
**Cause:** Customer ID from sandbox stored in DB, but app now using production
**Fix:** Clear `stripeCustomerId` from user record

### 3. Webhook Delivery Failure
**Symptom:** Webhooks show "No endpoint" in Stripe Dashboard
**Cause:** Webhook endpoint configured in wrong account
**Fix:** Configure webhook in correct account (sandbox or production)

## Pre-Flight Checklist

Before ANY Stripe CLI operation:

1. **Check current profile:**
   ```bash
   stripe config --list | grep account_id
   ```

2. **Verify keys match:**
   ```bash
   # In app
   grep '^STRIPE_SECRET_KEY' .env.local | cut -c1-25
   # Should match the account you're targeting
   ```

3. **Use correct profile:**
   ```bash
   stripe -p sandbox ...   # Development
   stripe -p production ... # Production
   ```

## Helper Script

`~/.claude/skills/stripe/scripts/stripe-env.sh`:
```bash
#!/bin/bash
echo "=== Stripe Environment Map ==="
echo "CLI sandbox:    $(stripe -p sandbox config --list 2>&1 | grep account_id | cut -d= -f2)"
echo "CLI production: $(stripe -p production config --list 2>&1 | grep account_id | cut -d= -f2)"
echo ".env.local:     $(grep '^STRIPE_SECRET_KEY' .env.local 2>/dev/null | cut -c1-40)..."
```

## Sources

- [Stripe Sandboxes Documentation](https://docs.stripe.com/sandboxes)
- [Stripe CLI Reference](https://docs.stripe.com/cli)
