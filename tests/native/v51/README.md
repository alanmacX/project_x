# Local timed scenes — 2026-10-05

This round used only the Mate 80 RS emulator (`127.0.0.1:5555`), portrait 1320 × 2848 and landscape 2848 × 1320. No physical device was tested or installed.

## Implemented and exercised

- Native rounded/cream scheduling sheet, saved arrangements, weekly weekdays, one-off date and time selection, enable/disable, edit/delete and preview. Landscape sheet scrolls within the system host.
- Three projection modes: saved geometry, another canvas, and focus card with rotated surrounding cards moved to the nearest edge leaving 5–14 board units visible. Source geometry and images stay unchanged.
- A local two-card fixture triggered focus automatically at 22:00 on Oct 5. Its central card could be tapped to restore in the app. Saved-layout and cross-canvas previews were entered and exited; the cross-canvas target was an empty existing test canvas.
- Launcher 4×4 card was added. Initial testing exposed an existing shared CardFace shadow call to app-only UIContext.vp2px: the form renderer threw and showed an empty white card. It now uses the form-supported global unit conversion. After a cold emulator restart, the fixture rendered on the desktop.
- Desktop focus delivery, restore button, central text-only card acknowledgement and subsequent base rendering were exercised. Decorative cards deliberately have no normal capability route; focus acknowledgement now explicitly accepts them through the same shape-aware hit test.
- The animation controller accepts a newer packet during an unfinished transition and ignores old callbacks; hide/reappear resets to the current packet. Pure controller tests step the actual native-animation callback chain. No JS timers run inside the form renderer.

## Performance evidence and scope

The observed automatic focus transition used a 560 ms native animation. In its short emulator ace/graphic trace window (animation start 1895.056714 monotonic seconds), 12 UIVsyncTask scopes were recognized; maximum and p95 scope duration were 2.38 ms. This is UI work for a two-card emulator sample, not a frame-rate measurement, a 32-card stress result or a physical-device refresh-rate guarantee.

The pure projection benchmark evaluated 500 focus scenes with 32 cards in approximately 16–20 ms total on the Mac host. Geometry is calculated at state changes, not each animation frame. Gestures/edits defer a scheduled transition; background palette extraction is suspended and invalidated while showing a derived scene. Ordinary updates retain the static gradient cache.

## Platform contract

Form pages support global animateTo; the installed SDK rejects app UIContext.animateTo and JS setTimeout/clearTimeout in forms. Cross-canvas forms commit the incoming nodes offscreen using a short native animation transaction before their entrance. Geometry, background, context and displayed canvas ID travel in an atomic scenePacket; binding ownership remains on the source canvas.

The installed FormProvider declaration sets setFormNextRefreshTime's minimum to 5 minutes. The 30-minute profile baseline and visibility refresh are retained; only a nearer scene boundary uses a scheduling request, with repeated-save deduplication. System daily quota, sleep and host suspension can delay display. This feature is a local visual schedule, not a precision notification/alarm service; sub-five-minute intervals cannot be guaranteed on the desktop.

Official context: [passive form refresh](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh), [Form Kit](https://developer.huawei.com/consumer/cn/sdk/form-kit/). Exact supported APIs were checked against the installed API 26 SDK declarations and verified by assembleHap and emulator rendering.

## Regression coverage

18 source-executing regression scripts: timed rule boundaries, overnight/whole-day/weekly/one-off dates, daylight-saving invalid intervals, sticky acknowledgement, overlapping-rule restore, next-day recurrence, missing targets, source isolation, rotated edge bounds, 32-card projection, shape-aware decorative focus hits, atomic/interrupted Form animation, binding ownership, target fanout, battery refresh without persisting projected geometry, foreground acknowledgement merge, refresh floor/quota, imported ID remapping and disabled rules; plus the existing model, editing, sharing, offline capabilities, timetable, holiday, palette and appearance checks. Debug assembleHap passed.

Raw emulator layouts, recordings and personal fixture images are not committed.
