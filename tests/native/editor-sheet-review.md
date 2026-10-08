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
