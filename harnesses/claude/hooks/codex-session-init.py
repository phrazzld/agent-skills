#!/usr/bin/env python3
"""
Codex session initialization - resets delegation state.

SessionStart hook that:
- Clears previous session state
- Shows enforcement mode for current repo
- Reminds about delegation options
"""
import json
import os
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".claude/config/delegation-enforcement.json"


def load_config() -> dict:
    """Load config with fallback to defaults."""
    if CONFIG_PATH.exists():
        try:
            return json.loads(CONFIG_PATH.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"enabled": True, "exclusions": {"repositories": [], "patterns": []}}


def get_state_file() -> Path:
    """Get session state file path based on parent PID."""
    ppid = os.getppid()
    return Path(f"/tmp/claude-delegation-{ppid}.json")


def is_excluded_repo(cwd: str, config: dict) -> bool:
    """Check if current working directory is in excluded repos."""
    import fnmatch
    exclusions = config.get("exclusions", {})

    for repo_path in exclusions.get("repositories", []):
        if cwd.startswith(repo_path):
            return True

    for pattern in exclusions.get("patterns", []):
        if fnmatch.fnmatch(cwd, pattern):
            return True

    return False


def main():
    # Initialize fresh state
    state = {
        "files_touched": [],
        "new_files_created": 0,
        "total_lines_added": 0,
        "directories_touched": [],
    }

    state_file = get_state_file()
    state_file.write_text(json.dumps(state, indent=2))

    # Load config and determine status
    config = load_config()
    cwd = os.getcwd()

    if not config.get("enabled", True):
        print("[codex] Delegation enforcement disabled.")
    elif is_excluded_repo(cwd, config):
        print("[codex] Excluded repo - delegation not enforced.")
    else:
        print("[codex] PATTERN: Codex first draft → You review → Ship. Don't investigate yourself.")

    sys.exit(0)


if __name__ == "__main__":
    main()
