# Changelog Setup (Greenfield)

Complete changelog infrastructure from scratch.

## Install Dependencies
```bash
pnpm add -D semantic-release @semantic-release/changelog @semantic-release/git @semantic-release/github
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

## Configure semantic-release
Create `.releaserc.js`:
```javascript
module.exports = {
  branches: ['main', 'master'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    ['@semantic-release/changelog', { changelogFile: 'CHANGELOG.md' }],
    ['@semantic-release/git', {
      assets: ['CHANGELOG.md', 'package.json'],
      message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
    }],
    '@semantic-release/github',
  ],
};
```

## Configure commitlint
```javascript
// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert']],
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 100],
  },
};
```

## Add Lefthook Hook
```yaml
commit-msg:
  commands:
    commitlint:
      run: pnpm commitlint --edit {1}
```

## GitHub Actions Workflow
See `changelog-github-actions-release.md` in this directory.

## LLM Synthesis
Create `scripts/synthesize-release-notes.mjs` and `.release-notes-config.yml`.
Model name from env var, NOT hardcoded. Use OpenRouter for flexibility.

## Secrets
- `GITHUB_TOKEN` (automatic)
- `GEMINI_API_KEY` or `OPENROUTER_API_KEY`
- `NPM_TOKEN` (only if publishing to npm)
