#!/usr/bin/env python3
"""Block PR comments that excuse broken things instead of fixing them.

Catches the pattern: diagnose a problem correctly, then rationalize not fixing
it by labeling it "pre-existing", "not introduced by this PR", etc.

The origin of a bug is irrelevant. If you found it, fix it.

Fires on: PreToolUse for Bash commands containing `gh pr comment`.
"""
import json
import re
import sys

EXCUSE_PATTERNS = [
    r"pre-existing",
    r"not introduced by this (PR|branch|change)",
    r"not from this (PR|branch|change)",
    r"not caused by this (PR|branch|change)",
    r"exists on (master|main)",
    r"already (existed|present|broken) (on|in|before)",
    r"predates this",
    r"unrelated to (this|the) (PR|change)",
    r"outside the scope of this",
]

COMBINED = re.compile("|".join(EXCUSE_PATTERNS), re.IGNORECASE)


def main():
    data = json.loads(sys.stdin.read())
    tool_input = data.get("tool_input", {})
    command = tool_input.get("command", "")

    if "gh pr comment" not in command and "gh api" not in command:
        return

    # --body-file means content is in a file, not the command string — skip
    if "--body-file" in command or "--body-file=" in command:
        return

    # Only check gh api calls that post comments
    if "gh api" in command and "/comments" not in command:
        return

    if COMBINED.search(command):
        print(
            json.dumps(
                {
                    "decision": "block",
                    "reason": (
                        "BLOCKED: You diagnosed a broken thing and are excusing it "
                        "instead of fixing it. Origin is irrelevant — fix what you "
                        "touch. Fix the problem first, then comment about the fix."
                    ),
                }
            )
        )
        sys.exit(0)

    # Catch "not a blocker" paired with failure language, but only when
    # there's no linked issue (which indicates proper tracking)
    if re.search(r"not (a )?block(er|ing)", command, re.IGNORECASE) and re.search(
        r"fail(ure|ing|ed)", command, re.IGNORECASE
    ) and not re.search(r"(#\d+|github\.com/.+/issues/\d+)", command):
        print(
            json.dumps(
                {
                    "decision": "block",
                    "reason": (
                        "BLOCKED: A failing check IS a blocker. Fix it, or file a "
                        "tracking issue and link it (e.g., 'tracked in #123')."
                    ),
                }
            )
        )
        sys.exit(0)


if __name__ == "__main__":
    main()
