# Content-fitted capability backings — 2026-10-07

## Changes
- Removed the material from the movable capability frame. The material now belongs to the actual content; the editing and hit area remain unchanged.
- Shared `ReadingBacking` applies the same compact geometry to paper, feather and scrim. Removed the old 1.45x background overscale.
- Battery uses a hollow 288-degree band following the dial, a short wider segment beneath the tangent numeric label, and a small circular support beneath the charging symbol. No full rectangular or circular fill.
- Clock/readout widths use cached native ArkUI text measurement; calendar follows seven columns. Timetable and agenda heights follow visible content, without layout-weight fillers. Padding is 4 content vp per side.
- Native Chinese TextClock `dd` includes 日. Measuring only two digits wrapped this suffix; date sizing now includes the native suffix and limits the readout font.

## Validation
- All `tests/*.test.cjs` passed, including measurement caching and annular-mask geometry. Release ArkTS build passed.
- Native MatePad Mini captures used a temporary read-only gallery with an existing local cutout. Verified battery, clock, week calendar, world clock, lunar date, date, countdown, progress and empty agenda/timetable.
- Also inspected `CardFace(widget:true)` with legacy feather battery, populated agenda and populated day timetable. This is the shared widget rendering mode inside an Ability, not a capture of the desktop Form host.
- Native captures remain outside git because they contain personal artwork. Temporary launch route/gallery removed before production build; no canvas fixture was saved to user storage.
