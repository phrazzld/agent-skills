#!/usr/bin/env python3
"""Block gh pr merge unless review settlement is explicitly complete.

Prevents the agent from merging PRs without:
1. Reading all 3 GitHub comment channels after the last push
2. Getting explicit user confirmation

Exit 0 + JSON deny = block the command
Exit 0 + no output = allow the command
"""
import json
import re
import sys


def deny(reason: str) -> None:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    print(json.dumps(output))
    sys.exit(0)


data = json.load(sys.stdin)
if data.get("tool_name") != "Bash":
    sys.exit(0)

cmd = data.get("tool_input", {}).get("command", "")

# Only match gh pr merge at the start of a command or after a pipe/semicolon/&&,
# not inside heredocs, strings, or echo/cat content.
first_line = cmd.split("\n")[0].strip()
if not re.search(r"(?:^|[;&|]\s*)gh\s+pr\s+merge\b", first_line):
    sys.exit(0)

deny(
    "BLOCKED: gh pr merge requires explicit user confirmation.\n\n"
    "Before merging, you must:\n"
    "1. Re-read ALL review comments (3 channels: issues/comments, pulls/reviews, pulls/comments)\n"
    "2. Respond to every unaddressed comment on the PR\n"
    "3. Ask the user for explicit merge confirmation\n\n"
    "Never merge autonomously — merging is a shared-state action that affects others."
)
