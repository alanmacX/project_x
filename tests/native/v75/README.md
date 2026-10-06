# V75: actual launcher startup handoff and rendering

Device: MatePad Mini, HarmonyOS 7 / API 26, 1600 × 2560 portrait, dark appearance, 120 Hz. Existing user canvas retained. Release build installed with replacement, no data reset.

The regression is opening the app, including the native window entrance. Commands that merely start an ability and measurements confined to the later card arrival are insufficient.

## Findings and change

- The previous texture prewarm set the entire home board to 1% alpha. The native starting window disappeared on an initial empty page, exposing a nearly blank home. The native starting window now remains until the complete scene is prepared; home backdrop and tools stay visible while only cards enter.
- Each photo silhouette was parsed/drawn through eight vector relief bands during launch. The same geometry, colors, band widths and alpha values are now rasterized by ArkGraphics2D on a worker and saved as an atomic, disposable PNG cache. Cache identity includes immutable asset version, geometry, scale and material; placement/capability updates do not rebake. Cache failures use the original vector path. Desktop Forms retain their existing vector renderer. Cache count is bounded to 128 completed files.
- Minimum-size/interior/placement solving still rescanned photo outlines in main-thread initialization and first capability builds. A validation worker now returns the existing immutable-asset layout caches with the hydrated scene. Main-thread geometry preparation fell from 67 ms to 1 ms. Prewarming does not alter user geometry. New asset versions invalidate it.
- Editor/share/photo tools use ArkTS lazy imports. An unchanged app opening no longer unconditionally persists and redelivers the whole canvas. Empty schedule refreshes return early.

## Measurement

`baseline.json` is the valid initial diagnostic launcher trace summary before relief/layout worker optimizations; it already contained the starting-window timing adjustment. `cold.json` is a force-stopped process opened by tapping the visible launcher icon after visually verifying its page. `warm.json` is a verified icon tap returning to the same live PID. Invalid captures on the wrong launcher page were discarded. Screenshots were collected separately from performance traces; screenshot readback can itself disturb frame timing. Private canvas screenshots and raw hilog were not committed.

| Metric | Before | Valid final sample |
| --- | --- | --- |
| UI frames constructing individual card surfaces | up to 92.92 ms | up to 15.08 ms |
| Main-thread geometry preparation after material readiness | 67 ms | 1 ms |
| Long preferences/initialization completion callback | 95–96 ms | absent from >15 ms callbacks in final cold sample |
| Index page source/load | about 77 ms | 40.49 ms |
| Post-entrance unconditional maintenance callback | about 172 ms | removed |
| Complete-scene readiness from ability onCreate (derived caches present) | 704–719 ms | 597–605 ms |
| Later card arrival (reported separately, not the completion criterion) | 106.4 fps / 41.69 ms maximum interval | 120.0 fps / 8.40 ms maximum interval |

In the complete final cold trace, 187 RenderService render tasks had a maximum duration of 9.77 ms; in the final warm trace, 128 had a maximum of 9.62 ms. Neither contained a >16.7 ms render task. These are task durations, not proof that every displayed frame meets an 8.33 ms deadline. Warm app UI still had a 16.88 ms frame; native UI initialization and the first home chrome construction are also not zero-cost. Do not describe this as every-device, every-frame 120 fps.

A cache miss adds roughly 0.4 s in the measured five-photo scene while the worker generates relief images; subsequent launches reuse them. Larger canvases, other orientations and cold filesystem/shader caches require separate measurements. This improves launch contention and handoff; it does not make the first installation's asset generation free.

## Checks

All 25 host regression scripts passed; release assembleApp succeeded. Additional regressions cover once-only starting-window removal, deadline/destruction/rejection handling, exact worker layout handoff without reading silhouette points, size/asset cache invalidation, relief resource release, and native time/timetable/form behavior. Opened the first card editor on the device, inspected its native controls and photo border, then returned without editing artwork. No runtime JS exception was observed in that check.

## Platform references

- [WindowStage.removeStartingWindow](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-window-WindowStage.md#removestartingwindow14): API 14+, ability metadata `enable.remove.starting.window=true`, system 5 s fallback. App additionally has a 2 s safety deadline.
- [Huawei ArkTS lazy imports](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-lazy-import).
- ArkGraphics2D Canvas/Path and ImageKit packing were checked against the installed API 26 SDK and executed on the device; the project baseline remains API 24.
