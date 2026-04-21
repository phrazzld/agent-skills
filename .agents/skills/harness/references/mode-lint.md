# /harness lint (in spellbook)

Validate a skill against spellbook's 12 Dagger gates plus the design
principles the gates don't directly enforce. "Lint" here is specific:
reproduce the gate locally, read the failure, fix at root.

## The load-bearing command

```
dagger call check --source=.
```

Runs all 12 gates in parallel. If this is green, the repo is
merge-ready from a CI perspective. Individual gates are also callable:

```
dagger call lint-yaml                   --source=.
dagger call lint-shell                  --source=.
dagger call lint-python                 --source=.
dagger call check-frontmatter           --source=.
dagger call check-index-drift           --source=.
dagger call check-vendored-copies       --source=.
dagger call test-bun                    --source=.
dagger call check-exclusions            --source=.
dagger call check-portable-paths        --source=.
dagger call check-harness-install-paths --source=.
dagger call check-deliver-composition   --source=.
dagger call check-no-claims             --source=.
```

When a single lint-class gate fails, the self-healing path is:

```
dagger call heal --source=. --model=gpt-4.1 --attempts=2
```

Bounded LLM repair of one gate. Use when the failure is a typo-class
issue the model can fix in one pass. If the fix requires design, heal
will not help — do it yourself.

## Gate-by-gate acceptance

| Gate | What it enforces | Fix when it fails |
|------|------------------|-------------------|
| `lint-yaml` | Top-2-level `*.yaml`/`*.yml` parse | Fix YAML syntax in the named file |
| `lint-shell` | `shellcheck --severity=error` on all non-`ci/` `.sh` | Address the reported shellcheck rule; never suppress |
| `lint-python` | `py_compile` on all non-`ci/` `.py` | Fix syntax/import error |
| `check-frontmatter` | `scripts/check-frontmatter.py` — required `name`/`description` + SKILL.md ≤500 lines | Add missing fields; extract content to `references/mode-*.md` |
| `check-index-drift` | `index.yaml` matches `scripts/generate-index.sh` output | Re-run `./scripts/generate-index.sh`; pre-commit normally handles this |
| `check-vendored-copies` | Vendored copies match canonical sources | Re-copy from source |
| `test-bun` | `bun test` under `skills/research/` | Fix the failing test |
| `check-exclusions` | No `@ts-ignore`, `.skip()`, `eslint-disable`, `as any` in source | Remove the suppression and fix the underlying issue |
| `check-portable-paths` | No `/Users/<name>/` or `C:\Users\` outside `harnesses/claude/` + `.claude/hooks` | Replace with `$HOME` or `git rev-parse --show-toplevel` |
| `check-harness-install-paths` | `scripts/check-harness-agnostic-installs.sh` — seed/tailor wording | Use "shared skill root" + describe `.claude/skills/` as a "bridge" |
| `check-deliver-composition` | `skills/deliver/SKILL.md` composes atomic phases, never inlines | Replace raw `dagger call check` / `bunx playwright` / direct bench dispatch with `/ci`, `/qa`, `/code-review` |
| `check-no-claims` | No `claims.sh`/`claim_acquire`/`claim_release` under `skills/` | Delete the reference; primitive was dropped per `backlog.d/032` |

## Design-principle checks (not gated, but required)

| Principle | Check |
|-----------|-------|
| **Description triggers** | Does `description:` include concrete utterances users actually say? |
| **Gotchas > procedures** | Does SKILL.md enumerate failure modes, not just happy path? |
| **Judgment test** | Does it encode judgment the model lacks? If not, delete. |
| **Mode bloat** | >3 modes with inline content? Extract to `references/mode-*.md`. |
| **Reference integrity** | Do all `references/*.md` paths cited in the body actually exist? |
| **No sidecars** | No `references/<repo>.md` or `references/spellbook.md`. |
| **Self-containment** | Scripts resolve via `$SCRIPT_DIR`, never `$REPO_ROOT`/`../../..` |
| **Cross-harness** | Works on Claude, Codex, AND Pi at the filesystem layer |
| **Prose for an agent** | No Phase-0/Phase-N state-machine shape. Invariants + shape-of-work. |

## Self-containment: two fast greps

```
rg -n 'source.*\$REPO_ROOT|source.*/scripts/lib/' skills/*/scripts/
rg -n 'SCRIPT_DIR/\.\./\.\.' skills/*/scripts/
```

Either match is a lint failure. The fix is structural — move the lib
into `skills/<name>/scripts/lib/`, not suppress the grep.

## The distribution smoke test

A scripted skill should ship `skills/<name>/scripts/distribution_test.sh`
that symlinks the skill into a throwaway project and verifies `--help`
runs from there. In-repo success is a false positive — the canonical
test is symlink-install + invoke from a foreign repo.

## Batch lint

```
for s in skills/*/SKILL.md; do /harness lint "$s"; done
```

Scoped across the full catalog. Pair with `/harness audit` to find
zero-invocation skills that survive lint but earn nothing.
