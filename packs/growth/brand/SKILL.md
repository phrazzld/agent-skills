---
name: brand
description: |
  Full brand-as-code pipeline: discovery, identity, tokens, assets, logo, video.
  Creates brand.yaml, compiles to CSS/Tailwind/TypeScript tokens, generates
  OG cards, social images, logos, and branded video. One command from zero to
  full brand system. Use when establishing or updating brand identity.
disable-model-invocation: true
---

# BRAND

Full brand-as-code pipeline. Discovery to assets in one flow.

## Absorbed Skills

This skill consolidates: `brand-init`, `brand-builder`, `brand-compile`,
`brand-assets`, `brand-logo`, `brand-video`, `brand-pipeline`, `og-card`.

---

## Quick Start

```bash
# Full pipeline: identity -> tokens -> assets
/brand [project-name]

# Just compile tokens from existing brand.yaml
/brand --compile [--format css|tailwind|ts|all] [--out dir]

# Generate specific assets
/brand --assets <template> --title "..." --out file.png

# Generate logo
/brand --logo [style: geometric|minimal|abstract]

# Generate video
/brand --video [type: demo|feature|launch]
```

---

## Phase 1: Discovery (Interactive)

### Auto-gather context
```bash
cat package.json 2>/dev/null | jq '{name, description, keywords}'
cat README.md 2>/dev/null | head -100
git log --oneline -10
```

### Ask via AskUserQuestion

1. **Identity**: product name, domain, tagline, category
2. **Audience**: primary user, segments, pain points
3. **Voice**: tone (casual/professional/technical/playful), personality, things to avoid
4. **Content**: topics, mix (product vs valuable), posting frequency

---

## Phase 2: Visual Direction (Interactive)

5. **Brand hue** -- present 4 options based on category:
   - SaaS/tech: blue (250), purple (280)
   - Health/fitness: green (140), teal (170)
   - Finance: navy (220), emerald (160)
   - Creative: orange (30), magenta (330)
   - Custom hue (0-360)

6. **Typography**: display + sans + mono font stacks
   - Modern: Inter/Geist
   - Classical: Playfair Display + serif
   - Technical: JetBrains Mono focused
   - Custom

7. **Color overrides**: accept specific hex colors, convert to OKLCH.

---

## Phase 3: Generate brand.yaml

Build the complete YAML with all sections:
- `version: "1"`
- `identity` (name, domain, tagline, category, logo paths)
- `audience` (primary, demographics, pain_points)
- `voice` (tone, personality, avoid)
- `palette` (brand_hue, primary/secondary/accent in OKLCH + hex, light/dark backgrounds)
- `typography` (display, sans, mono font stacks)
- `spacing`, `radii`, `elevation`, `motion` (sensible defaults)
- `content` (mix, topics, hashtags, posting_frequency)
- `inspirations`
- `meta` (generation timestamp)

### Migration from legacy format
```bash
# If brand-profile.yaml exists, offer migration
node ~/Development/brand-kit/dist/src/cli.js migrate \
  --profile brand-profile.yaml \
  $([ -f design-tokens.json ] && echo "--tokens design-tokens.json") \
  --out brand.yaml
```

---

## Phase 4: Validate + Compile

```bash
node ~/Development/brand-kit/dist/src/cli.js validate brand.yaml
node ~/Development/brand-kit/dist/src/cli.js compile --out ./src/styles
```

Produces:
- `tokens.css` -- CSS custom properties (`:root` + `.dark`)
- `theme.css` -- Tailwind 4 `@theme inline` with OKLCH values
- `tokens.ts` -- TypeScript const export for Satori/Remotion

### Format selection
- `--format css` -- only CSS custom properties
- `--format tailwind` -- only Tailwind 4 theme
- `--format ts` -- only TypeScript tokens
- `--format all` -- all three (default)

### Integration
```css
/* Tailwind 4 (recommended) */
@import "tailwindcss";
@import "./theme.css";
```

```typescript
/* TypeScript (Satori/Remotion) */
import { brand } from "./tokens.js";
```

---

## Phase 5: Generate Assets

### Available templates

| Template | Use Case |
|----------|----------|
| `og-blog` | Blog post OG cards |
| `og-product` | Product announcement cards |
| `og-changelog` | Version release cards |
| `og-default` | Generic fallback OG card |
| `social-announce` | Social media announcements |
| `social-quote` | Quote cards for social |
| `blog-header` | Blog post hero images |
| `launch-hero` | Product launch hero images |

### Generation
```bash
node ~/Development/brand-kit/dist/src/cli.js render og-default \
  --title "[Brand Name]" --subtitle "[Tagline]" --out ./public/og.png
```

### Context-aware inference
When invoked without arguments:
- Recent version tag in git -> `og-changelog`
- Blog post draft exists -> `og-blog` + `blog-header`
- Product Hunt kit exists -> `launch-hero` + `social-announce`
- Otherwise -> `og-default`

### Legacy Satori path (og-card)
For projects not yet on brand.yaml:
1. Read `brand-profile.yaml` for colors/fonts
2. Select template (blog, product, changelog, comparison)
3. Render via `skills/og-card/scripts/generate-card.ts`
4. Emit 1200x630 PNG

---

## Phase 6: Logo Generation

### Phase 6a: Icon-library-first path (preferred)

Check if project uses an icon library (Phosphor, Lucide, Heroicons, Tabler):
1. Scan `package.json` for icon libraries
2. If found: search for domain-relevant icons (e.g. "Heartbeat" for monitoring)
3. Present candidates with fill/bold weights — fill works best at 16px favicon
4. If user picks one:
   - Extract SVG path from package (`dist/defs/` or core assets)
   - Color with brand palette primary
   - Create `public/logo.svg` (256 viewBox, brand-colored fill)
   - Generate all favicon sizes via sharp:
```javascript
const sizes = [16, 32, 180, 192, 512];
for (const size of sizes) {
  await sharp(svg, { density: 300 }).resize(size).png().toFile(`favicon-${size}.png`);
}
```
   - Generate `favicon.ico` (ICO header + 32px PNG)
   - Skip AI generation entirely

### Phase 6b: AI generation (fallback)

When icon-library path is declined or no library exists:

1. **QuiverAI** (quiver.ai) — vector-native SVG generation
   - Free tier: 20 SVGs/week
   - API: `POST https://api.quiver.ai/v1/generate`
   - Prompt constraints: simple icon, max 3 shapes, brand colors only
2. **Constrained prompt fallback**: Generate 4 SVG candidates
   - Viewbox: 64x64, max 3 shapes (geometric primitives)
   - Colors: only primary + foreground hex
   - No text, no gradients, no filters, no embedded images
3. **Critique loop**: vision model scores distinctiveness, scalability, brand alignment
4. **User approval**: present top 2 candidates
5. **Optimize + variants**:
```bash
npx svgo logo.svg -o logo-optimized.svg
```
6. **Update brand.yaml** with logo paths

### Wordmark generation
- Use project's display font (from brand.yaml typography.display)
- Nano Banana 2 for high-quality text rendering if needed

Output:
```
assets/
  logo.svg, logo-mark.svg
  favicon-{16,32,180,192,512}.png
  favicon.ico
```

---

## Phase 7: Branded Video

Chain brand tokens, voiceover, and Remotion rendering.

### Prerequisites
- brand.yaml + compiled tokens
- Remotion installed

### Process
1. Generate or accept video script
2. Generate voiceover audio (ElevenLabs)
3. Import brand tokens into Remotion compositions
4. Compose scenes: TitleScene -> FeatureScene[] -> EndCard
5. Render:
```bash
npx remotion render src/video/BrandVideo.tsx brand-video.mp4 \
  --props '{"brandTokens": "./brand-output/tokens.ts"}'
```

### Video types

| Type | Scenes | Duration |
|------|--------|----------|
| `demo` | Title -> Screen capture -> Features -> End | 60-90s |
| `feature` | Title -> Feature deep-dive -> End | 30-45s |
| `launch` | Title -> Problem -> Solution -> Features -> CTA | 45-60s |

---

## Re-running

If brand.yaml exists:
1. Load existing brand
2. Ask which sections to update
3. Preserve unchanged sections
4. Recompile tokens

---

## Output

Full pipeline produces:
- `brand.yaml` in project root
- Compiled tokens in output directory
- Preview image `brand-preview.png`
- Logo + favicon variants (if requested)
- OG cards and social images (if requested)
- Video content (if requested)
