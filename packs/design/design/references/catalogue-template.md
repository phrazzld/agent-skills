# Catalogue Template

Structure and metadata for design proposal catalogues.

## Proposal Metadata Structure

Each proposal should include:

```yaml
name: "Midnight Editorial"
slug: "midnight-editorial"
dna:
  layout: editorial
  color: dark
  typography: display-heavy
  motion: scroll-triggered
  density: spacious
  background: layered

soul: |
  A dramatic, magazine-inspired aesthetic that treats content as art.
  Deep blacks punctuated by warm accent lighting. Typography commands
  attention like headlines on a newsstand.

typography:
  headings:
    family: "Playfair Display"
    weights: [400, 700]
    source: "Google Fonts"
  body:
    family: "Source Serif 4"
    weights: [400, 600]
    source: "Google Fonts"
  mono:
    family: "JetBrains Mono"
    weights: [400]
    source: "Google Fonts"

colors:
  background: "#0a0a0a"
  foreground: "#fafafa"
  primary: "#f59e0b"
  secondary: "#78716c"
  accent: "#fbbf24"
  muted: "#1c1917"
  border: "#292524"

key_moves:
  - "Dark mode as default, not afterthought"
  - "Editorial typography hierarchy with dramatic size contrast"
  - "Warm amber accents against cool dark backgrounds"
  - "Scroll-triggered reveals for content sections"
  - "Generous whitespace creating breathing room"

preserves:
  - "Existing component structure"
  - "Navigation patterns"
  - "Form layouts"

transforms:
  - "Complete color system overhaul"
  - "Typography from system fonts to editorial pairing"
  - "Add motion language throughout"

inspiration: "NYTimes Magazine, Bloomberg Businessweek, Monocle"
```

## DNA Variety Validation

Before finalizing catalogue, verify DNA diversity:

```
Proposal Matrix:
                Layout    Color      Type        Motion     Density    Background
01-midnight     editorial dark       display     scroll     spacious   layered
02-swiss        grid-brk  light      minimal     none       compact    solid
03-warm         centered  brand-tint text-fwd    subtle     spacious   gradient
04-brutalist    asymmetric mono      display     aggressive mixed      textured
05-luxe         asymmetric gradient  expressive  orchestrated spacious layered
06-technical    centered  dark       text-fwd    subtle     compact    solid

Check: No two proposals share >2 matching axes
```

## Catalogue Index Structure

The main viewer should display:

```html
<!-- Proposal Card -->
<article class="proposal-card" data-slug="midnight-editorial">
  <div class="preview-thumbnail">
    <iframe src="proposals/01-midnight-editorial/preview.html"></iframe>
  </div>
  <div class="proposal-meta">
    <h2>Midnight Editorial</h2>
    <p class="soul">A dramatic, magazine-inspired aesthetic...</p>
    <div class="dna-badges">
      <span class="dna-badge">editorial</span>
      <span class="dna-badge">dark</span>
      <span class="dna-badge">display-heavy</span>
    </div>
  </div>
</article>
```

## Preview Page Structure

Each proposal preview demonstrates:

1. **Hero Section** - Full-width, sets the tone
2. **Typography Scale** - h1 through body text
3. **Color Palette** - Visual swatches with hex codes
4. **Component Samples**:
   - Primary button (default, hover, active)
   - Secondary button
   - Card component
   - Form input
5. **DNA Badge** - Shows the 6-axis code

## Comparison Mode

The viewer should support side-by-side comparison:

```html
<div class="compare-mode">
  <div class="compare-left">
    <iframe src="proposals/01-midnight-editorial/preview.html"></iframe>
  </div>
  <div class="compare-right">
    <iframe src="proposals/03-warm-workshop/preview.html"></iframe>
  </div>
</div>
```

## Required Font Loading

Each proposal must load its fonts properly:

```html
<head>
  <!-- Google Fonts example -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Source+Serif+4:wght@400;600&display=swap" rel="stylesheet">
</head>
```

## Thumbnail Generation

For the grid view, use CSS scaling:

```css
.preview-thumbnail {
  width: 300px;
  height: 200px;
  overflow: hidden;
  border-radius: 8px;
}

.preview-thumbnail iframe {
  width: 1200px;
  height: 800px;
  transform: scale(0.25);
  transform-origin: top left;
  pointer-events: none;
  border: none;
}
```
