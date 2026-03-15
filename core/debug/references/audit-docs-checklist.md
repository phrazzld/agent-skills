# Documentation Audit Checklist

## Checks

### 1. Core Documentation
```bash
[ -f "README.md" ] && echo "OK" || echo "FAIL: README"
[ -f ".env.example" ] && echo "OK" || echo "FAIL: .env.example"
[ -f "ARCHITECTURE.md" ] || [ -f "docs/ARCHITECTURE.md" ] || [ -f "docs/CODEBASE_MAP.md" ] && echo "OK" || echo "FAIL: Architecture"
[ -f "CONTRIBUTING.md" ] && echo "OK" || echo "FAIL: CONTRIBUTING"
[ -d "docs/adr" ] || [ -d "docs/adrs" ] && echo "OK" || echo "FAIL: ADR directory"
```

### 2. README Quality
```bash
grep -q "## Installation" README.md 2>/dev/null && echo "OK" || echo "FAIL: Installation section"
grep -q "## Quick Start" README.md 2>/dev/null || grep -q "## Getting Started" README.md 2>/dev/null && echo "OK" || echo "FAIL: Quick start"
grep -q "## Configuration" README.md 2>/dev/null || grep -q "## Setup" README.md 2>/dev/null && echo "OK" || echo "FAIL: Configuration"
```

### 3. .env.example Coverage
```bash
grep -rhoE "process\.env\.[A-Z_]+" --include="*.ts" --include="*.tsx" src/ app/ 2>/dev/null | \
  sort -u | sed 's/process.env.//' > /tmp/env-used.txt
[ -f ".env.example" ] && cut -d= -f1 .env.example > /tmp/env-documented.txt || touch /tmp/env-documented.txt
comm -23 <(sort /tmp/env-used.txt) <(sort /tmp/env-documented.txt) 2>/dev/null
```

### 4. Staleness Check
```bash
find . -name "*.md" \( -path "./docs/*" -o -name "README.md" -o -name "CONTRIBUTING.md" \) 2>/dev/null | while read f; do
  if [ -f "$f" ]; then
    age=$(( ($(date +%s) - $(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)) / 86400 ))
    [ $age -gt 90 ] && echo "STALE ($age days): $f"
  fi
done
```

### 5. Auth System Consistency
```bash
current_auth=$(grep -oE "Clerk|Auth0|Convex Auth|NextAuth|Magic Link|Supabase Auth" README.md 2>/dev/null | head -1)
if [ "$current_auth" = "Clerk" ]; then
  grep -rlE "Magic Link|Resend|RESEND_API_KEY|Convex Auth|EMAIL_FROM" docs/ 2>/dev/null | while read f; do
    echo "INCONSISTENT ($f): References old auth system, but README uses Clerk"
  done
fi
```

### 6. Link Validation
```bash
command -v lychee >/dev/null && lychee --offline *.md docs/**/*.md 2>/dev/null || echo "Install lychee for link checking"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| Missing README.md | P0 |
| Missing .env.example (with env vars used) | P0 |
| Incomplete README sections | P1 |
| Missing architecture docs | P1 |
| Undocumented env vars | P1 |
| Stale documentation (90+ days) | P2 |
| Missing CONTRIBUTING.md | P2 |
| Missing ADRs | P2 |
| Polish and extras | P3 |

## Next.js Specific
- App Router conventions documented
- RSC vs client component boundaries explained
- Route handlers and middleware documented
