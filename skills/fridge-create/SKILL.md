---
name: fridge-create
description: Generate or refine editable offline 冰箱贴 .fridge card or canvas packages, following the app’s capability and design contracts. Use for requests to create 冰箱贴 works or static HTML cards; not for generic websites or app source changes.
---

# Fridge Create

Create editable works with deliberate art direction, not flattened screenshots or a default grid of labelled rectangles. Respond in the user's language.

Read [current-format.md](references/current-format.md) before writing any package. Use the included [native example](examples/native-canvas.fridge) as a format baseline, not as a mandatory composition.

## Version gate

Read the generated [design-contract.json](references/design-contract.json) first. It records the app version, supported capabilities/fields, current design tokens and identities for production models, materials and both renderers. In the app repository run `node previewer/build.cjs --check`; stale generated artifacts must be rebuilt and reviewed before authoring. App marketing version alone is insufficient during pre-release polishing: compare the implementation identities as well. The current package format has no persisted design profile; do not invent one. See [upgrades.md](references/upgrades.md) when a release or design changes.

The shipped reader supports `fridgememo-template` versions 1 and 2, `card`/`canvas`, state schema 2. Native-only packages remain v1. Static HTML cards use v2: preserve HTML source, a local image-layer cache, and at most one native capability. Read [html-draft.md](references/html-draft.md) for the supported workflow and limits. Arbitrary scripts, dynamic DOM and network providers are unsupported. Never claim the cache is live HTML, or discard the source to flatten a work.

## Static creative ceiling

For ambitious static work, read [static-authoring.md](references/static-authoring.md). Use the offline renderer to bake only decorative HTML/CSS/SVG into a source-linked cache; use real alpha-derived silhouettes, then assemble independent cards without flattening their capabilities. New authoring tools handle viewport capture and asset/ID remapping deterministically. Prefer rich composition and material over more live code: no animation, app WebView, scripts or new data providers.

## Creative direction and assets

For a themed or visually ambitious work, read [art-direction.md](references/art-direction.md). Research the visual world, actively look for appropriate source imagery when it would strengthen the design, and consider original image generation for missing motifs. Build a distinctive hierarchy and silhouette composition before filling slots with capabilities. The examples are structural baselines, not designs to copy. Don't prematurely fall back to zero assets because that is easier to validate.

Use [subject-tool.html](../../../previewer/subject-tool.html) for actual alpha-derived subject geometry. It preserves PNG bytes and exports production-derived contours plus diagnostics; both photo cutouts and intentionally designed original silhouettes are valid subject cards. Never guess a subject outline or flatten the whole canvas to fake its appearance. Keep a source/attribution sidecar for acquired or generated assets and inspect the complete rendered work before delivery.

## Authoring

Infer a coherent visual direction, target widget aspect, and necessary data from the request. Ask only for information that affects the result. If unspecified, use square 4×4 and a compact 3–6-card composition; keep the current 16-card limit. Preserve useful negative space and readable hierarchy. Aesthetic freedom belongs to artwork; app controls and behavior belong to the host.

Each card has at most one capability. Decorative text/photo/shape elements are not extra data sources. Keep native fields dynamic rather than painting fake current time, battery or courses onto an image. Battery has no status caption or percent sign; its host renderer supplies the ring and numeric reading. Album geometry belongs to the host (use current tokens in design-contract.json), with square local cover images.

Use a theme-appropriate palette with readable contrast; `cream` is available, not mandatory. Use the host reading surfaces (`cloud`, `bare`, `tag`, `sticker`; `badge` for battery only), not a homemade duplicate backing or guessed glass blur. Rectangular card corners, cutout white border, thickness and shadows are host-owned. Reading surfaces now default to `readingMaterial: "paper"` (warm white fine paper); `"matte"` is the lighter translucent alternative. Use [surfaces-and-transparency.md](references/surfaces-and-transparency.md) for material and transparent-canvas QA. Never persist experimental `readingMaterialStudy` IDs. Use `readingEdge` / `readingOutside` for intentional inside/outside attachment and `readingHook` (0–1) for hole placement when that host style supports it. `capFree:true` enables flexible capability placement; measure actual content rather than assuming the whole subject bounds are safe. Canvas frames are independent: `frameStyle` plus `frameMaterial` (`stone`, `walnut`, `oak`) work with every background; they are host-rendered and never painted into cutouts.

Images must be explicitly supplied or lawfully generated/obtained and embedded. Do not invent a cutout contour, fake a user photo, ship online image URLs, or reference agent filesystem paths. If source acquisition fails, try an appropriate alternative or original generation before a deliberate native-only fallback. Explain the actual gap rather than claiming a photo-based result.

Use explicit unique card/element IDs, preserve group relations, and order z values intentionally. Whole-card transforms are separate from card-internal element positions. Do not normalize x/y/w/h all using the same scale; read the coordinate contract.

## Scene artwork

A timed scene is authored as one ordinary card, not a new package kind. Local schedules, target canvas IDs and acknowledgement history do not travel with artwork. Supply separate files for alternate canvases; the user sets rotation and trigger times in App. Manual canvas selection pauses rotation while retaining its settings. See the scheduling boundary in [current-format.md](references/current-format.md). Never promise precise background alarms from a desktop Form.

## Data and privacy

Do not scrape private data to fill a template. Timetable and agenda use empty/unbound placeholders unless the user deliberately provides the data; do not invent their schedule. Battery starts unknown. No weather/parcel/fetch/online music capability. No arbitrary file, clipboard, account, health or network bridge. A shared binding does not authorize access to the recipient's data.

Importing a file into the offline app is the intended flow. Do not add a cloud AI endpoint to the app or promise app-store “single-app” approval based on this skill.

## Verify and deliver

If the FridgeMemo repository is available, run this Node-only checker:

`node /path/to/FridgeMemo/scripts/fridge-package-check.cjs /absolute/path/output.fridge`

The helper runs the actual current reader and checks identifiers, supported capability types and geometry preservation. It is not a complete media decoder, visual validator or security boundary. Never claim visual acceptance based only on JSON validation.

Match the installed app contract before generation; app updates may change supported capabilities and design profiles. Do not assume this reference supports newer fields. Start with the platform-independent browser previewer documented in previewer/README.md, which bundles the app's pure production models. Render the complete generated package at its target aspect ratio; inspect all cards, cutout alpha, clipping, layer order, attachment profiles, text fit and empty data. The browser supports all current native capabilities using production layout/data/contour modules and material assets. Unknown capabilities or missing resources block acceptance even when JSON parses. Static previews do not validate GIF playback, system Symbols or live device data; never mark pixel parity or actual Form verification from browser output alone. Use the native FridgePreviewer QA route in FRIDGE_PREVIEWER.md as a comparison host; compare source fingerprints and PNG/version/dimension reports. Neither browser nor native QA routes replace real Form testing.

Check target aspect, long text, overlap/z order, minimum size, empty data, missing assets and source permissions. Use the app's own renderer for preview if available. An HTML browser preview cannot prove native app/Form equality. If preview or native import has not been tested, state that plainly.

Deliver the actual file, a concise explanation of editable layers and data binding, and any compatibility limitations. Do not share externally or install onto a device unless authorized by the user.

For a generated work, save a separate `.qa.json` receipt alongside the `.fridge` with the contract identity, target dimensions/time, package checksum and actual validation/visual-review results. Keep renderer metadata out of the v1 package itself. Retain source assets and editable package; do not flatten the deliverable to avoid later design upgrades. A receipt records evidence, never guarantees future app or Form behavior.
