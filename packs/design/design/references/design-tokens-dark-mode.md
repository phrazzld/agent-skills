# Dark Mode

## System Preference (Automatic)

**Keep brand hue in dark mode** - just invert lightness:

```css
@theme {
  --brand-hue: 250;

  /* Light mode (default) */
  --color-background: oklch(0.995 0.005 var(--brand-hue));
  --color-foreground: oklch(0.15 0.02 var(--brand-hue));
  --color-muted: oklch(0.94 0.01 var(--brand-hue));
  --color-border: oklch(0.88 0.015 var(--brand-hue));

  @media (prefers-color-scheme: dark) {
    /* Dark mode - same hue, inverted lightness */
    --color-background: oklch(0.12 0.015 var(--brand-hue));
    --color-foreground: oklch(0.95 0.01 var(--brand-hue));
    --color-muted: oklch(0.22 0.02 var(--brand-hue));
    --color-border: oklch(0.28 0.025 var(--brand-hue));
  }
}
```

## Manual Toggle (Class-Based)

```css
@theme {
  --brand-hue: 250;
  --color-background: oklch(0.995 0.005 var(--brand-hue));
  --color-foreground: oklch(0.15 0.02 var(--brand-hue));
}

.dark {
  --color-background: oklch(0.12 0.015 var(--brand-hue));
  --color-foreground: oklch(0.95 0.01 var(--brand-hue));
}
```

## Toggle Component (React)

```tsx
'use client'

import { useEffect, useState } from 'react'

export function DarkModeToggle() {
  const [isDark, setIsDark] = useState(false)

  useEffect(() => {
    const isDark = localStorage.getItem('theme') === 'dark'
    setIsDark(isDark)
    document.documentElement.classList.toggle('dark', isDark)
  }, [])

  const toggle = () => {
    const newIsDark = !isDark
    setIsDark(newIsDark)
    localStorage.setItem('theme', newIsDark ? 'dark' : 'light')
    document.documentElement.classList.toggle('dark', newIsDark)
  }

  return (
    <button onClick={toggle}>
      {isDark ? 'Light' : 'Dark'}
    </button>
  )
}
```

## Key Principle

**Same brand hue, inverted lightness.** This maintains brand consistency while providing comfortable dark mode viewing.
