#!/usr/bin/env python3
"""
Portable code guard - prevents machine-specific paths and accidental commits.

PreToolUse hook that detects:
1. Hardcoded user home paths in shell scripts and config files
2. Attempts to add workspace node_modules to git

These issues break collaboration and bloat repositories.
"""
import json
import re
import sys
from pathlib import Path


# Machine-specific path patterns (common home directories)
HOME_PATH_RE = re.compile(r'/Users/[a-zA-Z0-9_-]+/')
WINDOWS_PATH_RE = re.compile(r'C:\\Users\\[a-zA-Z0-9_-]+\\')

# Files where we expect hardcoded paths (exclusions)
ALLOWED_PATH_FILES = {
    '.claude/hooks',  # Hook scripts may reference home
    'coverage/',      # Coverage reports contain paths
    '.next/',         # Build artifacts
    'dist/',          # Build outputs
}

# Workspace node_modules pattern
WORKSPACE_NODE_MODULES_RE = re.compile(r'packages/[^/]+/node_modules')


def ask(issue: str, detail: str) -> None:
    reason = (
        f"⚠️  Portability Issue: {issue}\n\n"
        f"{detail}\n\n"
        "This will break for other developers or bloat the repository.\n\n"
        "Proceed anyway?"
    )
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason
        }
    }
    print(json.dumps(output))
    sys.exit(0)


def is_allowed_path_file(file_path: str) -> bool:
    """Check if file is in an allowed location for hardcoded paths."""
    for allowed in ALLOWED_PATH_FILES:
        if allowed in file_path:
            return True
    return False


def detect_issues(file_path: str, content: str) -> tuple[str, str] | None:
    """Detect portability issues in file content."""
    if not content:
        return None

    # Check for hardcoded home paths in shell scripts and config files
    shell_extensions = {'.sh', '.bash', '.zsh', ''}
    config_files = {'lefthook', 'husky', '.gitconfig', '.env'}

    path_obj = Path(file_path) if file_path else Path('')
    is_shell_or_config = (
        path_obj.suffix in shell_extensions or
        any(cfg in file_path.lower() for cfg in config_files)
    )

    if is_shell_or_config and not is_allowed_path_file(file_path):
        if HOME_PATH_RE.search(content):
            match = HOME_PATH_RE.search(content)
            return (
                "Hardcoded Home Path",
                f"Found machine-specific path: {match.group(0)}...\n"
                "Other developers have different home directories."
            )
        if WINDOWS_PATH_RE.search(content):
            match = WINDOWS_PATH_RE.search(content)
            return (
                "Hardcoded Windows Path",
                f"Found machine-specific path: {match.group(0)}...\n"
                "This won't work on other machines."
            )

    return None


def check_git_add(tool_input: dict) -> tuple[str, str] | None:
    """Check if git add is trying to add workspace node_modules."""
    command = tool_input.get("command", "")

    if "git add" in command or "git stage" in command:
        if WORKSPACE_NODE_MODULES_RE.search(command):
            return (
                "Workspace node_modules in git",
                "Attempting to add workspace package node_modules to git.\n"
                "These should be in .gitignore and installed via pnpm."
            )

    return None


def iter_edits(tool_input: dict) -> list[tuple[str, str]]:
    """Extract file paths and content from tool input."""
    edits: list[tuple[str, str]] = []

    file_path = tool_input.get("file_path", "")
    content = tool_input.get("content") or tool_input.get("new_string")
    if file_path or content:
        edits.append((file_path, content or ""))

    for edit in tool_input.get("edits", []) or []:
        edit_path = edit.get("file_path", file_path) or ""
        edit_content = edit.get("content") or edit.get("new_string") or ""
        edits.append((edit_path, edit_content))

    return edits


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}

    # Check Bash commands for git add of node_modules
    if tool_name == "Bash":
        issue = check_git_add(tool_input)
        if issue:
            ask(issue[0], issue[1])

    # Check file writes for hardcoded paths
    if tool_name in ("Edit", "Write", "MultiEdit"):
        for file_path, content in iter_edits(tool_input):
            issue = detect_issues(file_path, content)
            if issue:
                ask(issue[0], issue[1])

    sys.exit(0)


if __name__ == "__main__":
    main()
