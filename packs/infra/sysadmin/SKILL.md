---
name: sysadmin
description: |
  System health diagnostics and maintenance for macOS. Resource usage, disk space,
  memory pressure, Docker, Homebrew, stuck processes. Quick health checks and
  safe maintenance actions.
disable-model-invocation: true
---

# /sysadmin

System health check and maintenance. Identifies resource hogs, disk usage, and potential issues.

**Critical constraint:** NEVER kill or terminate agent processes. Warn only.

## Diagnostics

### 1. System Overview
```bash
system_profiler SPHardwareDataType | grep -E "(Model|Chip|Memory|Cores)"
```

### 2. Resource Usage
```bash
ps aux -r | head -15   # Top CPU
ps aux -m | head -15   # Top memory
```

### 3. Agent Process Check
```bash
ps aux | grep -i "claude\|anthropic" | grep -v grep
```
If high usage: report prominently, suggest restart or `/clear`. DO NOT suggest killing.

### 4. Disk Usage
```bash
df -h / | tail -1
du -sh ~/Library/Caches ~/Library/Application\ Support ~/.Trash 2>/dev/null | sort -hr
docker system df 2>/dev/null || echo "Docker not running"
```

### 5. Memory Pressure
```bash
vm_stat | head -10
sysctl vm.swapusage
```

### 6. Stuck Processes
```bash
ps aux | awk '$3 > 50 {print}' | head -10
```

## Health Thresholds

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Disk | < 80% | 80-90% | > 90% |
| Swap | < 5GB | 5-15GB | > 15GB |
| CPU stuck | None | 1-2 procs | 3+ procs |

## Maintenance Actions (on request only)

```bash
# Clear caches
rm -rf ~/Library/Caches/* 2>/dev/null

# Empty trash
rm -rf ~/.Trash/* 2>/dev/null

# Docker cleanup
docker system prune -f

# Homebrew cleanup
brew cleanup --prune=7
```

## Remediation

```bash
# Quick cache clean
brew cleanup --prune=all && go clean -cache && pnpm store prune && pip cache purge

# Aggressive cleanup (manual)
/usr/bin/trash ~/Library/Caches/ms-playwright
/usr/bin/trash ~/Library/Developer/Xcode/DerivedData
xcrun simctl delete unavailable
```

Never run maintenance automatically. Always confirm first.
