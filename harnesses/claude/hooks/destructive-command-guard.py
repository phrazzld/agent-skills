#!/usr/bin/env python3
"""
Destructive command guard for Claude Code.

Blocks dangerous git and filesystem commands that can lose uncommitted work.
PreToolUse hook - runs before Bash commands execute.

Exit 0 + JSON with permissionDecision: "deny" = block the command
Exit 0 + no output = allow the command
"""
import json
import re
import subprocess
import sys

# Regex patterns for commands that need smarter matching
# These match the command only when it appears as an actual command invocation,
# not as a substring inside strings, commit messages, or other content.
#
# Matches: rm file, ls && rm file, $(rm file), `rm file`, ; rm file, | xargs rm
# Does NOT match: git commit -m "form optimization", echo "inform user"
RM_COMMAND_PATTERN = re.compile(
    r'(^|[;&|`]|\$\()\s*rm\s',
    re.MULTILINE
)

# Simple substring patterns - these are specific enough to not need regex
# (they won't accidentally match normal text)
DESTRUCTIVE_SUBSTRINGS = [
    # Git commands
    # NOTE: git checkout -- <specific-file> is handled by SAFE_CHECKOUT_PATTERN below.
    # Only git checkout -- . (whole-directory discard) is blocked here via check_checkout_discard().
    # ("git checkout -- ", ...) — replaced by smarter check below
    ("git reset --hard", "Destroys all uncommitted work. Use 'git stash' first."),
    ("git clean -f", "Deletes untracked files permanently. Use 'git clean -n' to preview first."),
    ("git push --force", "Overwrites remote history. Use '--force-with-lease' instead."),
    ("git push -f ", "Overwrites remote history. Use '--force-with-lease' instead."),
    # git branch -D is handled by check_branch_delete() — only protects main/master
    ("git stash drop", "Permanently deletes stashed changes."),
    ("git stash clear", "Permanently deletes ALL stashed changes."),
    # GitHub CLI commands - equally destructive as their git equivalents
    ("gh repo delete", "Permanently deletes repository. Extremely destructive."),
    # gh release delete — allowed; draft releases are ephemeral (QA evidence, etc.)
    ("gh issue delete", "Permanently deletes an issue."),
    ("gh repo archive", "Archives repository, making it read-only."),
]

# Patterns that need word boundary checking (could appear in strings)
DESTRUCTIVE_PATTERNS = [
    # (regex_pattern, reason)
    (re.compile(r'(^|[;&|`]|\$\()\s*git\s+restore\s+(?!--staged|-S)'),
     "git restore can discard uncommitted changes. Use 'git restore --staged' for safe unstaging."),
]

# Flags that are dangerous anywhere in the command
DANGEROUS_FLAGS = [
    ("--no-verify", "Skips git hooks. Hooks enforce quality gates."),
    ("--no-gpg-sign", "Skips commit signing. May violate repo policy."),
]

# Patterns that override DESTRUCTIVE (checked first)
SAFE = [
    "git checkout -b",         # new branch
    "git checkout --orphan",   # orphan branch
    "git restore --staged",    # unstaging is safe
    "git restore -S",          # unstaging short form
    "git clean -n",            # dry run
    "git clean --dry-run",     # dry run long form
    "--force-with-lease",      # safe force push
    "--force-if-includes",     # safe force push variant
]

def get_current_branch() -> str | None:
    """Get current git branch name, or None if not in a repo."""
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def is_protected_branch(branch: str | None) -> bool:
    """Check if branch is a protected main branch."""
    if not branch:
        return False
    return branch in ("main", "master")


def check_merge_protection(cmd: str) -> tuple[bool, str]:
    """
    Merge protection: only block merges when currently ON a protected branch.
    Feature branches can merge anything freely (remote tracking, other branches, etc.)
    """
    merge_match = re.match(r"^git\s+merge\s+(\S+)", cmd)
    if not merge_match:
        return False, ""

    current_branch = get_current_branch()

    # If on a protected branch, block all merges (use PRs)
    if is_protected_branch(current_branch):
        return True, (
            f"Merging into {current_branch} is blocked. "
            "Create a PR instead."
        )

    # On a feature branch: allow all merges freely
    return False, ""


def check_push_protection(cmd: str) -> tuple[bool, str]:
    """Block pushes to protected branches. Only PRs can update main/master."""
    push_match = re.match(r"^git\s+push\b(.*)$", cmd)
    if not push_match:
        return False, ""

    push_args = push_match.group(1).strip()

    # Case 1: Explicit target (git push origin main/master)
    explicit = re.search(r"\b(\w+)\s+(main|master)\s*$", push_args)
    if explicit:
        return True, (
            f"Direct push to {explicit.group(2)} blocked.\n\n"
            "Use PR workflow:\n"
            "  git push origin <feature-branch>\n"
            "  # Create PR on GitHub"
        )

    # Case 2: Refspec targeting protected (git push origin feature:main)
    refspec = re.search(r":\s*(main|master)\b", push_args)
    if refspec:
        return True, f"Refspec targeting {refspec.group(1)} blocked. Use PR workflow."

    # Case 3: Implicit push while on protected branch
    current = get_current_branch()
    if is_protected_branch(current):
        # Check if there's an explicit branch target
        # Patterns like "origin feature-branch" or "-u origin feature"
        has_branch = re.search(r"\b\w+\s+[\w\-/]+\s*$", push_args)
        if not has_branch:
            return True, (
                f"On {current}. Direct push blocked.\n\n"
                "Switch to feature branch first:\n"
                "  git checkout -b <feature>\n"
                "  git push -u origin <feature>"
            )

    return False, ""


def check_checkout_discard(cmd: str) -> tuple[bool, str]:
    """
    Block 'git checkout -- .' and 'git checkout -- /' (discard everything)
    but allow 'git checkout -- <specific-file>' (restore one file).
    """
    match = re.search(r"git\s+checkout\s+--\s+(.+)", cmd)
    if not match:
        return False, ""
    target = match.group(1).strip()
    # Block broad discards: '.', '/', '*', or empty
    if target in (".", "/", "*") or not target:
        return True, "Discards all uncommitted changes. Use 'git stash' first, or restore specific files."
    # Specific file restore is safe
    return False, ""


def check_branch_delete(cmd: str) -> tuple[bool, str]:
    """Block force-deletion of protected branches. Feature branches are fine."""
    match = re.search(r"git\s+branch\s+-D\s+(.*)", cmd)
    if not match:
        return False, ""
    for branch in match.group(1).split():
        if is_protected_branch(branch):
            return True, f"Force-deleting {branch} is blocked. Protected branch."
    return False, ""


def strip_quoted_content(cmd: str) -> str:
    """
    Remove content inside quotes to avoid false positives from string literals.
    Handles both single and double quotes, and escaped quotes.

    Example: git commit -m "rm all files" -> git commit -m ""
    """
    result = []
    i = 0
    in_single = False
    in_double = False

    while i < len(cmd):
        char = cmd[i]

        # Handle escape sequences
        if char == '\\' and i + 1 < len(cmd):
            if not in_single and not in_double:
                result.append(char)
                result.append(cmd[i + 1])
            i += 2
            continue

        # Handle quote transitions
        if char == '"' and not in_single:
            in_double = not in_double
            result.append(char)  # Keep the quote itself
        elif char == "'" and not in_double:
            in_single = not in_single
            result.append(char)  # Keep the quote itself
        elif not in_single and not in_double:
            result.append(char)
        # If inside quotes, don't append (strip the content)

        i += 1

    return ''.join(result)


def check_command(cmd: str) -> tuple[bool, str]:
    """
    Check if command should be blocked.
    Returns (should_block, reason).
    """
    if not cmd:
        return False, ""

    # Check safe patterns first (allowlist) - check original command
    for safe in SAFE:
        if safe in cmd:
            return False, ""

    # Check merge protection (branch-aware)
    blocked, reason = check_merge_protection(cmd)
    if blocked:
        return True, reason

    # Check push protection (only PRs can update protected branches)
    blocked, reason = check_push_protection(cmd)
    if blocked:
        return True, reason

    # Check branch force-delete (only protect main/master)
    blocked, reason = check_branch_delete(cmd)
    if blocked:
        return True, reason

    # Check git checkout -- (allow specific files, block broad discards)
    blocked, reason = check_checkout_discard(cmd)
    if blocked:
        return True, reason

    # Strip quoted content to avoid false positives from commit messages,
    # echo statements, string literals, etc.
    cmd_stripped = strip_quoted_content(cmd)

    # Check rm command with smart pattern (avoids false positives in strings)
    if RM_COMMAND_PATTERN.search(cmd_stripped):
        return True, "Use /usr/bin/trash instead. Moves to Trash (recoverable). Example: /usr/bin/trash file.txt"

    # Check simple substring patterns (specific enough to not need regex)
    for pattern, reason in DESTRUCTIVE_SUBSTRINGS:
        if pattern in cmd_stripped:
            return True, reason

    # Check regex patterns (for commands that could appear in strings)
    for pattern, reason in DESTRUCTIVE_PATTERNS:
        if pattern.search(cmd_stripped):
            return True, reason

    # Check dangerous flags (these are dangerous anywhere, even in strings,
    # because they might be used in eval or variable expansion)
    for flag, reason in DANGEROUS_FLAGS:
        if flag in cmd:  # Check original, not stripped
            return True, reason

    return False, ""


def deny(cmd: str, reason: str) -> None:
    """Output deny decision and exit."""
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"BLOCKED: {reason}\n\n"
                f"Command: {cmd}\n\n"
                f"Run this yourself if truly needed."
            )
        }
    }
    print(json.dumps(output))
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)  # can't parse, allow

    if data.get("tool_name") != "Bash":
        sys.exit(0)  # not a Bash command, allow

    tool_input = data.get("tool_input") or {}
    cmd = tool_input.get("command", "")

    if not isinstance(cmd, str) or not cmd:
        sys.exit(0)  # no command, allow

    should_block, reason = check_command(cmd)

    if should_block:
        deny(cmd, reason)

    # Allow
    sys.exit(0)


if __name__ == "__main__":
    main()
