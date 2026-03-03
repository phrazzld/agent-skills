---
name: ai-media
description: |
  AI-powered media generation: images (FLUX, Gemini, Grok, Seedream, Reve, 50+ models),
  videos (Veo, Seedance, Wan, OmniHuman lipsync, 40+ models), Remotion programmatic
  video, voiceover (ElevenLabs), demo videos, and asset generation pipelines.
  All via inference.sh CLI.
disable-model-invocation: true
argument-hint: "[type: image|video|remotion|demo|voiceover|asset] [prompt or description]"
allowed-tools: Bash(infsh *)
---

# /ai-media

AI-powered media generation across 150+ models.

## Quick Start

```bash
# Install inference.sh CLI
curl -fsSL https://cli.inference.sh | sh && infsh login

# Generate an image
infsh app run falai/flux-dev-lora --input '{"prompt": "a cat astronaut in space"}'

# Generate a video
infsh app run google/veo-3-1-fast --input '{"prompt": "drone shot flying over a forest"}'

# Browse all apps
infsh app list
```

## Capabilities

| Capability | Key Models | Reference |
|-----------|-----------|-----------|
| Text-to-Image | FLUX Dev LoRA, Gemini 3 Pro, Grok, Seedream 4.5, Reve | `references/image-generation.md` |
| Text-to-Video | Veo 3.1, Seedance 1.5 Pro, Grok Video | `references/video-generation.md` |
| Image-to-Video | Wan 2.5, Seedance Lite | `references/video-generation.md` |
| Avatar/Lipsync | OmniHuman 1.5, Fabric 1.0, PixVerse | `references/video-generation.md` |
| Gemini Image API | gemini-2.5-flash-image, gemini-3-pro-image-preview | `references/gemini-imagegen.md` |
| Prompt Library | 6000+ curated professional prompts | `references/prompt-library.md` |
| Remotion Render | React components to MP4 via cloud render | `references/remotion.md` |
| Demo Videos | Product demos with voiceover sync | `references/demo-video.md` |
| Voiceover | ElevenLabs TTS with word timestamps | `references/voiceover.md` |
| Asset Generation | Multi-provider logo/image pipeline (Recraft, OpenAI, Gemini) | `references/asset-generation.md` |

## Decision Tree

```
What do you need?
├── Static image
│   ├── Photo/art → FLUX Dev LoRA or Seedream 4.5
│   ├── With text → Reve or Seedream 3.0
│   ├── Google API → Gemini 3 Pro Image
│   └── Logo/asset → Asset generation pipeline
├── Video
│   ├── From text → Veo 3.1 or Seedance 1.5 Pro
│   ├── From image → Wan 2.5
│   ├── Talking head → OmniHuman 1.5
│   └── Product demo → Demo video pipeline
├── Programmatic video → Remotion render
└── Audio → ElevenLabs voiceover
```

## Image Generation

```bash
# FLUX (high quality)
infsh app run falai/flux-dev-lora --input '{"prompt": "professional product photo, studio lighting"}'

# Gemini 3 Pro
infsh app run google/gemini-3-pro-image-preview --input '{"prompt": "photorealistic landscape"}'

# Seedream 4.5 (4K cinematic)
infsh app run bytedance/seedream-4-5 --input '{"prompt": "cinematic portrait, golden hour"}'

# Upscaling
infsh app run falai/topaz-image-upscaler --input '{"image_url": "https://..."}'
```

## Video Generation

```bash
# Veo 3.1 (best quality, with audio)
infsh app run google/veo-3-1-fast --input '{"prompt": "timelapse of flower blooming"}'

# AI Avatar (talking head)
infsh app run bytedance/omnihuman-1-5 --input '{"image_url": "portrait.jpg", "audio_url": "speech.mp3"}'

# Animate image
infsh app run falai/wan-2-5 --input '{"image_url": "https://your-image.jpg"}'
```

## Remotion (React to Video)

```bash
infsh app run infsh/remotion-render --input '{
  "code": "import { useCurrentFrame, AbsoluteFill } from \"remotion\"; export default function Main() { const frame = useCurrentFrame(); return <AbsoluteFill style={{backgroundColor: \"#000\"}}><h1 style={{color: \"white\", opacity: frame / 30}}>Hello</h1></AbsoluteFill>; }",
  "duration_seconds": 3, "fps": 30, "width": 1920, "height": 1080
}'
```

See `references/remotion.md` for Remotion best practices (animations, captions, audio, transitions).

## References

| Reference | Content |
|-----------|---------|
| `references/image-generation.md` | All image models, examples, browse commands |
| `references/video-generation.md` | All video models, lipsync, utilities |
| `references/gemini-imagegen.md` | Gemini API image generation and editing |
| `references/prompt-library.md` | 6000+ curated prompts by category |
| `references/remotion.md` | Remotion best practices, animations, captions |
| `references/demo-video.md` | Product demo video pipeline |
| `references/voiceover.md` | ElevenLabs TTS with timestamps |
| `references/asset-generation.md` | Multi-provider logo/image pipeline |
