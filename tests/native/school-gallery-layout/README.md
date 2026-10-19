# School keyboard layout and gallery return — 2026-10-19

Device: connected MatePad tablet, landscape 2560×1600. Production signed debug HAP installed with `hdc install -r`; no uninstall, library reset, widget rebind, cloud toggle or subscription changes.

## Fixes

- School picker keeps its header/search fixed. School rows, explanatory text, pagination, generic-provider shortcuts and privacy text share one clipped List. Keyboard avoidance can reduce the list without fixed footer siblings consuming its whole height or escaping the panel's rounded bounds. Generic URL entry is scrollable. Choosing/closing from search stops text editing.
- Return uses the existing shared-preview rectangle animation only when the whole target fits between gallery chrome and the floating creation dock. Clipped/offscreen/missing targets use a 180ms local cached-image dissolve with a 2% shrink. No auto-scroll, preview generation or persistence wait gates returning; the gallery is interactive underneath.
- Scroll and filter changes invalidate retained target rectangles. A cached image remains available independently of geometry for widget-route returns.
- Retained HDS navigation keeps its title in layout and uses Hidden visibility while editing. Previously hideTitleBar changed viewport height and clamped the gallery scroll offset. Native material is never faded/transformed/snapshotted to implement this fix.

## Native observations

- Actual production flow: existing course card → edit → data → timetable → import → school picker → focus search. With the keyboard open the school list retains bounds `[179,384][2383,658]` (274px high). School rows are visible, with no generic buttons outside the rounded panel.
- Searching `ZJUT` with the keyboard open displays 浙江工业大学. Closing the school picker dismisses the search keyboard. No login credentials, course import confirmation or edits to course data were used.
- After scrolling, the original large preview is clipped. A widget-style EntryAbility Want (`canvasId`, `canvasDimension`) opens that document. Returning retains its **exact** clipped bounds `[57,105][1055,310]` before/after. Before preserving the native title layout, the bottom edge incorrectly moved to 547px.
- A second widget-parameter route opens the large canvas while the gallery is filtered to 2×2, so the target is absent altogether. Returning preserves that filter and has no lingering transition image. The gallery was restored to 全部 after verification.
- These route checks use the real production ability and UI with the same parameters as a widget; they do not claim an actual launcher-widget tap was performed. Exact animation trajectories and interruption safety are additionally covered by tests executing the actual page methods, not inferred from settled screenshots.

Ignored `output/` evidence: `school-keyboard-fixed.png`, `school-keyboard-search-fixed.png`, `school-close-keyboard-cleared.png`, `gallery-before-return-stable.png`, `gallery-after-return-stable.png`, `gallery-filtered-before-widget-route.png`, `gallery-filtered-widget-return.png`.

## Checks

94/94 suites; native assembleHap; production package page/extension audit; git diff whitespace check. Regression cases include fully visible targets preserving the original 260ms shared motion, top/bottom/horizontal clipping, no retained anchor, instant gallery interaction, no persistence/preview wait, and stale animation callbacks after another navigation.
