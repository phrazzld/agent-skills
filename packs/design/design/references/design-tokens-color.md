# Color System Design

## OKLCH Color Space (Recommended)

**Why OKLCH over RGB/HSL:**
- Perceptually uniform (consistent lightness across hues)
- Better for programmatic color generation
- Predictable color mixing
- Accessible contrast calculations

**Format**: `oklch(lightness chroma hue)`
- Lightness: 0 (black) to 1 (white)
- Chroma: 0 (gray) to ~0.4 (vivid)
- Hue: 0-360 degrees

## Full Color Palette

```css
@theme {
  /* Primary color palette - Blue */
  --color-primary-50: oklch(0.95 0.02 250);
  --color-primary-100: oklch(0.9 0.05 250);
  --color-primary-200: oklch(0.8 0.1 250);
  --color-primary-300: oklch(0.7 0.15 250);
  --color-primary-400: oklch(0.65 0.18 250);
  --color-primary-500: oklch(0.6 0.2 250);    /* Base */
  --color-primary-600: oklch(0.5 0.2 250);
  --color-primary-700: oklch(0.4 0.18 250);
  --color-primary-800: oklch(0.3 0.15 250);
  --color-primary-900: oklch(0.2 0.1 250);

  /* Semantic aliases */
  --color-primary: var(--color-primary-500);
  --color-primary-hover: var(--color-primary-600);
  --color-primary-active: var(--color-primary-700);
}
```

## Semantic Color System

```css
@theme {
  /* Brand hue - single source of truth */
  --brand-hue: 250;  /* Extract from your primary color */

  /* Base palette */
  --color-brand-blue: oklch(0.6 0.2 250);
  --color-brand-purple: oklch(0.65 0.25 290);
  --color-brand-green: oklch(0.7 0.2 140);

  /* Semantic mappings */
  --color-primary: var(--color-brand-blue);
  --color-secondary: var(--color-brand-purple);
  --color-accent: var(--color-brand-green);

  /* State colors (distinct hues for clarity) */
  --color-success: oklch(0.65 0.18 140);  /* Green */
  --color-warning: oklch(0.7 0.2 80);     /* Yellow */
  --color-error: oklch(0.6 0.22 20);      /* Red */
  --color-info: oklch(0.65 0.2 230);      /* Blue */
}
```

## Brand-Tinted Neutrals

**Why?** Pure grays (`oklch(x 0 0)`) feel generic. Adding imperceptible brand tint (chroma 0.005-0.02) creates cohesive "feeling" without visible color.

```css
@theme {
  --brand-hue: 250;

  /* Surface colors - brand-tinted */
  --color-background: oklch(0.995 0.005 var(--brand-hue));
  --color-foreground: oklch(0.15 0.02 var(--brand-hue));
  --color-surface: oklch(0.98 0.008 var(--brand-hue));
  --color-surface-hover: oklch(0.96 0.01 var(--brand-hue));
  --color-muted: oklch(0.94 0.01 var(--brand-hue));

  /* Border colors - brand-tinted */
  --color-border: oklch(0.88 0.015 var(--brand-hue));
  --color-border-hover: oklch(0.8 0.02 var(--brand-hue));
  --color-border-focus: var(--color-primary);

  /* Text colors - brand-tinted */
  --color-text-primary: var(--color-foreground);
  --color-text-secondary: oklch(0.45 0.015 var(--brand-hue));
  --color-text-muted: oklch(0.55 0.01 var(--brand-hue));
  --color-text-disabled: oklch(0.65 0.008 var(--brand-hue));
}
```
