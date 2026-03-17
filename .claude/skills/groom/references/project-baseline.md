# Project Baseline Standards

Policy reference for what "baseline compliant" means. Each requirement maps to an
audit domain check. `/groom` Phase 2 runs `/audit --all` which evaluates all of these.

## Universal (every project)

| Requirement | Domain | Check ID | Fix Skill | Priority |
|-------------|--------|----------|-----------|----------|
| Sentry error tracking | production | `sentry` | `/instrument-repo` | p1 |
| PostHog analytics | production | `posthog` | `/instrument-repo` | p1 |
| Unit test runner | quality | `test-runner` | — | p0 |
| E2E test framework | quality | `e2e-framework` | — | p2 |
| Coverage threshold 75%+ | quality | `coverage-threshold` | — | p1 |
| Coverage PR comments | quality | `coverage-pr-comments` | — | p2 |
| TypeScript strict mode | quality | `typescript-strict` | — | p1 |
| ESLint/Biome configured | quality | `eslint` | — | p1 |
| Lefthook git hooks | quality | `git-hooks` | — | p1 |
| Bun package manager | quality | `package-manager-bun` | `/bun` | p2 |
| CI workflow | quality | `ci-workflow` | — | p0 |
| Health endpoint exists | production | `health-endpoint` | — | p1 |
| Health validates deps | production | `health-endpoint-depth` | — | p2 |
| Structured logging | production | `structured-logging` | `/structured-logging` | p2 |
| Rate limiting | production | `rate-limiting` | — | p2 |
| Error boundaries (React) | quality | `error-boundaries` | — | p2 |

## Security (every project)

| Requirement | Domain | Check ID | Fix Skill | Priority |
|-------------|--------|----------|-----------|----------|
| Dependabot enabled | security | `dependabot` | — | p1 |
| Secrets scanning | security | `secrets-scanning` | — | p1 |
| Branch protection | security | `branch-protection` | — | p1 |
| Default branch = master | security | `default-branch-master` | — | p2 |
| Security headers | security | `security-headers` | — | p2 |

## Conditional: LLM Projects

Applies when `detect:` gate passes (project imports LLM SDKs).

| Requirement | Domain | Check ID | Fix Skill | Priority |
|-------------|--------|----------|-----------|----------|
| Helicone observability | llm | `helicone` | `/helicone-observability` | p1 |
| Promptfoo evaluation | llm | `promptfoo` | `/llm-evaluation` | p2 |
| LLM eval in CI | llm | `llm-ci-eval` | — | p3 |
| LLM session tracing | llm | `langfuse-or-traces` | — | p3 |
