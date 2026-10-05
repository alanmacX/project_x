# Card minimum-size audit — 2026-10-05

## Actual constraints

`BoardCard.startResize` computes a proportional floor from `minimumCardSize`; group resizing uses the same floor. A regular card had an unrelated 80×80 artwork floor even with no capability. `normalizeState` independently restored that same 80-unit lower bound, so a gesture-only correction would still inflate saved/imported artwork on reload.

Use shared artwork limits: regular shapes 32 units; extracted subjects retain their existing 16-unit floor. Capability constraints remain additional and are enforced from actual content and silhouette interior. Units are board coordinates (board width 344), not physical pixels; their on-screen size depends on the widget/editor scale.

Compact clock nominal content changes from 80×36 to 68×32. Compact countdown/anniversary changes its 80-unit baseline to 72 and height 50 to 46, retaining the digit-dependent width. Upcoming timetable gains a real 96×80 compact layout instead of always reserving 128×116: a one-line adaptive lesson name, time and location beneath its heading. Long titles truncate with an ellipsis; detail/week views retain full course data. Holiday, evening gating and course-switch timing remain unchanged. Day brief still reserves space for all lessons; it is not reduced to a single summary just to allow shrinking.

## Validation

Signed debug package builds and installs on the connected MatePad. No physical resize/frame-rate result is claimed for this iteration. Actual model/component code regressions verify:

- Small regular artwork survives normalization at 32×40, rather than returning to 80×80; group scaling reaches the same floor.
- Compact clock constraints fall below 80×80.
- A 300×360 photo whose interior spans only 40% of its width can shrink an upcoming timetable below 250 units wide; its capability still passes the readable-content check after accounting for white edge and reading inset. Repeated size reconciliation is idempotent.
- Day brief retains all eight lessons and its readable floor; thin silhouettes still refuse impossible dense content rather than silently cropping it.
- Model, capability framework, timetable display, template export/import, canvas capability and local sharing suites pass.

Existing artwork is not automatically shrunk. No original course or canvas content was edited by these regression checks.
