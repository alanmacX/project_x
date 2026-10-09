# Space-driven capability density — 2026-10-09

No device was provided for this round. Validation covers production model regressions, signed native compilation and the independent browser adapter; it is not native screenshot or device frame-rate acceptance.

## Implemented behavior

- Agenda typography caps at its original scale. Additional height adds rows; at 352 logical content units, width adds a second column. At most 12 events mount, and the remaining count includes all future events. Small cards preserve the established 0.8 readability floor.
- Timetable brief retains all lessons of the effective day and its established 1/2/3-column thresholds. Extra height changes each tile from 32 to 48/60 units, allowing two title lines and then two location lines. Font sizes remain stable. Next-lesson mode still contains only one lesson and retains holiday/evening gating; a sufficiently tall readout adds time-to-start, remaining time or duration.
- Calendar moves from the existing week/month views to a detailed month when width and row height allow. It adds cached local lunar/holiday captions without enlarging dates. Cache is bounded to 24 months; the Chinese-calendar formatter is reused.
- Native app, Form and exports use the same native components. Previewer uses the same pure density, time and calendar models, with a matching browser presentation adapter. Current-host authoring/design fingerprints are regenerated.

## QA

All 48 `tests/*.test.cjs` suites passed. `assembleHap` and `previewer/build.cjs --check` succeeded. `information-density.test.cjs` covers monotonic height/width event budgets, two-column thresholds, a bounded native node count, no source mutation, compact readability, timetable detail thresholds/context, six-week calendar fit and month-label cache identity.

`previewer/density-demo.html` renders fictional local samples through the production adapter. Browser inspection verified:

- Agenda 184×152 / 184×300 / 384×300: 2 / 5 / 10 visible entries, all at content scale 1.00.
- Daily timetable: complete start/end times; longer title/room strings wrap as space grows; remaining text ellipsizes. All six sample lessons remain present.
- Next lesson: one lesson at all sizes; extra space reveals the room and duration.
- Calendar: week → full month → month with lunar/holiday captions.

Browser font metrics, system-symbol substitutes and mica rendering remain approximations; real-device text layout and desktop parity need later acceptance. Imagegen personalization boards are proposals only, and do not introduce course color markers, new handwritten controls or new backgrounds into the app in this commit.
