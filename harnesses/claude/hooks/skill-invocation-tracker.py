#!/usr/bin/env python3
"""
PostToolUse hook: append skill invocation records to a JSONL log.

Passive telemetry -- exits 0 with no stdout. Never influences tool behavior.
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

LOG_PATH = Path(
    os.environ.get(
        "SKILL_TRACKER_LOG_PATH",
        os.path.expanduser("~/.claude/skill-invocations.jsonl"),
    )
)


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    tool_name = data.get("tool_name", "")
    if tool_name != "Skill":
        sys.exit(0)

    tool_input = data.get("tool_input") or {}
    skill = tool_input.get("skill", "")
    if not skill:
        sys.exit(0)

    cwd = data.get("cwd", "")
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "skill": skill,
        "args": tool_input.get("args", ""),
        "session_id": data.get("session_id", ""),
        "cwd": cwd,
        "project": os.path.basename(cwd) if cwd else "",
    }

    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with LOG_PATH.open("a") as f:
            f.write(json.dumps(entry, separators=(",", ":")) + "\n")
    except OSError:
        pass  # Never fail the hook -- telemetry is best-effort

    sys.exit(0)


if __name__ == "__main__":
    main()
