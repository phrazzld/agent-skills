# Visual Craft

Practical recipes for static visual polish. Complements `motion-craft.md` (animation) and `implementation-constraints.md` (hard rules). This file covers spatial relationships, depth, and optical refinement.

Source: [jakubkrehel.com](https://jakubkrehel.com/posts/details-that-make-interfaces-feel-better) + battle-tested patterns.

## Concentric Border Radius

When nesting rounded elements, the outer radius must equal the inner radius plus the gap (padding) between them. Mismatched radii are one of the most common "feels off" issues.

```
outer-radius = inner-radius + padding
```

```css
/* Card with 20px padding and inner elements with 8px radius */
.card {
  border-radius: 28px;  /* 8 + 20 */
  padding: 20px;
}
.card-inner {
  border-radius: 8px;
}

/* Smaller gap example: 12px padding, 8px inner */
.container {
  border-radius: 20px;  /* 8 + 12 */
  padding: 12px;
}
```

If the padding is less than the inner radius, the outer radius can equal the inner radius (the difference becomes negligible).

## Optical Alignment

Geometric alignment (pixel-perfect centering) sometimes looks wrong. When it does, align optically instead.

### Buttons with Icons

A button with text and an icon needs slightly less padding on the icon side to look balanced. The icon's visual weight differs from text.

```css
/* Geometric (looks unbalanced) */
.btn { padding: 8px 16px; }

/* Optical (looks centered) */
.btn-with-trailing-icon { padding: 8px 12px 8px 16px; }
.btn-with-leading-icon  { padding: 8px 16px 8px 12px; }
```

### Asymmetric Icons

Play buttons, arrows, and other directionally-weighted icons look off-center in circles or squares. Fix in the SVG itself (adjust viewBox) or add a small `margin-left`/`translate` nudge.

```css
/* Play icon in a circle: nudge right ~2px */
.play-icon { transform: translateX(1px); }
```

Prefer fixing in the SVG (adjust padding within the viewBox) so no extra CSS is needed by consumers.

## Shadows Instead of Borders

Borders are flat. A layered `box-shadow` creates depth that adapts to any background, including images and gradients.

```css
.elevated {
  box-shadow:
    0px 0px 0px 1px rgba(0, 0, 0, 0.06),
    0px 1px 2px -1px rgba(0, 0, 0, 0.06),
    0px 2px 4px 0px rgba(0, 0, 0, 0.04);
}

/* Hover: same structure, slightly darker */
.elevated:hover {
  box-shadow:
    0px 0px 0px 1px rgba(0, 0, 0, 0.08),
    0px 1px 2px -1px rgba(0, 0, 0, 0.08),
    0px 2px 4px 0px rgba(0, 0, 0, 0.06);
}
```

Three layers: (1) 1px ring for edge definition, (2) tight directional shadow, (3) ambient spread. Transition with `transition-[box-shadow]`.

**When to prefer shadows over borders:**
- Elements on varied backgrounds (images, gradients, mixed colors)
- Cards, inputs, dropdowns where depth matters
- Hover states that need subtle lift

**When borders are fine:**
- Dividers and separators (purely structural)
- Tables and dense data grids
- When the design system explicitly uses border tokens

## Image Outlines

Add a 1px semi-transparent outline to images for consistent edge definition and depth, especially in design systems where other elements have borders.

```css
.image-polished {
  outline: 1px solid rgba(0, 0, 0, 0.1);
  outline-offset: -1px;
}

.dark .image-polished {
  outline-color: rgba(255, 255, 255, 0.1);
}
```

The `outline-offset: -1px` places the outline inside the image bounds so it doesn't add to the element's size. Works on `<img>`, avatar containers, and thumbnail wrappers.

## Quick Reference

| Scenario | Solution |
|----------|----------|
| Nested rounded elements look off | `outer-radius = inner-radius + padding` |
| Button icon+text looks unbalanced | Reduce padding on the icon side by ~4px |
| Card edges disappear on white bg | Layered `box-shadow` (ring + directional + ambient) |
| Images float without definition | `outline: 1px solid rgba(0,0,0,0.1); outline-offset: -1px` |
| Play icon looks off-center | Nudge with `translateX(1px)` or fix SVG viewBox |
| Border doesn't work on gradient bg | Replace with `box-shadow` ring: `0 0 0 1px rgba(...)` |
