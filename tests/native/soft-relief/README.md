# Hollow transparent frame and soft-light card relief

2026-10-09, MatePad Mini, signed debug Profile with approved transparent Form entitlement.

- Transparent backgrounds carry `transparentFrame`: auto/light/dark/none. Default auto uses base/dark native color resources; explicit choices are native segmented controls in canvas background settings. A hollow 4.5vp rim with directional highlights and inner edge sits above cards without filling the center or intercepting input. App, native Form and browser retain the setting, including editable package normalization.
- Card relief uses a thinner 1.35 artwork-unit sidewall, a warm broad cast shadow (radius9, offset4.5), and short contact shadow (radius1.6, offset.6). Rounded cards use native shadows. Subject silhouettes use cached Gaussian-falloff contour bands, replacing three visibly discrete rings. Direct ArkUI Path.shadow was tried and rejected because the Form rendered a bounding rectangle. Both native hosts now use the same contour recipe, never alternate baked vs live backing paths. Browser uses matching soft filters.
- Production app startup and background panel no longer wait for the unused alternative silhouette depth bake. Placement/rotation remain transformed cached artwork; contour bands cache by scaled radius/color. This change has not been profiled for refresh-rate certification. Band count is higher than the previous three-ring approximation, so GPU/frame cost must still be measured on broader device scenes.
- Fixed browser transparent mode inadvertently emitting a full opaque root rectangle. renderLayers returns an independent frame layer as well as card layers.

## Acceptance

Signed native build and overwrite install passed. Real launcher screenshots verify white and dark hollow rims, unchanged wallpaper through empty space, contour relief without the rejected rectangular shadow block, and entering the app through blank widget space. Screenshots remain local under output/soft-relief. Manual light/dark choices verified; automatic system theme switching is implemented through resource qualifiers but not toggled on device during this run. Desktop screenshots on dark wallpaper cannot certify pixel-identical shadow contrast vs the white app surface.

All 50 host regression suites passed before the final guard/highlight cleanup; focused relief, transparent package and previewer tests re-run afterward. New tests cover frame normalization, omission of browser opaque fill and total alpha conservation across contour bands. No signed profiles, certificates or keys committed.
