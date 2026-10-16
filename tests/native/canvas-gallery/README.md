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

## Binding hardening and native editor polish · 2026-10-17

Supersedes the Preferences binding implementation in the preceding iteration. Confirmed code defects: multiple processes rewrote complete binding/dimension maps; absent dimension parameters defaulted to 4×4; onAdd returned empty scene fields during package-update restoration; a missing bound record could become a default blank document. These are concrete clearing/cross-size failure paths. The exact historical order of the user's reported all-widget clearing was not captured, so it is not claimed as a fully reconstructed incident.

The new registry is a separate SQLite/RDB file, with one row per instance, native dimensions, preview ownership, revision fences and removal tombstones. Old maps are read-only migration input. Real and temporary instances no longer share registry mutations; native update failures retain registry data. Delivery uses a cross-process per-instance SQL lease. Strict dimension checks run on selection, load, scheduled-target resolution, and immediately before native payload preparation. Missing/corrupt records do not publish default artwork. onAdd's synchronous response has only formId; genuinely new widgets render the onboarding UI locally, without sending a clearing packet to restored forms.

Automated evidence: `widget-registry.test.cjs` runs the real production SQL against node:sqlite through three isolated module loaders representing App/Form/FormEdit. It covers simultaneous writes for three sizes, native-versus-Want precedence, preview inheritance, removal/tombstones, repeated legacy import, persisted choices, delivery lease contention and revision rejection. `canvas-capabilities.test.cjs` now uses real SQLite for the registry alongside mocked Harmony services, and covers package restoration payloads, missing/corrupt/mismatched records, bound-size refresh, preview cleanup and explicit-only removal. `widget-frame.test.cjs` checks short/wide/square frame masks and edge budgets. Existing system binding, backdrop, gallery/cache, canvas geometry, scene policy, interruption and control regressions passed.

Physical API26 checks after installing the signed build: existing 4×4 desktop artwork remained present (`output/hardening-desktop.png`); the 2×2 desktop frame showed complete round corners (`output/smallpage.png`); long-press Edit showed matching 4×4 choices (`output/hardened-panel.json`) and the 2×4 editor showed only the matching 2×4 canvas (`output/strip-native-panel.json`). The system size carousel displayed the new onboarding card for square and strip sizes (`output/onboarding-widget.png`, `output/onboarding-strip.png`). A temporary 2×4 desktop instance was added for acceptance; its existing empty canvas was selected through the system flow. No user artwork was deleted or reset. The final UI replaces the early black rectangle with an explicit rounded host-compatible surface, removes redundant instructions and uses a scrolling single-choice list; final captures are recorded separately after the last rebuild.

Limit: process-restart persistence was tested; a full device reboot and crash at every possible native IPC boundary were not performed. Existing scene/rotation features continue within a matching widget dimension. Old invalid bindings retain their last desktop image and require an explicit choice in the system editor, rather than silently binding another canvas.

Final signed-package capture: `output/final-binding-polished.png` shows the actual 2×4 system editor, matching size badge, selected thumbnail/name/card count, host-compatible editor background and native Done button. `output/smallpage.png` shows the 2×2 frame fix. Reinstalled the final signed HAP after the last build; existing 4×4 and 2×2 artwork remained on their original desktop pages. Updated the backdrop test's stale app accessibility name to match the existing current product label; backdrop behavior itself remained passing.
