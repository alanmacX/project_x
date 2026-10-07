# Thin-paper capability backing — 2026-10-07

An optional `readingBlend: paper` material, not a migration of existing canvases. Available under capability appearance → layout/readability → blending, and the comparison sheet starts with the new paper sample. The shared CardCanvas renderer uses a #80FBF7EE translucent tint with a static generated paper-fibre bitmap at 55% opacity, compact adaptive corners (up to 10 card vp), a subtle bottom edge and one shallow shadow. It does not sample/blur the photograph, allocate generated textures, enlarge the capability box, or enable glyph halos. No full-area opaque backing sits under the translucent tint. Existing dark/custom ink is retained when it meets 4.5:1 contrast over both extreme black and white underlying photographs; other ink falls back to #10100C. The default paper opacity and a static texture do not trigger background sampling/recalculation during gestures. The existing ability opacity applies to the complete label.

Tests cover paper contrast, small corner bounds and storage normalization. Release HAP and all model test suites pass. A temporary read-only QA page used an existing device cutout with identical weekly-calendar content across old feather, paper app, and paper widget-rendering modes. Native MatePad capture confirms the expected paper appearance and both rendering modes. This is not a desktop Form-host capture or an FPS measurement. The temporary page, entry override and personal fixture were removed before the production build; no canvas data was changed.

The previous materials remain available for comparison; no default material was replaced. Albums still use their own fixed composition.

## Fibre texture revision

The previous sparse SVG strokes were imperceptible at working size. Replaced by a generated handmade tracing-paper texture, repeated at 160 card vp and clipped to the label corners. Tint opacity was reduced as fibre opacity increased to preserve the underlying image. The bitmap is static; no background sampling, image generation or procedural fibre work runs during editing. Native QA repeated the cutout/calendar app/widget-mode comparison. Removed the unused old SVG asset.

Asset: `entry/src/main/resources/base/media/reading_paper_fibres.png`. Generated using the built-in imagegen tool.

Final prompt:

> Use case: photorealistic-natural. Asset type: a seamless square paper fibre texture bitmap for a translucent tracing-paper UI label, NOT a mockup. Create an orthographic flat scan, cropped edge-to-edge, of fine warm ivory handmade tracing paper. Clearly visible natural long and short intertwined cellulose fibres, uneven sparse and dense fibre clusters, subtle softly raised paper tooth and small cloudy variations. Fibres should be visibly tactile at thumbnail size while leaving text overlaid later perfectly legible. Fairly delicate ivory and pale warm gray variation, no yellow parchment, no dark dirt, no grainy photographic noise, no scratches, no creases, no folds, no edge, no object, no writing, no border, no shadow around a sheet. Uniform neutral diffuse illumination with minute local relief. Seamlessly tileable in both directions, square. The texture fills the entire image. White ivory background, opaque asset; the application will apply transparency. Prefer compact 512 x 512 output.

Generator returned 1254×1254; asset retained without pixel edits.
