# Changelog Page (Next.js)

Public `/changelog` route with RSS feed.

## Components
1. **GitHub API Client** (`lib/github-releases.ts`) - Fetch releases, group by minor version
2. **Page** (`app/changelog/page.tsx`) - Display grouped releases
3. **RSS Feed** (`app/changelog.xml/route.ts`) - XML feed of releases

## Key Requirements
- Fetches from GitHub Releases API
- Groups by minor version (v1.2.x together)
- No auth required (public page)
- 5-minute cache (`next: { revalidate: 300 }`)
- RSS feed support

## Environment Variables
```bash
GITHUB_REPO=owner/repo
GITHUB_TOKEN=ghp_xxx  # optional, for rate limits
NEXT_PUBLIC_APP_NAME=MyApp
NEXT_PUBLIC_SITE_URL=https://myapp.com
```

## Page Must Be Public
Do not wrap in Clerk `<SignedIn>`, middleware auth, or session requirements.

## Discoverability
- Footer link to `/changelog`
- Settings page "View changelog" link
- Version display in settings
