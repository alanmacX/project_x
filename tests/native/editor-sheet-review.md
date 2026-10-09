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
