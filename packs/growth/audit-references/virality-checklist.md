# Virality Audit Checklist

## Checks

### 1. Share Mechanisms
```bash
grep -rqE "share|Share|clipboard|copy.*link|navigator\.share" --include="*.tsx" --include="*.ts" app/ components/ 2>/dev/null | head -10
```

### 2. Referral System
```bash
grep -rqE "referral|refer|invite|invit" --include="*.tsx" --include="*.ts" app/ components/ lib/ 2>/dev/null | head -10
grep -rqE "referral.*code|invite.*link|ref=" --include="*.ts" --include="*.tsx" . 2>/dev/null | head -5
```

### 3. Social Meta Tags (OG)
```bash
grep -rqE "og:title|og:description|og:image|openGraph|twitter:card" --include="*.tsx" --include="*.ts" app/ 2>/dev/null | head -5
[ -f "app/opengraph-image.tsx" ] || [ -f "app/opengraph-image.png" ] && echo "OK: OG image" || echo "FAIL: No OG image"
```

### 4. Social Proof Loops
```bash
grep -rqE "testimonial|review|rating|star|feedback" --include="*.tsx" components/ app/ 2>/dev/null | head -5
grep -rqE "user.*count|active.*user|community|member" --include="*.tsx" app/ components/ 2>/dev/null | head -5
```

### 5. Network Effects
```bash
grep -rqE "team|workspace|collaborate|org|group" --include="*.tsx" --include="*.ts" app/ lib/ 2>/dev/null | head -5
```

### 6. Viral Content
```bash
grep -rqE "embed|iframe|widget|badge|public.*profile" --include="*.tsx" --include="*.ts" app/ components/ 2>/dev/null | head -5
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| No share mechanism at all | P0 |
| No OG meta tags | P1 |
| No OG image | P1 |
| No referral system | P1 |
| No social proof elements | P2 |
| No embeddable content | P2 |
| No team/collaboration features | P2 |
| No viral loop analytics | P3 |
| No network effect design | P3 |
