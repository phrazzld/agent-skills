# Flaky test: symlink rejection races against timeout on CI

Priority: medium
Status: pending
Estimate: XS

## Goal

Fix `test/thinktank/executor/agentic_test.exs:101` — "rejects trusted agent
config trees that contain symlinks" — which flakes on CI when symlink
validation is slower than the 5s `timeout_ms`.

## Evidence

- CI run 23948998517 (2026-04-03): test expected `:crash` but got `:timeout`
- Same SHA (4bf2978) passed on the second CI run (23948999560)
- Seed 406239 triggered the failure
- The test sets `timeout_ms: 5_000` on the agent spec; symlink validation
  runs inside the agent subprocess. On slow CI runners, the timeout fires
  before the validation crash propagates.

## Root Cause

Symlink validation happens after subprocess launch, inside `run_once/4`. When
the subprocess is slow to start (CI resource contention, Erlang/OTP 28.0
regex recompilation overhead noted in the same log), the 5s timeout fires
first. The error gets classified as `:timeout` instead of `:crash`.

## Fix Options

1. **Increase timeout_ms in the test** to 15_000. Cheapest fix, but masks
   the real issue — validation should happen before subprocess launch.
2. **Move symlink validation before subprocess launch** — fail fast in
   `run_agent/7` before spawning the task. This makes the timeout irrelevant
   for config validation failures. Preferred fix.
3. **Tag the test `@tag :slow`** and increase timeout. Least preferred.

## Oracle

- [ ] `mix test test/thinktank/executor/agentic_test.exs:101 --seed 406239` passes 10/10 runs
- [ ] Symlink rejection is not racing against timeout (validation happens pre-launch or timeout is generous)
- [ ] No other tests broken
