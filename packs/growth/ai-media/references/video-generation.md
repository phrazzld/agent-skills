# AI Video Generation

Generate videos with 40+ AI models via inference.sh CLI.

## Text-to-Video
| Model | App ID | Best For |
|-------|--------|----------|
| Veo 3.1 Fast | `google/veo-3-1-fast` | Fast, optional audio |
| Veo 3.1 | `google/veo-3-1` | Best quality |
| Veo 3 | `google/veo-3` | High quality with audio |
| Grok Video | `xai/grok-imagine-video` | Configurable duration |
| Seedance 1.5 Pro | `bytedance/seedance-1-5-pro` | First-frame control |

## Image-to-Video
| Model | App ID | Best For |
|-------|--------|----------|
| Wan 2.5 | `falai/wan-2-5` | Animate any image |
| Seedance Lite | `bytedance/seedance-1-0-lite` | Lightweight 720p |

## Avatar / Lipsync
| Model | App ID | Best For |
|-------|--------|----------|
| OmniHuman 1.5 | `bytedance/omnihuman-1-5` | Multi-character |
| Fabric 1.0 | `falai/fabric-1-0` | Image talks with lipsync |
| PixVerse Lipsync | `falai/pixverse-lipsync` | Realistic lipsync |

## Utilities
| Tool | App ID | Description |
|------|--------|-------------|
| Foley | `infsh/hunyuanvideo-foley` | Add sound effects |
| Upscaler | `falai/topaz-video-upscaler` | Upscale quality |
| Merger | `infsh/media-merger` | Merge with transitions |

## Browse All
```bash
infsh app list --category video
```

## Examples
```bash
# Veo text-to-video
infsh app run google/veo-3-1-fast --input '{"prompt": "Timelapse of flower blooming"}'

# AI Avatar
infsh app run bytedance/omnihuman-1-5 --input '{"image_url": "portrait.jpg", "audio_url": "speech.mp3"}'

# Add sound effects
infsh app run infsh/hunyuanvideo-foley --input '{"video_url": "video.mp4", "prompt": "footsteps, birds"}'
```
