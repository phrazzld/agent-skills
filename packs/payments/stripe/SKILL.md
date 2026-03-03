---
name: stripe
description: |
  Complete Stripe lifecycle: audit, design, scaffold, configure, verify, and maintain
  payment integrations. Covers webhooks, subscriptions, checkout flows, billing UX,
  local dev, reconciliation, and security. One skill for all Stripe work.
disable-model-invocation: true
argument-hint: "[focus area, e.g. 'webhooks' or 'subscription UX' or 'local dev']"
---

# /stripe

World-class Stripe integration. Audit, fix, verify -- every time.

## What This Does

Examines your Stripe integration, identifies every gap, implements fixes, and verifies checkout flows work end-to-end. No partial modes. Every run does the full cycle.

## Branching

Assumes you start on `master`/`main`. Before making code changes:

```bash
git checkout -b fix/stripe-$(date +%Y%m%d)
```

Configuration-only changes (env vars, dashboard settings) don't require a branch. Code changes do.

## Process

### 0. Environment Check

**Detect environment mismatch first.** Before any Stripe operations:
```bash
~/.claude/skills/stripe/scripts/detect-environment.sh
```

This compares your app's STRIPE_SECRET_KEY account with CLI profiles. If mismatched, resources created via CLI won't be visible to your app.

**IMPORTANT: Stripe test mode is DEPRECATED.** Two separate accounts exist:
- **Sandbox** (`acct_...sandbox`): Fully isolated dev account. Use its keys for local dev.
- **Production** (`acct_...prod`): Real money. Only `sk_live_*` keys. Never `sk_test_*` from production.

**Billing invariant (Next.js + Convex):**
- `CONVEX_WEBHOOK_TOKEN` must be set in Next runtime (Vercel) and Convex env.
- Values must match (token parity). If drift: payments may succeed but access never unlocks.

### 1. Audit

**Spawn the auditor.** Use the `stripe-auditor` subagent for deep parallel analysis. It examines:
- Configuration (env vars on all deployments, cross-platform parity)
- Webhook health (endpoints registered, URL returns non-3xx, pending_webhooks = 0)
- Subscription logic (trial handling, access control, idempotency)
- Security (no hardcoded keys, secrets not logged, env vars trimmed)
- Business model compliance (single tier, trial honored on upgrade)
- Subscription management UX (settings page, billing history, portal integration)
- Local dev (stripe listen auto-sync, ephemeral secret handling)

**Run automated checks:**
```bash
~/.claude/skills/stripe/scripts/stripe_audit.sh
```

**Research first.** Before assuming current patterns are correct, check Stripe docs for current best practices. Use Gemini. What was right last year may be deprecated.

### 2. Plan

From audit findings, build a complete remediation plan. Don't just list issues -- plan the fixes.

Prioritize:
1. **Critical** -- Blocks checkout or causes payment failures
2. **High** -- Security issues, data integrity problems
3. **Medium** -- Missing UX, suboptimal patterns

### 3. Execute

**Fix everything.** Don't stop at a report.

**Configuration fixes (do directly):**
```bash
# Missing env var
bunx convex env set --prod CONVEX_WEBHOOK_TOKEN "$(printf '%s' 'value')"

# Vercel: set the SAME value (production + preview + dev)
vercel env add CONVEX_WEBHOOK_TOKEN production

# Verify
bunx convex env list --prod | rg "^(STRIPE_|CONVEX_WEBHOOK_TOKEN=)"
```

**Code fixes (delegate to Codex):**
```bash
codex exec --full-auto "Fix [specific issue]. \
File: [path]. Problem: [what's wrong]. \
Solution: [what it should do]. \
Verify: bun run typecheck && bun run test" \
--output-last-message /tmp/codex-fix.md 2>/dev/null
```

**Missing subscription management UX (non-negotiable):**
Every integration needs: settings page showing plan/status/billing date, payment method display, "Manage Subscription" button (Stripe Portal), billing history with downloadable invoices, state-specific messaging (trialing, canceled, past_due). See `references/subscription-ux.md`.

### 4. Verify

**Prove it works.** Not "looks right" -- actually works.

**Checkout flow test:**
1. Create test checkout session
2. Complete with card `4242 4242 4242 4242`
3. Verify webhook received (check logs)
4. Verify subscription created in Stripe Dashboard
5. Verify user state updated in database
6. Verify access granted

**Webhook delivery test:**
```bash
stripe events list --limit 5 | jq '.data[] | {id, type, pending_webhooks}'
# All should have pending_webhooks: 0
```

If any verification fails, go back and fix it.

## Multi-Provider Context

When other payment providers exist (Bitcoin, Lightning, BTCPay), detect and audit all active providers. See `references/multi-provider.md` for unified audit patterns.

## Default Stack

Assumes Next.js + TypeScript + Convex + Vercel + Clerk. Adapts gracefully to other stacks -- concepts are the same, only framework specifics change.

## References

| Reference | Content |
|-----------|---------|
| `references/subscription-ux.md` | Subscription management UI requirements, component structure, API patterns |
| `references/subscription-patterns.md` | Lifecycle patterns, trial-to-paid, access control, webhook handling |
| `references/billing-security.md` | Security patterns, env hygiene, debugging workflow |
| `references/reconciliation.md` | State sync between Stripe and database, event replay, drift detection |
| `references/design.md` | Integration design process, checkout flow decisions |
| `references/scaffold.md` | Code generation from design documents |
| `references/configure.md` | Dashboard setup, env vars across deployments |
| `references/local-dev.md` | Webhook secret auto-sync for local development |
| `references/health.md` | Webhook health diagnostics, redirect detection |
| `references/multi-provider.md` | Unified payment audit across Stripe/Bitcoin/Lightning |
