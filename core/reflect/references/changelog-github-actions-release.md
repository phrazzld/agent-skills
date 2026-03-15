# GitHub Actions Release Workflow

Complete workflow for semantic-release with LLM synthesis.

## .github/workflows/release.yml

```yaml
name: Release

on:
  push:
    branches: [main, master]

# Prevent concurrent releases
concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  # Job 1: Run semantic-release
  release:
    name: Release
    runs-on: ubuntu-latest
    outputs:
      new_release_published: ${{ steps.semantic.outputs.new_release_published }}
      new_release_version: ${{ steps.semantic.outputs.new_release_version }}
      new_release_notes: ${{ steps.semantic.outputs.new_release_notes }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Setup pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build

      - name: Run tests
        run: pnpm test

      - name: Semantic Release
        id: semantic
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: |
          pnpm semantic-release

  # Job 2: Synthesize user-friendly release notes
  synthesize-notes:
    name: Synthesize Release Notes
    needs: release
    if: needs.release.outputs.new_release_published == 'true'
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Synthesize Release Notes
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
          RELEASE_VERSION: ${{ needs.release.outputs.new_release_version }}
          RELEASE_NOTES: ${{ needs.release.outputs.new_release_notes }}
        run: node scripts/synthesize-release-notes.mjs

  # Optional Job 3: Notify on release
  notify:
    name: Notify
    needs: [release, synthesize-notes]
    if: needs.release.outputs.new_release_published == 'true'
    runs-on: ubuntu-latest

    steps:
      - name: Send Slack notification
        if: ${{ vars.SLACK_WEBHOOK_URL }}
        env:
          SLACK_WEBHOOK_URL: ${{ vars.SLACK_WEBHOOK_URL }}
          VERSION: ${{ needs.release.outputs.new_release_version }}
        run: |
          curl -X POST "$SLACK_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"Released v$VERSION\"}"
```

## Simpler Version (No Synthesis)

If you want releases without LLM synthesis:

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm build

      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: pnpm semantic-release
```

## Required Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GITHUB_TOKEN` | Auto-provided | Automatically available in workflows |
| `GEMINI_API_KEY` | For synthesis | Get from Google AI Studio |
| `NPM_TOKEN` | If publishing | Only if `npmPublish: true` |

## Setting Up Secrets

```bash
# Add Gemini API key
gh secret set GEMINI_API_KEY

# Add NPM token (if publishing)
gh secret set NPM_TOKEN
```

## Capturing semantic-release Outputs

To use release outputs in subsequent jobs, update your `.releaserc.js`:

```javascript
module.exports = {
  // ... other config ...
  plugins: [
    // ... other plugins ...
    ['@semantic-release/exec', {
      publishCmd: 'echo "new_release_published=true" >> $GITHUB_OUTPUT && echo "new_release_version=${nextRelease.version}" >> $GITHUB_OUTPUT'
    }],
  ],
};
```

Or use the semantic-release GitHub Action which provides outputs natively:

```yaml
- name: Semantic Release
  id: semantic
  uses: cycjimmy/semantic-release-action@v4
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Troubleshooting

**Release not triggering:**
- Check commit messages follow conventional format
- Verify `fetch-depth: 0` is set
- Check branch name matches config

**Permission denied:**
- Verify `permissions` block is present
- Check `persist-credentials: false` is set

**LLM synthesis failing:**
- Verify `GEMINI_API_KEY` secret is set
- Check synthesis script path is correct
