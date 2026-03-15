# Org and Repo Baseline

## Org settings target

- Actions: allow all; SHA pinning not required.
- New-repo security defaults: on for dependency graph, Dependabot alerts/updates,
  secret scanning, push protection.
- Org ruleset for `~DEFAULT_BRANCH` active for all repos:
  - block non-fast-forward
  - block deletions
  - PR required
  - required approvals: `0`
  - required conversation resolution: `true`

## Audit commands

```bash
ORG=your-org
gh api "/orgs/$ORG"
gh api "/orgs/$ORG/rulesets"
gh api "/orgs/$ORG/actions/permissions"
gh api "/orgs/$ORG/actions/permissions/workflow"
```

## Repo branch-protection audit

```bash
ORG=your-org
for REPO in $(gh repo list "$ORG" --limit 300 --json name -q '.[].name'); do
  BRANCH=$(gh api "/repos/$ORG/$REPO" --jq '.default_branch')
  gh api "/repos/$ORG/$REPO/branches/$BRANCH/protection" >/tmp/prot.json 2>/dev/null || { echo "$REPO no-protection"; continue; }
  CHECKS=$(jq '.required_status_checks.contexts | length' /tmp/prot.json)
  APPROVALS=$(jq '.required_pull_request_reviews.required_approving_review_count // 0' /tmp/prot.json)
  CONV=$(jq '.required_conversation_resolution.enabled' /tmp/prot.json)
  echo "$REPO checks=$CHECKS approvals=$APPROVALS conversation=$CONV"
done
```

## Required remediations

1. Any repo without branch protection: apply protection immediately.
2. Any protected repo with `0` required checks: add at least one required CI check.
3. Any repo with conversation resolution disabled: enable it.
4. Keep required approvals at `0` unless policy changes.
