#!/usr/bin/env python3
"""
Disk space guardrail - warns before heavy operations when disk is critically low.
Blocks operations that would likely fail or cause system instability.
"""

import json
import os
import sys

# Thresholds
WARN_THRESHOLD_GB = 20  # Warn when free space below this
BLOCK_THRESHOLD_GB = 5  # Block heavy operations below this

# Commands that need significant disk space
HEAVY_COMMANDS = [
    "npm install", "pnpm install", "yarn install",
    "brew install", "brew upgrade",
    "docker build", "docker pull",
    "cargo build", "go build",
    "git clone",
    "npx create-", "pnpm create",
]


def get_free_space_gb():
    """Get free space on main volume in GB."""
    try:
        stat = os.statvfs("/System/Volumes/Data")
        free_bytes = stat.f_bavail * stat.f_frsize
        return free_bytes / (1024 ** 3)
    except Exception:
        return None


def is_heavy_command(command: str) -> bool:
    """Check if command needs significant disk space."""
    cmd_lower = command.lower()
    return any(heavy in cmd_lower for heavy in HEAVY_COMMANDS)


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return

    tool_name = input_data.get("tool_name", "")
    if tool_name != "Bash":
        return

    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    if not is_heavy_command(command):
        return

    free_gb = get_free_space_gb()
    if free_gb is None:
        return

    if free_gb < BLOCK_THRESHOLD_GB:
        result = {
            "decision": "block",
            "reason": f"BLOCKED: Disk critically low ({free_gb:.1f}GB free). "
                      f"Run 'cache-clean' alias before heavy operations."
        }
        print(json.dumps(result))
        sys.exit(0)

    if free_gb < WARN_THRESHOLD_GB:
        # Just print warning, don't block
        sys.stderr.write(
            f"⚠️  Low disk space ({free_gb:.1f}GB free). "
            f"Consider running 'cache-clean' soon.\n"
        )


if __name__ == "__main__":
    main()
