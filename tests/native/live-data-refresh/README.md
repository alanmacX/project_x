# Live data refresh repair — 2026-10-20

Version 1.1 / versionCode 1001001. Original artwork, widget instance IDs, dimensions and bindings remain local and unchanged.

## Findings and changes

- App minute/foreground/battery refresh previously read only the selected document. Unchanged provider values caused no widget delivery, and the ordinary save fanout skipped independently bound canvases. Live refresh now fans out to all bindings, with per-form acknowledgements keyed by visible data, local render tick and binding revision. Static/unchanged forms are not resent each minute.
- Form local render time used the received packet revision, so restored cached packets could project courses/calendar/progress at an old time. One native TextClock minute callback now updates the form's local render dependency without JavaScript timers, provider wake-ups or image IPC. Clock creation is conditional on time-dependent content; the transparent noninteractive clock is excluded from accessibility, while the form root retains its launch action. SDK component/text_clock.d.ts documents onDateChange support in forms since API 11 and minute changes for widgets.
- Provider reads now share one in-flight request and short-lived per-access-token results across cards/canvases in each process. Battery events invalidate recent battery data. Calendar arrays are detached; failures retain the receiving card's own last successful records.
- Widget deliveries and gallery loads project live provider values over detached artwork. Read-attempt timestamps are excluded from disposable display projections so unchanged data does not regenerate thumbnails. Unchanged projections reuse their source; changed projections never mutate or persist the source document.
- A newer delivery invocation supersedes an older provider refresh that finishes later. Native binding revision/lease fences remain in force. Foreground refresh retries after gestures/transitions and retains one trailing pass for overlapping events.
- Returning to the gallery and revealing a scrolled-in row reread its document before requesting a thumbnail. Existing last-good thumbnails remain visible during capture.

## Validation and limits

Executable regression scenarios cover 40 simultaneous battery consumers (one native read), concurrent calendar query coalescing, mutable-array isolation, battery-event cache invalidation, failed-provider fallback, stable preview bytes, independent inactive bindings, minute/data IPC deduplication, old refresh vs newer edit ordering, restored packet clocks, overlapping foreground events and gesture isolation. Full suite: 98/98. Native debug HAP and release APP builds plus packaged production-page audit are required for this commit.

No device was connected (`hdc list targets` empty). The attempted existing isolated matrix emulator did not become an HDC target; no new native runtime acceptance is claimed for this repair. In particular, native TextClock visibility/resume behavior and a real battery charge/discharge change still require connected-device verification. The fix does not claim a permanent background provider or second-level battery updates after the app exits; system wake-up limits still apply. No artificial frequent timer wake-ups were added.
