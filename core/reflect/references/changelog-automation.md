# Changelog Automation

Two proven approaches to automated versioning.

## semantic-release (Recommended for Web Apps)
Commit-based, fully automated. Every merge to main deploys and releases.

## Changesets (Best for npm Monorepos)
PR-based with explicit change declarations. More control, less automation.

## When to Use What
| Scenario | Tool |
|----------|------|
| Web app (every merge is a release) | semantic-release |
| Publishing npm packages | Either |
| Monorepo with multiple packages | Changesets |
| Maximum automation | semantic-release |
| Explicit release control | Changesets |

## Best Practices
- Choose one approach, not both
- Enforce conventional commits (commitlint)
- Automate with GitHub Actions
- Generate user-friendly notes (LLM synthesis)
- Tag releases in git
- Provide public changelog page
