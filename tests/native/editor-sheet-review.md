# Editor sheet review — 2026-10-09

Native API 24 Pura X Max emulator: folded 1264×1848 and unfolded 2584×1828.

- Portrait: embedded ArkUI bindSheet with 40% / 78% control detents, native drag bar, transparent mask and outside interaction. Preview stays visible at both detents.
- Landscape: persistent full-height controls on the right. Sheet anchor is outside the adaptive branch so folding back restores the sheet.
- Checked opening, dragging up, dragging down, folding/unfolding and Done without a residual overlay.
- Subject editing excludes hidden capability overflow; main preview and shape gallery center the subject. Layer thumbnails use a common frame; capability entries use native symbols instead of illegible miniature text.
- Color presets and picker share a row. Subject appearance is in Color; photograph mode does not expose ineffective base-color controls.
- Capability picker uses native Search/List/ListItem with a larger sheet; life-category rows were checked for truncation and compression.
- Battery policy is badge/cloud/brush; unsupported saved styles migrate to badge. Empty album title is omitted.

Validation: native assembleHap; 11 regression suites (editor-workspace, editor-visual-choices, cloud-capability, capability-framework, model, album, previewer, battery-ring, shared-capability, nav-menu, editor-motion); previewer build --check.

Local screenshots: output/editor-native-review/{phone-preview,phone-controls,wide-controls}.jpeg.

Limits: no physical-device frame-rate measurement or API 26 material rendering verification in this pass.

## Native gesture handoff — 2026-10-10

- Removed EditorScrollDetent, touch tracking, content-only translation and distance-only release thresholds.
- Portrait Scroll now uses PARENT_FIRST forward / SELF_FIRST backward with the embedded bindSheet. Landscape keeps SELF_ONLY inside persistent controls.
- Preview follows measured native sheet height; no threshold-triggered secondary spring. Card composition bounds are cached independently of height.
- Phone emulator 1320×2848: content swipe at 900 px/s expanded sheet Scroll bounds from [0,1839][1320,2847] to [0,920][1320,2848]; corresponding layer strip bottom changed from 1785 to 867. Downward content swipe restored original bounds. Additional fast up / slow down swipes and Back executed.
- assembleHap passed; all 53 remaining host regression suites passed (obsolete custom gesture suite removed). Frame-cache regression covers 126 continuous pane-height samples without repeated outline tracing.
- This verifies native gesture handoff and settled geometry, not physical-device tactile quality or frame-rate performance.

## Editor and home control surfaces — 2026-10-10

- Frame node is retained at the canvas coordinates throughout editor entry/exit; opacity follows the existing board transition instead of mounting at exit completion.
- Calendar and other automatic capabilities have no Data tab. Countdown, anniversary, world clock, agenda and timetable retain editable data; album retains cover/details. Capability replacement clamps the selected inspector section.
- Home controls use an independent root surface above cards and frame. Only its four 44vp target rectangles participate in hit testing; the rest remains available to the card surface. Artwork consumes the same atomic resize/rotation pose. Geometry commits preserve stored z order.
- Phone emulator 1320×2848: checked native sheet at both detents; layer strip continues beneath the rounded top corners without a straight viewport cutoff. Selected-card Edit opens the editor from the root controls. Resize release retains all four controls and updates their bounds (e.g. resize target [1118,663][1267,812] to [1101,664][1250,813]).
- Found an additional interaction issue: reapplying the same scheduled scene cleared selection. Same-scene refresh now retains selection; entering a board gesture invalidates older asynchronous scene calculations.
- assembleHap and 54 host regression suites passed. Regression added for control pose ownership, editable tabs, same-scene selection and preserved card stacking.
- No physical-device frame-rate claim; frame node retention is verified in code, not a device frame-by-frame video in this pass.
