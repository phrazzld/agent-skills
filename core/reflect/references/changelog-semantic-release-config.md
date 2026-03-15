# semantic-release Configuration

Full configuration for semantic-release with all plugins.

## .releaserc.js

```javascript
/**
 * semantic-release configuration
 *
 * Plugins run in order:
 * 1. commit-analyzer - Determine version bump from commits
 * 2. release-notes-generator - Generate changelog content
 * 3. changelog - Write to CHANGELOG.md
 * 4. npm - Update package.json version (and optionally publish)
 * 5. git - Commit changes and create tag
 * 6. github - Create GitHub Release
 */
module.exports = {
  branches: [
    'main',
    'master',
    // Support release branches if needed
    { name: 'beta', prerelease: true },
    { name: 'alpha', prerelease: true },
  ],

  plugins: [
    // Analyze commits to determine version bump
    ['@semantic-release/commit-analyzer', {
      preset: 'conventionalcommits',
      releaseRules: [
        // Default rules from conventional-changelog
        { type: 'feat', release: 'minor' },
        { type: 'fix', release: 'patch' },
        { type: 'perf', release: 'patch' },
        // Additional rules
        { type: 'refactor', release: 'patch' },
        { type: 'docs', release: false },
        { type: 'style', release: false },
        { type: 'chore', release: false },
        { type: 'test', release: false },
        { type: 'build', release: false },
        { type: 'ci', release: false },
        // Breaking changes always trigger major
        { breaking: true, release: 'major' },
      ],
    }],

    // Generate release notes from commits
    ['@semantic-release/release-notes-generator', {
      preset: 'conventionalcommits',
      presetConfig: {
        types: [
          { type: 'feat', section: 'Features' },
          { type: 'fix', section: 'Bug Fixes' },
          { type: 'perf', section: 'Performance' },
          { type: 'refactor', section: 'Refactoring' },
          { type: 'docs', section: 'Documentation', hidden: true },
          { type: 'style', section: 'Styling', hidden: true },
          { type: 'chore', section: 'Maintenance', hidden: true },
          { type: 'test', section: 'Testing', hidden: true },
          { type: 'build', section: 'Build', hidden: true },
          { type: 'ci', section: 'CI/CD', hidden: true },
        ],
      },
    }],

    // Write changelog to file
    ['@semantic-release/changelog', {
      changelogFile: 'CHANGELOG.md',
      changelogTitle: '# Changelog\n\nAll notable changes to this project will be documented in this file.',
    }],

    // Update package.json version
    // Remove this plugin if not publishing to npm
    ['@semantic-release/npm', {
      npmPublish: false, // Set to true if publishing to npm
    }],

    // Commit changelog and package.json changes
    ['@semantic-release/git', {
      assets: ['CHANGELOG.md', 'package.json'],
      message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
    }],

    // Create GitHub Release
    '@semantic-release/github',
  ],
};
```

## Alternative: JSON Configuration

If you prefer JSON, use `.releaserc.json`:

```json
{
  "branches": ["main", "master"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/changelog", {
      "changelogFile": "CHANGELOG.md"
    }],
    ["@semantic-release/npm", {
      "npmPublish": false
    }],
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md", "package.json"],
      "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    "@semantic-release/github"
  ]
}
```

## Minimal Configuration

If you want the simplest setup:

```javascript
// .releaserc.js
module.exports = {
  branches: ['main'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
    '@semantic-release/npm',
    '@semantic-release/git',
    '@semantic-release/github',
  ],
};
```

## Package.json Scripts

Add these scripts:

```json
{
  "scripts": {
    "release": "semantic-release",
    "release:dry-run": "semantic-release --dry-run"
  }
}
```

## Required Dependencies

```bash
pnpm add -D semantic-release \
  @semantic-release/changelog \
  @semantic-release/git \
  @semantic-release/github \
  conventional-changelog-conventionalcommits
```

## Notes

- `[skip ci]` in commit message prevents infinite release loops
- `fetch-depth: 0` required in GitHub Actions for commit history
- `persist-credentials: false` needed for GitHub token to work
- Don't use with Changesets - choose one or the other
