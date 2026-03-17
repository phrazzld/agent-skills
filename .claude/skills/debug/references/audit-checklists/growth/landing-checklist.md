# Landing Page Audit Checklist

## Checks

### 1. Page Existence
```bash
[ -f "app/page.tsx" ] || [ -f "app/(marketing)/page.tsx" ] || [ -f "pages/index.tsx" ] && echo "OK" || echo "FAIL: No landing page"
grep -qE "redirect|SignIn|Dashboard" app/page.tsx 2>/dev/null && echo "WARN: Landing page redirects" || echo "OK: Landing page is content"
```

### 2. Value Proposition
```bash
grep -rE "hero|Hero|headline|Headline" --include="*.tsx" app/ components/ 2>/dev/null | head -5
grep -rE "<h1|className.*text-(4xl|5xl|6xl)" --include="*.tsx" app/page.tsx 2>/dev/null | head -3
grep -rE "features|Features|benefits|Benefits" --include="*.tsx" app/ components/ 2>/dev/null | head -5
```

### 3. CTA
```bash
grep -rE "Get Started|Sign Up|Try Free|Start|Join" --include="*.tsx" app/page.tsx components/ 2>/dev/null | head -5
grep -rE "href.*(signup|sign-up|register|get-started|try)" --include="*.tsx" app/ 2>/dev/null | head -5
```

### 4. Social Proof
```bash
grep -rE "testimonial|Testimonial|review|Review|customer|Customer" --include="*.tsx" app/ components/ 2>/dev/null | head -5
grep -rE "logo.*client|partner.*logo|trusted.*by|as.*seen" --include="*.tsx" app/ components/ 2>/dev/null | head -3
```

### 5. Mobile Responsiveness
```bash
grep -rE "md:|lg:|sm:|responsive|grid-cols|flex-col" --include="*.tsx" app/page.tsx 2>/dev/null | head -10
grep -rE "hidden.*md:|md:hidden|mobile|viewport" --include="*.tsx" app/page.tsx components/ 2>/dev/null | head -5
```

### 6. Performance
```bash
grep -rE "next/image|Image.*src|<img" --include="*.tsx" app/page.tsx 2>/dev/null | head -5
grep -rE "loading.*lazy|priority|placeholder.*blur" --include="*.tsx" app/page.tsx 2>/dev/null | head -3
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| No landing page exists | P0 |
| Landing page redirects to app | P0 |
| No value proposition / headline | P1 |
| No CTA button | P1 |
| CTA doesn't link to action | P1 |
| No social proof | P2 |
| Not responsive | P2 |
| No image optimization | P2 |
| Missing trust indicators | P3 |
| Performance optimization | P3 |
