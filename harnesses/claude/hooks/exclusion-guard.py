#!/usr/bin/env python3
"""
Exclusion guard - prevents lazy path shortcuts.

PreToolUse hook that detects exclusion patterns and requires justification.
Strict mode: ALL exclusion patterns trigger confirmation.

Patterns detected:
- Coverage exclusions (vitest.config, jest.config)
- ESLint disables
- TypeScript @ts-ignore, @ts-expect-error, as any
- Test skips (.skip, xit, xdescribe)
"""
import json
import re
import sys
from pathlib import Path


COVERAGE_CONFIG_RE = re.compile(r'(vitest|jest)\.config', re.IGNORECASE)
EXCLUDE_RE = re.compile(r'\bexclude\s*:', re.IGNORECASE)

ESLINT_DISABLE_RE = re.compile(r'eslint-disable(?:-next-line)?', re.IGNORECASE)
TS_IGNORE_RE = re.compile(r'@ts-ignore', re.IGNORECASE)
TS_EXPECT_ERROR_RE = re.compile(r'@ts-expect-error', re.IGNORECASE)
TS_AS_ANY_RE = re.compile(r'\bas\s+any\b')
TS_COLON_ANY_RE = re.compile(r':\s*any\b')

SKIP_RE = re.compile(r'\.skip\s*\(')
XIT_RE = re.compile(r'\bxit\s*\(')
XDESCRIBE_RE = re.compile(r'\bxdescribe\s*\(')


def ask(pattern_type: str) -> None:
    reason = (
        f"⚠️  Exclusion Pattern Detected: {pattern_type}\n\n"
        "Before excluding, consider:\n"
        "□ Can the code be refactored to be testable?\n"
        "□ Can handler functions be exported and tested with mocks?\n"
        "□ Is this genuinely runtime-only code?\n"
        "□ Are there existing patterns in the codebase for testing similar code?\n\n"
        "If exclusion is truly necessary, document WHY in a comment.\n\n"
        "Proceed with this exclusion?"
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


def detect_pattern(file_path: str, content: str) -> str | None:
    if not content:
        return None

    if file_path and COVERAGE_CONFIG_RE.search(file_path) and EXCLUDE_RE.search(content):
        return "Coverage exclusion"

    if ESLINT_DISABLE_RE.search(content):
        return "ESLint disable"

    if TS_IGNORE_RE.search(content):
        return "TypeScript ignore"

    if TS_EXPECT_ERROR_RE.search(content):
        return "TypeScript expect-error"

    if TS_AS_ANY_RE.search(content) or TS_COLON_ANY_RE.search(content):
        return "TypeScript any"

    if SKIP_RE.search(content) or XIT_RE.search(content) or XDESCRIBE_RE.search(content):
        return "Test skip"

    return None


def iter_edits(tool_input: dict) -> list[tuple[str, str]]:
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

    if tool_name not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    for file_path, content in iter_edits(tool_input):
        normalized_path = str(Path(file_path)) if file_path else ""
        pattern_type = detect_pattern(normalized_path, content)
        if pattern_type:
            ask(pattern_type)

    sys.exit(0)


if __name__ == "__main__":
    main()
