# Remotion Best Practices

Video creation in React. Use when dealing with Remotion code.

## Cloud Render
```bash
infsh app run infsh/remotion-render --input '{
  "code": "...", "duration_seconds": 3, "fps": 30, "width": 1920, "height": 1080
}'
```

## Available Imports
```tsx
import { useCurrentFrame, useVideoConfig, spring, interpolate, AbsoluteFill, Sequence, Audio, Video, Img } from "remotion";
import React, { useState, useEffect } from "react";
```

## Topic References
Load these rule files for specific needs:
- `rules/animations.md` - Fundamental animation skills
- `rules/sequencing.md` - Delay, trim, limit duration
- `rules/timing.md` - Interpolation curves, spring animations
- `rules/transitions.md` - Scene transitions
- `rules/text-animations.md` - Typography patterns
- `rules/subtitles.md` - Captions and subtitles
- `rules/audio.md` - Audio import, trim, volume, speed
- `rules/audio-visualization.md` - Spectrum bars, waveforms
- `rules/sound-effects.md` - Sound effects
- `rules/ffmpeg.md` - FFmpeg operations
- `rules/3d.md` - Three.js / React Three Fiber
- `rules/charts.md` - Data visualization
- `rules/assets.md` - Importing images, videos, fonts
- `rules/tailwind.md` - TailwindCSS usage
- `rules/voiceover.md` - AI-generated voiceover (ElevenLabs)
- `rules/parameters.md` - Parameterizable videos with Zod schema
- `rules/maps.md` - Mapbox animated maps
