# OG Image Patterns

## Dimensions

**Required:** 1200×630 pixels (1.91:1 ratio)

This is the standard for Twitter, LinkedIn, Facebook, and most platforms.

## Dynamic OG Images with Next.js

### Basic Setup

```typescript
// app/api/og/route.tsx
import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);

  // Parse parameters
  const title = searchParams.get('title') ?? 'Default Title';

  return new ImageResponse(
    (
      <div style={{ /* your design */ }}>
        {title}
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
```

### Using Custom Fonts

```typescript
import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET(request: Request) {
  // Load font
  const font = await fetch(
    new URL('./Inter-Bold.ttf', import.meta.url)
  ).then((res) => res.arrayBuffer());

  return new ImageResponse(
    (
      <div style={{ fontFamily: 'Inter' }}>
        Your content
      </div>
    ),
    {
      width: 1200,
      height: 630,
      fonts: [
        {
          name: 'Inter',
          data: font,
          style: 'normal',
          weight: 700,
        },
      ],
    }
  );
}
```

### With Background Image

```typescript
export async function GET(request: Request) {
  const backgroundUrl = `${process.env.NEXT_PUBLIC_APP_URL}/og-background.png`;

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          backgroundImage: `url(${backgroundUrl})`,
          backgroundSize: 'cover',
        }}
      >
        <div style={{ /* overlay content */ }}>
          Title here
        </div>
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
```

## Common Layouts

### Centered Title + Description

```typescript
<div style={{
  height: '100%',
  width: '100%',
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  backgroundColor: '#000',
  padding: 80,
}}>
  <div style={{
    fontSize: 64,
    fontWeight: 'bold',
    color: '#fff',
    textAlign: 'center',
    marginBottom: 24,
  }}>
    {title}
  </div>
  <div style={{
    fontSize: 32,
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'center',
  }}>
    {description}
  </div>
</div>
```

### Left Content + Right Image

```typescript
<div style={{
  height: '100%',
  width: '100%',
  display: 'flex',
  backgroundColor: '#fff',
}}>
  <div style={{
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    padding: 60,
  }}>
    <div style={{ fontSize: 48, fontWeight: 'bold' }}>{title}</div>
    <div style={{ fontSize: 24, marginTop: 16, opacity: 0.7 }}>{description}</div>
  </div>
  <div style={{
    width: 500,
    backgroundImage: `url(${imageUrl})`,
    backgroundSize: 'cover',
  }} />
</div>
```

### Blog Post Style

```typescript
<div style={{
  height: '100%',
  width: '100%',
  display: 'flex',
  flexDirection: 'column',
  backgroundColor: '#1a1a1a',
  padding: 60,
}}>
  {/* Category tag */}
  <div style={{
    fontSize: 20,
    color: '#3b82f6',
    textTransform: 'uppercase',
    letterSpacing: 2,
  }}>
    {category}
  </div>

  {/* Title */}
  <div style={{
    fontSize: 56,
    fontWeight: 'bold',
    color: '#fff',
    marginTop: 24,
    lineHeight: 1.2,
  }}>
    {title}
  </div>

  {/* Author + date */}
  <div style={{
    marginTop: 'auto',
    display: 'flex',
    alignItems: 'center',
    gap: 16,
  }}>
    <img src={authorAvatar} style={{ width: 48, height: 48, borderRadius: 24 }} />
    <div style={{ color: '#888' }}>{author} · {date}</div>
  </div>
</div>
```

## Using in Metadata

### Inheritance (DRY pattern)

Next.js automatically inherits `title` and `description` from top-level metadata into `openGraph` and `twitter` objects. Don't duplicate:

```typescript
// ❌ REDUNDANT - duplicates title/description
export const metadata: Metadata = {
  title: "My App",
  description: "App description",
  openGraph: {
    title: "My App",           // Redundant
    description: "App description", // Redundant
    siteName: "My App",
  },
};

// ✅ CLEAN - let Next.js inherit
export const metadata: Metadata = {
  title: "My App",
  description: "App description",
  openGraph: {
    type: "website",
    siteName: "My App",
    url: "https://myapp.com",
  },
  twitter: {
    card: "summary_large_image",
  },
};
```

### Dynamic metadata

```typescript
// app/blog/[slug]/page.tsx
export async function generateMetadata({ params }): Promise<Metadata> {
  const post = await getPost(params.slug);

  const ogImageUrl = new URL('/api/og', process.env.NEXT_PUBLIC_APP_URL);
  ogImageUrl.searchParams.set('title', post.title);
  ogImageUrl.searchParams.set('description', post.excerpt);
  ogImageUrl.searchParams.set('author', post.author);

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      images: [ogImageUrl.toString()],
    },
    twitter: {
      card: 'summary_large_image',
      images: [ogImageUrl.toString()],
    },
  };
}
```

## Testing

### Local Testing

```bash
# Start dev server
pnpm dev

# Test the endpoint directly
open "http://localhost:3000/api/og?title=Test%20Title"
```

### Production Testing

```bash
# OpenGraph validator
open "https://www.opengraph.xyz/url/https://yoursite.com/page"

# Twitter Card validator
open "https://cards-dev.twitter.com/validator"

# LinkedIn Post Inspector
open "https://www.linkedin.com/post-inspector/"

# Facebook Sharing Debugger
open "https://developers.facebook.com/tools/debug/"
```

## Common Issues

### Image not updating on social platforms

Social platforms cache OG images. To force refresh:
1. Use the platform's debug tool (links above)
2. Click "Scrape Again" or similar
3. Or add a cache-busting query param: `?v=2`

### Image looks blurry

Ensure you're outputting at 1200×630. Some platforms downscale, but never upscale.

### Text getting cut off

Keep titles under 60 characters. Add ellipsis for longer content:

```typescript
const truncatedTitle = title.length > 60
  ? title.slice(0, 57) + '...'
  : title;
```

### Emoji not rendering

Edge runtime has limited emoji support. Either:
1. Use an emoji font (Noto Color Emoji)
2. Replace emoji with images
3. Avoid emoji in OG images

### Font format error: "Unsupported OpenType signature wOF2"

**Satori (which powers ImageResponse) does NOT support woff2 fonts.** Use TTF instead.

```typescript
// ❌ WRONG - woff2 causes "Unsupported OpenType signature wOF2"
const fontData = await fetch(
  "https://fonts.gstatic.com/s/inter/v20/...woff2"
).then(res => res.arrayBuffer());

// ✅ CORRECT - use TTF format
const fontData = await fetch(
  "https://fonts.gstatic.com/s/inter/v20/...ttf"
).then(res => res.arrayBuffer());
```

To get TTF URLs from Google Fonts:
```bash
# Don't include woff2 user-agent - gets TTF by default
curl -s "https://fonts.googleapis.com/css?family=Inter:wght@500" | grep -o "https://[^)]*"
```

### Google Fonts URLs return 404

Google Fonts URLs are version-specific (v14, v16, v20, etc.). Hardcoded URLs break when versions change.

**Solution:** Fetch fresh URLs from the Google Fonts CSS API rather than hardcoding:
```bash
curl -s "https://fonts.googleapis.com/css?family=Bebas+Neue" | grep -o "https://[^)]*"
```

Or pin to a known working version and add a comment noting it may need updating.
