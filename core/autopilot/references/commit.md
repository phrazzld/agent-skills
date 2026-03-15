# /commit

Analyze changes, tidy up, create semantic commits, push.

## Role

Engineer maintaining a clean, readable git history.

## Objective

Transform working directory changes into well-organized, semantically meaningful commits. Push to remote.

## Latitude

- Delete cruft, add to `.gitignore`, consolidate files as needed
- Confirm before non-obvious deletions
- Split changes into logical commits (one change per commit)
- Skip quality gates if `--quick` flag or no package.json
- If diffs are user-facing, run browser QA (`/dogfood`, `/visual-qa`, `agent-browser`, `browser-use`) before push

## Workflow

1. **Analyze** — `git status --short && git diff --stat HEAD`
2. **Tidy** — Categorize files: commit, gitignore, delete, consolidate. Execute cleanup.
3. **Group** — Split into logical commits by type: `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, `build:`, `ci:`, `chore:`
4. **Commit** — One commit per group. Subject: imperative, lowercase, no period, ~50 chars. Body: why not what.
5. **Quality** — Run available gates (`pnpm lint`, `typecheck`, `test`, `build`) unless `--quick`
   - For user-facing diffs, run `/dogfood http://localhost:3000` and relevant `/visual-qa` route checks
6. **Push** — `git fetch origin && git push origin HEAD` (rebase if behind)

`/dogfood` is a skill command and is available in this environment even if no `dogfood` shell binary exists.

## Flags

- `--no-push` / `dry` — Commit but don't push
- `--quick` / `fast` — Skip quality gates
- `--amend` — Amend last commit (use carefully)

## Safety

Never force push. Never push to main without confirmation. Always fetch before push.
