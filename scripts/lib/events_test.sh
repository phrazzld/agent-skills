#!/usr/bin/env bash
# Tests for events.sh — typed event log append.
# Runs in a temp dir to avoid polluting the real repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

setup() {
  ORIG_DIR="$(pwd)"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  # shellcheck source=scripts/lib/events.sh
  source "$SCRIPT_DIR/events.sh"
  CYCLE_DIR="$TEST_DIR/_cycles/01HTESTCYCLE00000000000000"
  mkdir -p "$CYCLE_DIR"
  LOG="$CYCLE_DIR/cycle.jsonl"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "  PASS  $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL  $desc (expected '$expected', got '$actual')"
  fi
}

assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local actual
  if "$@" >/dev/null 2>&1; then actual=0; else actual=$?; fi
  assert_eq "$desc" "$expected" "$actual"
}

# --- Tests ---

test_emit_event_appends_jsonl_line() {
  emit_event "$LOG" cycle.opened shape planner '{"note":"hello"}'
  local count
  count="$(wc -l < "$LOG" | tr -d ' ')"
  assert_eq "emit_event writes exactly one line" "1" "$count"
}

test_emit_event_writes_required_fields() {
  emit_event "$LOG" cycle.opened shape planner '{"note":"hi"}'
  local kind
  kind="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['kind'])" < "$LOG")"
  assert_eq "emit_event persists kind" "cycle.opened" "$kind"
  local phase
  phase="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['phase'])" < "$LOG")"
  assert_eq "emit_event persists phase" "shape" "$phase"
  local agent
  agent="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['agent'])" < "$LOG")"
  assert_eq "emit_event persists agent" "planner" "$agent"
}

test_emit_event_sets_schema_version() {
  emit_event "$LOG" cycle.opened shape planner '{}'
  local v
  v="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['schema_version'])" < "$LOG")"
  assert_eq "schema_version is 1" "1" "$v"
}

test_emit_event_sets_timestamp() {
  emit_event "$LOG" cycle.opened shape planner '{}'
  local ts
  ts="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['ts'])" < "$LOG")"
  # ISO 8601 UTC, zulu time. Basic shape check: contains 'T' and ends with 'Z'.
  case "$ts" in
    *T*Z) assert_eq "ts is ISO-8601 UTC" "ok" "ok" ;;
    *)    assert_eq "ts is ISO-8601 UTC" "ok" "bad:$ts" ;;
  esac
}

test_emit_event_derives_cycle_id_from_path() {
  emit_event "$LOG" cycle.opened shape planner '{}'
  local cid
  cid="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['cycle_id'])" < "$LOG")"
  assert_eq "cycle_id comes from parent dir" "01HTESTCYCLE00000000000000" "$cid"
}

test_emit_event_rejects_unknown_kind() {
  assert_exit "emit_event rejects unknown kind" 1 emit_event "$LOG" bogus.kind shape planner '{}'
}

test_emit_event_rejects_empty_kind() {
  assert_exit "emit_event rejects empty kind" 1 emit_event "$LOG" "" shape planner '{}'
}

test_emit_event_rejects_empty_phase() {
  assert_exit "emit_event rejects empty phase" 1 emit_event "$LOG" cycle.opened "" planner '{}'
}

test_emit_event_rejects_bad_payload_json() {
  assert_exit "emit_event rejects malformed payload" 1 emit_event "$LOG" cycle.opened shape planner 'not json'
}

test_emit_event_appends_multiple_lines() {
  emit_event "$LOG" cycle.opened   shape  planner '{}'
  emit_event "$LOG" shape.done     shape  planner '{}'
  emit_event "$LOG" build.done     build  builder '{}'
  emit_event "$LOG" cycle.closed   close  orchestrator '{}'
  local count
  count="$(wc -l < "$LOG" | tr -d ' ')"
  assert_eq "multiple events all appended" "4" "$count"
}

test_emit_event_payload_cannot_override_core_envelope() {
  # Adversarial payload tries to clobber every envelope field. Envelope must
  # win — consumers key on these, silent override would let a malicious or
  # buggy phase forge event identity.
  emit_event "$LOG" cycle.opened shape planner \
    '{"kind":"attacker","cycle_id":"fake","ts":"1999-01-01T00:00:00Z","agent":"evil","schema_version":999,"phase":"hijacked"}'
  local kind cid ts agent sv phase
  kind="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['kind'])" < "$LOG")"
  cid="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['cycle_id'])" < "$LOG")"
  ts="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['ts'])" < "$LOG")"
  agent="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['agent'])" < "$LOG")"
  sv="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['schema_version'])" < "$LOG")"
  phase="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['phase'])" < "$LOG")"
  assert_eq "payload cannot override kind" "cycle.opened" "$kind"
  assert_eq "payload cannot override cycle_id" "01HTESTCYCLE00000000000000" "$cid"
  assert_eq "payload cannot override agent" "planner" "$agent"
  assert_eq "payload cannot override schema_version" "1" "$sv"
  assert_eq "payload cannot override phase" "shape" "$phase"
  case "$ts" in
    1999-*) assert_eq "payload cannot override ts" "ok" "bad:$ts" ;;
    *T*Z)   assert_eq "payload cannot override ts" "ok" "ok" ;;
    *)      assert_eq "payload cannot override ts" "ok" "bad:$ts" ;;
  esac
}

test_emit_event_merges_payload_fields() {
  emit_event "$LOG" shape.done shape planner '{"refs":["a","b"],"note":"ok"}'
  local refs note
  refs="$(python3 -c "import json,sys; print(','.join(json.loads(sys.stdin.read())['refs']))" < "$LOG")"
  note="$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['note'])" < "$LOG")"
  assert_eq "payload refs merged" "a,b" "$refs"
  assert_eq "payload note merged" "ok" "$note"
}

test_emit_event_all_known_kinds_accepted() {
  local kinds=(
    cycle.opened shape.done build.done review.iter ci.done
    qa.done deploy.done reflect.done harness.suggested
    phase.failed budget.exhausted cycle.closed
  )
  local all_ok=0
  for k in "${kinds[@]}"; do
    if ! emit_event "$LOG" "$k" test test '{}' >/dev/null 2>&1; then
      all_ok=1
      echo "    kind rejected: $k"
    fi
  done
  assert_eq "all 12 known kinds accepted" "0" "$all_ok"
}

test_emit_event_each_line_parses_as_json() {
  emit_event "$LOG" cycle.opened shape planner '{}'
  emit_event "$LOG" shape.done shape planner '{"note":"a"}'
  emit_event "$LOG" cycle.closed close orchestrator '{}'
  local ok
  ok="$(python3 -c "
import json, sys
bad = 0
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try: json.loads(line)
    except Exception: bad += 1
print(bad)
" < "$LOG")"
  assert_eq "all JSONL lines parse" "0" "$ok"
}

test_emit_event_concurrent_writes_no_corruption() {
  # Two shell children append simultaneously. Atomic flock should serialize.
  (
    for i in 1 2 3 4 5; do
      emit_event "$LOG" cycle.opened shape planner "{\"note\":\"a$i\"}"
    done
  ) &
  local pid_a=$!
  (
    for i in 1 2 3 4 5; do
      emit_event "$LOG" shape.done shape planner "{\"note\":\"b$i\"}"
    done
  ) &
  local pid_b=$!
  wait "$pid_a" "$pid_b"
  local total bad
  total="$(wc -l < "$LOG" | tr -d ' ')"
  bad="$(python3 -c "
import json, sys
bad = 0
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try: json.loads(line)
    except Exception: bad += 1
print(bad)
" < "$LOG")"
  assert_eq "concurrent writes produce 10 lines" "10" "$total"
  assert_eq "concurrent writes produce 0 corrupt lines" "0" "$bad"
}

# --- Runner ---

run_tests() {
  local funcs
  funcs="$(declare -F | awk '/test_/{print $3}')"
  for t in $funcs; do
    setup
    "$t"
    teardown
  done

  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}

run_tests
