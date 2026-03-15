# Browser Automation Helpers

Common patterns for design discovery using Chrome MCP tools.

## Inspiration Site Analysis

Visit and analyze a website for design patterns:

```markdown
### Setup
1. mcp__claude-in-chrome__tabs_context_mcp
2. mcp__claude-in-chrome__tabs_create_mcp

### Navigate and Capture
3. mcp__claude-in-chrome__navigate url="https://example.com"
4. mcp__claude-in-chrome__computer action="screenshot"

### Extract (from screenshot analysis)
- **Colors:** bg=#___, text=#___, accent=#___
- **Typography:** Headlines=[Font], Body=[Font]
- **Layout:** [grid structure, spacing rhythm]
- **Distinctive:** [unique UI patterns, memorable elements]
- **DNA inference:** [layout, color, typography, motion]
```

### Example Output

```markdown
## Inspiration: linear.app

**Colors:**
- Background: #0A0A0B (near black)
- Text: #E8E8E8 (off-white)
- Accent: #5E6AD2 (muted purple)

**Typography:**
- Headlines: SF Pro Display, tight tracking
- Body: Inter (they can use it, you can't)

**Key Patterns:**
- Keyboard shortcuts visible throughout
- Smooth motion with spring physics
- High information density, minimal chrome

**DNA Inference:** [centered, dark, text-forward, orchestrated, compact, solid]
```

## Coolors Palette Selection

Browse and select color palettes:

```markdown
### Navigate to Trending
1. mcp__claude-in-chrome__navigate url="https://coolors.co/palettes/trending"
2. mcp__claude-in-chrome__computer action="screenshot"

### Present Options
"I see these trending palettes:
1. Earth tones: #D4A373, #FAEDCD, #E9EDC9...
2. Moody blues: #03045E, #023E8A, #0077B6...
3. Warm sunset: #FFBE0B, #FB5607, #FF006E...
4. Sage and sand: #606C38, #283618, #FEFAE0...

Which catches your eye? Or scroll for more?"

### On Selection
3. Click palette title to expand
4. Screenshot to capture hex codes
5. Map to Tailwind config:

tailwind.config = {
  theme: {
    extend: {
      colors: {
        background: '[based on user Q4: light/dark/tinted]',
        foreground: '[contrasting text]',
        primary: '[most distinctive color]',
        accent: '[secondary complement]',
        muted: '[softest color]',
      }
    }
  }
}
```

### Color Mapping Strategy

| User Choice (Q4) | Background | Foreground |
|------------------|------------|------------|
| Pure white | `#ffffff` | Darkest from palette |
| Off-white/warm | `#faf8f5` or `#f5f5f0` | Darkest from palette |
| Light tinted | Lightest from palette | Darkest from palette |
| Dark/moody | Darkest from palette | White or lightest |

## Google Fonts Selection

Browse and select typography:

```markdown
### Navigate to Trending
1. mcp__claude-in-chrome__navigate url="https://fonts.google.com/?sort=trending"
2. mcp__claude-in-chrome__computer action="screenshot"

### Present Options
"Trending fonts I see:
1. **Bricolage Grotesque** - Variable display, quirky curves
2. **Instrument Serif** - Elegant editorial serif
3. **Cabinet Grotesk** - Modern geometric sans
4. **Fraunces** - Playful variable serif with optical size
5. **Outfit** - Clean geometric, great for UI

Which for **headlines**? Or search for something specific?"

### After Selection
Repeat for body font, then generate:

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@400;700&family=Outfit:wght@400;500;600&display=swap" rel="stylesheet">

tailwind.config = {
  theme: {
    extend: {
      fontFamily: {
        heading: ['Bricolage Grotesque', 'sans-serif'],
        body: ['Outfit', 'sans-serif'],
      }
    }
  }
}
```

### Font Pairing Strategies

| Aesthetic | Heading | Body |
|-----------|---------|------|
| **Editorial** | Serif (Instrument, Newsreader) | Sans (Outfit, General Sans) |
| **Technical** | Mono or Sans (Geist, IBM Plex) | Same family |
| **Luxury** | Display (Clash, Cabinet) | Elegant sans |
| **Playful** | Variable (Fraunces, Bricolage) | Neutral sans |
| **Brutalist** | Bold sans (Bebas, Archivo Black) | Mono |

## Scrolling and Navigation

When user wants more options:

```markdown
### Scroll Down
mcp__claude-in-chrome__computer action="scroll" scroll_direction="down" scroll_amount=5

### Take New Screenshot
mcp__claude-in-chrome__computer action="screenshot"

### Search for Specific
mcp__claude-in-chrome__find query="search input"
mcp__claude-in-chrome__form_input ref="ref_X" value="Playfair Display"
```

## Full Discovery Flow

Combine all helpers for complete design discovery:

```markdown
Phase 0: Discovery

1. **Context Questions** (AskUserQuestion)
   - What to build
   - Project context
   - Target audience
   - Background style

2. **Inspiration Analysis** (if URLs provided)
   → Extract colors, fonts, patterns, DNA

3. **Palette Selection** (Coolors)
   → Browse trending → user picks → extract hex → map to Tailwind

4. **Typography Selection** (Google Fonts)
   → Browse trending → user picks heading → user picks body → generate config

5. **Output: Design Foundation**
   - Tailwind color config
   - Tailwind font config
   - @import links for head
   - Inferred DNA code
```
