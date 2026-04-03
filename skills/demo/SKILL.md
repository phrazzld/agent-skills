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
argument-hint: "[evidence-dir|feature] [--format gif|video|launch] [upload]"
---

# /demo — Project-Local Skill Required

Demo effectiveness depends on project-specific context: features to capture,
artifact types, capture methods, upload targets. This global fallback exists
only to redirect you.

## Execution Stance

You are the executive orchestrator.
- Keep shot selection, evidence sufficiency, and final artifact approval on the lead model.
- Delegate planning, capture, and critique to separate focused subagents.
- Use a cold reviewer for final quality judgment.

## If this project has no scaffolded demo skill

Run `/harness scaffold demo` to generate one. The scaffold investigates the
codebase (features, visual deltas, capture tools, upload targets), designs
with you, and writes a project-local `.claude/skills/demo/SKILL.md`.

Once scaffolded, `/demo` will resolve to the project-local skill automatically.

## Quick one-off demo (no scaffold)

If you need to capture evidence right now without scaffolding:

### Workflow: Planner -> Implementer -> Critic

Each phase is a **separate subagent**. The critic must inspect artifacts cold
(no context from the implementer) to prevent self-grading.

1. **Plan:** Identify the feature delta, build a shot list, choose capture method
2. **Capture:** Execute the plan — every "after" has a paired "before"
3. **Critique:** Fresh agent validates source, pairing, text delta, coverage, quality
4. **Upload:** `gh release create qa-evidence-pr-{N} --draft` + PR comment

### FFmpeg quick reference

```bash
# WebM -> GIF (800px, 8fps, 128 colors)
ffmpeg -y -i input.webm \
  -vf "fps=8,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
  -loop 0 output.gif
```

For detailed capture patterns, read `skills/harness/references/evidence-capture.md`.
For PR evidence upload, read `skills/harness/references/pr-evidence-upload.md`.
For Remotion video composition, read `skills/harness/references/remotion.md`.
For TTS narration, read `skills/harness/references/tts-narration.md`.

## Gotchas

- **Default-state evidence proves nothing.** Show the delta, not just defaults.
- **Self-grading is worthless.** The critic subagent inspects artifacts cold.
- **This fallback is intentionally thin.** Generic demo instructions can't encode
  your app's features, capture methods, or upload targets. Scaffold for quality.
- **Autopilot expects a scaffolded skill.** If `/autopilot` invokes `/demo` and
  hits this redirect, scaffold first: `/harness scaffold demo`.
