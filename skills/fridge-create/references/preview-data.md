# Host-only synthetic data for authoring QA

Use capabilities that fit the work, not only a clock because other providers have no real user data. Keep artwork portable and recipient-bound; populate the **preview host** instead. The previewer uses the exact same production calculations and visual adapter for fixture and real data.

Load the `.fridge` first, then set a fixed time with `FridgeHarness.setTick(ISO_TIMESTAMP)`. `setDataProfile('demo')`, `setDataProfile('long')`, `setDataProfile('empty')` and `setDataProfile('none')` provide deterministic generated records based on that time. Or call `setPreviewData(fixture)` with `{format:"fridge-preview-data",version:1,byCard:{CARD_ID:DATA}}`. `setPreviewData(null)` resets. Opening another artwork resets custom data.

Allowed per-kind overrides:

- battery: percent, charging, chargeState.
- agenda: events, each {id,title,start,end,location,allDay}; timestamps are numeric epoch milliseconds.
- timetable: semester, courses, holidayDates, teachingDays, courseChanges. CourseItem is {id,name,room,day,start,end,firstWeek,lastWeek,parity}; day 1–7, time HH:mm. Use synthetic teaching days if the fixed fixture date is a holiday.
- countdown/anniversary: title, date (YYYY-MM-DD).

All other kinds derive data from preview tick or deliberate artwork. Do not override capability type, geometry, style, resources or renderer internals through fixtures. Keep a `.preview-data.json` sidecar with custom values and record the fixed tick in `.qa.json`. The UI also loads this local JSON. Never include fake records in the actual `.fridge`, decorative assets or static HTML.

Capture populated and empty/unbound states at 300/420px (and the target widget size). The report records `previewData.synthetic`, profile mode and applied card IDs. `getCardMetrics()` inspects the same projected data as the screenshot, so fit checks must use it after applying fixtures. Inspect long names if the work includes information-dense capabilities. Do not accept a beautiful populated preview whose unbound state clips or breaks.

Only synthetic, invented data belongs here. Do not scrape the sender’s private data to fill a demonstration. Actual App permissions, saved user records and Form rendering remain separate native QA; a browser fixture does not establish parity.
