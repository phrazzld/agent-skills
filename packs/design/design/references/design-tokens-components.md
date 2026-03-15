# Component Tokens

## Button Tokens

```css
@theme {
  --button-height-sm: 2rem;
  --button-height-md: 2.5rem;
  --button-height-lg: 3rem;
  --button-padding-x: var(--spacing-4);
  --button-border-radius: var(--radius-md);
}
```

## Input Tokens

```css
@theme {
  --input-height: 2.5rem;
  --input-padding-x: var(--spacing-3);
  --input-border-width: 1px;
  --input-border-radius: var(--radius-md);
  --input-border-color: var(--color-border);
  --input-focus-border-color: var(--color-primary);
  --input-focus-ring-width: 2px;
  --input-focus-ring-color: oklch(from var(--color-primary) l c h / 0.2);
}
```

## Card Tokens

```css
@theme {
  --card-padding: var(--spacing-6);
  --card-border-radius: var(--radius-lg);
  --card-border-color: var(--color-border);
  --card-shadow: var(--shadow-sm);
  --card-shadow-hover: var(--shadow-md);
}
```

## Animation Tokens

```css
@theme {
  /* Durations */
  --duration-instant: 0ms;
  --duration-fast: 150ms;
  --duration-base: 200ms;
  --duration-slow: 300ms;
  --duration-slower: 500ms;

  /* Easing functions */
  --ease-linear: linear;
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);

  /* Combined transitions */
  --transition-fast: var(--duration-fast) var(--ease-out);
  --transition-base: var(--duration-base) var(--ease-in-out);
  --transition-slow: var(--duration-slow) var(--ease-in-out);
}
```

## WebGL & Shader Integration

When using Three.js or GLSL shaders, export tokens in formats shaders can consume:

```css
@theme {
  /* Shader-compatible color format (RGB normalized 0-1) */
  --color-primary-rgb: 0.376 0.510 0.965;
  --color-accent-rgb: 0.878 0.420 0.420;

  /* Animation timing for GSAP/Lottie sync */
  --duration-stagger: 50ms;
  --duration-reveal: 600ms;
  --duration-scroll: 1000ms;

  /* Spring physics (for Framer Motion / GSAP) */
  --spring-stiffness: 300;
  --spring-damping: 30;
  --spring-mass: 1;
}
```

**Accessing tokens in JavaScript for Three.js:**

```tsx
const styles = getComputedStyle(document.documentElement)
const primaryRGB = styles.getPropertyValue('--color-primary-rgb')
  .split(' ')
  .map(Number) // [0.376, 0.510, 0.965]
```
