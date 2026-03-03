# AI Image Generation

Generate images with 50+ AI models via inference.sh CLI.

## Available Models

| Model | App ID | Best For |
|-------|--------|----------|
| FLUX Dev LoRA | `falai/flux-dev-lora` | High quality with custom styles |
| FLUX.2 Klein LoRA | `falai/flux-2-klein-lora` | Fast with LoRA support |
| Gemini 3 Pro | `google/gemini-3-pro-image-preview` | Google's latest |
| Gemini 2.5 Flash | `google/gemini-2-5-flash-image` | Fast Google model |
| Grok Imagine | `xai/grok-imagine-image` | xAI's model |
| Seedream 4.5 | `bytedance/seedream-4-5` | 2K-4K cinematic |
| Seedream 3.0 | `bytedance/seedream-3-0-t2i` | Accurate text rendering |
| Reve | `falai/reve` | Natural language editing, text rendering |
| ImagineArt 1.5 Pro | `falai/imagine-art-1-5-pro-preview` | Ultra-high-fidelity 4K |
| Topaz Upscaler | `falai/topaz-image-upscaler` | Professional upscaling |

## Browse All
```bash
infsh app list --category image
```

## Examples
```bash
# FLUX
infsh app run falai/flux-dev-lora --input '{"prompt": "professional product photo, studio lighting"}'

# Grok (with aspect ratio)
infsh app run xai/grok-imagine-image --input '{"prompt": "cyberpunk city", "aspect_ratio": "16:9"}'

# Reve (text rendering)
infsh app run falai/reve --input '{"prompt": "A poster that says HELLO WORLD in bold letters"}'

# Stitch images
infsh app run infsh/stitch-images --input '{"images": ["url1", "url2"], "direction": "horizontal"}'
```
