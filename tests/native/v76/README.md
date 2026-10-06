# V76: offline ICS timetable and background sheet

MatePad Mini, HarmonyOS 7 / API 26, portrait 1600×2560, 120Hz, existing five-photo canvas. Release HAP replaced without resetting data.

## Background sheet

Tapped the same background setting on the same canvas, with no screenshot readback during either trace. The previous opening had a 125.99ms UI frame, including 76.41ms layout. The final trace's first sheet frame was 11.84ms; maximum UI frame was 30.95ms during first native segmented-control creation. Preview-card construction frames were 9.29–11.14ms, instead of constructing the whole miniature in one 30–37ms burst.

Changes: mount settings sections across frames; defer preview work until after native sheet entrance; bake thumbnail silhouette relief on a worker using the same renderer as the homepage; stage individual preview faces invisibly across frames, then fade them in together. Cancellation/generation checks prevent a closed or replaced sheet being repopulated. Opening does not regenerate the smart background palette.

The first native control still exceeds the 8.33ms device budget. This is a large reduction of the reported stall, not a claim that every frame is now 120fps. JSON summaries contain native UI task durations, not displayed-frame FPS. Private artwork screenshots and full traces are not committed.

## Real HarmonyOS course export

WakeUp installed version 6.1.90: share menu has “导出到日历”, “在线分享课表”, “分享 App”; calendar export writes to the system calendar, with no direct ICS file-save choice. The cross-platform WakeUp website alone was insufficient to describe this version.

System Calendar on this device was checked through:
- event details → Share → format menu lists .vcs / .ics / text → Save As;
- More → View all events → long press course → Multi-select → select courses → Share;
- bulk share panel confirmed nine repeating events can be shared together.

Actual selected local ICS was read through DocumentViewPicker/taskpool and reached the native weekly preview, with nine course arrangements. No network client or permission added. User can choose up to 32 ICS files; their different date origins are rebased to one civil week, preserving actual dates and deduplicating identical runs.

ICS model regression covers full-semester weekly expansion beyond the agenda's 90-day window, timezone conversion, excluded/gapped weeks, VTIMEZONE isolation, exact multi-file rebase, and explicit rejection of unsupported monthly/modified-occurrence/all-day/overnight records. Native editor was opened and the selected capability layer's separate trash symbol was visually checked in the layer picker.

## Checks

All 26 host regression scripts passed; release assembleApp succeeded. Detailed user steps are in docs/课程表离线导入.md and the import panel itself. Offline copies do not automatically follow later WakeUp or calendar changes.
