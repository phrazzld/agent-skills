#!/usr/bin/env python3
"""Nudge toward /research skill (Exa-first) instead of raw WebSearch.

The /research skill routes through Exa for code context search, which finds
reference implementations — not blog posts. Raw WebSearch should be a
last resort, not the default.

Fires on: PreToolUse for WebSearch.
"""
import json
import sys


def main():
    print(
        json.dumps(
            {
                "decision": "warn",
                "reason": (
                    "STOP — WebSearch alone is not research. Use /research "
                    "(no sub-command) which fans out to Exa + thinktank + xAI "
                    "in parallel. WebSearch is a fallback, not a primary tool. "
                    "If you're inside /research already, you MUST also launch "
                    "thinktank and Exa in parallel — a single WebSearch does "
                    "not satisfy the fanout requirement."
                ),
            }
        )
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
