# Motion Craft

Practical CSS-level recipes for motion that feels right. Complements `implementation-constraints.md` (hard rules) and `banned-patterns.md` (what to avoid). This file covers **how to implement** good motion.

Source: [animations.dev](https://animations.dev) + battle-tested patterns.

## Quick Fixes

| Scenario | Solution |
|----------|----------|
| Buttons feel flat | `transform: scale(0.97)` on `:active` |
| Element appears from nowhere | Start from `scale(0.95)`, not `scale(0)` |
| Shaky/jittery animation | Add `will-change: transform` (remove after animation ends) |
| Hover causes flicker | Animate the child element, not the parent |
| Popover scales from wrong point | Set `transform-origin` to trigger location |
| Sequential tooltips feel slow | Skip delay/animation after the first tooltip |
| Small buttons hard to tap | 44px minimum hit area (pseudo-element) |
| Something still feels off | Add subtle blur (under 20px) to mask it |
| Hover triggers on mobile | `@media (hover: hover) and (pointer: fine)` |

## Easing

Use `ease-out` for entrances (element arriving), `ease-in` for exits (element leaving), `ease-in-out` for continuous motion (looping, morphing). Never use `linear` for UI motion.

```css
/* Good defaults */
--ease-out: cubic-bezier(0.16, 1, 0.3, 1);    /* snappy entrance */
--ease-in:  cubic-bezier(0.55, 0, 1, 0.45);    /* accelerating exit */
--ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1); /* overshoot for delight */
```

Keep interaction feedback under 200ms. Entrances 200-400ms. Exits 150-250ms (faster than entrances — users don't want to wait for things to leave).

**Transitions vs keyframes:** CSS transitions interpolate toward the latest state and can be interrupted mid-animation. Keyframe animations run on a fixed timeline and don't retarget. Use transitions for interactions (menus, toggles, hovers) and keyframes for staged sequences that run once (page load, enter/exit).

## Button Feel

```css
button {
  transition: transform 150ms ease-out;
}

/* Hover: lift slightly */
@media (hover: hover) and (pointer: fine) {
  button:hover {
    transform: translateY(-1px);
  }
}

/* Active: press in */
button:active {
  transform: scale(0.97);
  transition-duration: 75ms; /* snap down fast */
}
```

Why `0.97` not `0.9`? Subtle scale feels physical. Large scale feels broken.

## Hit Areas

Interactive elements need 44px minimum touch targets even when visually smaller.

```css
.icon-button {
  position: relative;
  /* visual size can be 24px, 32px, whatever */
}

.icon-button::before {
  content: '';
  position: absolute;
  inset: -10px; /* expand clickable area */
  /* no background — invisible but tappable */
}
```

## Popovers, Tooltips, Dropdowns

Always set `transform-origin` to the trigger location so the element scales from where the user clicked.

```css
/* Popover opening below a button */
.popover {
  transform-origin: top center;
  animation: popover-in 200ms var(--ease-out);
}

/* Popover opening from right-click */
.context-menu {
  transform-origin: top left;
}

@keyframes popover-in {
  from { opacity: 0; transform: scale(0.95) translateY(-4px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}
```

### Sequential Tooltips

When hovering across a row of icons, the delay on the first tooltip is good (prevents accidental triggers). But subsequent tooltips should appear instantly — the user is clearly exploring.

```css
/* CSS-only: use :has() to detect "tooltip group active" */
.tooltip-group:has(:hover) .tooltip-trigger:hover .tooltip {
  transition-delay: 0ms;
  animation-delay: 0ms;
}
```

Or track "warm" state in JS: after first tooltip opens, set a warm window (~300ms) where subsequent tooltips skip delay.

## Entrance Patterns

Start close to the final state. `scale(0)` or `translateY(100px)` feels cartoonish. Subtle offsets feel physical.

```css
/* Good: subtle entrance */
@keyframes fade-in-up {
  from {
    opacity: 0;
    transform: translateY(8px);  /* 4-12px, not 50-100px */
  }
}

/* Staggered list entrance */
.list-item {
  animation: fade-in-up 300ms var(--ease-out) both;
}
.list-item:nth-child(1) { animation-delay: 0ms; }
.list-item:nth-child(2) { animation-delay: 50ms; }
.list-item:nth-child(3) { animation-delay: 100ms; }
/* Cap at ~5 items or 250ms total stagger */
```

Cap stagger delay at 50-75ms per item. Longer feels sluggish. After 5-6 items, remaining items should appear together.

### Split and Stagger with CSS Custom Properties

Break animated content into semantic chunks (title, description, buttons) rather than animating a single container. Use a CSS custom property for stagger index:

```css
@keyframes enter {
  from {
    transform: translateY(8px);
    filter: blur(5px);
    opacity: 0;
  }
}

.animate-enter {
  animation: enter 800ms cubic-bezier(0.25, 0.46, 0.45, 0.94) both;
  animation-delay: calc(var(--delay, 0ms) * var(--stagger, 0));
}
```

```html
<div class="animate-enter" style="--stagger: 1"><Title /></div>
<div class="animate-enter" style="--stagger: 2"><Description /></div>
<div class="animate-enter" style="--stagger: 3"><Buttons /></div>
```

For headings, split into per-word spans with `--delay: 80ms`. Keep description as a single block. Buttons can be individually staggered.

## Exit Patterns

Exits should be more subtle than entrances. Entering elements need attention; exiting elements should leave quietly.

```tsx
// Full exit — mirrors entrance (sometimes too dramatic)
exit={{ opacity: 0, y: "calc(-100% - 4px)", filter: "blur(4px)" }}

// Subtle exit — fixed small offset (preferred)
exit={{ opacity: 0, y: "-12px", filter: "blur(4px)" }}
```

Keep some directional motion on exits to indicate where the element went. Don't remove animation entirely — just reduce the travel distance to a fixed small value (8-12px) instead of percentage-based.

## Icon Swap Transitions

When icons change contextually (copy → check, play → pause), animate opacity, scale, and blur on the transition. Without this, the swap feels like a glitch.

```tsx
<AnimatePresence mode="wait">
  {isCopied ? (
    <motion.span key="check"
      initial={{ opacity: 0, scale: 0.6, filter: "blur(4px)" }}
      animate={{ opacity: 1, scale: 1, filter: "blur(0)" }}
      exit={{ opacity: 0, scale: 0.6, filter: "blur(4px)" }}
      transition={{ duration: 0.15 }}>
      <CheckIcon />
    </motion.span>
  ) : (
    <motion.span key="copy" /* same animation props */>
      <CopyIcon />
    </motion.span>
  )}
</AnimatePresence>
```

CSS-only alternative: crossfade with absolute positioning and `opacity` transitions on each icon.

## Hover Without Flicker

Animate the child, not the hovered element. When hover state changes an element's bounds, the cursor can leave the element, triggering mouseout, causing flicker.

```css
/* Bad: animating the hovered element */
.card:hover { transform: scale(1.02); }

/* Good: animate an inner element */
.card:hover .card-inner { transform: scale(1.02); }
```

## Blur as Polish

Subtle blur (4-16px) on entering/exiting elements masks imperfect motion. Under 20px is imperceptible as "blur" but smooths transitions.

```css
@keyframes enter-with-blur {
  from {
    opacity: 0;
    transform: translateY(8px);
    filter: blur(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
    filter: blur(0);
  }
}
```

Keep blur surfaces small. Never blur full-screen or large images (GPU cost — per `implementation-constraints.md`).

## Mobile Guards

Hover effects must be gated behind capability queries. Touch devices fire hover on tap, causing stuck states.

```css
/* Only apply hover effects on devices that support real hover */
@media (hover: hover) and (pointer: fine) {
  .interactive:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px oklch(0 0 0 / 0.1);
  }
}
```

## Reduced Motion

Required by `implementation-constraints.md`. Provide meaningful alternatives — don't just kill all motion.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Use `0.01ms` not `0s` — zero duration can skip `animationend` events and break JS listeners.

## Compositor-Only Checklist

Per `implementation-constraints.md`: only animate `transform` and `opacity`. Everything else triggers layout or paint.

| Want to animate | Do this instead |
|-----------------|-----------------|
| `width` / `height` | `transform: scale()` |
| `top` / `left` | `transform: translate()` |
| `margin` / `padding` | `transform: translate()` |
| `background-color` | Crossfade two layers with `opacity` |
| `border-radius` | `clip-path` or overlay with `opacity` |
| `box-shadow` | Pseudo-element with pre-rendered shadow, animate its `opacity` |
