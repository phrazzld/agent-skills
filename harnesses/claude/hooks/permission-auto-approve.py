#!/usr/bin/env python3
"""
Permission auto-approve hook for Claude Code.

Auto-approves safe, read-only operations to reduce friction.
Blocks/requires confirmation for anything that modifies state.

PreToolUse hook - runs before tool execution.

Exit 0 + JSON with permissionDecision: "allow" = auto-approve
Exit 0 + JSON with permissionDecision: "deny" = block
Exit 0 + no output = use default permission behavior

Boris tip: "Route permission requests to Opus via hook—let it scan for
attacks and auto-approve safe ones."
"""
import json
import os
import re
import sys

# --- AUTO-APPROVE PATTERNS ---
# These are always safe and should never require confirmation

SAFE_BASH_COMMANDS = [
    # Read-only file/dir operations
    r'^ls\b',
    r'^cat\b',
    r'^head\b',
    r'^tail\b',
    r'^less\b',
    r'^more\b',
    r'^wc\b',
    r'^file\b',
    r'^stat\b',
    r'^du\b',
    r'^df\b',
    r'^tree\b',
    r'^find\b.*-print',  # find with print only
    r'^find\b.*-name',   # find by name
    r'^find\b.*-type',   # find by type
    # Safe git operations
    r'^git\s+(status|log|diff|show|branch|remote|tag|stash\s+list)',
    r'^git\s+ls-',       # git ls-files, ls-tree, etc.
    r'^git\s+rev-parse',
    r'^git\s+describe',
    r'^git\s+config\s+--get',
    r'^git\s+config\s+-l',
    r'^git\s+config\s+--list',
    r'^git\s+shortlog',
    r'^git\s+blame',
    r'^git\s+annotate',
    r'^git\s+worktree\s+list',
    # Safe CLI tools
    r'^rg\b',            # ripgrep
    r'^ag\b',            # silver searcher
    r'^fd\b',            # fd-find
    r'^fzf\b',           # fuzzy finder
    r'^jq\b',            # JSON processor
    r'^yq\b',            # YAML processor
    r'^bat\b',           # better cat
    r'^eza?\b',          # better ls
    r'^ast-grep\b',      # semantic grep
    r'^tokei\b',         # code stats
    r'^cloc\b',          # count lines
    r'^scc\b',           # source code counter
    # Package info (read-only)
    r'^npm\s+(list|ls|view|info|outdated|audit)',
    r'^pnpm\s+(list|ls|view|info|outdated|audit)',
    r'^yarn\s+(list|info|outdated|audit)',
    r'^pip\s+(list|show|freeze)',
    r'^cargo\s+(tree|metadata|pkgid)',
    r'^go\s+(list|mod\s+graph)',
    # System info
    r'^uname\b',
    r'^whoami\b',
    r'^hostname\b',
    r'^pwd\b',
    r'^env\b',
    r'^printenv\b',
    r'^echo\s+\$',       # echoing env vars
    r'^which\b',
    r'^whereis\b',
    r'^type\b',
    r'^command\s+-v',
    # Process/system read
    r'^ps\b',
    r'^top\s+-l\s+1',    # one-shot top
    r'^uptime\b',
    r'^date\b',
    r'^cal\b',
    # gh CLI read operations
    r'^gh\s+(repo|issue|pr|release|workflow|run)\s+(view|list|status|diff)',
    r'^gh\s+api\s+.*-X\s+GET',
    r'^gh\s+api\s+[^-]*$',  # gh api without method = GET
    r'^gh\s+auth\s+status',
    # Vercel read operations
    r'^vercel\s+(list|ls|inspect|logs|env\s+ls)',
    r'^vercel\s+--help',
    # Convex read operations
    r'^npx\s+convex\s+(env\s+list|dashboard|logs)',
]

# Compile patterns for efficiency
SAFE_BASH_PATTERNS = [re.compile(p, re.IGNORECASE) for p in SAFE_BASH_COMMANDS]

# --- NEVER AUTO-APPROVE ---
# Even if they match safe patterns, block these

NEVER_APPROVE = [
    r'rm\s',
    r'rmdir\s',
    r'unlink\s',
    r'>\s',              # redirect to file
    r'>>\s',             # append to file
    r'\|\s*tee\b',       # pipe to tee
    r'curl.*-[dXP]',     # curl with POST/PUT/DELETE
    r'wget\s',           # wget downloads
    r'sudo\b',
    r'su\b',
    r'chmod\b',
    r'chown\b',
    r'chgrp\b',
    r'kill\b',
    r'pkill\b',
    r'killall\b',
]

NEVER_APPROVE_PATTERNS = [re.compile(p, re.IGNORECASE) for p in NEVER_APPROVE]


def is_safe_bash(cmd: str) -> bool:
    """Check if bash command is safe for auto-approval."""
    # First check never-approve patterns
    for pattern in NEVER_APPROVE_PATTERNS:
        if pattern.search(cmd):
            return False

    # Then check if it matches any safe pattern
    for pattern in SAFE_BASH_PATTERNS:
        if pattern.match(cmd.strip()):
            return True

    return False


def is_safe_tool(tool_name: str, tool_input: dict) -> bool:
    """Check if tool operation is safe for auto-approval."""
    # Read tool is always safe
    if tool_name == "Read":
        return True

    # Glob and Grep are always safe
    if tool_name in ("Glob", "Grep"):
        return True

    # LS is always safe
    if tool_name == "LS":
        return True

    # Bash needs command inspection
    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        return is_safe_bash(cmd)

    # Task tool - allow exploration agents
    if tool_name == "Task":
        subagent = tool_input.get("subagent_type", "")
        if subagent in ("Explore", "Plan"):
            return True

    # WebFetch and WebSearch are read-only
    if tool_name in ("WebFetch", "WebSearch"):
        return True

    return False


def auto_approve(reason: str = "") -> None:
    """Output approval decision and exit."""
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
        }
    }
    if reason:
        output["hookSpecificOutput"]["permissionDecisionReason"] = reason
    print(json.dumps(output))
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)  # can't parse, use default behavior

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}

    if is_safe_tool(tool_name, tool_input):
        auto_approve(f"Auto-approved: {tool_name} is read-only")

    # For everything else, exit silently to use default permission behavior
    sys.exit(0)


if __name__ == "__main__":
    main()
