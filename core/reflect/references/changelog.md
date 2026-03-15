# /changelog

Automated changelogs, semantic versioning, and user-friendly release notes. Audit, fix, verify -- every time.

## What This Does

Examines your release infrastructure, identifies every gap, implements fixes, and verifies the full pipeline works. No partial modes. Every run does the full cycle.

## Process

### 1. Audit

Check what exists and what's broken:

```bash
# Configuration
[ -f ".releaserc.js" ] || [ -f ".releaserc.json" ] && echo "semantic-release" || echo "MISSING"
[ -f "commitlint.config.js" ] || [ -f "commitlint.config.cjs" ] && echo "commitlint" || echo "MISSING"
grep -q "commit-msg" lefthook.yml 2>/dev/null && echo "commit-msg hook" || echo "MISSING"

# GitHub Actions
[ -f ".github/workflows/release.yml" ] && echo "release workflow" || echo "MISSING"
grep -q "semantic-release" .github/workflows/release.yml 2>/dev/null && echo "runs semantic-release" || echo "MISSING"

# Public page
ls app/changelog/page.tsx src/app/changelog/page.tsx 2>/dev/null && echo "changelog page" || echo "MISSING"
```

### 2. Plan

Every project needs:
- **Must have:** semantic-release, commitlint, Lefthook hook, GitHub Actions workflow
- **Should have:** LLM synthesis, public `/changelog` page, RSS feed

### 3. Execute

Fix everything. Install dependencies, create configs, set up workflows.
See `references/changelog-setup.md` for greenfield installation.
See `references/changelog-automation.md` for semantic-release vs Changesets comparison.

**Making changelog discoverable (CRITICAL):**
- Footer link to `/changelog`
- Settings link to "View changelog"
- Version display in settings
- RSS feed mention on page

### 4. Verify

- commitlint rejects bad messages
- Commit hook blocks non-conventional commits
- Push to main triggers release workflow
- GitHub Release created with LLM-synthesized notes
- Public page displays releases

## The Release Flow

```
Commit with conventional format (enforced by Lefthook)
  -> Push/merge to main
  -> GitHub Actions runs semantic-release
  -> Version bumped, CHANGELOG.md updated, GitHub Release created
  -> LLM synthesis transforms changelog -> user notes
  -> Public /changelog page displays latest
```

## References

| Reference | Content |
|-----------|---------|
| `references/changelog-setup.md` | Greenfield installation (dependencies, configs, workflows) |
| `references/changelog-audit.md` | Deep audit process and report format |
| `references/changelog-automation.md` | semantic-release vs Changesets comparison |
| `references/changelog-page.md` | Public changelog page scaffold (Next.js) |
| `references/changelog-github-actions-release.md` | GitHub Actions release workflow |
| `references/changelog-semantic-release-config.md` | semantic-release configuration |
| `references/changelog-llm-synthesis-script.md` | LLM synthesis script for release notes |
