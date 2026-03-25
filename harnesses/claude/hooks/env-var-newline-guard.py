#!/usr/bin/env python3
"""
Environment variable newline guard for Claude Code.

Blocks `echo` piped to env-setting commands because echo appends a newline
that silently corrupts secrets/API keys.

Use printf '%s' instead: printf '%s' "value" | vercel env add NAME
Or heredoc without trailing newline.

PreToolUse hook - runs before Bash commands execute.
"""
import json
import re
import sys

# Commands that set environment variables and are sensitive to trailing newlines
ENV_SETTERS = [
    "vercel env add",
    "vercel env set",
    "npx convex env set",
    "convex env set",
    "flyctl secrets set",
    "fly secrets set",
    "heroku config:set",
    "railway variables set",
    "netlify env:set",
    "wrangler secret put",
    "doppler secrets set",
    "infisical secrets set",
    "vault kv put",
    "aws ssm put-parameter",
    "gcloud secrets",
    "az keyvault secret set",
]

# Pattern: echo (with or without flags, but NOT -n) piped to something
# Matches: echo "foo" | ..., echo foo | ..., echo $VAR | ...
# Does NOT match: echo -n "foo" | ... (that's safe)
ECHO_PIPE_PATTERN = re.compile(
    r'\becho\s+'           # echo followed by space
    r'(?!-n\b|-en\b)'      # NOT followed by -n or -en (safe flags)
    r'[^|]*'               # anything until pipe
    r'\|'                  # pipe character
)


def check_command(cmd: str) -> tuple[bool, str]:
    """
    Check if command uses echo (without -n) piped to an env setter.
    Returns (should_block, reason).
    """
    if not cmd:
        return False, ""

    # Must have echo piped to something
    if not ECHO_PIPE_PATTERN.search(cmd):
        return False, ""

    # Check if any env setter is in the command
    cmd_lower = cmd.lower()
    for setter in ENV_SETTERS:
        if setter.lower() in cmd_lower:
            return True, (
                f"`echo` adds a trailing newline that corrupts env vars.\n\n"
                f"Use printf instead:\n"
                f"  printf '%s' \"value\" | {setter.split()[0]} ...\n\n"
                f"Or echo -n (bash-specific):\n"
                f"  echo -n \"value\" | {setter.split()[0]} ..."
            )

    return False, ""


def deny(cmd: str, reason: str) -> None:
    """Output deny decision and exit."""
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"BLOCKED: {reason}\n\n"
                f"Command: {cmd}"
            )
        }
    }
    print(json.dumps(output))
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    tool_input = data.get("tool_input") or {}
    cmd = tool_input.get("command", "")

    if not isinstance(cmd, str) or not cmd:
        sys.exit(0)

    should_block, reason = check_command(cmd)

    if should_block:
        deny(cmd, reason)

    sys.exit(0)


if __name__ == "__main__":
    main()
