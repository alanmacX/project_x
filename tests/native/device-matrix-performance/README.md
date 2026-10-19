# Device matrix / startup and storage — 2026-10-20

## Native coverage

- Actual MatePad Mini: portrait 1600×2560 gallery, canvas, course editor, single school sheet and keyboard. School result list retained usable height; screenshots inspected. Existing three canvases were retained. Earlier landscape 2560×1600 coverage is recorded in the single-sheet review; this run's new real-device measurements use portrait.
- Fresh isolated TripleFold emulator, API 26: single 1008×2232, double 2048×2232 and triple 3184×2232. Eight synthetic canvases cover three dimensions, multiple cards and geometry, without credentials/images. Homepage screenshots inspected in all three forms. Rotation commands returned success but screenshots did not rotate, so those commands are **not** counted as additional visual coverage.
- Existing Huawei_TripleFold emulator showed an unreadable historical local record. It was stopped and preserved, not reset/uninstalled or silently repaired. A separate FridgeMatrix20261019 emulator instance was created for synthetic fixtures. Its initial Celia keyboard consent was not accepted; fixture preferences were seeded only into this new isolated instance. No real-device artwork/preferences were overwritten.
- Production geometry regressions cover narrow/tall/square/wide/short windows and safe areas; editor matrix adds 216 combinations. Short windows no longer invent a 120vp body beyond available height.

## Changes

- Normal icon startup opens gallery without eagerly decoding original scene images. Direct widget/card routes still prepare images before workspace reveal, including warm same-canvas widget routes after a gallery-only startup. Native decode limits and pixel quality are unchanged.
- Cold gallery index reading is limited to four concurrent reads instead of one per canvas at once.
- Relief preparation batches all cards in the same directory: one raster/cache-cleanup call per folder. Canonical fingerprints keep identical artwork reusable across card IDs. No additional per-card directory scans; no lossy image conversion.
- Idle maintenance prunes only flat `gallery_v2_*` generated files older than ten minutes, protects live index references and retained visible/in-memory image paths, excludes new writes, and stops if a live index is ambiguous. No recursive deletion, original asset/share/export/cloud-history cleanup or widget identity changes. Cleanup runs once per page instance and never blocks navigation.
- App cloud menu, check button and panel removed. The manual cloud coordinator is no longer linked into the packaged product. System cloud remains disabled on the tested device; no cloud data was published. Automatic sync after enabling the system toggle is still pending, not implied by removing UI.

## Measurements

Same actual tablet, portrait, existing three-canvas library. Three force-stop/cold-start samples per build, with memory sampled after three seconds. Debug build, local warm filesystem caches, no claim of controlled laboratory conditions. No log clearing or device-wide settings changes.

| Metric | Before (3 samples) | After (3 samples) |
| --- | --- | --- |
| Scene ready from ability creation, ms | 497, 406, 376 | 273, 389, 304 |
| Median scene ready | 406ms | 304ms (~25% lower) |
| App PSS, KiB | 165769, 122390, 126636 | 113969, 92632, 86425 |
| Median app PSS | ~123.7MiB | ~90.5MiB (~27% lower) |
| Graphics PSS, KiB | 35704, 35652, 35652 | 7100, 7100, 7100 |

The biggest deterministic change is that the gallery no longer decodes editor-only originals. Process PSS is noisy and varies with OS reclaim/GC; these small-sample improvements are evidence for this dataset, not a universal guarantee or frame-rate claim.

First native cleanup removed **11** stale generated cache files, reclaiming **1,570,943 bytes**. Subsequent two starts removed zero. Gallery-cache directory snapshot went from 18 files / 3,812,506 bytes to 7 files / 2,673,478 bytes; live preview rewrites explain why net size change differs from reclaimed bytes. Original files and cloud history were excluded. Memory stats and metadata-only profiles are in ignored output/matrix-perf-{before,after}* and output/matrix-cache-{before,after}.json.

## Checks / limits

97/97 suites, native assembleHap, production package page/extension audit, no cloud panel/manual coordinator or temporary orientation hooks in final ABC. Cache tests use real temporary files, including directory-looking filenames, corrupt live indexes, recent/in-flight files and retained preview references. No complete frame-time trace, 60/120fps claim, actual cloud round trip or authenticated school import is claimed. Original source-image orphan collection remains intentionally outside this change because undo, saved canvases/scenes and forms can retain references.

Final installed tablet package: native menu inspection confirmed no cloud entry; three consecutive gallery → editor → gallery cycles completed without a stuck transition or missing canvases.
