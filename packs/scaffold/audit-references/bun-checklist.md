# Bun Compatibility Audit Checklist

## Checks

### 1. Current Package Manager
```bash
[ -f "pnpm-lock.yaml" ] && echo "Current: pnpm"
[ -f "bun.lock" ] || [ -f "bun.lockb" ] && echo "Current: bun"
[ -f "package-lock.json" ] && echo "Current: npm"
[ -f "yarn.lock" ] && echo "Current: yarn"
grep -o '"packageManager":.*' package.json 2>/dev/null || echo "No packageManager field"
ls -la *.lock* 2>/dev/null | wc -l  # Multiple lockfiles?
```

### 2. Deployment Target
```bash
[ -f "vercel.json" ] && echo "Vercel deployment detected"
[ -f "app.json" ] && grep -q "expo" app.json && echo "Expo detected - Bun NOT supported"
[ -f "netlify.toml" ] && echo "Netlify deployment - limited Bun support"
[ -f "fly.toml" ] && echo "Fly.io deployment - full Bun support"
```

### 3. Dependency Compatibility
```bash
grep -E "sharp|bcrypt|canvas|puppeteer|better-sqlite3" package.json 2>/dev/null
grep -E "node-gyp|node-pre-gyp" package-lock.json pnpm-lock.yaml 2>/dev/null | head -5
```

### 4. CI Configuration
```bash
grep -l "pnpm/action-setup" .github/workflows/*.yml 2>/dev/null
grep -l "oven-sh/setup-bun" .github/workflows/*.yml 2>/dev/null
```

### 5. Workspace Configuration
```bash
[ -f "pnpm-workspace.yaml" ] && echo "pnpm-workspace.yaml found"
grep -q '"workspaces"' package.json && echo "workspaces in package.json"
```

### 6. Node.js API Usage
```bash
grep -rE "child_process|cluster|vm|dgram" --include="*.ts" --include="*.js" src/ 2>/dev/null | head -10
grep -rE "worker_threads" --include="*.ts" --include="*.js" src/ 2>/dev/null | head -5
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| Expo/EAS deployment (blocker) | P0 |
| Native modules incompatible | P0 |
| Mixed lockfiles | P1 |
| CI not updated | P1 |
| Workspace config needs migration | P1 |
| Scripts using `node` | P2 |
| Test runner not optimized | P2 |
| Missed optimization opportunities | P3 |

## Migration Complexity

- **LOW**: No blockers, simple deps, flexible deployment
- **MEDIUM**: Some native modules (compatible), CI needs updating, workspace migration
- **HIGH**: Platform limitations, heavy native modules, complex monorepo
