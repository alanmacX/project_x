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

Pending emulator connection. Emulator CLI required confirmation of updated Huawei license agreements; the user chose to open the emulator and confirm personally. No device data was reset or removed.

Once connected, verify:

1. Ordinary icon launch opens the library; previews include real artwork and respect authored proportions.
2. Open a canvas, move a card, return to the library, reopen; saved position and refreshed preview agree.
3. New, rename, duplicate, share and delete use the intended canvas; cancel leaves content intact.
4. Imported whole canvases retain their aspect; imported single cards name their target and reveal the workbench.
5. Card editor back returns to the canvas; next back returns to the library. Timed-scene back still returns through its completion path.
6. Cold and warm widget launches open the workbench directly; repeat after returning to the library.
7. Folded phone and expanded/landscape layouts keep header, previews and tools within the safe area; no old canvas switch popup remains.

Preview PNGs are derived local cache files. Failed previews remain openable as original artwork. Device captures and build logs belong under ignored `output/`, not in this commit.
