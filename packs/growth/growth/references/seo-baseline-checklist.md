# SEO Baseline Checklist

Quick reference for essential SEO checks.

## The 5 Must-Haves

### 1. Title Tag
- [ ] Exists
- [ ] 50-60 characters
- [ ] Contains primary keyword
- [ ] Unique per page
- [ ] Brand name included

**Formula**: `[Keyword] - [Brand] | [Benefit]`

### 2. Meta Description
- [ ] Exists
- [ ] 150-160 characters
- [ ] Contains primary keyword
- [ ] Compelling (drives clicks)
- [ ] Unique per page

**Formula**: `[What it does] + [Key benefit] + [CTA]`

### 3. OG Image
- [ ] og:image exists
- [ ] 1200x630px (or 2:1 ratio)
- [ ] Shows product/brand clearly
- [ ] Text readable if included
- [ ] og:image:width and og:image:height set

### 4. Sitemap
- [ ] Exists at /sitemap.xml
- [ ] Valid XML format
- [ ] Contains all important pages
- [ ] Referenced in robots.txt
- [ ] Submitted to Search Console

### 5. robots.txt
- [ ] Exists at /robots.txt
- [ ] Doesn't block important pages
- [ ] References sitemap
- [ ] Allows search engine crawlers

## Copy-Paste Templates

### Minimal HTML Head
```html
<head>
  <title>Primary Keyword - Brand Name</title>
  <meta name="description" content="Compelling description under 160 chars." />

  <!-- OG Tags -->
  <meta property="og:title" content="Primary Keyword - Brand Name" />
  <meta property="og:description" content="Compelling description." />
  <meta property="og:image" content="https://example.com/og.png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:url" content="https://example.com" />
  <meta property="og:type" content="website" />

  <!-- Twitter Cards -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="Primary Keyword - Brand Name" />
  <meta name="twitter:description" content="Compelling description." />
  <meta name="twitter:image" content="https://example.com/og.png" />
</head>
```

### Minimal robots.txt
```
User-agent: *
Allow: /

Sitemap: https://example.com/sitemap.xml
```

### Next.js Sitemap Setup
```bash
pnpm add next-sitemap
```

```javascript
// next-sitemap.config.js
/** @type {import('next-sitemap').IConfig} */
module.exports = {
  siteUrl: process.env.SITE_URL || 'https://example.com',
  generateRobotsTxt: true,
  robotsTxtOptions: {
    policies: [
      { userAgent: '*', allow: '/' },
    ],
  },
}
```

```json
// package.json scripts
{
  "scripts": {
    "postbuild": "next-sitemap"
  }
}
```

## Quick Diagnostics

### Check from Terminal
```bash
# Title and meta description
curl -s "https://example.com" | grep -E '<title>|<meta name="description"'

# OG tags
curl -s "https://example.com" | grep -E 'property="og:'

# Sitemap
curl -s "https://example.com/sitemap.xml" | head -20

# robots.txt
curl -s "https://example.com/robots.txt"
```

### Check with Browser Tools
```javascript
// Run in browser console
console.log({
  title: document.title,
  description: document.querySelector('meta[name="description"]')?.content,
  ogImage: document.querySelector('meta[property="og:image"]')?.content,
});
```

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Title too long | Shorten to 60 chars max |
| Title too generic | Add keyword + brand |
| No meta description | Add to layout/page head |
| OG image wrong size | Resize to 1200x630 |
| No sitemap | Add next-sitemap or generate manually |
| robots.txt blocks | Change `Disallow: /` to `Allow: /` |
| Not in Search Console | Add property, verify, submit sitemap |

## Priority Order

If time is limited, fix in this order:
1. **Title** - Most important for rankings
2. **Meta description** - Drives click-through
3. **Sitemap** - Helps discovery
4. **OG image** - Social sharing
5. **robots.txt** - Usually fine by default

## Tools for Testing

- **Google Rich Results Test**: https://search.google.com/test/rich-results
- **Twitter Card Validator**: https://cards-dev.twitter.com/validator
- **Facebook Sharing Debugger**: https://developers.facebook.com/tools/debug/
- **Ahrefs Free Tools**: https://ahrefs.com/free-seo-tools
