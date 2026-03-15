# Typography System

## Type Scale (1.200 Modular Ratio)

```css
@theme {
  --font-size-xs: 0.694rem;     /* 11.11px */
  --font-size-sm: 0.833rem;     /* 13.33px */
  --font-size-base: 1rem;       /* 16px */
  --font-size-lg: 1.2rem;       /* 19.20px */
  --font-size-xl: 1.44rem;      /* 23.04px */
  --font-size-2xl: 1.728rem;    /* 27.65px */
  --font-size-3xl: 2.074rem;    /* 33.18px */
  --font-size-4xl: 2.488rem;    /* 39.81px */
  --font-size-5xl: 2.986rem;    /* 47.78px */
  --font-size-6xl: 3.583rem;    /* 57.33px */
  --font-size-7xl: 4.300rem;    /* 68.80px */

  /* Line heights */
  --line-height-tight: 1.2;
  --line-height-snug: 1.375;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.625;
  --line-height-loose: 2;

  /* Letter spacing */
  --letter-spacing-tight: -0.02em;
  --letter-spacing-normal: 0;
  --letter-spacing-wide: 0.02em;
  --letter-spacing-wider: 0.05em;
}
```

## Font Families

**Avoid generic fonts (Inter, Roboto, Arial)**—choose distinctive fonts per frontend-design skill.

```css
@theme {
  /* Example: Editorial style */
  --font-display: "Clash Display", "Inter Variable", sans-serif;
  --font-sans: "Inter Variable", system-ui, sans-serif;
  --font-serif: "Merriweather", Georgia, serif;
  --font-mono: "JetBrains Mono", "Fira Code", monospace;

  /* Font weights */
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --font-weight-extrabold: 800;
}
```

## Font Loading (Next.js)

```tsx
// app/layout.tsx
import { Inter, Merriweather, JetBrains_Mono } from 'next/font/google'
import localFont from 'next/font/local'

const inter = Inter({ subsets: ['latin'], variable: '--font-sans' })
const merriweather = Merriweather({
  weight: ['300', '400', '700'],
  subsets: ['latin'],
  variable: '--font-serif'
})
const jetbrains = JetBrains_Mono({ subsets: ['latin'], variable: '--font-mono' })
const clashDisplay = localFont({
  src: './fonts/ClashDisplay-Variable.woff2',
  variable: '--font-display',
})

export default function RootLayout({ children }) {
  return (
    <html className={`${inter.variable} ${merriweather.variable} ${jetbrains.variable} ${clashDisplay.variable}`}>
      <body>{children}</body>
    </html>
  )
}
```
