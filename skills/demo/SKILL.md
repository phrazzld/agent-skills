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

## Three Tiers of Demo Output

### Tier 1: Quick Evidence (default)

Screenshots + GIFs from QA artifacts. Minimal processing. Done in minutes.

1. Collect evidence from `/tmp/qa-{slug}/`
2. Convert WebM → GIF via ffmpeg (if needed)
3. Upload to draft GitHub release
4. Embed in PR comment

This is the default when invoked as part of `/autopilot` or when the user
says "upload evidence" or "PR evidence."

### Tier 2: Walkthrough Video

Assemble captures into a composed video with title cards, captions, and
transitions. No narration.

1. Collect evidence (screenshots, recordings)
2. Create a Remotion project (or use existing)
3. Compose: intro card → step-by-step scenes → outro
4. Render to MP4
5. Upload or share

See `references/remotion.md` for composition patterns.

### Tier 3: Launch Video

Full production: narration, background music, motion graphics.

1. Write a script (or generate from feature description)
2. Generate voiceover via TTS
3. Generate or select background music
4. Compose in Remotion with captures + voiceover + music + captions
5. Render and deliver

See `references/remotion.md` and `references/tts-narration.md`.

## FFmpeg Essentials

These are the patterns you'll use constantly for post-processing.

### WebM → GIF (for inline PR rendering)

```bash
ffmpeg -y -i input.webm \
  -vf "fps=8,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
  -loop 0 output.gif
```
GitHub renders GIFs inline but not WebM. Always convert for PRs.

### Concatenate clips

```bash
# Create file list
echo "file 'clip1.mp4'" > /tmp/concat.txt
echo "file 'clip2.mp4'" >> /tmp/concat.txt

ffmpeg -y -f concat -safe 0 -i /tmp/concat.txt -c copy output.mp4
```

### Add audio track

```bash
ffmpeg -y -i video.mp4 -i narration.mp3 \
  -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 \
  -shortest output.mp4
```

### Burn subtitles/captions

```bash
ffmpeg -y -i video.mp4 \
  -vf "subtitles=captions.srt:force_style='FontSize=24'" \
  output.mp4
```

### Resize for platforms

```bash
# 16:9 for YouTube/web
ffmpeg -y -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" output-16x9.mp4

# 1:1 for social
ffmpeg -y -i input.mp4 -vf "crop=min(iw\,ih):min(iw\,ih),scale=1080:1080" output-square.mp4

# 9:16 for mobile/stories
ffmpeg -y -i input.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" output-vertical.mp4
```

## PR Evidence Upload (Quick Reference)

For the full protocol, see `references/pr-evidence-upload.md`.

```bash
# Upload to draft release
gh release create qa-evidence-pr-{NUMBER} \
  --title "QA Evidence: PR #{NUMBER}" \
  --notes "Visual QA evidence" \
  --draft \
  /tmp/qa-{slug}/*.gif \
  /tmp/qa-{slug}/*.png

# Get asset URLs and embed in PR comment
RELEASE_TAG=$(gh release list --json tagName,isDraft \
  --jq '.[] | select(.isDraft) | .tagName' \
  | grep "qa-evidence-pr-{NUMBER}" | head -1)
```

## Gotchas

- **WebM in PR comments doesn't render.** Always convert to GIF for inline
  display. Link to the full WebM/MP4 for higher quality.
- **GIFs over 10MB** load slowly in PR comments. Target 800px width, 8fps,
  128-color palette. Trim to the essential flow.
- **Screenshots of static state don't need GIFs.** Use GIF only for flows
  with visible state changes.
- **Remotion requires Node.** Check the project has Node before starting
  video composition. Consider `npx create-video --yes --blank --tmp` for
  one-off renders.
- **TTS costs money.** OpenAI TTS is $0.015/1K chars. ElevenLabs is more
  expensive but higher quality. Don't generate narration for internal QA
  evidence — save it for launch videos.
- **Draft releases cost nothing** but accumulate. Clean up after PR merge
  if the repo has many PRs.
- **Committing binary artifacts to the repo** is always wrong. Use draft
  releases, external hosting, or `/tmp`.
