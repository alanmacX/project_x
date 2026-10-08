# Current .fridge authoring contract

Verified against FridgeMemo TemplatePackage.ets/CardSchema.ets on 2026-10-08. The generated design-contract.json is the release snapshot for fields, capabilities and design tokens. This prose explains semantics. When working in the app repo, production source files are authoritative: run previewer/build.cjs --check and update this reference if semantics changed.

## Container

UTF-8 JSON, not ZIP:

```
{"format":"fridgememo-template","version":1,"kind":"canvas","state":{"schemaVersion":2,"canvasAspect":1,"cards":[]},"assets":[]}
```

`kind=card` requires exactly one card and no external group membership; `canvas` has at most 16 cards. Use schema 2. The actual example is complete and passes the reader; snippets here are explanatory.

`state`: canvasId (local placeholder), canvasAspect (>0), canvasDimension `4*4`, background, maxZ, cards, sceneLayouts, sceneRules, sceneBaseLayoutId. Start without schedules. Reader handles remapping IDs on import. Do not create undocumented scheduled transitions or cross-canvas references.

Background: solid color (`#RRGGBB`) is easiest. Other current modes are smart/blend/photo/preset but they require host-generated images/palettes for faithful output; do not claim a hand-written list of colors reproduces the app gradient. Photo background references must be embedded asset keys.

## Coordinates

Card `x,w,h` are in the model's 344-unit width space. Card `y` uses its legacy 470-unit vertical space. For target aspect A (width/height), the artwork height H is 344/A. For normalized positions (u,v) and normalized physical dimensions (rw,rh):

- x = u * 344
- y = v * 470
- w = rw * 344
- h = rh * H

These are top-left positions. Card h is NOT multiplied by 470. On a square canvas a 100×100 card remains square. Rotation is degrees, z controls stacking. Host fit may uniformly scale a received composition, not reflow every card independently.

Element/capBox x/y/w/h are fractions of that card's bounding box; their rot is degrees. For ordinary in-bounds elements use x≥0, y≥0, w≤1, h≤1, x+w≤1, y+h≤1. Content readability is verified separately; satisfying these limits does not prove no text clipping.

## Card fields

id, groupId (`''` if none), x/y/w/h/rot/z; shape `rect`/`round`/`pill`/`blob`/`subject`; material `white`/`cream`/`kraft`/`mint`/`blue`/`pink`/`dark`; paper/ink custom `#RRGGBB` or `''`; capability (one object or null); capBox; capFree; elements. For basic cards use rect, frame=false, cutout='', outline=[], subjectPhoto=false, subjectBorder=true. A subject card needs a real transparent PNG and validated contour, not a guessed polygon.

A group has at least two cards sharing a nonempty groupId. A card-only package clears groupId. Do not reuse identifiers across card/element instances.

Elements: id, kind `text`/`image`/`shape`, x/y/w/h/rot/opacity, text/src/fs/color/bold/align/behindCapability/primitive. shape primitive is rect/circle/line; text alignment left/center/right. Font size is in model units; do not put essential instructions in tiny decorative text.

## Capabilities

Supported k: clock, date, calendar, countdown, anniversary, dayprogress, yearprogress, battery, agenda, timetable, worldclock, lunar, album.

Prefer the example's core fields. Additional types need source review; don't invent a field from a natural-language name.

- clock/date/calendar/dayprogress/yearprogress/lunar: native data. calendarOffset is month offset.
- countdown/anniversary: title and date `YYYY-MM-DD`.
- worldclock: city and a valid IANA zone, e.g. Asia/Shanghai.
- battery: percent=-1, charging=false, updatedAt=0, attemptedAt=0. Native service fills data.
- timetable: do not generate real courses without explicit user input. semester, courses, timetableMode next/day, skipHolidays are existing fields; actual school rules require a valid user course source.
- agenda: imported source and events explicitly provided by user; never pretend a package grants full system-calendar permission.
- album: square local albumCover AND host-compatible albumBackground, artist/title; host fixes albumInset=4.9. Review albumItems schema if using a library. No search or platform credentials.

Reading blends cloud/bare/tag/sticker work for ordinary capabilities. Battery additionally supports badge; no badge for other types. Album uses its own appearance. Bare means the current host brush surface, not a second handwritten CSS implementation. Current reader migrates space/dock to sticker/tag; don't author the legacy names.

## Assets

Each asset is {key:`asset://0`, extension:`.png`, data:Base64}. Keys are unique numeric IDs. Only png/jpg/jpeg/gif/webp extensions. Use actual image bytes; fake signatures or SVG pretending to be PNG are invalid artwork even if JSON parsing succeeds. Every nonempty cutout, element src, background src/photo and album image ref must resolve to an embedded asset. Never embed file://, HTTP URLs or credentials in a package.

Current reader limits package text to 90MiB, assets to 256, individual asset Base64 to 32MiB, and canvas cards to 16. These are hard limits, not generation targets; keep works small. HTML/CSS/SVG/font resources are NOT supported package assets yet.

## Static HTML cards (container v2)

Use container version 2 only when a card has `html`. Native-only v1 works keep importing. The card stores `{version:1,designVersion:1,width,height,source,previewElementId}`; its referenced image element embeds the appearance cache as a normal local asset. IDs must be remapped together. App editing changes normal layers/capability/layout; changing HTML source requires regenerating its cache with the authoring workflow. HTML is not a new provider and never runs in desktop Forms. See html-draft.md.

## Design-only sharing and recipient data

`.fridge` transfers artwork and native provider intent, not sender runtime data. Production `SharedCapability.sharedCapability` is the export/import allowlist. Never embed calendar events, courses, semester dates, school exceptions, battery snapshots, countdown/anniversary targets, credentials, cached provider responses or private future fields in a template capability. Agenda binds to the recipient system calendar (with their existing permission); timetable binds to their saved local timetable or remains unconfigured. Clock/date/progress/battery use the recipient device. Deadline capabilities require the recipient to set their own title/date. World-clock city/zone are intentional design choices. Album titles/artists/covers are artwork; rotation restarts on import. HTML native bindings follow the same policy.

Decorative text, photos, album covers, HTML source and its appearance cache are intentionally shared artwork. Do not bake personal provider records into those assets; automatic provider sanitization cannot remove information already painted into an image or static HTML. Preview fixtures may use synthetic data for QA, but exported/imported templates must use recipient bindings. Timed scene designs arrive disabled and without sender acknowledgement history.
