# Onboarding Audit Checklist

## Checks

### 1. Auth Flow
```bash
grep -rE "SignIn|SignUp|sign-in|sign-up|login|register" --include="*.tsx" app/ 2>/dev/null | head -10
grep -rE "ClerkProvider|SessionProvider|AuthProvider" --include="*.tsx" app/layout.tsx 2>/dev/null
```

### 2. First-Run Experience
```bash
grep -rE "onboarding|welcome|getting-started|first-run|setup-wizard" --include="*.tsx" --include="*.ts" app/ components/ 2>/dev/null | head -10
```

### 3. Empty States
```bash
grep -rE "empty.*state|no.*items|get.*started|EmptyState" --include="*.tsx" components/ app/ 2>/dev/null | head -10
```

### 4. Progressive Disclosure
```bash
grep -rE "step|wizard|multi-step|progress|tour|tooltip.*new" --include="*.tsx" components/ app/ 2>/dev/null | head -10
```

### 5. Error Recovery
```bash
grep -rE "try.*again|retry|error.*boundary|fallback" --include="*.tsx" app/ components/ 2>/dev/null | head -10
```

### 6. Mobile Auth
```bash
grep -rE "responsive|mobile.*auth|sm:|md:" --include="*.tsx" app/sign-in/ app/login/ app/\(auth\)/ 2>/dev/null | head -5
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| No auth flow exists | P0 |
| Auth flow broken/errors | P0 |
| No onboarding/first-run experience | P1 |
| No empty states in key views | P1 |
| No error recovery in auth | P1 |
| No progressive disclosure | P2 |
| Auth not mobile responsive | P2 |
| No user feedback during setup | P2 |
| No success celebration/confirmation | P3 |
| No analytics on onboarding funnel | P3 |
