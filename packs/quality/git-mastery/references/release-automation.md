# Release Automation

Versions and changelogs determined by commits, never manual.

## Semantic Versioning from Commits

| Commit Type | Version Bump |
|-------------|--------------|
| `fix:` | PATCH (1.0.0 → 1.0.1) |
| `feat:` | MINOR (1.0.0 → 1.1.0) |
| `BREAKING CHANGE:` | MAJOR (1.0.0 → 2.0.0) |

## semantic-release Setup

```bash
npm install -D semantic-release @semantic-release/changelog @semantic-release/git
```

`.releaserc.json`:
```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/git",
    "@semantic-release/github"
  ]
}
```

## GitHub Actions Workflow

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm test
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Changelog Output

Auto-generated from commits:
```markdown
## [1.2.0] - 2024-01-15

### Features
- **auth**: add OAuth2 login flow (#123)

### Bug Fixes
- **api**: handle null response in user endpoint (#124)

### BREAKING CHANGES
- **config**: rename `apiUrl` to `baseUrl`
```

## Pre-releases

```json
{
  "branches": [
    "main",
    { "name": "beta", "prerelease": true },
    { "name": "alpha", "prerelease": true }
  ]
}
```

Produces: `1.0.0-alpha.1`, `1.0.0-beta.1`, `1.0.0`
