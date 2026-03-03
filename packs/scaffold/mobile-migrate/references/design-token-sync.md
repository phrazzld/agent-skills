# Design Token Sync: Tailwind → NativeWind

Goal: one token source, two predictable outputs.

## Style Dictionary setup

Keep tokens in a single folder, generate platform outputs.

Suggested structure:

```text
tokens/
  color.json
  spacing.json
style-dictionary.config.cjs
```

Minimal config:

```js
// style-dictionary.config.cjs
const StyleDictionary = require("style-dictionary");

module.exports = {
  source: ["tokens/**/*.json"],
  platforms: {
    web: {
      transformGroup: "css",
      buildPath: "build/web/",
      files: [
        {
          destination: "tokens.css",
          format: "css/variables",
        },
      ],
    },
    native: {
      transformGroup: "js",
      buildPath: "build/native/",
      files: [
        {
          destination: "tokens.js",
          format: "javascript/es6",
        },
      ],
    },
  },
};
```

Build:

```bash
npx style-dictionary build
```

## Token format: web vs mobile

One source. Different outputs.

Example token:

```json
{
  "color": {
    "brand": {
      "primary": { "value": "#0A84FF" }
    }
  },
  "spacing": {
    "4": { "value": "16" }
  }
}
```

Web output (CSS vars):

```css
:root {
  --color-brand-primary: #0A84FF;
  --spacing-4: 16;
}
```

Native output (JS objects):

```js
export const colorBrandPrimary = "#0A84FF";
export const spacing4 = 16;
```

Guideline:

- Keep units implicit for native-friendly tokens (numbers where possible).

## NativeWind configuration

Make NativeWind read the same tokens via Tailwind config.

Pattern:

1. Generate a native token file (for example `build/native/tokens.js`).
2. Import it inside `tailwind.config.js`.
3. Map tokens to `theme.extend`.

Example:

```js
// apps/mobile/tailwind.config.js
const tokens = require("../../build/native/tokens.js");

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./App.{js,ts,tsx}", "./src/**/*.{js,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: tokens.colorBrandPrimary,
        },
      },
      spacing: {
        4: tokens.spacing4,
      },
    },
  },
};
```

## Theme synchronization strategy

Keep the pipeline shallow and obvious.

Recommended flow:

1. Edit tokens in `tokens/*.json`.
2. Run Style Dictionary.
3. Consume generated outputs in both apps.

Rules that prevent drift:

- Never hand-edit generated files.
- Keep token names stable; rename rarely and deliberately.
- Use one shared `tailwind.config.js` preset when possible.

## Dark mode support

Treat dark mode as first-class tokens, not overrides scattered in code.

Two practical approaches:

Approach A: separate dark tokens:

```json
{
  "color": {
    "surface": {
      "default": { "value": "#FFFFFF" },
      "default-dark": { "value": "#0B0B0C" }
    }
  }
}
```

Approach B: themed token files per mode:

- `tokens/light/*.json`
- `tokens/dark/*.json`

For NativeWind:

- Use `darkMode: "class"` in Tailwind config.
- Toggle a top-level `dark` class based on system theme.
- Ensure both light and dark tokens map into Tailwind theme.

