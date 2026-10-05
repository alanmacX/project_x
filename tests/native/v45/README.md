# Smart colour and UI review — 2026-10-05

MatePad Mini: portrait 1600×2560; app-only landscape/dark appearance QA 2560×1600. Temporary EntryAbility overrides restored before the final signed debug build; system theme/orientation settings were not changed. Personal screenshots remain outside Git.

## Root causes and fixes

- Image extraction returned colour names without cluster proportions. Ranking assigned 1, 1/2, 1/3 to clusters regardless of image coverage, exaggerating small accents. Extraction now retains normalized cluster weights, including alpha and the existing perceptual weighting.
- Small cards received a square-root area vote. Votes now follow visible bounding area, so small red artwork does not outweigh large yellow artwork. This is a bounded estimate; fully occluded cards still contribute and per-pixel compositing of the entire artwork is not performed.
- Successive radial fields painted weak accents over stronger tones with a minimum 55% opacity. Paint weaker fields first and derive opacity from relative weight. Replace the aggressive Overlay lighting pass with a restrained second source-over layer; yellow no longer turns orange/red through channel multiplication. Keep the final blur and the existing slow native motion.
- Signature v8 includes subject version, subject photo/shape mode and background element coverage. Movement/rotation retains the existing colours and does not enqueue new extraction. Manual re-extraction caches a bitmap for its actual anchors, instead of reusing the old pose's image under an identical palette signature. Stale async results cannot overwrite newer artwork inputs.
- Source position mapping was reviewed against the board's bottom-left rotation pivot: x uses BOARD_W and y uses BOARD_H; this intentionally matches app/widget rendering and was retained.

The existing mostly yellow native canvas changed from a red/orange background to a yellow/gold wash after the migration. Worker-level tests check a 94%-yellow/6%-red image, a large yellow card with a small red card, transparent samples, hue preservation, movement-stable signatures and manual pose invalidation. Model, album, canvas capabilities, capability framework, local sharing and timetable display regressions pass.

## Actual UI operations and changes

Opened home layer selection/group frame, canvas picker, background sheet, editor background/content tabs, expanded substrate settings, capability appearance and capability picker. Inspected dark landscape home and its cream/dark section hierarchy, plus portrait editor typography and handles. Native HDS top bar labels remain readable in the light editor.

- Canvas menu create/duplicate actions used default blue styling inconsistent with the app. Apply shared control/selected colours while retaining native Buttons.
- Home background entry now has a native chevron and an explicit accessibility action, distinguishing background adjustment from adjacent artwork-file import.
- Capability picker left an oversized blank bottom region on the tablet. Bound height by the number of results and cap it at 78% of available space, preserving a scrollable list and fixed close/no-capability actions.

Coverage limits: this is a native review of the listed surfaces, plus shared-component/source review, not an exhaustive claim that every capability/editor validation state or all screen sizes were exercised. No new device-FPS claim; background work remains in TaskPool, native motion remains compositor-driven, and dragging does not decode or extract palettes. No external sharing message was sent.
