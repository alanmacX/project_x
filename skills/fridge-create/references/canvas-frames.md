# Canvas frames: supported selection and creative perimeter artwork

## Native frame contract

Put frame selection in `state.background`, independently of background mode:

```json
{"mode":"transparent","frameStyle":"light","frameMaterial":"oak"}
```

`frameStyle`: `none`, `light`, `dark`, `auto`. `auto` follows the receiving device theme. `frameMaterial`: `stone`, `walnut`, `oak`. Omit for no frame; do not use names such as `marble`, `wood` or `fluid`. The checker rejects unknown fields and values instead of accepting a work that changes on import.

Choose deliberately: pale stone for a quiet gallery/collectible; oak for warm pets, notebooks or nature; walnut for dark cinema/game/music collections. A heavily decorated edge may be stronger with native frame `none`. Inspect material and theme at real widget size; a dark scene does not automatically need a dark frame.

The current contract is hollow and host-owned: eight cached perimeter tiles, rounded App/Form outer geometry, square social poster geometry, no central fill, no texture generation during drag. Width, relief, corner radii and lights are release tokens in `design-contract.json`, not portable user overrides. Every background mode supports the frame. Do not encode the host wood/stone image as a background photograph, or duplicate its shadow in subjects.

## More creative frames without a new runtime feature

A torn botanical border, graphic bracket, stamp edge or irregular collage perimeter can be an ordinary editable *decorative card*, created through the supported static HTML/image authoring path. This is artwork, not another frame material enum. Set native `frameStyle: none` if the two would compete.

Use a tight viewport and transparent central opening; preserve actual holes with the production alpha tracer. `subjectPhoto: false` plus the HTML cache layer avoids drawing source artwork twice. Keep its capability null and place it at an explicit z: behind content for a backdrop, in front only when intentional framing should occlude artwork. It counts toward the 16-card limit and can be hidden or edited like other cards. Never flatten the whole canvas into it. Do not change the other cards' positions to make a border fit without artistic intent.

For a complex perimeter split at most into a few separately editable elements/cards when that improves composition; don't create hundreds of small strips. Static SVG patterns, inline gradients and local textures allow varied print/material recipes within the existing HTML validator. No running canvas animation, remote resource or invented CSS/data bridge.

## Acceptance and upgrades

Validate exact fields with `fridge-package-check.cjs`. Render 180/300/420 widths, both themes and square poster output. Check the center is truly transparent, borders touch the intended canvas edge, corners are continuous and no separate rectangular alpha patch covers artwork. Intentional overlap is allowed; do not 'repair' it merely because two objects overlap.

Keep original HTML/assets and generation configuration outside the package for later redesign. App-owned frame tokens may evolve with the release; custom decorative artwork remains editable as ordinary card data. A future custom tile API must first land in schema, importer, App, Form, share and previewer together, then in the skill contract. Never ship proposed tile fields before that support exists.
