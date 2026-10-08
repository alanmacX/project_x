# Window and editor lifecycle QA — 2026-10-09

Device: MatePad Mini, 1600×2560, 120 Hz. Native HAP, existing eight-card canvas. Source baseline: 08b3f73.

## Repairs

- Native embedded sheet handles PRESS_BACK explicitly, releases its overlay, and retains back requests during hero entry.
- Sheet visibility has its own two-way state; the anchor belongs to the stable window root. Closing a hero must not reopen a dismissed sheet, and changing a layer must not replace the navigation-owned sheet anchor.
- Native sheet mounts before hero motion; its own native entrance runs independently of the editor chrome opacity.
- Preview follows detent crossings with hysteresis; pan frames do not regenerate artwork. Exit starts at the actual expanded preview rectangle.
- Inspector nodes and capability visibility use native TransitionEffect. Different native SegmentButton option counts use separate keyed instances inside a fixed-height host, avoiding a synchronous button-count layout flush.
- Warm same-canvas Form routing reuses the loaded scene. Foreground capability results commit in one batch, and late results wait for gestures/hero transitions to settle.
- Scene acknowledgement reads avoid full model normalization; unchanged saves avoid rebuilding the derived contour cache.

## Measurements and limitations

Native hitrace categories: ace, app, graphic. UI task duration is **not** a complete frame-present/FPS measurement. Raw traces and user screenshots remain outside Git.

| Sample | Observed result |
| --- | --- |
| Warm widget route before | Preferences completion callbacks of 49.93 and 51.83 ms, including redundant model reconstruction |
| Warm widget route after reuse | Those full-reload callbacks absent; sampled UI-task maximum 22.76 → 18.65 ms; p95 12.85 → 14.40 ms (no p95 improvement claim) |
| Editor late sheet mounting | Entry-region UI-task maximum 48.99 ms |
| Sheet prepared before hero | Entry-region maximum 14.40 ms in one sample; subsequent repeated-entry samples 15.71–18.79 ms |
| Native button-count mutation | SegmentButton update 63.33 ms; outer click callback 76.25 ms |
| Keyed native option groups | Sample UI-task maximum 14.89 ms; touch callback 3.83 ms; prior button-count update spike absent |

Initial inspector creation had a 42.88 ms frame in one trace; exit samples reached 24.16 ms. Cold-start total timing was not demonstrably improved. Therefore this is not evidence of sustained 120 FPS or complete elimination of all startup costs.

## Native acceptance

Verified Form tap opens the correct app; fast edge back and system Back leave editing; returning and entering again recreates the inspector; capability/base selection; portrait detent expansion; returning from an expanded editor. Preserve existing artwork and avoid the layer deletion badge when selecting thumbnails.

Run targeted regressions: window-editor-lifecycle, editor-motion, editor-workspace, startup-frame, startup-presentation, render-startup, editor-visual-choices, appearance-lifecycle, model, cloud-capability, capability-framework, shared-capability, previewer, widget-backdrop. Native assembleHap and previewer/build.cjs --check passed.

Reference: [Huawei: onBackPress is not called with a sheet/dialog](https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-arkui-1390). A registered onWillDismiss intercepts default dismissal; PRESS_BACK includes system and edge navigation.
