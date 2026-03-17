# Product Standards Audit Checklist

## Checks

### 1. Core Experience
```bash
# App loads without errors
grep -rqE "error\.tsx|ErrorBoundary" --include="*.tsx" app/ 2>/dev/null && echo "OK: Error handling"
# Loading states
grep -rqE "loading\.tsx|Skeleton|Loading|Spinner" --include="*.tsx" app/ components/ 2>/dev/null && echo "OK: Loading states"
```

### 2. Responsive Design
```bash
grep -rqE "sm:|md:|lg:|xl:" --include="*.tsx" app/ components/ 2>/dev/null | head -5
grep -qE "viewport|mobile" app/layout.tsx 2>/dev/null && echo "OK: Viewport meta"
```

### 3. Accessibility
```bash
grep -rqE "aria-|role=|alt=|sr-only" --include="*.tsx" components/ app/ 2>/dev/null | wc -l
grep -rqE "tabIndex|onKeyDown|onKeyPress" --include="*.tsx" components/ 2>/dev/null | head -5
```

### 4. SEO
```bash
grep -rqE "metadata|generateMetadata|<title|<meta" --include="*.tsx" --include="*.ts" app/ 2>/dev/null | head -5
[ -f "app/sitemap.ts" ] || [ -f "public/sitemap.xml" ] && echo "OK: Sitemap"
[ -f "app/robots.ts" ] || [ -f "public/robots.txt" ] && echo "OK: Robots"
```

### 5. Performance
```bash
grep -rqE "next/image|Image.*src" --include="*.tsx" app/ components/ 2>/dev/null && echo "OK: Image optimization"
grep -rqE "next/font|font.*variable" --include="*.tsx" --include="*.ts" app/ 2>/dev/null && echo "OK: Font optimization"
grep -rqE "lazy|dynamic|Suspense" --include="*.tsx" app/ 2>/dev/null | head -5
```

### 6. Data Handling
```bash
grep -rqE "zod|yup|superstruct|validation|schema" package.json 2>/dev/null && echo "OK: Schema validation"
grep -rqE "toast|sonner|notification|alert" --include="*.tsx" components/ app/ 2>/dev/null && echo "OK: User feedback"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| App crashes without error handling | P0 |
| No loading states (blank screens) | P0 |
| Not responsive on mobile | P1 |
| No viewport meta tag | P1 |
| No input validation | P1 |
| No accessibility attributes | P2 |
| No SEO metadata | P2 |
| No image optimization | P2 |
| No user feedback (toasts) | P2 |
| Missing sitemap/robots | P3 |
| No font optimization | P3 |
| No lazy loading | P3 |
