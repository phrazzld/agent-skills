# /pr-walkthrough

Capture and attach real evidence to a PR. No markdown busywork.

## Objective

Produce visual artifacts that prove the merge claim. Attach them to the PR body.
The PR description IS the narrative. This skill produces the proof.

## What This Skill Produces

1. **Screenshots** — before/after of the changed surface
2. **GIFs/recordings** — browser interactions, state transitions, workflows
3. **Terminal captures** — test results, command output, type-check proof
4. **PR body update** — `## Reviewer Evidence` with embedded/linked artifacts

What this skill does NOT produce: markdown walkthrough files, prose evidence bundles,
or any committed `.md` files in `walkthrough/` directories. Those are redundant with the PR body.

## Workflow

### 1. Understand the claim

Read the diff, PR body, and changed tests. Identify:
- What surface changed (UI, CLI, API, infra)?
- What's the merge claim? ("new feature", "bug fix", "refactor with parity")
- Is it demoable? (Default: yes for anything user-visible)

### 2. Choose capture method

| Change type | Primary capture | Tool |
|-------------|----------------|------|
| UI/UX feature or fix | Screenshots + GIF of interaction | `claude-in-chrome` or `agent-browser` |
| Motion/animation/transition | Browser GIF recording | `mcp__claude-in-chrome__gif_creator` |
| Static visual delta | Before/after screenshots | `mcp__claude-in-chrome__computer` (screenshot) |
| CLI/terminal behavior | Terminal output capture | `Bash` with output saved to `/tmp` |
| Internal/infra refactor | Test suite output + app happy-path screenshot | Both |
| Behavioral parity claim | App screencast proving the flow still works | Browser GIF + terminal |

### 3. Capture evidence

Run the app on the branch. Capture real execution.

**For UI changes:**
1. Launch the app (`npm start`, `npm run dev`, etc.)
2. Open in browser via `claude-in-chrome` or `agent-browser`
3. Screenshot the before state (if on main) or the after state (if on branch)
4. For interactions: use `gif_creator` to record the flow
5. Save artifacts to `/tmp/pr-evidence/`

**For terminal/infra changes:**
1. Run the proving commands (tests, type-check, build)
2. Capture output to `/tmp/pr-evidence/`
3. If the PR claims "still works," also screenshot the running app

**For before/after:**
- If main is available, capture main state first, then branch state
- If not, describe the before state in the PR body and capture the after

### 4. Attach to PR

Upload artifacts and update the PR body with a `## Reviewer Evidence` section.

**For GitHub PRs:**
- Use `gh pr comment` with uploaded images when possible
- Use `gh pr edit --body` to add the evidence section
- For video/GIF: upload via browser automation to GitHub, or commit to a
  PR-scoped path only as a last resort

**PR body format:**
```
## Reviewer Evidence

[screenshot or GIF embedded here]

- **Claim:** [one sentence]
- **Proof:** [what the artifact shows]
- **Tests:** `[command]` — [result summary]
- **Gap:** [what's not automated, if any]
```

### 5. Verify links work

After updating the PR body, fetch the PR and confirm media renders.
Broken image links are a walkthrough failure.

## Rules

- Never generate markdown files as the walkthrough deliverable
- Every walkthrough must include at least one real capture (screenshot, GIF, or terminal output)
- The PR body is the walkthrough. Attach evidence there, not in committed files
- Prefer screenshots for static proofs, GIFs for interactions
- Don't record video of motionless screens — use screenshots instead
- For UX changes, default to a GIF demo unless it's purely static
- For parity claims ("still works"), show it working
- Store scratch in `/tmp/pr-evidence/` — never commit walkthrough artifacts unless no other delivery works
- If you can't capture the real surface, say so. Don't fake it with prose
- If no automated check protects the demonstrated path, surface it as a quality finding, not just a gap note
- In private repos: use GitHub attachments or `../blob/<ref>/path.png?raw=true` for images. Never use `raw.githubusercontent.com` links or bare repo-relative asset paths

## References

- `pr-walkthrough-contract.md` — renderer selection rubric, evidence quality bar
