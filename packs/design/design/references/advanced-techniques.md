# Advanced Visual Techniques

## WebGL & Shaders

For backgrounds that need to feel alive—hero sections, landing pages, creative portfolios.

**Three.js Backgrounds:**
```tsx
import { Canvas } from '@react-three/fiber'
import { GradientMesh } from './GradientMesh'

<Canvas className="absolute inset-0 -z-10">
  <GradientMesh colors={['#ff6b6b', '#4ecdc4', '#45b7d1']} />
</Canvas>
```

**Capabilities:**
- Animated gradient meshes
- Particle systems
- Procedural noise
- 3D depth
- Custom GLSL shaders

**GLSL Shader Effects:**
- Noise/grain overlays
- Color distortion
- Blur/bokeh
- Dynamic lighting
- Morphing shapes

## SVG Animation Libraries

### Lottie (lottie-react)
JSON animations from After Effects, LottieFiles marketplace.
- Best for: Illustrations, loading animations, micro-interactions

### GSAP (GreenSock)
Professional timeline animations with ScrollTrigger plugin.
- Best for: Scroll-driven narratives, morphing, complex sequences

### Framer Motion
React-first declarative animations.
- Best for: Layout animations, gestures, shared element transitions

## CSS Art Techniques

Asset-free, themeable illustrations.

**Pure CSS Illustrations:**
- box-shadow stacking
- pseudo-elements
- complex gradients

**Advanced Gradients:**
- Conic (pie charts, color wheels)
- Radial (orbs, spotlights)
- Multi-layer textures

**Clip-path Magic:**
- Non-rectangular containers
- Reveal animations
- Complex shapes

**CSS Houdini (experimental):**
- Custom paint worklets
- Procedural patterns

## ASCII Art & Terminal Aesthetics

For brutalist or retro designs.

**Character-based visuals:**
```css
.ascii-box {
  font-family: 'JetBrains Mono', monospace;
  white-space: pre;
}
.ascii-box::before {
  content: '┌──────────────────┐\A│                  │\A└──────────────────┘';
}
```

**Use cases:**
- Logos and headers
- Decorative borders
- Progress bars
- Loading spinners

**Tools:** figlet (text banners), boxes (frames)

## Icon Libraries

### Lucide (default)
Clean, consistent, good coverage for common icons.

### Iconify (200,000+ icons)
When Lucide isn't enough:
```tsx
import { Icon } from '@iconify/react'

<Icon icon="mdi:account" />           // Material Design
<Icon icon="ph:rocket-launch" />      // Phosphor (modern)
<Icon icon="tabler:brand-github" />   // Tabler (consistent stroke)
<Icon icon="carbon:analytics" />      // Carbon (IBM style)
```

**When to use Iconify:**
- Need icons Lucide doesn't have (brands, payment, flags)
- Want different style (filled, duotone)
- Matching specific aesthetics

## Custom Asset Generation

When designs need imagery that doesn't exist, suggest:

> "This design would benefit from [custom illustration/texture/icon].
> Consider generating with:
> - **Midjourney**: Photorealistic images, illustrations, textures
> - **Gemini Nano Banana** (`gemini-imagegen` skill): Quick iterations, text-in-image
>
> Prompt suggestion: [specific prompt matching brand aesthetic]"

**Use cases:**
- Hero illustrations
- Custom iconography
- Textures/patterns
- Product mockups
