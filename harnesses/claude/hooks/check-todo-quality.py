#!/usr/bin/env python3
"""
Claude Code PreToolUse hook to warn when TODO.md contains non-actionable items.

This hook runs before Edit and Write tool calls on TODO.md to remind about
keeping TODOs actionable and avoiding wishful thinking items.
"""

import json
import sys
import re

def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)

        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})

        # Initialize response
        response = {
            "continue": True,  # Don't block the tool call
            "suppressOutput": True  # Don't show raw output in transcript
        }

        # Check for Edit or Write operations on TODO.md
        if tool_name in ["Edit", "Write", "MultiEdit"]:
            file_path = tool_input.get("file_path", "")

            # Check if operating on TODO.md file
            if "TODO.md" in file_path or "todo.md" in file_path.lower():
                # For Edit operations, check the new_string content
                new_content = ""
                if tool_name == "Edit":
                    new_content = tool_input.get("new_string", "")
                elif tool_name == "Write":
                    new_content = tool_input.get("content", "")
                elif tool_name == "MultiEdit":
                    # Check all edits for new_string content
                    edits = tool_input.get("edits", [])
                    new_content = " ".join([edit.get("new_string", "") for edit in edits])

                # Pattern match for non-actionable words
                non_actionable_patterns = [
                    r'\bfuture\b',
                    r'\bmaybe\b',
                    r'\bconsider\b',
                    r'\bpossibly\b',
                    r'\beventually\b',
                    r'\bsomeday\b',
                    r'\bshould\s+probably\b',
                    r'\bmight\s+want\b',
                    r'\bcould\s+be\b',
                    r'\bnice\s+to\s+have\b'
                ]

                # Check for non-actionable patterns in new content
                found_patterns = []
                for pattern in non_actionable_patterns:
                    if re.search(pattern, new_content, re.IGNORECASE):
                        # Extract the actual matched word
                        match = re.search(pattern, new_content, re.IGNORECASE)
                        if match:
                            found_patterns.append(match.group(0))

                # Build warning message if patterns found
                if found_patterns:
                    response["systemMessage"] = (
                        "⚠️ TODO Quality Warning: Detected non-actionable language in TODO.md\n\n"
                        f"Found words/phrases: {', '.join(set(found_patterns))}\n\n"
                        "The Torvalds Test: 'If it's not needed for this PR, it's not a TODO'\n\n"
                        "TODOs should be:\n"
                        "• Actionable - Clear steps that can be done now\n"
                        "• Specific - No ambiguity about what needs doing\n"
                        "• Current - Needed for active work, not 'someday' items\n\n"
                        "Consider moving wishful items to BACKLOG.md instead."
                    )

        # Output the response
        print(json.dumps(response))
        sys.exit(0)

    except Exception as e:
        # On error, allow the tool to continue but log the issue
        error_response = {
            "continue": True,
            "systemMessage": f"Hook error (non-blocking): {str(e)}"
        }
        print(json.dumps(error_response))
        sys.exit(0)

if __name__ == "__main__":
    main()