# Gemini Image Generation

Generate and edit images using Google's Gemini API. Requires `GEMINI_API_KEY`.

## Models
| Model | Resolution | Best For |
|-------|------------|----------|
| `gemini-2.5-flash-image` | 1024px | Speed, high-volume |
| `gemini-3-pro-image-preview` | Up to 4K | Professional assets, text rendering |

## Core API Pattern
```python
from google import genai
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=["Your prompt here"],
)
for part in response.parts:
    if part.inline_data:
        part.as_image().save("output.png")
```

## Image Config
```python
config=types.GenerateContentConfig(
    response_modalities=['TEXT', 'IMAGE'],
    image_config=types.ImageConfig(
        aspect_ratio="16:9",  # 1:1, 2:3, 3:2, 4:3, 9:16, 16:9, 21:9
        image_size="2K"       # 1K, 2K, 4K (Pro only for 4K)
    ),
)
```

## Editing Images
Pass existing images with text prompts:
```python
img = Image.open("input.png")
response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=["Add a sunset to this scene", img],
)
```

## Multi-Turn Refinement
Use chat for iterative editing with `client.chats.create()`.

## Advanced (Pro Only)
- Google Search Grounding: add `tools=[{"google_search": {}}]`
- Multiple Reference Images: up to 14 images in one call

## Notes
- All generated images include SynthID watermarks
- Image-only mode won't work with Search grounding
