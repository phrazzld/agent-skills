# Asset Generation

Multi-provider visual asset pipeline for logos, icons, hero imagery.

## Providers
1. **Recraft** - Symbol marks, icon-style logos
2. **OpenAI** (`gpt-image-1`) - General image generation
3. **Nano Banana Pro** (Gemini) - Text rendering, professional assets

## Core Rules
- Use all three providers during exploratory rounds
- Generate in proposal context, not detached
- Logos must pass favicon/app-icon constraints (flat, simple, legible at 16px)
- Never produce marks that can be confused with existing company logos

## Complexity Budget
Reject marks exceeding: 8 primitives, 2 stroke widths, 2 brand colors + 1 neutral.

## Phase-Aware Breadth
- **Phase A (exploration)**: 1 concept per provider, high diversity
- **Phase B (convergence)**: 2 focused variants from best providers

## Logo Prompt Contract
Always include: `no text`, `no mockup`, `no shadows`, `no gradients`, `centered symbol`, `flat icon`.

## QA Gates (reject if fails)
- Noisy illustration masquerading as logo
- Too many micro-details for favicon
- Same colorway duplicated across batch
- Obvious resemblance to known logos
