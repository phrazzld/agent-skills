#!/usr/bin/env python3
"""
Post-edit session stats - shows cumulative edit metrics.

PostToolUse hook that displays session metrics after each edit.
Includes a gentle reminder about Codex CLI delegation for larger sessions.
"""
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from lib.team_utils import is_in_active_team


def get_state_file() -> Path:
    """Get session state file path based on parent PID."""
    ppid = os.getppid()
    return Path(f"/tmp/claude-delegation-{ppid}.json")


def load_state() -> dict:
    """Load session state."""
    state_file = get_state_file()
    if state_file.exists():
        try:
            return json.loads(state_file.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def count_lines(tool_input: dict) -> int:
    """Estimate lines in this edit."""
    new_string = tool_input.get("new_string", "")
    content = tool_input.get("content", "")
    text = new_string or content
    if not text:
        return 0
    return len(text.strip().split("\n"))


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}

    if tool_name not in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        sys.exit(0)

    file_path = tool_input.get("file_path", "unknown")
    lines = count_lines(tool_input)
    state = load_state()

    if not state:
        # No state = first edit or state cleared
        print(f"[codex] Edited {file_path} ({lines} lines)")
        sys.exit(0)

    # Show cumulative stats
    num_files = len(state.get("files_touched", []))
    total_lines = state.get("total_lines_added", lines)
    num_dirs = len(state.get("directories_touched", []))
    new_files = state.get("new_files_created", 0)

    stats = f"{num_files} files | {total_lines} lines | {num_dirs} dirs"
    if new_files > 0:
        stats += f" | {new_files} new"

    print(f"[codex] {file_path} (+{lines}) → Session: {stats}")

    # Suppress delegation pressure for agent team teammates
    if is_in_active_team():
        print(f"[team] {file_path} (+{lines}) → Session: {stats}")
        sys.exit(0)

    # Gentle reminder on substantial sessions
    if total_lines >= 100 or num_files >= 5:
        print(
            "[codex] 💡 Consider delegating further work to Codex CLI if this grows."
        )

    sys.exit(0)


if __name__ == "__main__":
    main()
