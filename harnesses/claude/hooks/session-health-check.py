#!/usr/bin/env python3
"""
Session start health check - warns if system resources are constrained.
Lightweight check that runs at session start.
"""

import json
import os
import subprocess
import sys
from pathlib import Path


SETTINGS_PATH = Path.home() / ".claude/settings.json"


def get_disk_percent():
    """Get disk usage percentage."""
    try:
        result = subprocess.run(
            ["df", "-h", "/System/Volumes/Data"],
            capture_output=True, text=True, timeout=5
        )
        # Parse "97%" from output
        for line in result.stdout.strip().split('\n')[1:]:
            parts = line.split()
            if len(parts) >= 5:
                return int(parts[4].rstrip('%'))
    except Exception:
        pass
    return None


def get_swap_gb():
    """Get swap usage in GB."""
    try:
        result = subprocess.run(
            ["sysctl", "vm.swapusage"],
            capture_output=True, text=True, timeout=5
        )
        # Parse "used = 7783.88M"
        output = result.stdout
        if "used = " in output:
            used_part = output.split("used = ")[1].split()[0]
            value = float(used_part.rstrip('M'))
            return value / 1024  # Convert MB to GB
    except Exception:
        pass
    return None


def count_orphan_test_processes():
    """Count vitest/jest watch processes that may be zombies."""
    count = 0
    try:
        result = subprocess.run(
            ["pgrep", "-lf", "vitest"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            lines = [l for l in result.stdout.strip().split('\n')
                     if 'vitest' in l.lower() and 'pgrep' not in l]
            count += len(lines)
    except Exception:
        pass
    return count


def find_missing_hook_targets():
    """Find hook commands in settings.json that point at missing local scripts."""
    try:
        settings = json.loads(SETTINGS_PATH.read_text())
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return []

    missing = []
    for groups in settings.get("hooks", {}).values():
        for group in groups:
            for hook in group.get("hooks", []):
                command = hook.get("command", "")
                for token in command.split():
                    if token.startswith("~/.claude/hooks/"):
                        target = Path(os.path.expanduser(token))
                        if not target.exists():
                            missing.append(target.name)
                        break
    return sorted(set(missing))


def main():
    warnings = []

    disk_pct = get_disk_percent()
    if disk_pct and disk_pct >= 90:
        warnings.append(f"Disk at {disk_pct}% - consider running 'cache-clean'")

    swap_gb = get_swap_gb()
    if swap_gb and swap_gb >= 15:
        warnings.append(f"Swap at {swap_gb:.1f}GB - high memory pressure")

    orphans = count_orphan_test_processes()
    if orphans > 0:
        warnings.append(
            f"Found {orphans} vitest process(es) still running. "
            f"Run: pkill -f vitest"
        )

    missing_hooks = find_missing_hook_targets()
    if missing_hooks:
        listed = ", ".join(missing_hooks[:4])
        if len(missing_hooks) > 4:
            listed += f" (+{len(missing_hooks) - 4} more)"
        warnings.append(
            "settings.json references missing hook scripts: "
            f"{listed}. Remove stale entries before continuing."
        )

    if warnings:
        message = "[codex] ⚠️ SYSTEM HEALTH:\n" + "\n".join(warnings)
        print(json.dumps({"message": message}))
    else:
        print(json.dumps({}))


if __name__ == "__main__":
    main()
