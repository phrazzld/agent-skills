# Quality Gates Philosophy

From the absorbed `quality-gates` skill.

## What You Get (When Complete)

- Lefthook pre-commit: lint, format, typecheck (fast, staged files only)
- Lefthook pre-push: test, build (comprehensive)
- Vitest with coverage configured
- GitHub Actions CI running on every PR
- Branch protection requiring CI to pass
- Commitlint enforcing conventional commits
- Verified end-to-end

## Must Have (Every Project)

- Lefthook with pre-commit hooks (lint, format, typecheck on staged files)
- Lefthook pre-push hooks (test, build)
- Vitest configured with coverage
- GitHub Actions CI (lint, typecheck, test, build on every PR)
- Branch protection on main

## Should Have (Production Apps)

- Conventional commits via commitlint
- Coverage reporting in PRs
- E2E tests for critical flows
- Security audit in CI

## The Iron Rule

NEVER lower a quality gate to pass CI. Coverage thresholds, lint rules, type
strictness, security gates are load-bearing walls. When a gate fails, write
code to meet it (more tests, better code, actual fixes). Never move the
goalpost. If the threshold is genuinely wrong, escalate to the user.

## Philosophy

This codebase will outlive you. Every shortcut becomes someone else's burden.
The patterns you establish will be copied. The corners you cut will be cut again.
Quality gates exist to fight entropy.
