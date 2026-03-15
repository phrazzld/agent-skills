# Banned Patterns

Explicit "never use" elements to avoid AI slop and generic aesthetics.

## Banned Elements

### Typography

**BANNED fonts:**
- Inter
- Roboto
- Arial
- system-ui
- Open Sans
- Space Grotesk (AI favorite)
- Satoshi (overused)

**Why:** These are defaults that signal "no decision was made."

**Instead:** Choose fonts with character that match the brand soul.

### Layout Patterns

**BANNED:**
- Hero badges/pills above headlines ("New", "AI-Powered", "Introducing", "Beta")
- Predictable hero → CTA → features → testimonials → footer
- `max-w-7xl mx-auto` centered everything
- Generic grid cards with even spacing
- Hamburger menu hiding everything on mobile

**Why:** These patterns are templates, not designs.

**Instead:** Start from content and meaning, not from patterns.

### Color

**BANNED:**
- Purple/blue gradients on white backgrounds
- Tailwind default colors without customization (blue-500, etc.)
- Pure grays (no brand tinting)
- Generic semantic names without personality

**Why:** These are the statistical average of all AI outputs.

**Instead:** Commit to a color voice. Tint your neutrals with brand hue.

### Visual Elements

**BANNED:**
- Generic geometric shapes
- Abstract blobs
- Excessive uniform rounded corners everywhere
- Gradients that "glow" without purpose
- Stock illustration styles

**Why:** Decoration without meaning is noise.

**Instead:** Every visual element should serve a purpose or tell a story.

### Alert/Callout Patterns

**BANNED:**
- Left border accent with rounded corners (e.g., `border-left: 3px solid color; border-radius: 8px`)
- The "rounded card with colored left stripe" pattern for alerts, warnings, info boxes

**Why:** This is one of the most overused AI patterns. It's lazy, generic, and signals "no thought was applied." Every AI chatbot and generated codebase uses this exact pattern.

**Instead:** Consider:
- Full-width colored background with subtle tint
- Icon-led alerts with the icon providing the semantic color
- Top border or bottom border instead of left
- No border at all — use background color alone
- Outlined/stroke style cards
- Inset box shadows for depth
- Completely custom alert paradigms (toast, banner, inline text)

### Motion

**BANNED:**
- `transition-all duration-200` everywhere
- Instant state changes with no acknowledgment
- Decorative animations that distract from content
- Scattered micro-interactions without coherence

**Why:** Motion should be orchestrated, not sprinkled.

**Instead:** One well-choreographed page load beats 20 random hover effects.

## Self-Review Checklist

Before delivering any design, scan for violations:

```
[ ] No hero badges above headlines?
[ ] No banned fonts (Inter, Roboto, Arial, Space Grotesk)?
[ ] No purple/blue gradient on white?
[ ] No Tailwind defaults without customization?
[ ] No generic geometric shapes/blobs?
[ ] No left-border-accent alerts with rounded corners?
[ ] Layout starts from content, not template?
[ ] Mobile has real navigation, not buried hamburger?
[ ] Motion is orchestrated, not scattered?
```

## The "Discard First 10" Rule

When generating proposals or improvements:

> Mentally discard your first 10 ideas. These are usually the statistical average—the patterns most frequently seen in training data. The 11th idea is where originality begins.

Practically: Before committing to any design choice, ask:
- "Is this what everyone would do?"
- "What's a distinctive alternative?"
- "Would this be memorable?"

## Pattern Detection

Watch for these red flags in your output:

| Red Flag | What It Signals |
|----------|-----------------|
| `font-sans` without override | No typography decision |
| `bg-white` + purple accent | AI default palette |
| Centered cards in 3-column grid | Template thinking |
| "Introducing" badge | Startup cliche |
| Hamburger menu everywhere | Laziness |
| `border-left` + `border-radius` on alerts | Peak AI slop |

When you catch yourself reaching for these, stop and choose something intentional.
