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

## Preview corner clipping correction · 2026-10-17

Preserve the original rounded material frame on desktop and in preview snapshots. The attempted square-tile/native-rounded-mask change was withdrawn before commit because it changed the frame to an outer-round/inner-square appearance. The final change only clips preview artwork to the original frame's outer radius, converted from native host vp to snapshot coordinates; removes the opaque thumbnail backing that leaked through transparent corners; and avoids a second arbitrary 10vp mask on system-editor thumbnails. Cache signature v6 regenerates the affected PNGs. Native signed compilation/install and widget-frame, canvas-gallery, gallery-preview-cache, widget-backdrop and soft-relief-frame tests passed. `output/fixed-preview-corners.png` shows the final 4×4 and 2×2 gallery previews with the original rounded frame and no backing surface outside it.


## Gallery content behind the immersive title · 2026-10-17

The scroll surface now occupies the whole page beneath a sibling native HDS navigation layer. Initial content padding compensates for the former navigation safe-area inset, keeping the title/menu positions identical and filter/artwork positions within one physical pixel of the baseline. HDS component safe-area handling extends the native material behind the status bar; the gallery opts into a 32vp gradient tail while the workbench keeps its existing setting. Removed the Scroll fading edge that cut content before it reached the material.

Physical API26 evidence: `output/header-safearea.png` shows scrolling artwork behind the status bar/title and the gradient fading into the gallery. `header-before.json` / `header-safearea.json` record matching title/menu bounds and the 1px filter/artwork rounding difference. Swiping still scrolls the content; the floating create button opens the size/name controls; Cancel returns without creating a canvas; native More opens both Skill entries. No artwork or widget bindings were changed. Signed native compilation and canvas-gallery, chrome-material and chrome-material-compatibility tests passed.

Reference: [Huawei navigation dynamic blur](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-navigation-dynamic-blur); safe-area/title options were checked against the installed HDS SDK declarations.


## Native safe-area blur coverage correction · 2026-10-17

The previous gallery navigation retained 4vp of outer top padding: this shifted the blur surface below the physical top even with component safe-area handling. Removed that outer padding and its matching content spacer; HDS now owns title safe-area avoidance and extends the material from the top of the full-page surface. The gallery also leaves `maskExtraHeight` undefined, using the SDK gradient extent instead of the App's explicit 32vp override. Workbench settings are unchanged. Fixed page spacing remains a design value, separate from system status-bar coverage.

The signed build was installed on the connected API26 device. `output/header-system-inset.png` shows scrolling artwork blurred through the physical top with no former unblurred top strip. Native compilation and the canvas-gallery/chrome-material/chrome-material-compatibility tests passed. Other device sizes were not physically tested; their status-bar handling is delegated to HDS component safe areas rather than a device-specific offset.


## Shape and gallery rendering review · 2026-10-18

Fixed the ellipse/capsule rendering collision: ArkUI percentage border radii normalized the ellipse into a capsule. The face now uses real elliptical backing, silhouette blur, rim and content clipping; capsule geometry and album-specific rounding remain separate. `output/review-shapes-final.png` shows both alternatives in the actual native editor. Existing artwork was inspected without changing shape choices.

The gallery survives navigation with its decoded images, filter and scroller. Cache indexes/host rectangles are primed before initial gallery construction, metadata restoration is parallel, existing images survive document/encoding failures, and refreshed images replace old images after encoding/commit. PNG decode is synchronous only in snapshot mode and the gallery's cached Image; live editor/widget image loading retains its normal policy. This matters: native acceptance exposed that disabling image-status validation alone could capture an incomplete scene, including a missing leaf subject. Snapshot mode now decodes photos/relief/album/backdrop/frame assets before capture; a genuinely missing photo still falls back without suppressing all other cards. Signature v9 invalidates incomplete earlier candidates. Time-dependent previews refresh by minute without replacing unrelated cached images.

The selected cached preview is the shared visual between measured thumbnail and board rectangles. Native frame/render completion gates the destination; a prepared frame commits the initial shared-image pose before its 360ms animation. Chrome recedes separately. Resized/offscreen anchors fall back, hidden pages cannot intercept input, cancellation releases frame waits, and stale animation/load completions cannot resurrect navigation after backgrounding. Native button disabled-state dimming was removed from the artwork button. Direct widget launches defer the gallery until its first use.

Acceptance used the existing Mate 80 RS API24 emulator through its HDC server on port 8710. The physical phone was disconnected and was not re-tested. The final signed package was installed without uninstall/reset. `output/review-decoded.png` and `output/gallery-motion/decoded-contact.png` show a complete cached gallery and sampled entrance/return frames with the same subject present throughout. `output/scroll-before.json` / `output/scroll-after.json` record identical preview bounds after a scrolled round trip. A force-stop/relaunch restored cached images; the earliest capture (`review-cold-first.png`) is the normal system launch surface, not evidence of an empty gallery. No canvases, source assets or desktop instances were deleted. Static frame samples are not a frame-time performance trace.

Regression coverage includes keeping old artwork during delayed/failed reads, per-directory cache ownership and cold metadata/host-rectangle priming, waiting for native rendering, measured shared-image destinations/return paths, rotation fallback, rapid second taps, failed saves, background cancellation during document or preview loading, old native completions and destroyed pages. Targeted test results are recorded in `output/gallery-review-tests.log`; native compilation results are in `output/gallery-review-build.log`.


## Native material duplicate-block investigation · 2026-10-18

The user supplied a physical-device screenshot showing an extra cropped copy of the framed canvas behind the upper-right navigation buttons. Review found page-wide `renderGroup(true)`, page transforms containing native HDS samplers, a whole-workspace snapshot, and an older editor-toolbar snapshot. These paths have been removed: the snapshot prewarms only `canvasArtwork`, selected artwork alone follows the shared geometry transition, content fades independently, and native material stays in window coordinates. The editor waits for layout with its real controls instead of capturing the HDS bar. Title colors are explicit in both native scroll states.

API26 investigation also exposed a hit-test problem in the full-page empty sibling navigation. The final hierarchy puts Scroll inside HdsNavigation with top `ignoreLayoutSafeArea`, matching the native component safe-area model. Initial measured filter bounds remain `[156,402][381,556]` on the 1256×2760 QA phone. Retained-page transient forms now close when leaving; filter/scroll intent remains retained.

Acceptance used a newly created independent API26 phone emulator, `FridgeGlitchQA`. The earlier TripleFold emulator hit an existing local-record-read failure; no original record was cleared, replaced, or repaired for this visual test. In the new instance, UI actions created a plain card, enabled its canvas frame and changed its background, and added a second test canvas to permit scrolling. No physical phone was connected. `output/glitch-final-header.png` and `output/material-glitch-qa/roundtrip-2.png` show the frame passing beneath status/title/menu areas without the separate duplicate block. Three round trips and a Home/resume sequence were sampled; `output/glitch-editor-final.png` shows the native editor after removal of toolbar screenshotting. Rotation was requested but the portrait-locked app did not change size, so this is not landscape acceptance. The user's original photo/artwork and GPU were not reproduced exactly; native QA establishes the tested API26 path, not a guarantee across every device.

`native-material-boundary.test.cjs` guards window-space native ancestors, artwork-only snapshots (including exclusion of editor chrome), native-owned scrolling hierarchy, top layout-safe-area expansion and explicit light/dark title styles. The gallery regression also exercises closing retained transient forms without resetting the current filter. Targeted native/material/gallery/editor/startup/widget regression results are in `output/glitch-fix-tests.log`, and native signed build results are in `output/glitch-fix-build.log`.

Reference: [Huawei native navigation dynamic blur](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-navigation-dynamic-blur), especially native Scroll/List ownership, component safe areas and unclipped content. The offscreen nature of renderGroup was checked against the installed ArkUI SDK declaration. The original screenshot's exact GPU failure is an inference from the code/rendering boundary, not an OS-level root-cause trace.


## Press mask, landing dissolve and split creation · 2026-10-18

Acceptance on the independent API26 FridgeGlitchQA phone emulator:
- Native top plus opens an anchored HDS size menu. Created 2×2 with a name from this menu, 2×4 from the split bottom control while the gallery filter was 2×2, and 4×4 while browsing 2×4. The resulting gallery labels and strip geometry retain the explicit creation size. Original QA documents were preserved.
- Bottom controls emerge from the original capsule centre; X merges the pieces back. A later final-build check covers system Back closing the expanded control. Naming actions remain visible above the system keyboard (`output/split-name-final.png`); empty-name submission is disabled.
- Imported a synthetic fixture containing nine distinct 1024px JPEG assets (6.11MB package) using the system document picker into a new, independent canvas. Three gallery/workspace round trips were sampled, eight entrance frames and four exit frames per cycle. All nine photos remain present through the observed handoff, without blank card replacement; see `output/gallery-nine-contact.png` and `output/gallery-nine-enter-*` / `exit-*`. This is emulator sampling, not frame-perfect physical-device acceptance.
- Regression includes `gallery-surface-readiness.test.cjs`: an in-flight data request cannot mutate artwork during landing and resumes after settlement. Gallery tests exercise explicit creation sizes, empty/busy submission, landing overlay lifetime and cancellation. Native-material boundary tests keep the HDS sampler outside transformed/cached ancestors.

Artifacts: `output/gallery-split-build.log`, `output/gallery-split-tests.log`, `output/split-expanded-final.png`, `output/split-created-strip.png`, `output/split-created-large.png`.


## Geometry parity and navigation critical path · 2026-10-18

New independent test canvas contains a short horizontal card, tall narrow card, ellipse, capsule-like card and a rotated card. Native preview bounds `[56,640][1200,1784]` were compared against the live board `[43,758][1213,1928]` after normalization to board size. Colored silhouette bounding boxes differ by at most 0.00183 of board width/height (under 0.2%; rasterization and scaled antialiasing remain). Artifacts: `output/geometry-after-preview.png`, `output/geometry-after-live.png`, `output/gallery-geometry-comparison.json`. This quantitative check covers the five test cards on API26, not every existing user composition.

The model regression checks detached exact active-document geometry and equality of inactive-preview/editor hydration, including an off-canvas rotated tall card. Viewport regression checks shared measured host ratio. `gallery-preview-policy.test.cjs` verifies metadata return does not await a never-resolving screenshot, unchanged canvases are not reread, hidden/busy galleries do not resume work, and rotating albums invalidate at their own period. A persistent plus glyph guards against text-plus/X crossfade substitution.

Three nine-JPEG round trips were sampled after removing the navigation GPU readback (`output/fast-gallery-nine-enter-*`, `exit-*`). Entry retains layout frame barriers and the landing dissolve. Gallery content is no longer synchronously rebuilt before return; only visible thumbnails resume after settlement. Build and regression results: `output/gallery-geometry-build.log`, `output/gallery-geometry-tests.log`. Native-material boundary tests now prohibit snapshot readback in navigation, while still excluding all HDS chrome from cached/transformed ancestors.


### Capability backing follow-up (actual reproduced failure)

A four-timetable canvas reproduced a concrete failure missed by the earlier primitive-card checks: first-frame offscreen capture stretched the paper backing downward and extended the cloud backing beyond the card (`output/capability-before-preview.png` vs `capability-before-live.png`). Reading surfaces use nested native measurement callbacks; image syncLoad plus waitUntilRenderFinished does not settle those later state updates when capture is forced at delay 0.

Capability captures now use the native offscreen API's default 300ms settling delay, outside navigation; static artwork still uses zero. The cache version invalidates previously stretched PNGs. Normal and missing-image fallback captures share the layout delay.

QA included adding a real course and semester through native editor controls (shared templates intentionally strip personal courses). `output/capability-lessons-live.png` and `capability-lessons-preview-full.png` compare a populated timetable and three other timetable surface styles. Normalized paper-boundary differences are at most 0.00154 (under 0.2% of board size). The second fixture covers agenda, world clock, calendar and battery with paper/tag/cloud/badge backings; maximum boundary difference is 0.00305 (under 0.4%). See `output/capability-lessons-comparison.png/json` and `capability-mixed-comparison.png/json`. These are emulator raster comparisons, not physical-device or every-capability certification. The stale retained preview is intentionally visible until its new PNG commits; comparisons wait for the new course content to appear.

Build: `output/gallery-capability-build.log`. Regression: `output/gallery-capability-tests.log`. `gallery-preview-policy.test.cjs` guards both snapshot paths retaining measurement delay, transition suspension and nonblocking navigation.


Final native run sampled three additional round trips on the populated timetable canvas (`output/capability-final-enter-*`, `exit-*`) and checked that the course text survives each entrance. The reversible persistent plus/X control and system-Back collapse were exercised again (`output/plus-final-open-*`, `close-*`). The wall times in `capability-native-roundtrips.json` include multiple screenshot commands and layout dumps; they are not animation latency or FPS measurements.
