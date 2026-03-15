# Frontend Aesthetics Guidelines

## Typography

Choose fonts that are beautiful, unique, and interesting. Pair a distinctive display font with a refined body font.

**Avoid convergence**: You tend toward common choices (Space Grotesk, Satoshi, Inter Variable). Each project deserves its own font personality.

**Font selection principles:**
- Display fonts: characterful, memorable, sets the tone
- Body fonts: refined, readable, complements display
- Consider: humanist sans, geometric sans, neo-grotesque, serifs, slabs, monospace
- Match font personality to content tone

## Color & Theme

Commit to a cohesive aesthetic. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Draw from IDE themes (Dracula, Nord, Solarized, Tokyo Night) and cultural aesthetics (Japanese minimalism, Bauhaus, Art Nouveau, Swiss design) for unexpected palette inspiration.

**Vary your approach:**
- High-contrast monochrome
- Soft pastels
- Bold neons
- Earth tones
- Jewel tones
- Industrial neutrals

**Brand-tinted neutrals:**
Don't use pure grays. Tint ALL neutrals with your brand hue at very low chroma (0.01-0.03 in OKLCH):
```css
/* Blue-tinted neutral instead of pure gray */
oklch(0.95 0.01 250)  /* vs oklch(0.95 0 0) */
```

This creates imperceptible but cohesive brand "feeling" throughout.

## Motion & Animation

Focus on high-impact moments. One well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.

**Priorities:**
1. Page load orchestration (staggered animation-delay)
2. Scroll-triggered reveals
3. Hover states that surprise
4. Micro-interactions for feedback

**Implementation:**
- CSS-only for HTML projects
- Motion library for React
- GSAP for complex sequences
- Framer Motion for React-first declarative animations

## Spatial Composition

Break out of predictable layouts:
- Asymmetry over symmetry
- Overlap elements intentionally
- Diagonal flow, not just grid
- Grid-breaking hero elements
- Generous negative space OR controlled density

## Backgrounds & Visual Details

Create atmosphere and depth:

- **Gradient meshes**: Multi-color gradients for dynamic atmosphere
- **Noise textures**: SVG or CSS noise for analog warmth
- **Geometric patterns**: Subtle repeating shapes or grids
- **Layered transparencies**: Overlapping elements with opacity
- **Dramatic shadows**: Deep shadows with color tints
- **Decorative borders**: Custom border treatments with personality
- **Custom cursors**: Brand-specific cursor design
- **Grain overlays**: Film grain for texture and depth

## Tone Spectrum

Pick an extreme and commit:
- Brutally minimal
- Maximalist chaos
- Retro-futuristic
- Organic/natural
- Luxury/refined
- Playful/toy-like
- Editorial/magazine
- Brutalist/raw
- Art deco/geometric
- Soft/pastel
- Industrial/utilitarian

**Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.**
