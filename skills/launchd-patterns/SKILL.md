---
name: launchd-patterns
description: "macOS launchd scheduling and service management. LaunchAgent/Daemon patterns, launchctl CLI, plist authoring, cron migration, debugging. The production gotchas Apple docs don't cover."
argument-hint: "[create|debug|migrate|patterns]"
---

## Routing Table

| Command | Action |
|---------|--------|
| (no args) / `create` | Create a new LaunchAgent/Daemon |
| `debug` | Debug a failing launch job |
| `migrate` | Migrate cron jobs to launchd |
| `patterns` | Load `references/plist-templates.md` |

## Why launchd, Not cron

cron exists on macOS but is a second-class citizen. launchd is PID 1.

| Feature | cron | launchd |
|---------|------|---------|
| Survives sleep/wake | No -- missed jobs are gone | Yes -- fires on wake if time passed |
| On-demand triggers | Time only | Time, file change, network state, directory contents |
| Resource limits | None | CPU, memory, I/O throttling per job |
| Logging | Roll your own | stdout/stderr capture + unified log |
| Dependency ordering | None | `KeepAlive`, `AfterInitialDemand` |
| Apple blessed | Deprecated warnings since 10.15 | System default since 10.4 |

`crontab -e` still works but logs a deprecation notice. Apple can remove it any release.

## Core Concepts

| Type | Path | Runs as | Available |
|------|------|---------|-----------|
| User Agent | `~/Library/LaunchAgents/` | Current user | When user is logged in |
| Global Agent | `/Library/LaunchAgents/` | Current user | When any user logs in |
| Daemon | `/Library/LaunchDaemons/` | root (or `UserName` key) | Always, even before login |
| System | `/System/Library/Launch*` | root | Always -- **never touch these** |

**Rule of thumb:** If it needs a GUI or user context (menu bar, notifications, user files) use an Agent. If it needs to run without any user logged in, use a Daemon.

## launchctl CLI (Modern vs Legacy)

```bash
# Modern (macOS 10.11+) -- use these
launchctl bootstrap gui/$(id -u) /path/to/plist    # Load agent
launchctl bootstrap system /path/to/plist           # Load daemon
launchctl bootout gui/$(id -u)/com.user.job         # Unload agent
launchctl bootout system/com.user.job               # Unload daemon
launchctl kickstart -k gui/$(id -u)/com.user.job    # Force restart (-k kills first)
launchctl print gui/$(id -u)/com.user.job           # Full status + config dump
launchctl list                                       # All loaded jobs
launchctl list com.user.job                          # Single job status

# Domain targets
# gui/501          = user with UID 501
# gui/$(id -u)     = current user (portable)
# system           = system-wide daemons
# user/501         = per-user background (no GUI)

# Legacy (still works but deprecated -- avoid)
launchctl load /path/to/plist       # Caching bugs: unloaded jobs reappear after reboot
launchctl unload /path/to/plist     # Same issue
launchctl load -w /path/to/plist    # -w "forces" but interacts badly with bootstrap
```

**Why bootstrap over load:** `load`/`unload` use a persistent override database (`/var/db/launchd.db/`) that can desync with the actual plist state. `bootstrap`/`bootout` operate directly and predictably.

## Plist Template: StartCalendarInterval (Recurring)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.weekly-cleanup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/script.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.weekly-cleanup.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.weekly-cleanup.stderr.log</string>
</dict>
</plist>
```

## Key Gotchas

1. **Label MUST match filename** (minus `.plist` extension). `com.user.myjob` lives in `com.user.myjob.plist`. launchctl silently ignores mismatches on some macOS versions -- job loads but never fires.

2. **ProgramArguments is an array, not a string.** Each argument is its own `<string>` element. `bash -c "complex command"` requires three elements:
   ```xml
   <array>
       <string>/bin/bash</string>
       <string>-c</string>
       <string>complex command with pipes | and stuff</string>
   </array>
   ```

3. **StartCalendarInterval fires on wake.** If the Mac was asleep at scheduled time, the job fires immediately on wake. This is the killer feature over cron, which simply misses the window.

4. **File permissions matter silently.** Wrong permissions = job silently ignored, no error in logs.

   | Type | Owner | Permissions |
   |------|-------|-------------|
   | LaunchAgent | current user | `644` (`-rw-r--r--`) |
   | LaunchDaemon | `root:wheel` | `644` (`-rw-r--r--`) |

   ```bash
   # Fix agent permissions
   chmod 644 ~/Library/LaunchAgents/com.user.myjob.plist

   # Fix daemon permissions
   sudo chown root:wheel /Library/LaunchDaemons/com.user.myjob.plist
   sudo chmod 644 /Library/LaunchDaemons/com.user.myjob.plist
   ```

5. **launchctl load is DEPRECATED.** Use `bootstrap`/`bootout`. The `load`/`unload` API has persistent override caching where unloaded jobs silently re-appear after reboot.

6. **Code signing on Ventura+ (macOS 13+).** Unsigned scripts may be blocked by Gatekeeper. Workaround: use `/bin/bash` as the program and pass the script path as an argument. `/bin/bash` is Apple-signed.
   ```xml
   <!-- Instead of this (may be blocked): -->
   <string>/Users/me/scripts/myjob.sh</string>

   <!-- Use this: -->
   <array>
       <string>/bin/bash</string>
       <string>/Users/me/scripts/myjob.sh</string>
   </array>
   ```

7. **Environment variables are NOT inherited.** launchd does not run your shell profile. `$HOME` and `$USER` exist, but `$PATH`, custom vars, Homebrew env -- all absent. Use the `EnvironmentVariables` key:
   ```xml
   <key>EnvironmentVariables</key>
   <dict>
       <key>PATH</key>
       <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
       <key>HOMEBREW_PREFIX</key>
       <string>/opt/homebrew</string>
   </dict>
   ```

8. **PATH is minimal.** Default PATH is just `/usr/bin:/bin:/usr/sbin:/sbin`. Homebrew (`/opt/homebrew/bin` on Apple Silicon, `/usr/local/bin` on Intel), pyenv, nvm, cargo -- none of these exist unless you add them.

9. **StartCalendarInterval with multiple times.** Use an array of dicts, not multiple keys:
   ```xml
   <key>StartCalendarInterval</key>
   <array>
       <dict>
           <key>Hour</key><integer>9</integer>
           <key>Minute</key><integer>0</integer>
       </dict>
       <dict>
           <key>Hour</key><integer>17</integer>
           <key>Minute</key><integer>0</integer>
       </dict>
   </array>
   ```

10. **RunAtLoad + StartCalendarInterval.** `RunAtLoad` fires the job immediately when bootstrapped AND at the next calendar interval. Useful for "run now and then on schedule." Without it, first run waits for next interval.

## Debugging Failed Jobs

```bash
# 1. Is it loaded?
launchctl list | grep com.user.myjob

# 2. Full status dump (most useful command)
launchctl print gui/$(id -u)/com.user.myjob
# Look for: "last exit code", "state", "path", "runs"

# 3. Validate plist syntax
plutil -lint ~/Library/LaunchAgents/com.user.myjob.plist

# 4. Check system log for launch failures
log show --predicate 'subsystem == "com.apple.xpc.launchd"' --last 5m
log show --predicate 'process == "myjob"' --last 5m

# 5. Check stdout/stderr logs (if configured)
cat /tmp/com.user.myjob.stdout.log
cat /tmp/com.user.myjob.stderr.log

# 6. Dry run the command manually to verify it works
/bin/bash /path/to/script.sh
```

### Common Exit Codes (from `launchctl print` or `launchctl list`)

| Code | Meaning | Fix |
|------|---------|-----|
| `0` | Success | -- |
| `78` | Configuration error | Bad plist syntax; run `plutil -lint` |
| `126` | Permission denied | Check script permissions, code signing |
| `127` | Command not found | PATH issue; use absolute paths |
| `-2` | (SIGINT) | Script was interrupted |
| `-9` | (SIGKILL) | Killed by system (memory pressure, timeout) |
| `-15` | (SIGTERM) | Normal termination signal |

### "Job loaded but never runs" Checklist

1. Label matches filename? (`plutil -p plist | grep Label` vs filename)
2. Permissions correct? (`ls -la` the plist)
3. Script executable? (`chmod +x` or use `/bin/bash` wrapper)
4. Full paths in ProgramArguments? (no `~`, no `$HOME`)
5. Check `launchctl print` -- does it show `state = not running` with `runs = 0`?
6. If `StartCalendarInterval`: is the next fire date in the future? (`launchctl print` shows it)

## Cron Migration

```
# Cron entry
0 2 1 * * /path/to/cleanup.sh >> /var/log/cleanup.log 2>&1
```

Translation:

| Cron field | Value | launchd key |
|------------|-------|-------------|
| Minute | 0 | `Minute` = 0 |
| Hour | 2 | `Hour` = 2 |
| Day of month | 1 | `Day` = 1 |
| Month | * | (omit -- means every month) |
| Day of week | * | (omit -- means every day that matches) |

Steps:
1. Write plist with `StartCalendarInterval` mapping above fields
2. Set `StandardOutPath`/`StandardErrorPath` (replaces `>>` redirect)
3. Add full `PATH` in `EnvironmentVariables` (replaces shell profile)
4. Use absolute paths for everything (no `~` expansion in plists)
5. `plutil -lint` the plist
6. Copy to `~/Library/LaunchAgents/`
7. `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.cleanup.plist`
8. Verify: `launchctl list | grep com.user.cleanup`
9. Remove cron entry: `crontab -e` and delete the line

### Cron vs launchd Field Reference

| Cron | launchd | Notes |
|------|---------|-------|
| Minute (0-59) | `Minute` | Same |
| Hour (0-23) | `Hour` | Same |
| Day of month (1-31) | `Day` | Same |
| Month (1-12) | `Month` | Same |
| Day of week (0-7, 0/7=Sun) | `Weekday` | launchd: 0=Sunday through 6=Saturday (7 NOT valid) |
| `*/5` (every 5 min) | No equivalent | Use `StartInterval` (300) instead |
| `1,15` (1st and 15th) | Array of dicts | One dict per combination |

## Common Scheduling Patterns

| Pattern | Key | Example |
|---------|-----|---------|
| Every N seconds | `StartInterval` | `<integer>300</integer>` (5 min) |
| Cron-like schedule | `StartCalendarInterval` | See template above |
| File/directory change | `WatchPaths` | Trigger when file modified |
| Directory has contents | `QueueDirectories` | Trigger when dir non-empty, batch processing |
| Run when network up | `KeepAlive` + `NetworkState` | Wait for connectivity |
| Run once at load | `RunAtLoad` | Combined with other triggers |
| Stay alive forever | `KeepAlive` = `true` | Restarts on crash (daemon pattern) |
| Throttle restarts | `ThrottleInterval` | Min seconds between launches (default: 10) |

## Lifecycle: Create, Test, Deploy

```bash
# 1. Write and validate
vim ~/Library/LaunchAgents/com.user.myjob.plist
plutil -lint ~/Library/LaunchAgents/com.user.myjob.plist
chmod 644 ~/Library/LaunchAgents/com.user.myjob.plist

# 2. Load
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.myjob.plist

# 3. Test (force immediate run)
launchctl kickstart gui/$(id -u)/com.user.myjob

# 4. Verify
launchctl list | grep com.user.myjob
cat /tmp/com.user.myjob.stdout.log

# 5. Iterate (edit plist, then reload)
launchctl bootout gui/$(id -u)/com.user.myjob
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.myjob.plist

# 6. Remove
launchctl bootout gui/$(id -u)/com.user.myjob
rm ~/Library/LaunchAgents/com.user.myjob.plist
```
