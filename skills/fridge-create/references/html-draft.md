# Static HTML card — supported v2 authoring

HTML belongs to the `.fridge` framework, not a parallel website. Card geometry, grouping, host thickness/shadow, editor controls, sharing and one native capability remain the normal card model.

## What works

- Container `fridgememo-template`, version **2**, state schema 2; native-only files keep version 1.
- `card.html` stores `version:1`, `designVersion:1`, logical `width`/`height`, original `source`, and `previewElementId`.
- That ID points to a normal image element holding the offline appearance cache. Embed the PNG in assets, like any other image. The source survives save/export/import; import and duplicate remap this ID with the layer.
- App, desktop and platform-independent previewer draw the same local cache. No HTML decoding or Web creation during drag, rotation, grouping or Form updates.
- At most one normal native capability; place it with capBox and leave its region blank in HTML. Time/date/calendar/battery/progress/local events/timetable use existing host data and permission semantics. No arbitrary script data bridge. Album retains its own exclusive appearance.
- Native editing works on normal layers, card geometry and capability. App does **not** currently have an HTML source editor or rerenderer. Agent edits source externally and rebuilds its cache. Clearly disclose this.

## Authoring workflow

1. Read the current generated design contract, colors/radii and capability metrics. Source must use system fonts, fit its fixed viewport, avoid app controls and leave native text slots readable. Use host-style cream colors, subtle depth and restrained accents; creativity may use static HTML/CSS gradients and typography. Do not rasterize native dynamic content into the cache.
2. Prepare source.html + config.json (`width` <=320, `height` <=420, optional supported `capability` and normalized `capBox`). Native frame sizes and source aspect should match initially.
3. `node scripts/fridge-html-card.cjs prepare source.html config.json preview.html`. Open the resulting served local page. It isolates the appearance in a script-free, network-free iframe. The helper displays the iframe at 2× scale. Capture exactly width*2 × height*2 pixels starting at (0,0) to PNG. No browser chrome or capability text in that cache. Convert a JPEG screenshot to PNG if needed without changing its visual content.
4. `node scripts/fridge-html-card.cjs pack source.html config.json appearance.png work.fridge`. It uses the production reader, includes the original HTML source, cache asset and native capability.
5. Run the package checker, import in both browser and native previewer, check clipping/empty/long capability content and compare. Include a QA receipt. Browser review never proves real desktop Form verification.
6. For a whole canvas, combine these ordinary cards and merge/rekey their assets, keeping html.previewElementId linked to its layer. Exporting from App handles this automatically.

No user JS, event handlers, iframe/object/embed, form controls, remote resources/fonts, CSS/SVG animation, fetch, filesystem bridge or account access. Static SVG gradients may refer to local IDs via url(#id). Source contains only static local appearance; images must be embedded data URIs. The authoring CSP also blocks any unknown resource paths. Unknown template/design versions are rejected, not silently stripped. Runtime never executes source. Keep source/version/cache separate so later renderer/design updates can rebuild from the original source with user approval and visual QA.
