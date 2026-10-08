---
name: fridge-create
description: Generate or refine editable offline 冰箱贴 .fridge card or canvas packages, following the app’s capability and design contracts. Use for requests to create 冰箱贴 works or HTML card drafts; not for generic websites or app source changes.
---

# Fridge Create

Create editable works, not flattened screenshots of a whole canvas. Respond in the user's language.

Read [current-format.md](references/current-format.md) before writing any package. Use the included [native example](examples/native-canvas.fridge) as a format baseline, not as a mandatory composition.

## Version gate

The shipped reader supports only `fridgememo-template`, version 1, `card`/`canvas`, state schema 2. HTML templates are not implemented. Never place invented `html`, `slots`, providers or script assets in a v1 `.fridge` and claim it works. For an HTML request, deliver clearly labelled `.draft.json` and a local HTML prototype, explain that integration is pending, and follow [html-draft.md](references/html-draft.md). Do not downgrade HTML silently into an image or native approximation.

## Authoring

Infer a coherent visual direction, target widget aspect, and necessary data from the request. Ask only for information that affects the result. If unspecified, use square 4×4 and a compact 3–6-card composition; keep the current 16-card limit. Preserve useful negative space and readable hierarchy. Aesthetic freedom belongs to artwork; app controls and behavior belong to the host.

Each card has at most one capability. Decorative text/photo/shape elements are not extra data sources. Keep native fields dynamic rather than painting fake current time, battery or courses onto an image. Battery has no status caption or percent sign; its host renderer supplies the ring and numeric reading. Album geometry belongs to the host (4.9% inset per side, cover radius 14vp, card radius 20vp), with square local cover images.

For generated native cards, prefer `cream` material or deliberate artwork colors, dark readable ink, and a small consistent palette. Use the host reading surfaces (`cloud`, `bare`, `tag`, `sticker`; `badge` for battery only), not a homemade duplicate backing or guessed glass blur. Rectangular card corners, cutout white border, thickness and shadows are host-owned.

Images must be explicitly supplied or lawfully generated/obtained and embedded. Do not invent a cutout contour, fake a user photo, ship online image URLs, or reference agent filesystem paths. Without usable images, use native text/shapes rather than claiming a photo-based result.

Use explicit unique card/element IDs, preserve group relations, and order z values intentionally. Whole-card transforms are separate from card-internal element positions. Do not normalize x/y/w/h all using the same scale; read the coordinate contract.

## Data and privacy

Do not scrape private data to fill a template. Timetable and agenda use empty/unbound placeholders unless the user deliberately provides the data; do not invent their schedule. Battery starts unknown. No weather/parcel/fetch/online music capability. No arbitrary file, clipboard, account, health or network bridge. A shared binding does not authorize access to the recipient's data.

Importing a file into the offline app is the intended flow. Do not add a cloud AI endpoint to the app or promise app-store “single-app” approval based on this skill.

## Verify and deliver

If the FridgeMemo repository and DevEco TypeScript runtime are available, run:

`node /path/to/FridgeMemo/scripts/fridge-package-check.cjs /absolute/path/output.fridge`

The helper runs the actual current reader and checks identifiers, supported capability types and geometry preservation. It is not a complete media decoder, visual validator or security boundary. Never claim visual acceptance based only on JSON validation.

Match the installed app contract before generation; app updates may change supported capabilities and design profiles. Do not assume this reference supports newer fields. Start with the platform-independent browser previewer documented in previewer/README.md, which bundles the app's pure production models. An unsupported capability blocks visual acceptance, even if JSON import succeeds. Use the native FridgePreviewer QA route in FRIDGE_PREVIEWER.md as a comparison host; compare source fingerprints and PNG/version/dimension reports. Neither browser nor native QA routes replace real Form testing.

Check target aspect, long text, overlap/z order, minimum size, empty data, missing assets and source permissions. Use the app's own renderer for preview if available. An HTML browser preview cannot prove native app/Form equality. If preview or native import has not been tested, state that plainly.

Deliver the actual file, a concise explanation of editable layers and data binding, and any compatibility limitations. Do not share externally or install onto a device unless authorized by the user.
