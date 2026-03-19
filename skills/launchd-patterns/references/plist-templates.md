# Plist Templates

Copy-paste-ready launchd plist templates. Replace `com.user.JOBNAME`, paths, and schedule values.

All templates assume LaunchAgent (user context). For LaunchDaemon: change install path to `/Library/LaunchDaemons/`, set owner to `root:wheel`, and add `<key>UserName</key><string>username</string>` if you don't want it running as root.

---

## Daily Script

Runs a script every day at 2:30 AM. Fires on wake if the Mac was asleep at that time.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.daily-task</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/me/scripts/daily-task.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>30</integer>
    </dict>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.daily-task.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.daily-task.stderr.log</string>
</dict>
</plist>
```

**Install:**
```bash
cp com.user.daily-task.plist ~/Library/LaunchAgents/
chmod 644 ~/Library/LaunchAgents/com.user.daily-task.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.daily-task.plist
```

---

## File Watcher

Triggers when a file or directory changes. Useful for auto-processing downloads, config reloads, or build triggers.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.file-watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/me/scripts/on-file-change.sh</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Users/me/Downloads</string>
    </array>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.file-watcher.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.file-watcher.stderr.log</string>
</dict>
</plist>
```

**Gotchas:**
- `WatchPaths` fires on ANY change (create, modify, delete, rename) in the watched path.
- For directories, fires when directory contents change, NOT when files inside subdirectories change. Not recursive.
- `ThrottleInterval` prevents rapid re-firing. Default is 10 seconds. Set lower if you need faster response.
- The job receives no information about WHAT changed. Your script must track state itself (e.g., compare against a manifest file).

---

## Network-Triggered Service

Runs when the network becomes available. Useful for sync jobs, VPN setup, or upload queues.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.network-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/me/scripts/sync-when-online.sh</string>
    </array>
    <key>KeepAlive</key>
    <dict>
        <key>NetworkState</key>
        <true/>
    </dict>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.network-sync.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.network-sync.stderr.log</string>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
```

**How it works:**
- `KeepAlive` with `NetworkState = true` means: keep the job alive whenever the network is reachable.
- If the script exits, launchd restarts it (after `ThrottleInterval` seconds) as long as the network is still up.
- When the network drops, launchd sends SIGTERM. When it returns, the job is relaunched.
- For one-shot sync (run once when network appears, not continuously): have the script do its work and exit. It will re-run each time network state transitions to "up."

**Important:** `NetworkState` checks for an active interface with an IP, not actual internet connectivity. A captive portal WiFi connection counts as "network available."

---

## On-Demand Long-Running Service

A daemon-style service that starts at login and restarts on crash. Pattern for menu bar apps, local API servers, or background sync engines.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.my-service</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/my-service</string>
        <string>--port</string>
        <string>8080</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>/Users/me</string>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.my-service.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.my-service.stderr.log</string>
    <key>ProcessType</key>
    <string>Background</string>
    <key>SoftResourceLimits</key>
    <dict>
        <key>NumberOfFiles</key>
        <integer>4096</integer>
    </dict>
</dict>
</plist>
```

**Notes:**
- `KeepAlive = true` means launchd restarts the process whenever it exits (crash or clean exit).
- `ThrottleInterval` prevents restart storms. If the service crashes immediately, launchd waits 10 seconds before retrying.
- `ProcessType = Background` tells macOS this is low-priority background work. Reduces CPU/IO priority to avoid impacting foreground apps.
- `SoftResourceLimits` raises the open file limit (default is 256, too low for many servers).
- To stop: `launchctl bootout gui/$(id -u)/com.user.my-service`. `kill` alone just triggers a restart.

---

## Batch Processor (QueueDirectories)

Fires whenever a directory has contents. Process files, then remove them. launchd re-triggers if more files appear.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.batch-processor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/me/scripts/process-queue.sh</string>
    </array>
    <key>QueueDirectories</key>
    <array>
        <string>/Users/me/queue/incoming</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.batch-processor.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.batch-processor.stderr.log</string>
</dict>
</plist>
```

**Pattern for the processing script:**
```bash
#!/bin/bash
QUEUE_DIR="/Users/me/queue/incoming"
DONE_DIR="/Users/me/queue/processed"

mkdir -p "$DONE_DIR"

for file in "$QUEUE_DIR"/*; do
    [ -f "$file" ] || continue
    # Process the file
    echo "Processing: $(basename "$file")"
    # ... your logic here ...
    mv "$file" "$DONE_DIR/"
done
```

**How `QueueDirectories` differs from `WatchPaths`:**
- `QueueDirectories` only fires when the directory is **non-empty**. If the script removes all files, launchd waits until new files appear.
- `WatchPaths` fires on any change, even deletion. Your script must handle empty states.
- `QueueDirectories` is the right choice for "process files as they arrive" workflows.

---

## Interval Timer (Every N Seconds)

Simple repeating timer. Less precise than `StartCalendarInterval` but simpler for "every 5 minutes" patterns.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.heartbeat</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/me/scripts/heartbeat.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.user.heartbeat.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.user.heartbeat.stderr.log</string>
</dict>
</plist>
```

**Behavior notes:**
- Timer starts from when the job finishes, not from when it starts. A 300-second interval with a 60-second script means ~360 seconds between start times.
- Timer resets on wake from sleep. If Mac sleeps for 8 hours with a 5-minute interval, one run fires on wake, then resumes the 5-minute cadence.
- Cannot combine `StartInterval` and `StartCalendarInterval` in the same plist. Pick one.
