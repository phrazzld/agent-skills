---
name: demo
description: |
  Generate demo artifacts: screenshots, GIF walkthroughs, video recordings,
  polished launch videos with narration and music. From raw evidence to
  shipped media. Also handles PR evidence upload via draft releases.
  Use when: "make a demo", "generate demo", "record walkthrough", "launch video",
  "PR evidence", "upload screenshots", "demo artifacts", "make a video",
  "demo this feature", "create a walkthrough".
  Trigger: /demo.
argument-hint: "[evidence-dir|feature] [--format gif|video|launch] [--narrate] [upload]"
---

# /demo

Turn evidence into artifacts. From raw QA screenshots to polished launch videos.

**Target:** $ARGUMENTS

## Routing

| Keyword / Intent | Reference |
|-----------------|-----------|
| `upload`, PR evidence | `references/pr-evidence-upload.md` |
| Remotion, video composition, walkthrough video | `references/remotion.md` |
| Narration, voiceover, TTS, music | `references/tts-narration.md` |
| Quick evidence (default) | This file |

## Workflow: Three Distinct Subagents

Each phase is a **separate subagent** launched via the Agent tool. The lead
orchestrates but does NOT do the work itself. This prevents self-grading —
the critic must be a fresh agent that challenges the implementer's output.

### Phase 1: Planner (subagent_type: Plan)

Launch a Plan agent with this prompt structure:

> I need to capture demo evidence for [feature]. Research the codebase to
> produce a complete shot list.
>
> 1. Identify the feature delta — what visible state changes?
> 2. `grep` for ALL call sites across ALL relevant apps. List every
>    page/route where the feature renders something visible.
> 3. Build a shot list table:
>    `| # | App | Route | State | What to capture | Expected text/element |`
>    Every "after" MUST have a paired "before" at the same route.
> 4. Identify auth/env prerequisites (ports, slugs, tokens, login flows).
> 5. Choose capture method per app (Playwright video, Chrome MCP, etc.).
> 6. Write the plan to `/tmp/demo-plan.md`.

**Wait for the plan.** Review it. Present to user if non-trivial.
Do NOT proceed until the shot list is complete and reviewed.

### Phase 2: Implementer (subagent_type: general-purpose)

Launch a general-purpose agent with the plan from Phase 1:

> Execute this demo capture plan: [paste /tmp/demo-plan.md contents]
>
> Rules:
> - Verify all dev servers are running before starting
> - Use Playwright with `page.video()` for automated captures
> - Use Chrome MCP `gif_creator` for interactive flows
> - Capture ALL "before" screenshots first, then apply state change,
>   then capture ALL "after" screenshots
> - Every screenshot must have a programmatic text assertion
>   (verify the expected text is present, log pass/fail)
> - Record a continuous walkthrough video — NOT a slideshow of PNGs
> - Post-process: WebM → GIF, target < 5MB, 800px, 8fps
> - Output everything to `/tmp/demo-evidence/`
> - Clean up any state changes (reset overrides, etc.) after capture

The implementer produces files. It does NOT upload or post.

### Phase 3: Critic (subagent_type: general-purpose)

Launch a **fresh** agent to validate. It has NO context from the implementer
— it inspects the artifacts cold.

> Review the demo evidence in `/tmp/demo-evidence/` against the shot list
> in `/tmp/demo-plan.md`. Run every gate below. Report PASS/FAIL for each.
> If ANY gate fails, output specific fix instructions — do not upload.
>
> Gates:
> 1. **Source validation**: Read each screenshot. Does it show the correct
>    app? Check URL bar, app chrome, page content.
> 2. **Before/after pairing**: Every "after" has a "before" from the same
>    route. List any unpaired screenshots.
> 3. **Text delta**: Before and after for the same route are visibly
>    different. Read both images, confirm the expected text changed.
> 4. **Coverage**: Compare shot list to captured files. For each shot list
>    row, is there a corresponding file? List uncovered rows.
> 5. **GIF quality**: Walkthrough has > 10 frames, > 2fps. Not a slideshow.
>    `ffmpeg -i walkthrough.gif -f null - 2>&1 | grep frame=`
> 6. **File sizes**: GIFs < 5MB, PNGs < 500KB. `ls -lh`
>
> Output: PASS (all gates green) or FAIL (list failures + fix instructions).

**If critic says FAIL**: fix the specific issues, re-run implementer for
the failed items only, then re-run critic. Loop until PASS.

**If critic says PASS**: proceed to upload and post.

### Upload & Post (lead does this, not a subagent)

After critic PASS:
1. Upload to draft release: `gh release create qa-evidence-pr-{N} --draft ...`
2. Compose PR comment using the template below
3. Post via `gh pr comment`

## PR Comment Template

```markdown
## Demo: [Feature Name] — [Delta Description]

### Walkthrough
![walkthrough](URL/walkthrough.gif)

### [App 1] — Before vs After

| Page | Before | After |
|------|--------|-------|
| [Route] | ![](URL/before.png) | ![](URL/after.png) |

### [App 2] — Before vs After

| Page | Before | After |
|------|--------|-------|
| [Route] | ![](URL/before.png) | ![](URL/after.png) |

### Override Flow
| Step | Screenshot |
|------|-----------|
| 1. [Action] | ![](URL/step.png) |
```

## Three Tiers

| Tier | Output | Subagent depth |
|------|--------|---------------|
| **1. Quick Evidence** (default) | Screenshots + GIF | Full triad |
| **2. Walkthrough Video** | Composed MP4 with title cards | Full triad + Remotion |
| **3. Launch Video** | Narration + music + motion | Full triad + TTS + Remotion |

See `references/remotion.md` and `references/tts-narration.md` for tiers 2-3.

## FFmpeg Quick Reference

```bash
# WebM → GIF
ffmpeg -y -i input.webm \
  -vf "fps=8,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
  -loop 0 output.gif

# Concatenate clips
ffmpeg -y -f concat -safe 0 -i list.txt -c copy output.mp4
```

## PR Evidence Upload

See `references/pr-evidence-upload.md`.

## Gotchas

- **Default-state evidence proves nothing.** Show the delta, not just defaults.
- **Self-grading is worthless.** The implementer must NOT critique its own work.
  The critic subagent inspects artifacts cold — no shared context.
- **Wrong-app screenshots are silent failures.** The critic reads each image.
- **ffmpeg slideshows are not GIFs.** Real GIFs need browser recording or
  Playwright video. The critic checks frame count.
- **Unpaired "after" is noise.** The critic checks pairing.
- **WebM doesn't render in PR comments.** Convert to GIF.
- **GIFs over 5MB** are too slow. Target 800px, 8fps, 128 colors.
- **Never commit binary artifacts.** Use draft releases or `/tmp`.
