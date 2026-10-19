# Widget entry review — 2026-10-19

MatePad Mini, 1600 × 2560, existing user artwork and Form bindings retained. No uninstall/reset or fixture artwork edits. Screenshots and raw traces are in ignored output/.

## Reproduced failure and changes

A warm Form router entrance from the gallery rendered native navigation and layers, but left the entire artwork invisible. cancelGalleryTransition derived artwork opacity from galleryVisible before reloadWidgetRoute set galleryVisible=false. The retained zero opacity survived both same-canvas and cross-canvas routes. presentWidgetWorkspace now explicitly establishes the destination visibility, mount and opacity together; the launcher retains ownership of the entrance animation.

Warm cross-canvas routing previously initialized the whole store, hydrated its prior active document, discarded document caches, then opened the bound document. It now reads only the requested record, preserving existing document/contour caches and widget-side edits. Cold initialization accepts a validated preferred canvas and hydrates it once. Invalid targets retain the previous complete page/fallback. Pending routes serialize; newer requests suppress obsolete scene publication. An unpublished cross-canvas read restores the visible document and prior active selection before the next route, including when that next target is missing. Cold-start route changes and native entrance preparation also reconcile after startup. Existing same-canvas editing remains intact.

Native traces then located 30–50ms synchronous PNG decode calls inside UI layout. SceneImageCache prepares full-resolution PixelMaps asynchronously with two decoders per preparation, deduplicates in-flight work and reuses pixels for subject, album, background and static image layers. Animated assets keep their existing playback. Image sources and partial failed allocations are released. Inactive least-recently-used entries are evicted after a replacement frame when the cache exceeds 48MiB or 32 sources. Active artwork and pending decodes are protected, so the active working set may exceed that budget; this is not a hard application memory cap. The cache does not alter exported pixels, stored artwork or Form delivery.

Maintenance timers coalesce. Foreground reconciliation skips acknowledgement storage IPC if no scene rules exist.

## Native observations

The comparison uses the same signed debug configuration, tablet and alternating existing 4×4 / 2×2 route sequence, six entries including initial page construction. The baseline includes only the opacity correction so both samples draw artwork. These are UI-thread UIVsyncTask elapsed spans, not presented FPS or total CPU/GPU work:

| Measurement | Visible baseline | Route/cache change |
| --- | ---: | ---: |
| UI tasks | 52 | 57 |
| Sum of task durations | 914.56ms | 621.52ms |
| Maximum | 236.97ms | 130.94ms |
| 95th percentile | 64.79ms | 63.24ms |
| Tasks over 8.33ms | 9 | 12 |
| PreferencesGetPreferences requests | 20 | 6 |

The sum drops about 32% and maximum about 45% in this sample. More tasks and remaining long native measure/layout spans mean this is **not** acceptance of sustained 120FPS or a globally minimum workload. Full-resolution reuse retains some native image memory in exchange for avoiding repeated decoding. Trace nesting still identifies complex first-time native measurement and component construction as the main remaining cost.

Actual desktop taps verified warm cross-canvas entry, force-stopped cold entry, three launcher roundtrips, return to gallery and later refreshed clock/battery previews. Photos, materials, native chrome and artwork positions were visually checked. Routing tests also cover latest-wins reads, same-canvas edit preservation, missing targets and storage failure recovery. Image-cache tests cover decode deduplication, two-worker concurrency, eviction safety, missing assets and source cleanup.

## Validation limits

Native assembleHap and the generated preview contract check pass. The complete local run reports 81/87 passing suites. Six existing harness/config expectations remain unresolved: chrome-material compatibility lacks its AppDesign mock; cutout checker lacks sharp in this environment; the legacy model harness lacks ArkData; release-study-routes expects no WidgetBinding page; share expects the old product name; transparent-material-release expects only 4×4. These files and the corresponding product configuration/name were not changed in this review. Focused production store, Form binding, route, cache, native material, startup, gallery, editor and interruption suites pass. Two touched legacy fixtures were reconciled with existing warm cancellation and aspect-dependent palette behavior; no production palette behavior changed.
