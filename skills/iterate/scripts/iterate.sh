#!/usr/bin/env bash
# /iterate Phase 1 entrypoint: dry-run orchestration of the outer loop.
#
# Real mode (not implemented in Phase 1) shells out to /shape, /autopilot,
# /code-review, /qa, /deploy, /reflect. Dry-run walks all 9 phases and writes
# one event per phase — this exists so contract #5 (≥ cycle.opened
# and cycle.closed in cycle.jsonl) is verifiable without burning model budget.
#
# Flags:
#   --max-cycles N    (default 1)
#   --budget $N       (refuse if N cycles > 1 without this)
#   --dry-run         (no real phase handlers; write events only)
#
# Phase 2 flags (stubbed, not implemented):
#   --until <pred>, --resume <ulid>, --abandon <ulid>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Anchor all relative paths (cycle dir, default lock path) to REPO_ROOT so
# invocations from outside the repo can't corrupt a $PWD-shaped state tree.
# Callers who override ITERATE_LOCK_PATH should pass an absolute path.
cd "$REPO_ROOT"

# shellcheck source=../../../scripts/lib/events.sh
source "$REPO_ROOT/scripts/lib/events.sh"
# shellcheck source=../../../scripts/lib/iterate_lock.sh
source "$REPO_ROOT/scripts/lib/iterate_lock.sh"

DRY_RUN=0
MAX_CYCLES=1
BUDGET=""

# Phase 2 flags — parsed but not wired to prevent "silent flag drift" where
# someone adds --resume and it ghost-succeeds.
UNTIL=""
RESUME=""
ABANDON=""

usage() {
  cat >&2 <<EOF
/iterate — outer-loop workflow orchestrator (Phase 1)

Usage: iterate.sh [--dry-run] [--max-cycles N] [--budget \$N]

Phase 1 supports --dry-run only in full end-to-end mode. Real mode shells
out to /shape, /autopilot, /code-review, /qa, /deploy, /reflect and will
fail loudly if any is missing (no auto-scaffold in Phase 1).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)      DRY_RUN=1; shift ;;
    --max-cycles)   MAX_CYCLES="${2:?--max-cycles needs N}"; shift 2 ;;
    --budget)       BUDGET="${2:?--budget needs \$N}"; shift 2 ;;
    --until)        UNTIL="${2:?}"; shift 2 ;;
    --resume)       RESUME="${2:?}"; shift 2 ;;
    --abandon)      ABANDON="${2:?}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "iterate: unknown flag '$1'" >&2; usage; exit 2 ;;
  esac
done

# Phase 2 guards — fail loud rather than silently ignore.
if [ -n "$UNTIL" ]; then
  echo "iterate: --until is Phase 2; not implemented" >&2; exit 2
fi
if [ -n "$RESUME" ] || [ -n "$ABANDON" ]; then
  echo "iterate: --resume/--abandon are Phase 2; not implemented" >&2; exit 2
fi

# Phase 1 is strictly single-cycle. A multi-cycle outer loop would need to
# either hold the lock across cycles (currently released between cycles, so
# a second iterate could sneak in) or re-acquire it, neither of which is
# implemented. Carmack cut: reject >1 loudly until Phase 2 wires the logic.
# We keep --max-cycles and --budget in the parser so Phase 2 can flip this
# guard without breaking any callers.
if [ "$MAX_CYCLES" -ne 1 ]; then
  echo "iterate: --max-cycles > 1 is Phase 2; not yet implemented" >&2
  exit 2
fi

# ULID generation. Prefer python-ulid if present; otherwise emit a real
# Crockford-base32 ULID (10 chars timestamp + 16 chars randomness = 26 chars),
# lexicographically sortable and interchangeable with the library output.
new_ulid() {
  python3 - <<'PYEOF'
try:
    import ulid
    print(str(ulid.new()))
except Exception:
    import secrets, time
    CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    def _enc(v, n):
        out = []
        for _ in range(n):
            out.append(CROCKFORD[v & 0x1F]); v >>= 5
        return "".join(reversed(out))
    ts = int(time.time() * 1000) & ((1 << 48) - 1)
    rnd = secrets.randbits(80)
    print(_enc(ts, 10) + _enc(rnd, 16))
PYEOF
}

run_cycle() {
  local cycle_id cycle_dir log
  cycle_id="$(new_ulid)"
  cycle_dir="backlog.d/_cycles/$cycle_id"
  log="$cycle_dir/cycle.jsonl"

  # Acquire lock BEFORE materializing cycle dir — a failed acquire must not
  # orphan backlog.d/_cycles/<ulid>/ trees on disk.
  if ! iterate_acquire "$cycle_id"; then
    echo "iterate: could not acquire lock" >&2
    return 1
  fi
  mkdir -p "$cycle_dir/evidence"
  # Release on any exit path — SIGINT, normal return, or failure. Scoped to
  # this cycle_id so traps don't clobber a successor. Bash's default after
  # an INT/TERM handler is to resume the script, not exit — we must exit
  # explicitly to honor the SKILL.md contract (SIGINT → 130, SIGTERM → 143).
  # shellcheck disable=SC2064  # we want $cycle_id expanded now
  trap "iterate_release '$cycle_id'" EXIT
  # shellcheck disable=SC2064
  trap "iterate_release '$cycle_id'; exit 130" INT
  # shellcheck disable=SC2064
  trap "iterate_release '$cycle_id'; exit 143" TERM

  # Test hook: if ITERATE_SIGINT_TEST_SLEEP is set, pause after acquire so
  # integration tests can reliably fire SIGINT against the cycle. No effect
  # in normal operation (env var unset).
  if [ -n "${ITERATE_SIGINT_TEST_SLEEP:-}" ]; then
    sleep "$ITERATE_SIGINT_TEST_SLEEP"
  fi

  emit_event "$log" cycle.opened pick orchestrator \
    "{\"note\":\"cycle started (dry_run=$DRY_RUN)\"}"

  if [ "$DRY_RUN" -eq 1 ]; then
    # Walk phases 1-9 from 028 control flow. Each phase is a no-op that
    # writes a placeholder event so the full event trail is exercised.
    emit_event "$log" shape.done         shape   planner       '{"note":"dry-run"}'
    emit_event "$log" build.done         build   builder       '{"note":"dry-run"}'
    emit_event "$log" review.iter        review  critic        '{"note":"dry-run","iter":1}'
    emit_event "$log" ci.done            ci      dagger        '{"note":"dry-run"}'
    emit_event "$log" qa.done            qa      qa            '{"note":"dry-run"}'
    emit_event "$log" deploy.done        deploy  deployer      '{"note":"dry-run"}'
    emit_event "$log" reflect.done       reflect reflector     '{"note":"dry-run"}'
    # harness.suggested is a Phase 2 event (writes to a branch, not dry-run).
    # Emitting it here would train the wrong mental model of the contract.
  else
    # Real mode: each phase shells out to the corresponding slash command.
    # Phase 1 does not auto-scaffold missing skills (that's Phase 3), so if
    # any handler is missing we write phase.failed, release the lock via trap,
    # and exit non-zero.
    echo "iterate: real mode not yet wired in Phase 1 — use --dry-run" >&2
    emit_event "$log" phase.failed pick orchestrator \
      '{"note":"real mode unimplemented in Phase 1","reason":"phase-1-scope"}'
    emit_event "$log" cycle.closed close orchestrator '{"status":"aborted"}'
    iterate_release "$cycle_id"
    trap - EXIT INT TERM
    return 1
  fi

  emit_event "$log" cycle.closed close orchestrator \
    "{\"status\":\"closed\",\"cycle_id\":\"$cycle_id\"}"

  iterate_release "$cycle_id"
  trap - EXIT INT TERM
  echo "$cycle_id"
}

# Phase 1: exactly one cycle. The guard above rejects MAX_CYCLES != 1.
run_cycle
