# Spacing System

## 8-Point Grid (Industry Standard)

```css
@theme {
  --spacing-0: 0;
  --spacing-0\.5: 0.125rem;   /* 2px */
  --spacing-1: 0.25rem;       /* 4px */
  --spacing-2: 0.5rem;        /* 8px */
  --spacing-3: 0.75rem;       /* 12px */
  --spacing-4: 1rem;          /* 16px */
  --spacing-5: 1.25rem;       /* 20px */
  --spacing-6: 1.5rem;        /* 24px */
  --spacing-8: 2rem;          /* 32px */
  --spacing-10: 2.5rem;       /* 40px */
  --spacing-12: 3rem;         /* 48px */
  --spacing-16: 4rem;         /* 64px */
  --spacing-20: 5rem;         /* 80px */
  --spacing-24: 6rem;         /* 96px */
  --spacing-32: 8rem;         /* 128px */

  /* Semantic aliases */
  --spacing-xs: var(--spacing-1);
  --spacing-sm: var(--spacing-2);
  --spacing-md: var(--spacing-4);
  --spacing-lg: var(--spacing-6);
  --spacing-xl: var(--spacing-8);
  --spacing-2xl: var(--spacing-12);
  --spacing-3xl: var(--spacing-16);
}
```

## Border Radius

```css
@theme {
  --radius-sm: 0.25rem;    /* 4px */
  --radius-md: 0.5rem;     /* 8px */
  --radius-lg: 0.75rem;    /* 12px */
  --radius-xl: 1rem;       /* 16px */
  --radius-2xl: 1.5rem;    /* 24px */
  --radius-full: 9999px;
}
```

## Shadows

```css
@theme {
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}
```

## Responsive Breakpoints

```css
@theme {
  --screen-sm: 640px;
  --screen-md: 768px;
  --screen-lg: 1024px;
  --screen-xl: 1280px;
  --screen-2xl: 1536px;
}
```

**Usage with media queries:**

```css
.container {
  padding: var(--spacing-md);

  @media (min-width: theme(--screen-md)) {
    padding: var(--spacing-lg);
  }

  @media (min-width: theme(--screen-xl)) {
    padding: var(--spacing-2xl);
  }
}
```

## Z-Index Layers

```css
@theme {
  --z-base: 0;
  --z-dropdown: 1000;
  --z-sticky: 1100;
  --z-overlay: 1200;
  --z-modal: 1300;
  --z-popover: 1400;
  --z-tooltip: 1500;
}
```
