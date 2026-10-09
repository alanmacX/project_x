# Static authoring with a higher visual ceiling

Static frontend power belongs to **authoring**, not runtime. Use CSS/SVG layout, local gradients, patterns, clipping, typography, layered imagery and custom silhouettes; render once, preserve source and let the app draw a cache. Avoid animated effects, WebView, JS and extra host data access. No plugin, arbitrary URL provider or undocumented layout field is required.

## Separate three responsibilities

1. Artwork: an intentional material/shape/photo/decorative type system. Can be complex static CSS/SVG; rasterize just this part.
2. Native binding: one capability, recipient device data, host density/layout/contrast/backing and minimum size. Leave a quiet region in artwork; never bake clock, battery or private schedule values.
3. Composition: multiple editable card instances with their own geometry/z/group. The whole canvas must not become one screenshot.

Use native text/image/shape elements when they are enough. HTML is worthwhile for a cut paper contour, textile/repeating pattern, editorial typography or complex original graphic that native primitives cannot easily represent. Do not duplicate host white border, relief/drop shadow or native reading surfaces. A detailed static asset costs one decoded image at runtime; many layered translucent primitives may cost much more. Prefer cache over dozens of ornamental layers, but keep user-editable labels and each independent card separate.

## Reproducible renderer

```
node scripts/fridge-static-render.cjs source.html config.json output.fridge
```

Requires Playwright and Chromium in the authoring environment. Optional `FRIDGE_CHROME=/absolute/path/to/chrome`; `NODE_PATH` may point to the available workspace dependency runtime. Never embed these paths in artwork.

Config includes width/height (logical vp, <=320×420), optional capability/capBox and optional `shape:"subject"`. Output: editable v2 package, `.appearance.html`, `.appearance.png` and `.render.json`. The renderer disables document JS, denies HTTP requests, captures exactly 2× transparent viewport pixels and packs through the actual reader. It does not claim native or Form verification.

Subject mode traces the same screenshot alpha with production `SubjectGeometry.traceMask`, retaining holes and disconnected parts; the original HTML cache layer stays visible and source-linked; the subject image supplies only the mask (`subjectPhoto:false`), so artwork is drawn once. The host adds border/relief. Keep the opaque silhouette close to the viewport bounds (small breathing space is fine); huge transparent padding wastes the native card box. Inspect alpha on dark/light and re-trace after every shape edit. Source itself is not editable in the App yet; externally regenerate the cache to change it.

The included `examples/static/silhouette.html` + `.json` is a deterministic shape/material test, **not a composition to repeat for every user**. It demonstrates a slight handmade outline with a quiet slot for a native clock. Inline SVG in HTML does not need an HTTP `xmlns` attribute; the source policy rejects HTTP resource strings. Use local SVG IDs, system fonts and data image URIs only. More complex static filter/pattern recipes must pass the validator and be visually inspected; unsupported resources are failures, not reasons to disable validation.

## Assemble without flattening

```
node scripts/fridge-compose.cjs manifest.json canvas.fridge
```

Example manifest (input paths relative to manifest; geometry follows current-format.md):

```json
{"canvasAspect":1,"background":{"mode":"transparent","frameStyle":"light","frameMaterial":"walnut"},"cards":[
 {"file":"hero.fridge","x":20,"y":35,"w":150,"h":210,"rot":-4,"z":1,"groupId":"collected"},
 {"file":"note.fridge","x":165,"y":250,"w":150,"h":130,"rot":3,"z":2,"groupId":"collected"}
]}
```

Optional `backgroundImage:"background.png"` embeds a locally prepared static photo/graphic background; this is artwork, not an invented smart-gradient provider. Native smart/blend must keep their actual host-generated image/palette. The assembler validates inputs, rekeys assets and card/element/HTML cache IDs, preserves source and groups, uses the production sharing allowlist for recipient bindings, then validates output. It takes 1–16 single-card packages. Add native editable elements before packing where useful; do not invent a post-rasterization live HTML data bridge.

## Upgrade and QA

Archive sources, config, unmodified input images, `.sources.json`, contract identities and exported `.fridge`. A future design update can re-render source caches and recompose assets without losing original layers or bindings. Pure host changes (corner/shadow/frame/native capability) should update through the normal release contract rather than editing the artwork. For cache changes run package checker and compare rendered output again; never automatically bless a changed baseline.

Review full canvas at realistic 180/300/420 width, dense/empty native data, long text, contrast, edge clipping, intentional overlap and actual silhouette. Record browser/native/Form results separately in `.qa.json`. `.render.json` records the cache pipeline only, not design acceptance. Static source text and photos are shared artwork: do not use them to bypass the provider-data sanitizer.
