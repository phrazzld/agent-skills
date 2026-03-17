# PR Body Template

Use this structure when creating or heavily rewriting a PR description.

## Goals

- Lead with significance, not mechanics.
- Explain value added, trade-offs accepted, and why those trade-offs are worth it.
- Make the diff legible with before/after diagrams, not a single abstract chart.
- Make the walkthrough artifact part of the merge case, not an afterthought.
- Keep the top of the PR skimmable; push heavier detail into `<details>` blocks.

## Top-Level Shape

These sections should stay visible on first load:

````markdown
## Reviewer Evidence
- Start here:
- Direct video download:
- Walkthrough notes:
- Fast claim:

## Why This Matters
- Problem:
- Value:
- Why now:
- Issue:

## Trade-offs / Risks
- Value gained:
- Cost / risk incurred:
- Why this is still the right trade:
- Reviewer watch-outs:

## What Changed
One short paragraph explaining the improvement in plain English.

### Base Branch
```mermaid
graph TD
  ...
```

### This PR
```mermaid
graph TD
  ...
```

### Architecture / State Change
```mermaid
graph TD
  ...
```

Why this is better:
- ...
- ...
````

## Visibility Toggles

Use `<details>` for sections that are valuable but not needed at first glance:

- `Intent Reference`
- `Changes`
- `Acceptance Criteria`
- `Alternatives Considered`
- `Manual QA`
- `Walkthrough`
- `Test Coverage`
- `Merge Confidence`
- `Screenshots / before-after evidence`

Pattern:

```md
<details>
<summary>Alternatives Considered</summary>

## Alternatives Considered
### Option A — Do nothing
- Upside:
- Downside:
- Why rejected:

### Option B — Alternate implementation
- Upside:
- Downside:
- Why rejected:

### Option C — Current approach
- Upside:
- Downside:
- Why chosen:

</details>
```

## Required Sections

All PRs must contain these sections, visible or inside `<details>`:

### `## Reviewer Evidence`

Put the proof before the prose when the PR has user-visible evidence.

- Link one obvious reviewer entrypoint
- Link the video in a way that does not drop reviewers into a confusing code viewer
- Surface 1-3 screenshots inline when they materially help
- State the merge claim in one sentence
- Include at least one durable artifact from real branch execution
- For UX work, include a watchable demo artifact unless the change is truly static
- Prefer an actual capture of the changed surface over a reconstructed or narrated facsimile
- Do not treat a markdown note or prose summary as sufficient reviewer evidence

For private repositories:

- prefer GitHub-uploaded attachments for screenshots and video
- if repo-hosted evidence is necessary, use a PR- or branch-unique path such as `walkthrough/pr-123/...`
- fallback screenshot syntax in PR bodies/comments: `../blob/<ref>/path/to/image.png?raw=true`
- fallback repo-hosted video link: `../blob/<ref>/path/to/video.mp4?raw=1`
- do not use `raw.githubusercontent.com/...` or bare asset paths like `walkthrough/screenshots/foo.png`
- do not use shared filenames like `walkthrough/reviewer-evidence.md` for PR-local evidence

### `## Why This Matters`

Top-line significance. This is the first thing a reviewer should understand.

- What problem or opportunity existed before this PR?
- What user, product, operational, or architectural value does this add?
- Why is this worth reviewer attention now?

### `## Trade-offs / Risks`

Be explicit. There are no perfect solutions.

- What complexity or cost did we add?
- What risks remain?
- Why is the value worth those risks?
- What should reviewers pressure-test?

### `## What Changed`

Use diagrams to make the delta legible:

1. **Base branch flow chart** — what the current path looks like before merge
2. **PR flow chart** — what changes after merge
3. **Architecture/state/sequence diagram** — the underlying structural improvement

Then explain why the new shape is better. The diagrams are not self-explanatory.

### `## Alternatives Considered`

Show that other paths were examined.

Include at least:
- do nothing / defer
- one credible alternate implementation
- why the current choice won

### `## Changes`

Concrete file/module summary. This is the mechanical diff summary, so it should not come before significance.

### `## Intent Reference`

Link the issue/spec/intent contract that justifies the work.

- Quote or summarize the core intent
- Link to the source issue, spec, or design section
- Make it easy for reviewers to compare intent vs implementation

### `## Acceptance Criteria`

Copy or derive from the issue. Use checkboxes.

### `## Manual QA`

Exact commands, URLs, setup, expected output. Keep long logs or screenshots under `<details>`.

### `## Walkthrough`

This is the proof package for the PR.

- Renderer
- Artifact
- Claim
- Before / After scope
- Persistent verification
- Residual gap
- Observable artifact from actual execution on this branch
- For UX work, default the artifact to a real video or terminal recording rather than prose or a static note
- For UX work, ensure the artifact is readable at normal speed and does not bury the changed surface under explanatory overlays

For the script and rubric, load `./pr-walkthrough-contract.md`.

### `## Before / After`

Show the previous state and the new state explicitly.

- Text is mandatory for every PR
- Screenshots are mandatory for user-visible changes
- For internal-only changes, explain why screenshots are not needed

### `## Test Coverage`

Point to exact test files or suites. Call out gaps plainly.

### `## Merge Confidence`

State:
- confidence level
- strongest evidence
- remaining uncertainty
- what could still go wrong after merge

## Diagram Selection

Choose the third diagram based on change type:

- feature / composition change → `graph TD`
- bug fix with state transition → `stateDiagram-v2`
- API/request flow → `sequenceDiagram`
- data model → `erDiagram`

The first two diagrams are always **base branch** and **this PR** flow charts when the change has meaningful flow.

For Mermaid syntax examples and GitHub rendering constraints, load
`~/.claude/skills/visualize/references/github-mermaid-patterns.md`.

## Cleanliness Rules

- Do not bury the value proposition below a long diff recap.
- Do not bury the reviewer evidence below the narrative when the branch has user-visible proof.
- Do not present prose-only reviewer evidence as proof.
- Do not present risks only as a footnote.
- Do not use a single diagram when before/after comparison is the actual point.
- Do not force screenshots for purely internal changes, but do provide text before/after.
- Do use `<details>` to keep the PR readable when sections get long.
- Do make the walkthrough point to one durable automated check, not just a polished artifact.
- Do keep repo-hosted PR artifacts uniquely scoped to the PR or branch. Shared artifact paths create needless merge conflicts.
