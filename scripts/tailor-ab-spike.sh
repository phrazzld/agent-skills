#!/usr/bin/env bash
# tailor-ab-spike.sh — Commit 0 spike for ticket 029.
#
# Validates the load-bearing measurement for /tailor's A/B killswitch:
# can we run a canned task headlessly via `claude -p --output-format
# stream-json` and capture {tool_calls, wall_s, passed}?
#
# Acceptance (from backlog.d/029-tailor-per-repo-harness-generator.md):
#   - Emits JSON {"tool_calls": N, "wall_s": F, "passed": BOOL}
#   - tool_calls is a non-negative integer counted from assistant
#     message content blocks where type == "tool_use"
#   - wall_s is duration_ms / 1000 from the terminal result event
#   - passed derives from result.is_error (true → passed=false)
#
# If this script returns a well-formed measurement for a tool-using
# canned task, /tailor MVP can proceed to Commit 1 (tailor-lint.sh).
# If stream-json parsing, tool-use counting, or duration capture fail,
# the MVP must pivot to Alt C (LLM-as-judge) before further work.
#
# Usage:
#   scripts/tailor-ab-spike.sh [task_prompt]
#
# Env:
#   TAILOR_AB_BUDGET_USD  (default: 0.40) — cost cap per run
#   TAILOR_AB_CWD         (default: $PWD) — workdir for the headless run
#   TAILOR_AB_DEBUG=1     → dump last 3 stream lines to stderr before parse
#
# Example:
#   TAILOR_AB_BUDGET_USD=0.50 scripts/tailor-ab-spike.sh \
#     "Read bootstrap.sh and report its line count. Number only."

set -euo pipefail

TASK="${1:-Use the Read tool to read bootstrap.sh in the current directory, then output ONLY its total line count as a single integer with no other text.}"
BUDGET="${TAILOR_AB_BUDGET_USD:-0.40}"
RUN_CWD="${TAILOR_AB_CWD:-$PWD}"

command -v claude >/dev/null 2>&1 || {
  echo 'claude CLI not on PATH' >&2
  exit 2
}

# stdout captures the JSONL event stream for parsing; stderr is suppressed
# because claude -p writes warnings/info there that would pollute the pipe.
# Use TAILOR_AB_DEBUG=1 to see the tail of the stream if a run fails.
raw=$(cd "$RUN_CWD" && claude -p "$TASK" \
  --output-format stream-json \
  --verbose \
  --max-budget-usd "$BUDGET" \
  --permission-mode bypassPermissions \
  2>/dev/null) || {
    # claude returns non-zero on budget-exceed or internal error; still
    # try to parse whatever partial stream arrived so we can report it.
    true
  }

if [ "${TAILOR_AB_DEBUG:-0}" = "1" ]; then
  printf '%s\n' "$raw" | tail -3 >&2
fi

python3 -c '
import json, sys

tool_calls = 0
wall_ms = 0
is_error = True
result_seen = False

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except json.JSONDecodeError:
        continue

    if ev.get("type") == "assistant":
        msg = ev.get("message") or {}
        for block in msg.get("content") or []:
            if isinstance(block, dict) and block.get("type") == "tool_use":
                tool_calls += 1

    if ev.get("type") == "result":
        result_seen = True
        wall_ms = ev.get("duration_ms", 0) or 0
        is_error = bool(ev.get("is_error", True))

if not result_seen:
    print(json.dumps({
        "tool_calls": tool_calls,
        "wall_s": None,
        "passed": None,
        "error": "no result event in stream",
    }))
    sys.exit(1)

print(json.dumps({
    "tool_calls": tool_calls,
    "wall_s": round(wall_ms / 1000.0, 3),
    "passed": not is_error,
}))
' <<<"$raw"
