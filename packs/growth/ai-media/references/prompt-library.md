# Nano Banana - Image Prompt Library

6000+ curated professional prompts for AI image generation.

## Categories
| Category | Count | Best For |
|----------|-------|----------|
| Social Media | 3800+ | Instagram, Twitter, Facebook |
| Product Marketing | 1900+ | Ads, campaigns |
| Avatars | 700+ | Headshots, portraits |
| Infographic | 350+ | Data visualization |
| Posters | 300+ | Events, announcements |
| Comics | 200+ | Sequential art |
| E-commerce | 200+ | Product shots |
| Game Assets | 200+ | Sprites, characters |
| Thumbnails | 100+ | Video covers |
| Web Design | 100+ | UI mockups |

## Usage
```bash
# Search prompts
python scripts/search_prompts.py "avatar professional"

# Direct generation
python scripts/generate_image.py "A cat wearing a wizard hat" output.png

# Edit existing image
python scripts/edit_image.py input.png "Add rainbow background" output.png
```

## Workflow
1. **Direct**: Clear prompt -> generate immediately
2. **Exploration**: Vague request -> search prompts first
3. **Content-based**: User provides article -> extract themes, search

## Prompting Best Practices
- **Photorealistic**: Include camera details (lens, lighting, angle)
- **Stylized**: Specify style explicitly (kawaii, cel-shading, etc.)
- **Text in Images**: Be explicit about font and placement, use Pro model
- **Product Mockups**: Describe lighting setup and surface
