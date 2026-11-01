# Template layout and homepage preview review — 2026-11-01

## Fixed

- Reproduced the homepage showing only the background/frame while the workspace showed the palette clock. The offscreen builder snapshot did not capture the Canvas-painted template. Snapshot/share paths now use synchronous native shape/text/image nodes driven by the same scene and text-fitting functions; the interactive App/Form retains Canvas rendering.
- Thumbnail identity now includes a generated native-render fingerprint (models, native rendering code, painting code and local materials), so an upgraded renderer cannot indefinitely reuse stale pixels for unchanged user data. The background is explicitly beneath every card. Enabling full-canvas mode no longer assigns a negative card layer.
- Shared measured text fitting: bounded slots, numeric shrink-to-fit, two-line primary titles, ellipsis that preserves combining marks, flags and joined emoji. Native snapshots use vp text dimensions to match the Canvas coordinate system at different system font scales.
- Rebalanced countdown number/unit/date slots, day-ring value/caption slots, lunar rows, two-city hours/minutes and photo-anniversary title/count/unit slots. Removed synthesized bold from the already-black condensed font.
- All-day agenda labels, non-today event/course dates, impossible-date placeholders, past/future countdown labels, semester state, precise weekly time-axis labels, six-row months and DST-safe annual civil-day counting.
- Light calendar pills use dark text. Course cells retain dark labels; course slips adapt their surface to the selected palette. Battery values have a stable contrast window across the changing fill. Album record placeholders have a readable cover surface.

## Verification

- `tests/template-layout.test.cjs`: **12,480 scenes / 90,720 text slots**: 39 designs × 4 data profiles × 5 boundary dates × 4 aspect ratios × 4 palettes. Additional 144 battery cases and targeted six-row month, DST, impossible-date, countdown and all-day checks.
- Existing five ensemble recipes retain their composition-boundary and serialization checks in `card-templates.test.cjs`.
- Browser visual review: **78 rendered examples / 587 text slots**, using the actual bundled font and measured widths; no overflow or browser exceptions. Generated contact sheet and JSON are in `output/template-review/` (local QA artifacts).
- HarmonyOS simulator: reproduced missing template pixels before the fix; homepage now displays the clock rectangles and hands after upgrade and cache regeneration. The workspace still uses the Canvas renderer. Screenshots are local QA artifacts, not release assets.
- Full suite: **107/107 passed**. Native release `assembleApp`, 4 storage-integrity suites, release-page audit and generated-preview check passed. No source artwork, canvas ID or system binding was deleted.

Live Canvas scene-cache regression also exercises palette and photo changes on the same object, matching ArkUI prop mutation; offscreen snapshot selection is explicitly independent of synchronous image loading.

A native countdown was edited with a long Latin title: the live Canvas updated to two lines with an ellipsis while keeping the number, phase and date separate; returning to the homepage regenerated its image. The atomic template layer thumbnail now retains its capability/photo instead of clearing them like a creative backing.
