# UI Rules — Battle-Tested Gotchas

Quick-lookup reference: severity-tagged rules focusing on non-obvious gotchas.
Some rules overlap with detailed references (motion-craft.md, mobile-excellence.md,
implementation-constraints.md) — this file is the triage view, those are deep dives.

## Severity Guide

- **CRITICAL** — Breaks UX, causes user confusion or data loss
- **HIGH** — Noticeable degradation, professional vs amateur signal
- **MEDIUM** — Polish item, compounds with other issues

---

## 1. Animation & Motion

**CRITICAL: Gesture-driven motion needs springs, not easing curves.**
Easing curves (cubic-bezier) have fixed duration — they can't respond to velocity.
When the user flicks, swipes, or drags, the animation must inherit the gesture's
momentum. Springs do this naturally; easing curves create a jarring disconnect.

**HIGH: Exit animations must mirror entry state, not play entry in reverse.**
If an element slides in from the left, it should slide out to the left (back where
it came from), not slide out to the right. Reverse playback looks like a VHS rewind.

**HIGH: Stagger delays must be short (30-50ms) and total duration capped.**
Long staggers (>80ms per item) on lists with 20+ items means the last item appears
2+ seconds later. Cap total stagger duration at ~400ms regardless of item count.

**MEDIUM: Reduced motion preference must disable motion, not duration.**
Setting `duration: 0` causes visual glitches (flash of final state). Use
`animation: none !important; transition: none !important;` instead.

**HIGH: Spring defaults:** stiffness 100-300, damping 15-30, mass 1.
High stiffness + low damping = oscillation. Low stiffness + high damping = sluggish.

**CRITICAL: Container animation needs two-div pattern (outer animated, inner counter-animated).**
When animating a container's size, the content distorts. Fix: animate the outer div,
counter-animate the inner div to maintain its natural dimensions.

```jsx
// WRONG: Content distorts during animation
<motion.div animate={{ scaleX: expanded ? 1 : 0.5 }}>
  <Content /> {/* Text and images squish */}
</motion.div>

// RIGHT: Two-div pattern
<motion.div animate={{ scaleX: expanded ? 1 : 0.5 }}>
  <motion.div animate={{ scaleX: expanded ? 1 : 2 }}> {/* Counter-scale */}
    <Content /> {/* Stays crisp */}
  </motion.div>
</motion.div>
```

**HIGH: Layout animations must use `layout` prop, not manual width/height.**
Framer Motion's `layout` prop handles FLIP animation automatically.

**MEDIUM: Parallax must be subtle (0.1-0.3x scroll speed difference).** Aggressive
parallax (0.5x+) causes motion sickness and makes content hard to read.

---

## 2. Typography

**CRITICAL: Use `tabular-nums` for data columns.**
Without it, numbers with different digit widths cause columns to jitter
when values change. `font-variant-numeric: tabular-nums;`

**CRITICAL: Use `text-wrap: balance` for headings.**
Prevents orphaned words (single word on last line).

**HIGH: Don't use viewport units for font size without clamp.**
`font-size: clamp(1rem, 2.5vw + 0.5rem, 3rem);` — never raw `vw`.

---

## 3. Color

**CRITICAL: Never use pure black (#000000) on pure white (#FFFFFF).**
The extreme contrast causes halation (text appears to vibrate). Use off-black
(`zinc-950`) on off-white (`zinc-50`).

**HIGH: OKLCH for color systems, not HSL.**
HSL's "lightness" is perceptually non-uniform — 50% lightness yellow looks much
brighter than 50% lightness blue. OKLCH fixes this.

```css
/* OKLCH: actually perceptually uniform */
--blue: oklch(0.6 0.2 250);
--yellow: oklch(0.6 0.2 90);
```

**HIGH: Brand-tinted neutrals over pure grays.** Add chroma 0.005-0.02 at your
brand hue to neutral grays. Creates cohesion without being noticeable.

**MEDIUM: Dark mode is not "invert colors."** Reduce contrast slightly (surfaces
at 10-15% lightness, not 0%), reduce saturation, same brand hue with adjusted lightness.

**MEDIUM: Semantic color tokens, not palette references.** `--color-danger` not
`--color-red-500`. Semantics survive theme changes.

---

## 4. Layout

**CRITICAL: Use `min-h-[100dvh]` not `h-screen` for full-height layouts.**
`100vh` doesn't account for mobile browser chrome. `100dvh` does.

**HIGH: Container queries over media queries for components.** Components don't
know what page they'll be on. `@container` adapts to parent size, not viewport.

---

## 5. Interaction

**HIGH: Disabled buttons should explain why.** A grayed-out button with no tooltip
is a dead end. Show what's missing: "Complete all required fields."

**MEDIUM: Scroll position preservation on navigation.** Back = restore scroll.
Forward to list = scroll to top.

---

## 6. Forms

**MEDIUM: Show password requirements BEFORE validation fails.** Don't make users
guess the rules, then tell them they guessed wrong.

**LOW: `inputmode` for mobile keyboards.** `inputmode="numeric"` for phone
numbers/ZIPs. `inputmode="email"` for email fields.

---

## 7. Responsive

**HIGH: Test at 375px, 768px, 1024px, 1440px.** iPhone SE, iPad portrait,
iPad landscape/small laptop, desktop.

---

## 8. Media

**MEDIUM: `loading="lazy"` for below-fold images.** But NOT for above-fold hero
images or LCP candidates — use `loading="eager"` with `fetchpriority="high"`.
