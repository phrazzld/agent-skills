#!/usr/bin/env python3
"""
SessionStart hook: Inject current time and timezone into Claude's context.

Claude Code doesn't inherently know the current time. This hook runs at session
start and outputs the current datetime so Claude can reason about time correctly.
"""

import json
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

def main():
    # Get local timezone
    local_tz = datetime.now().astimezone().tzinfo
    now = datetime.now(local_tz)

    # Format: "Tuesday, January 21, 2026 at 3:45 PM CST"
    friendly_time = now.strftime("%A, %B %d, %Y at %-I:%M %p %Z")
    iso_time = now.isoformat()

    # Output as a system message that Claude will see
    result = {
        "result": "continue",
        "message": f"Current time: {friendly_time} ({iso_time})"
    }

    print(json.dumps(result))

if __name__ == "__main__":
    main()
