# Frontend Anti-Patterns (AI Slop to Avoid)

## The Problem

Claude tends to converge toward generic, "on distribution" outputs. In frontend design, this creates what users call the "AI slop" aesthetic.

**Signs of AI slop:**
- Every design looks similar
- Safe, uninspired choices
- No distinctive character
- Could be any template

## Typography Anti-Patterns

**Never use these fonts (overexposed):**
- Inter (most common AI default)
- Roboto
- Arial
- System fonts
- Space Grotesk (AI favorite)
- Satoshi (becoming overused)
- Inter Variable

**Problem:** These are fine fonts, but their ubiquity in AI outputs makes them feel generic.

**Solution:** Research fonts specific to the aesthetic direction. Each project gets its own font personality.

## Color Anti-Patterns

**Never use:**
- Purple gradients on white backgrounds (cliched)
- Pure gray neutrals when brand color exists
- Evenly-distributed palettes (timid)
- Safe, predictable color schemes

**Solution:** Commit to bold color directions. Dominant + accent. Brand-tinted neutrals.

## Layout Anti-Patterns

**Never default to:**
- Centered max-width containers on every page
- Standard header-hero-cards-footer structure
- Predictable symmetric grids
- Same layout patterns across projects

**Solution:** Consider asymmetry, overlap, diagonal flow, grid-breaking elements.

## The Convergence Trap

**Watch for these patterns in your outputs:**
- Same 3-4 font families appearing repeatedly
- Similar color palettes across projects
- Identical layout structures
- Same animation patterns
- Same component patterns

**Solution:** Before implementing, ask: "Have I used this choice recently? What's a distinctive alternative?"

## Variation Mandate

**No design should be the same.** Vary between:
- Light and dark themes (don't always default to light)
- Different font pairings (avoid go-to favorites)
- Different aesthetics (editorial, brutalist, luxury, playful, technical, organic)
- Different color approaches (monochrome, bold, pastel, neon, earth tones)

**Each project is unique—treat it that way.**

## Matching Complexity to Vision

**Maximalist designs** need:
- Elaborate code
- Extensive animations
- Rich effects
- Many visual layers

**Minimalist designs** need:
- Restraint
- Precision
- Careful spacing
- Subtle typography details
- Quiet elegance

**Problem:** Adding complexity to minimalist designs, or under-implementing maximalist visions.

**Solution:** Match implementation depth to aesthetic direction.
