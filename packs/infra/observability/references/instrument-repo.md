# Instrument Repo

Add production observability to a repository. Detects stack, installs SDKs, writes config, opens PR.

## Shared Config

```
SENTRY_ORG=your-org
SENTRY_TEAM=your-team
POSTHOG_PROJECT_ID=293836
POSTHOG_HOST=https://us.i.posthog.com
```

All repos share ONE PostHog project (segmented by events). Each repo gets its OWN Sentry project.

## Detection

```bash
# Language detection
[ -f package.json ] && echo "typescript"
[ -f go.mod ] && echo "go"
[ -f pyproject.toml ] || [ -f setup.py ] && echo "python"
[ -f Package.swift ] && echo "swift"
[ -f Cargo.toml ] && echo "rust"

# Framework detection (TypeScript)
grep -q '"next"' package.json 2>/dev/null && echo "nextjs"
grep -q '"hono"' package.json 2>/dev/null && echo "hono"
grep -q '"express"' package.json 2>/dev/null && echo "express"
grep -q '"react-native"' package.json 2>/dev/null && echo "react-native"

# LLM usage detection (for Helicone)
grep -rq '@ai-sdk\|openai\|anthropic\|@google/genai' package.json src/ lib/ app/ 2>/dev/null && echo "has-llm"
```

## What to Add (Decision Matrix)

| Condition | Sentry | PostHog | Helicone |
|-----------|--------|---------|----------|
| Any app/service | YES | -- | -- |
| User-facing web app | YES | YES | -- |
| Has LLM SDK imports | YES | maybe | YES |
| CLI tool | YES | NO | maybe |
| GitHub Action / lib | NO | NO | NO |

## Per-repo Workflow

1. Detect language, framework, LLM usage, existing instrumentation
2. `git checkout -b infra/observability origin/main`
3. Create Sentry project if needed
4. Install packages (language-specific)
5. Write/update config files from templates
6. Update .env.example
7. Typecheck/build to verify
8. Commit, push, open PR

## Sentry Sampling Rates

```
tracesSampleRate: 0.1          # 10% of transactions
replaysSessionSampleRate: 0    # Don't record sessions by default
replaysOnErrorSampleRate: 1.0  # Always replay on error
```

## Templates by Stack

| Stack | Install | Key Files |
|-------|---------|-----------|
| Next.js | `pnpm add @sentry/nextjs posthog-js posthog-node` | sentry.*.config.ts, instrumentation.ts, lib/sentry.ts, posthog-provider.tsx |
| Node (Express/Hono) | `pnpm add @sentry/node` | lib/sentry.ts |
| Go | `go get github.com/getsentry/sentry-go` | internal/observability/sentry.go |
| Python | `pip install sentry-sdk` | observability.py |
| Swift | SPM: sentry-cocoa | SentrySetup.swift |
| Rust | `sentry = "0.35"` in Cargo.toml | src/sentry_init.rs |
| React Native | `pnpm add @sentry/react-native posthog-react-native` | -- |

## Env Var Reference

| Variable | Scope | Notes |
|----------|-------|-------|
| `NEXT_PUBLIC_SENTRY_DSN` | Per-project | Unique per Sentry project |
| `SENTRY_AUTH_TOKEN` | Shared | For source map uploads |
| `SENTRY_ORG` | your-org | Set per organization |
| `NEXT_PUBLIC_POSTHOG_KEY` | Shared | PostHog project API key |
| `NEXT_PUBLIC_POSTHOG_HOST` | `/ingest` | Via rewrite proxy |
| `HELICONE_API_KEY` | Shared (server-only) | Never expose client-side |

## Anti-Patterns

- `tracesSampleRate: 1` -- exhausts free tier instantly
- Missing PII scrubbing -- privacy violation
- `sendDefaultPii: true` -- leaks emails/IPs
- PostHog without `/ingest` rewrite -- blocked by ad blockers
- Helicone API key in client-side code -- key exposure
- Hardcoded DSN in code instead of env var
- Missing `respect_dnt: true` on PostHog
