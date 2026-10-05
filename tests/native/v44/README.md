# Card depth, native material and cold startup — 2026-10-05

Validated on MatePad Mini, physical display 1600×2560. Private artwork, screenshots and raw native traces stay outside the repository.

## Rendering and material

All app/editor/hero/widget faces share a warm tinted solid sidewall, a tight contact shadow and a broader cast shadow. Subject cards draw and blur their actual silhouette; a rectangle shadow attached to a clipped component was visibly wrong and was removed. Regular cards retain native rounded shadows and a restrained edge highlight. Animated GIFs and moving inner layers opt out of the static face texture cache.

The first silhouette-blur implementation dropped compositor throughput to roughly 74–79 FPS. Caching the complete static face with `renderGroup` restores efficient transform-only motion while preserving the shadows. Four alternating native pans with the final rendering/material implementation:

| Pan | Duration ms | Compositor FPS | UI Vsync p95 ms | UI max ms |
|---|---:|---:|---:|---:|
| 1 | 686 | 117.0 | 2.75 | 3.49 |
| 2 | 714 | 115.7 | 2.62 | 2.92 |
| 3 | 736 | 118.6 | 2.45 | 3.13 |
| 4 | 720 | 119.9 | 2.55 | 3.77 |

These are this device's gesture windows, not a guaranteed refresh rate across all hardware. Timing does not establish desktop-host refresh performance.

Following [Huawei's immersive material guidance](https://developer.huawei.com/consumer/cn/doc/doccenter-advanced-features/bpta-spatiality-immersive): retain adaptive HDS navigation material; add native point lighting and material to supported popup/action-menu hosts. Ordinary floating content buttons use native background blur and translucent tint because regular system material is scoped to navigation/tab/popup hosts. API 24 keeps its guarded fallback. Explicit HDS menu/back glyph and text colors fixed white labels on the light editor; verified on the device.

## Startup diagnosis

Native duration markers start in Ability.onCreate. Before the fix, storage was available at 256 ms, but repeated contour topology processing held readiness until 2,021 ms (contours ready at 1,925 ms). Cache exact-source, versioned derived geometry separately for each canvas; corrupt/missing cache falls back to the immutable master. Cache reads cannot make artwork unreadable. Deleting a canvas also deletes its cache. FormKit size IPC no longer gates the first scene; cached geometry remains stable through the arrival animation.

Final cached force-stop/relaunch: storage 230 ms, contours 250 ms, material 253 ms, scene ready **338 ms**, scene idle 928 ms. `scene-ready` measures scene preparation; `scene-idle` is after the arrival animation, not first-pixel timing. Initial upgrade/cache rebuilding still pays a one-time worker cost (measured 1,923 ms readiness); changed source artwork invalidates the cache. Earlier three cached launches were 337/344/377 ms.

## Checks

Signed debug package builds and installs successfully. Model, capability framework, appearance lifecycle, canvas capabilities, local sharing, timetable display and new contour-cache regressions pass. Tests cover exact source/asset matching, worker avoidance, corrupted/versioned cache fallback, geometry edit invalidation, separate canvas cache persistence, switching reuse, unavailable cache reads and deletion cleanup.
