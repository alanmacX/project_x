# Canvas gallery prototype · 2026-10-17

Implements design A: library home → canvas workbench → card editor. Existing desktop binding behavior is unchanged; the independent-instance binding design is a separate iteration.

## Automated validation

- Native API26 debug HAP compilation and signing: passed; compatible API24 as configured by the existing project.
- `canvas-gallery.test.cjs`: mixed-size layout and filtering at eight widths, rapid repeated open, save-before-return, load/save failure recovery, nested editor and timed-scene return, destroyed-page completion, warm widget entry, stale metadata cancellation and per-document preview failures.
- Existing targeted regressions passed: `scene-editor-navigation`, `window-editor-lifecycle`, `nav-menu`, `compact-tools-migration`, `share-receive-policy`, `editor-workspace`, `workspace-layout`, `home-panel-race`, `board-controls`, `widget-launch-selection`, `startup-frame`, `canvas-capabilities`, `editor-mount`, `background-mount`, `widget-interruption`, `startup-presentation`, `render-startup`, `scene-policy-v2`.
- `template.test.cjs` and `local-sharing.test.cjs` also passed during import/share boundary checks.
- `git diff --check`: passed.

Existing unrelated baseline issues observed before feature completion: `share.test.cjs` expects the former share title “created by 冰箱贴” while the saved baseline uses “created by 冰箱贴桌面小组件”; `fridge-cutout-check.test.cjs` requires an unavailable `sharp` dependency. No full-suite pass is claimed.

## Native visual verification

Initial prototype verification waited for an emulator connection. On 2026-10-17, the subsequent motion/material iteration was compiled, installed and checked on a connected physical API26 device. No device data was reset or removed.

Verified in that iteration: normal launch shows the library with native HDS import/new/more buttons; opening an existing canvas shows the HDS back/more title bar; system Back restores the library; native More menus remain clickable after the transition. Both portrait and wide window layouts were observed on the device. Transition screenshots are in ignored `output/gallery-enter-*.png`. Automated coverage includes rapid navigation blocking, stale completion isolation, timeout recovery and cancellation.

The device check also exposed stale loading placeholders in retained ArkUI row builders. Row keys now include settled preview metadata, so asynchronously generated thumbnails replace their initial loading nodes. A rebuilt package was installed and the native library showed the actual preview with no loading placeholders (`output/gallery-final-home.png`).

Once connected, verify:

1. Ordinary icon launch opens the library; previews include real artwork and respect authored proportions.
2. Open a canvas, move a card, return to the library, reopen; saved position and refreshed preview agree.
3. New, rename, duplicate, share and delete use the intended canvas; cancel leaves content intact.
4. Imported whole canvases retain their aspect; imported single cards name their target and reveal the workbench.
5. Card editor back returns to the canvas; next back returns to the library. Timed-scene back still returns through its completion path.
6. Cold and warm widget launches open the workbench directly; repeat after returning to the library.
7. Folded phone and expanded/landscape layouts keep header, previews and tools within the safe area; no old canvas switch popup remains.

Preview PNGs are derived local cache files. Failed previews remain openable as original artwork. Device captures and build logs belong under ignored `output/`, not in this commit.

## Size creation and selected-card actions · 2026-10-17

Native API26 debug build/signing passed and the package was installed on the physical device. Creating from the 2×2 filter preselected 2×2; the resulting gallery entry retained 2×2 after force-stop and cold launch. Creating from the 2×4 filter preselected 2×4 and opened a visibly horizontal 2×4 workbench (`output/stripready.png`). Temporary empty canvases were created for this manual check; existing artwork was preserved.

Selected an existing card without changing its content. The native HDS popup shows the red trash, divider and edit action; resize remains at top-right and rotation at bottom-left. A card extending below the board initially placed its popup over the inspector; placement now uses the board bottom and flips above (`output/pill3.png`). Tapping the popup edit button opened the correct music-album editor; Back returned without changing content.

Twelve targeted tests passed: canvas-gallery, canvas-capabilities, canvas-viewport, board-controls, card-action-placement, board-hold, template, editor-motion, chrome-material, chrome-material-compatibility, home-panel-race and widget-launch-selection. New coverage exercises filter-to-form size inheritance, dimension persistence/reopening/copying, stale host size isolation and rotated popup placement within board bounds. The card delete action was not exercised on existing user artwork. Desktop widget supported sizes and independent bindings remain outside this change.

## System-owned binding flow and persistent previews · 2026-10-17

This iteration supersedes the prior deferred binding note. `form_config.json` supports 4×4 / 2×4 / 2×2 and routes configuration to a `formEdit` extension, rather than a UIAbility. A temporary App-owned addition flow was removed before completion. No gallery/workbench action routes to the binding page. The system supplies size selection and its native editor's preview/header/Done; the extension supplies only the canvas choices.

Physical-device observations: long-pressing a widget exposed the native Edit menu; Edit opened the system half-modal panel and passed distinct `cardId` / `previewCardId` values to the extension. After using shared session LocalStorage correctly, the native panel showed the binding choices without the missing-instance error (`output/nativefixed.json`). The 2×2 panel showed only matching canvases (`output/system-sizes.json`); the desktop subsequently displayed the selected 2×2 artwork (`output/system-bound.png`). Captures from the temporary App addition prototype are not acceptance evidence.

Preview checks: the native gallery displayed correctly sized full/small previews (`output/cache-ready.json`). After force-stop/relaunch, the first captured layout contained no generating/reading-preview placeholders (`output/cache-cold.json`). A content-signature/contour-worker mismatch found during device QA was corrected: contour workers receive raw JSON; the versioned cache signature is metadata only. Opening background settings with a selected card retained its HDS edit/delete capsule and resize/rotate controls (`output/background-actions.png`). Existing artwork was not edited or deleted for these checks.

Added automated coverage: independent widget registration/binding and size rejection, legacy policy freeze, preview-instance inheritance/removal, navigation isolation, native formEdit configuration/session IDs, persistent thumbnail restoration/replacement/missing-file recovery, native preview dimensions, and selected-card actions across auxiliary panels. Targeted passing tests: canvas-gallery, gallery-preview-cache, canvas-capabilities, system-widget-binding, widget-launch-selection, canvas-viewport, board-controls, card-action-placement, board-hold, template, chrome-material, chrome-material-compatibility, home-panel-race. API26 native compile/sign/install passed; API24 remains the configured minimum.

API references: the installed SDK's `@ohos.app.form.FormEditExtensionAbility`, `FormEditExtensionContext`, and `formProvider.getFormRect` declarations; [Huawei widget editing guide](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/-ui-widget-event-formeditextensionability-overview). The host owns when it opens the editor: the documented existing-widget path is long-press → Edit, and an unconfigured widget also offers a tap to open that system editor.

Final native editor check: `output/system-edit-selected.png` shows the system-owned live preview, selected canvas row and native Done button after binding; no App activity is involved. The final signed build was reinstalled after validation.
