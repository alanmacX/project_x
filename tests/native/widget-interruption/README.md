# Widget interruption and editor cache regression — 2026-10-09

Device: MatePad Mini, 1600 × 2560, 120 Hz. Native signed HAP with the existing user canvas; no artwork/data reset. Raw traces and screenshots remain outside Git.

## Changes

- Native window focus loss cancels foreground reconciliation before the later background callback. Async acknowledgement/data reads cannot commit across a newer entrance generation.
- Pure page-hide/background roundtrips no longer serialize and publish unchanged canvases. Pending edits and incomplete gestures still commit once.
- Offscreen minute clocks and startup maintenance do not repaint the hidden page. Stable visible foreground resumes maintenance and data reads.
- Unchanged appearance avoids repeated system-bar/window IPC. Form revisions share minute-granularity capability dependencies instead of invalidating every face on each delivery.
- The clipped Form surface is render-group cached during launcher scaling, with live rendering restored during a backdrop crossfade.
- Cold Form entry retains incremental card construction but skips the second app scatter animation. Icon entry keeps the existing arrival effect.
- Editor viewport geometry and subject-only thumbnails reuse immutable preview snapshots. Sheet dimensions, safe areas, layer visibility and new card snapshots invalidate geometry.

## Native evidence and remaining work

These are **UIVsyncTask CPU durations, not presented FPS**. Hitrace categories: ace, graphic, app. Separate samples are not identical workloads or guarantees.

| Sample | Result |
| --- | --- |
| Previous cold entry mounting all cards together | App task maximum 165.67 ms |
| Incremental cold widget entry | App task maximum 44.60 ms; 9 of 38 tasks exceeded 8.33 ms |
| Four rapid warm widget → app → gesture-home roundtrips | App maximum 6.32 ms; 0 of 11 tasks exceeded 8.33 ms |
| Fresh-install Form reconstruction | Form process maximum 158.01 ms; still unresolved |
| First album editor after geometry-cache build | Maximum 87.68 ms; 7 of 60 tasks exceeded 8.33 ms |
| First timetable editor/control construction in the same process | Maximum 161.48 ms; 5 of 48 tasks exceeded 8.33 ms |

Editor slow-frame nesting points to native control construction and page measurement (timetable: layout flush 97.55 ms, page measure 84.07 ms), rather than steady motion alone. The geometry cache removes repeated scans/copies but does **not** resolve initial control/thumbnail construction. Follow-up must isolate and stage that work while retaining visual previews, native controls and correct sheet geometry. Cold launch, cold Form creation and editor entrance are not accepted as sustained 120 FPS.

Native screenshots verified the existing album rendering and expanded timetable inspector; the preview refits when the embedded sheet expands and native back exits. A desktop-only trace and an early test assertion that expected album labels while the current first row was timetable were excluded from performance claims.

## Automated validation

All 47 `tests/*.test.cjs` suites passed, native `assembleHap` succeeded, and `node previewer/build.cjs --check` passed. New executable regressions cover stale asynchronous entrance results, early focus cancellation, no-op exits, pending-edit durability, incremental cold Form preparation, minute-bucket Form revisions and immutable editor-cache invalidation.
