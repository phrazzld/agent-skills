# Branch Protection & Coverage Reporting

## Branch Protection Rules

Configure in GitHub Settings → Branches → Branch protection rules for `main`:

### Required Settings
- Require a pull request before merging
- Require approvals: 1
- Require status checks to pass before merging
  - Select: `Quality Checks`, `Test`, `Build`, `E2E Tests`
- Require branches to be up to date before merging
- Require conversation resolution before merging
- Do not allow bypassing the above settings

### Recommended Settings
- Require signed commits
- Require linear history
- Lock branch (for production branches)

## Codecov Setup

1. Sign up at codecov.io with GitHub
2. Add repository
3. Add `CODECOV_TOKEN` to GitHub secrets
4. Add codecov.yml:

```yaml
# codecov.yml
coverage:
  status:
    project:
      default:
        target: auto     # Maintain current coverage
        threshold: 5%    # Allow 5% decrease
        if_ci_failed: error

    patch:
      default:
        target: 70%      # New code should be well-tested
        if_ci_failed: error

comment:
  layout: "reach, diff, flags, files"
  behavior: default
  require_changes: false

ignore:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/*.config.ts"
  - "**/*.d.ts"
  - "**/test/**"
  - "**/__tests__/**"
```

## GitHub Actions Integration

```yaml
- uses: codecov/codecov-action@v4
  with:
    files: ./coverage/coverage-final.json
    fail_ci_if_error: false
```
