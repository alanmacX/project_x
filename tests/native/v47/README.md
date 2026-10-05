# Smart gradient depth regression — 2026-10-05

The v45 hue correction also removed Overlay lighting and used the weighted colour average as the foundation. For a single colour, every subsequent source-over layer had that same colour; the result was a mathematically flat fill despite blur and animation.

Restore the Overlay light folds at 65% and use a darker, subdued foundation derived from the measured palette. Keep measured cluster proportions, visible-area voting, strongest-last ordering and proportional opacity, so tiny red accents do not acquire equal influence. Static worker and ArkUI compositor use the same foundation and lighting strength. Bump background signature to fluid-v9 to invalidate existing flattened bitmaps. Drag does not invoke palette extraction; animation duration remains 180 seconds.

Validation:
- background-palette.test.cjs: measured proportions, transparency, yellow-dominant output despite red accent, single-hue Lab lightness span >8, worker output and cache behavior.
- For a controlled single-yellow 96×128 field, the former algorithm has lightness span 0; this revision has span 11.89.
- album.test.cjs and canvas-capabilities.test.cjs pass.
- Signed debug build succeeds, installs and starts on MatePad Mini 5KLBB25C19200110.
- Actual portrait home screenshot inspected at /tmp/fluid-restored.jpeg: yellow/gold hue retained, darker blurred outer areas and brighter inner areas, intact existing card layout.
- No new frame-rate measurement or desktop-widget lifecycle timing measurement performed this turn. Changes add no per-frame task, pixel generation or image decoding.

Controlled comparison /tmp/fluid-compare.png is temporary and contains synthetic colours; native capture stays outside the repository.
