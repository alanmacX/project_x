# Native card templates — 2026-11-01

## Implementation

- 39 single-card templates covering the existing 13 capabilities; 5 multi-card recipes.
- Add-card sheet: swipe/segmented 模板 / 创作. Creative cards keep the original editor.
- Optional `card.template` v1; state schema stays 2. Existing cards, canvas IDs and system Form bindings are not migrated or replaced.
- Full-canvas templates use the original canvas background/frame and lock their geometry; ordinary templates retain card movement/rotation/size controls. Full-canvas artwork preserves its proportions.
- Photo clock: original photo → clock → extracted foreground; select photo, reuse local subject extraction, toggle depth, adjust subject size/position. Photo and alpha use the existing element resource ownership/export/GC paths.
- Shared scene model feeds native App/home/Form rendering and the browser adapter. Local Canvas painting uses one surface for normal templates, a second ink surface only for the depth clock; no new timers, network provider or preview bitmap persistence.
- Paper: ambientCG CC0. Digits: Barlow Condensed / OFL. Both licenses ship alongside the assets; no AI artwork is bundled.
- Packages containing templates use v3. Creative/native v1 and HTML v2 imports remain supported. The v3 reader checks template version/capability compatibility. Old readers reject v3 rather than silently strip a design.

## Automated verification

- `npm test`: 105/105 suites.
- `npm run test:storage`: all 4 integrity suites (real SQLite/WAL subprocesses, killed writers, independent recovery snapshots, local/cloud isolation).
- `node previewer/build.cjs --check`: generated production models/materials/render identities match.
- Release `assembleApp`: successful; `npm run release:check`: production entry/extensions retained, no study/temporary QA pages packaged.
- `card-templates.test.cjs`: all 44 presets at 5 canvas ratios (0.3, 0.9, 1, 2, 3), schema/package/storage round trips, detached render metadata, full-height persistence, recipe bounds, two palette axes without text, internal depth projection, full-canvas import adaptation, gradient color sampling, template-only undo/redo.
- `render-startup.test.cjs`: real Form payload preparation maps template metadata, photo and alpha together; a subsequent identical payload opens no new image descriptors.

## Simulator observations

HarmonyOS simulator: native picker, palette clock, template switching, palette controls, depth options, photo picker opening, editor → home preview and app restart were exercised. Full-canvas mode was confirmed on in the native accessibility tree; native Undo restored it to off and restored the original card size. The simulator Gallery contained no photos. Transparent-photo layering and Form image delivery are covered by the model/payload tests above.

During native review, the old 320-unit card limit rejected full-canvas templates, and appearance-only template edits were missing from the undo key. Both were fixed and given regression coverage. Obsolete capability layer handles are hidden for atomic templates.
