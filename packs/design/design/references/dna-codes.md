# DNA Variation System

Force structural variety across design proposals. Each proposal MUST declare a unique DNA code.

## DNA Axes

| Axis | Options | Description |
|------|---------|-------------|
| **Layout** | centered, asymmetric, grid-breaking, full-bleed, bento, editorial | Spatial structure and composition |
| **Color** | dark, light, monochrome, gradient, high-contrast, brand-tinted | Color strategy and mood |
| **Typography** | display-heavy, text-forward, minimal, expressive, editorial | Type hierarchy and voice |
| **Motion** | orchestrated, subtle, aggressive, none, scroll-triggered | Animation philosophy |
| **Density** | spacious, compact, mixed, full-bleed | Content packing and whitespace |
| **Background** | solid, gradient, textured, patterned, layered | Surface treatment |

## DNA Rules

### When Generating Multiple Proposals

1. **Each proposal MUST declare its DNA** in the header:
   ```
   ### Proposal A: The Rams
   **DNA:** [centered, monochrome, text-forward, subtle, spacious, solid]
   ```

2. **No two proposals may share >2 axes** - Forces genuine structural variety

3. **Log DNA for tracking** - Prevents cross-session convergence

### DNA Examples by Aesthetic

| Aesthetic | Typical DNA |
|-----------|-------------|
| **Minimalist** | centered, light, minimal, subtle, spacious, solid |
| **Brutalist** | grid-breaking, monochrome, display-heavy, none, compact, solid |
| **Luxury** | asymmetric, dark, expressive, orchestrated, spacious, layered |
| **Editorial** | editorial, brand-tinted, editorial, scroll-triggered, mixed, textured |
| **Playful** | bento, gradient, display-heavy, aggressive, mixed, patterned |
| **Technical** | centered, dark, text-forward, subtle, compact, solid |

## DNA in Practice

### For /aesthetic Proposals

When generating 3 elevation proposals, ensure DNA variety:

```markdown
## Proposal A: The Rams
**DNA:** [centered, monochrome, text-forward, subtle, spacious, solid]
(Shares 0 axes with B and C)

## Proposal B: The Vignelli
**DNA:** [asymmetric, gradient, display-heavy, orchestrated, compact, layered]
(Shares 0 axes with A, 2 with C)

## Proposal C: The Hara
**DNA:** [grid-breaking, high-contrast, editorial, scroll-triggered, mixed, textured]
(Shares 2 axes with B, 0 with A)
```

### For /polish DNA Awareness

Infer current design's DNA before suggesting improvements:

```markdown
### Current DNA Inference

Analyzing screenshots and config...

Layout: centered (max-w-7xl mx-auto detected)
Color: light (white background, muted palette)
Typography: text-forward (body font dominates)
Motion: subtle (basic transitions)
Density: spacious (generous padding)
Background: solid (no patterns/gradients)

**Inferred DNA:** [centered, light, text-forward, subtle, spacious, solid]
```

### DNA Constraints by Mode

| Mode | DNA Constraint |
|------|----------------|
| **Quick pass** | Stay within DNA (refine, don't shift) |
| **Full polish** | Can shift 1-2 axes if justified |
| **Overhaul** | Complete DNA redefinition allowed |

## Anti-Convergence via DNA

The DNA system prevents:
- **Session convergence**: Same proposal structure repeated
- **Cross-session convergence**: Same DNA across projects
- **AI defaults**: Tendency toward "safe" combinations

**Track what you've used recently.** If last 3 projects were `centered, light, text-forward`, force yourself toward `asymmetric, dark, display-heavy` for the next.
