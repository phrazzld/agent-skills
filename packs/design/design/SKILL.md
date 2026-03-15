---
name: design
description: |
  Full design orchestrator: audit, explore, catalog, theme, tokens, build, QA.
  Two modes: Explore (greenfield, 6 directions) or Extend (refinement).
  Composes design tokens, aesthetic system, taste constraints, and visual QA.
  Use when designing UI systems, exploring directions, or establishing brand visuals.
---

# DESIGN

Full design orchestrator. Audit what exists, explore directions, build tokens, implement.

## Absorbed Skills

This skill consolidates: `design-exploration`, `design-catalog`, `design-sprint`,
`design-section-labs`, `design-md`, `design-audit`, `design-theme`, `design-tokens`,
`aesthetic-system`, `taste-skill`, `ui-ux-pro-max`.

Reference skills preserved verbatim in `references/`:
- `references/web-design-guidelines.md` (Vercel)
- `references/frontend-design.md` (Anthropic)
- `references/vercel-react-best-practices.md` (Vercel)
- `references/vercel-composition-patterns.md` (Vercel)

## Mode Selection

Ask the user upfront:

> **Which mode?**
> - **Explore** -- new design system, major rebrand, greenfield project (6 distinct directions)
> - **Extend** -- variations within an existing system (6 targeted refinements)
> - **Audit** -- inventory tokens, check consistency, find violations
> - **Sprint** -- full cycle: audit, catalog, pick, theme, build

---

## Phase 1: Detect Context

Check for an existing design system:
- `brand.yaml` / `brand-profile.yaml`
- `tailwind.config.ts` / `tailwind.config.js`
- `globals.css` or `app.css` (CSS `@theme` blocks, custom properties)
- Component library directories (`components/ui`, `src/components`)
- `DESIGN_MEMORY.md` (per-project decision record -- read first if present)

Output summary: **Has system / Partial / None** + what exists.

---

## Phase 2: Live Research

Research the current ecosystem -- do NOT use a hardcoded list:

```bash
gemini "Research the current state (2026) of OSS UI/UX libraries for React/Next.js.
Categorize by: component libraries, dashboard kits, animation, icon sets,
design token systems. For each: GitHub stars, npm downloads, key differentiator,
maintenance status. Surface significant new entrants."
```

If Gemini unavailable, use WebSearch with targeted queries per category.

Present findings as a ranked, annotated list. Highlight what's gained adoption,
what's declined, what combinations work well, and what's relevant to the project.

**User selects** libraries/references before proceeding.

---

## Phase 3: Visual Catalog -- 6 Full-Page Directions

Write a **self-contained HTML file** (`design-catalog.html`) with tab navigation --
6 tabs, one per direction. Each tab reveals a full-page scrollable experience.

### Each direction must include:
1. **App shell** -- nav bar with logo, links, user avatar
2. **Dashboard stats strip** -- 4 metric cards using project's data shape
3. **Primary component** -- full fidelity rendering (e.g., monitor cards with status states)
4. **Active incident/alert** -- contextual alert component
5. **Component kit** -- all button variants, badge variants, form inputs, toggle,
   typography scale, color palette swatches

### Technical requirements:
- Single HTML file, no local asset imports
- Google Fonts `<link>` (different font per direction)
- Tailwind CDN for structural utilities
- `[data-dir="dN"]` scoping -- no global resets that bleed
- Tab switcher at top (fixed, 44px)
- Uptime bars/charts generated in JS
- Reduced motion respected

### DNA variation:
Differentiate across: type voice, color temperature, surface treatment, radius,
density, personality. No two proposals share >2 axes.

**Explore mode:** 6 maximally distinct directions.
**Extend mode:** 6 targeted refinements of existing system.

```bash
open design-catalog.html
```

---

## Phase 4: Design Audit

Analyze current design system for violations, gaps, inconsistencies.

1. **Inventory tokens** -- colors, typography, spacing, shadows
2. **Check consistency** -- are tokens used consistently?
3. **Find violations** -- hardcoded values, magic numbers
4. **Assess accessibility** -- WCAG compliance, color contrast, focus states, touch targets
5. **Report debt** -- accumulated design debt

Output:
```markdown
## Design Audit: [Project Name]

### Token Inventory
- Colors: [count] defined, [violations] hardcoded
- Typography: [count] scales, [violations] magic sizes
- Spacing: [count] values, [violations] arbitrary

### Consistency Score: [X]/100
### Critical Issues
- [ ] [Issue] - [location] - [fix]
### Debt Items
- [ ] [Tech debt] - [impact] - [effort]
```

---

## Phase 5: Select + Build Tokens

User picks a direction (or hybrid). Then:

1. **Build token foundation** using Tailwind 4 `@theme` directive:

```css
@import "tailwindcss";

@theme {
  --brand-hue: 250;
  --color-primary: oklch(0.6 0.2 var(--brand-hue));
  --color-background: oklch(0.995 0.005 var(--brand-hue));
  --color-foreground: oklch(0.15 0.02 var(--brand-hue));
  --font-sans: "Custom Font", system-ui, sans-serif;
  --spacing-md: 1rem;
  --radius-md: 0.5rem;
}
```

**Token principles:**
- CSS-first: define in CSS `@theme`, not JavaScript config
- Semantic naming: `--color-primary` not `--color-blue-500`
- Brand-tinted neutrals: chroma 0.005-0.02, not pure gray
- OKLCH colors: perceptually uniform
- 8-point spacing grid
- Dark mode: same brand hue, inverted lightness

2. **Apply constraint layers:**
   - `references/frontend-design.md` aesthetic principles
   - Taste constraints (anti-slop rules, dials 8/6/4)
   - `references/web-design-guidelines.md` compliance

3. **Scaffold component library** if none exists.
4. **Codify token rules** with `/guardrail` so raw values fail at edit time.

Detailed token references:
- `references/design-tokens-color.md` -- OKLCH, semantic colors, brand-tinted neutrals
- `references/design-tokens-typography.md` -- type scale, font pairings, loading
- `references/design-tokens-spacing.md` -- 8pt grid, radius, shadows, breakpoints
- `references/design-tokens-dark-mode.md` -- system preference, manual toggle
- `references/design-tokens-components.md` -- button, input, card, animation tokens

---

## Phase 6: Theme Implementation

Update `app/globals.css` (or equivalent):
- Define all tokens in `@theme`
- Migrate hardcoded values to tokens
- Ensure dark mode support
- Update components to use `var(--color-*)` and `var(--spacing-*)`
- Add guardrails for token usage and wire them into pre-commit

Naming convention: `--category-variant-state`
```
--color-primary
--color-primary-hover
--color-text-muted
--spacing-component-gap
```

Minimum guardrails for tokenized systems:
- no raw color literals outside token/theme files (`#hex`, `rgb[a]`, `hsl[a]`, `oklch`, named colors)
- no arbitrary spacing/radius values outside token/theme files
- components consume semantic tokens, not palette literals

---

## Phase 7: Visual QA

After building tokens and components:
1. Run visual QA against affected routes
2. Check: do rendered results match the chosen direction?
3. Fix P0/P1 issues (spacing, contrast, overflow)
4. Re-screenshot to confirm
5. Iterate until visual inspection passes

Never ship design changes without seeing them rendered.

---

## Taste Constraints (Anti-Slop)

### Active Baseline
- DESIGN_VARIANCE: 8 (1=Symmetry, 10=Artsy Chaos)
- MOTION_INTENSITY: 6 (1=Static, 10=Cinematic)
- VISUAL_DENSITY: 4 (1=Art Gallery, 10=Cockpit)

Adapt dynamically based on user requests.

### Architecture Conventions
- Framework: React/Next.js, default to Server Components
- Styling: Tailwind CSS (check v3 vs v4 in package.json)
- Icons: `@phosphor-icons/react` or `@radix-ui/react-icons`
- Viewport: `min-h-[100dvh]` never `h-screen`
- Grid over Flex-Math
- Dependency verification: check package.json before importing

### Forbidden Patterns (AI Tells)
- NO Inter/Roboto/Space Grotesk as primary fonts
- NO purple gradients on white backgrounds ("Lila Ban")
- NO pure black (#000000) -- use off-black/zinc-950
- NO oversaturated accents
- NO centered-only layouts when DESIGN_VARIANCE > 4
- NO generic 3-column card layouts
- NO emojis in code/markup
- NO generic placeholder names (John Doe, Acme)
- NO Unsplash links (use picsum.photos or SVG avatars)
- NO `h-screen` for heroes (use `min-h-[100dvh]`)

### Quality Bar
Reference: Stripe, Linear, Vercel as quality exemplars.
**The Gasp Test:** Would users gasp at how stunning this is?

### Mobile Excellence
- Touch targets: 44x44px minimum
- Swipe gestures: natural, discoverable
- Bottom navigation: thumb-reachable
- Momentum scrolling: physics-based
- Test at 375px, 768px, 1024px, 1440px

---

## Section Labs (Extend Mode)

For incremental refinement preserving current identity:

Create `.design-catalogue/` with lab pages:
- Each lab: Baseline + Variant A + Variant B (same content structure)
- Design System Reference (type, palette, component states)
- Implementation Map (exact repo file paths + what to change)

Guardrails: preserve brand fonts/tokens unless the lab explicitly changes them.

---

## Stitch Integration (design-md)

For Stitch projects, analyze screens and synthesize `DESIGN.md`:
1. Extract project identity from Stitch MCP
2. Define atmosphere (mood, density, aesthetic philosophy)
3. Map color palette with descriptive names + hex codes + functional roles
4. Translate geometry and shape to physical descriptions
5. Describe depth and elevation

Output `DESIGN.md` with: Visual Theme, Color Palette, Typography, Component Stylings, Layout Principles.

---

## Design Memory

At end of each session, write/update `DESIGN_MEMORY.md`:

```markdown
## Design Memory
- Component library: [e.g., shadcn/ui + Tremor]
- Font: [e.g., Geist + Geist Mono]
- Primary: [e.g., oklch(55% 0.18 240)]
- Vetoes: [e.g., no purple gradients]
- References: [e.g., Supabase Studio (nav), Resend (typography)]
- Last updated: YYYY-MM-DD
```

Read at the start of every `/design` session.

---

## UI/UX Pro Max Reference

Comprehensive design guide with 50+ styles, 97 palettes, 57 font pairings,
99 UX guidelines, 25 chart types across 9 stacks.

### CLI Usage
```bash
# Generate design system (always start here)
python3 skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system -p "Name"

# Persist with hierarchical retrieval
python3 skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Name"

# Domain-specific searches
python3 skills/ui-ux-pro-max/scripts/search.py "<keyword>" --domain <domain>

# Stack-specific guidelines
python3 skills/ui-ux-pro-max/scripts/search.py "<keyword>" --stack html-tailwind
```

Available domains: product, style, typography, color, landing, chart, ux, react, web, prompt.
Available stacks: html-tailwind, react, nextjs, vue, svelte, swiftui, react-native, flutter, shadcn, jetpack-compose.

---

## Performance Guardrails

- Grain/noise filters on fixed, pointer-events-none pseudo-elements only
- Animate via `transform` and `opacity` only (never top/left/width/height)
- Z-index only for systemic layers (nav, modal, overlay)
- Perpetual animations memoized in isolated Client Components
- `staggerChildren` parent and children in same Client Component tree

---

## Creative Arsenal

When basic CSS isn't enough:
- **WebGL/Three.js**: living backgrounds, gradient meshes
- **GSAP**: scrolltelling, parallax (never mix with Framer Motion in same tree)
- **Framer Motion**: UI interactions, layout transitions, springs
- **CSS Art**: clip-path, pure CSS illustrations
- **Iconify**: 200k+ icons when Lucide isn't enough

Advanced patterns: parallax tilt cards, spotlight borders, glassmorphism panels,
magnetic buttons, sticky scroll stacks, horizontal scroll hijack, kinetic marquees,
text mask reveals, particle explosions, mesh gradient backgrounds.

---

## Pre-Flight Check

Before delivering:
- [ ] Mobile layout collapse guaranteed for high-variance designs
- [ ] `min-h-[100dvh]` not `h-screen` for full-height sections
- [ ] `useEffect` animations have cleanup functions
- [ ] Empty, loading, error states provided
- [ ] Cards omitted in favor of spacing where possible
- [ ] CPU-heavy animations isolated in own Client Components
- [ ] All icons from consistent set, no emojis
- [ ] Hover states don't cause layout shift
- [ ] Focus states visible for keyboard nav
- [ ] Color contrast 4.5:1 minimum

---

## Output

Session ends with:
1. `design-catalog.html` written and opened (user selects direction)
2. Token foundation implemented for chosen direction
3. Component library scaffold (if new)
4. Visual QA passed
5. `DESIGN_MEMORY.md` written with decisions and vetoes
