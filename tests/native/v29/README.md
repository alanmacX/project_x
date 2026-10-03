# v29 UI refinement QA

MatePad Mini, HarmonyOS 7, API 26; 1600×2560 portrait and 2560×1600 landscape.

- Opened existing card without editing data; checked background/content tabs and cream section hierarchy in light portrait.
- Used temporary app-only landscape orientation and dark appearance overrides to inspect native UI; production EntryAbility restored before final build/install. No system appearance or rotation setting changed.
- Verified capability configuration precedes placement, current capability disclosure opens/closes without changing capability, selected choices remain readable, preview resize handle remains readable over a white card.
- Opened course dialog without saving: start/end controls, weekday/parity choices, placeholders and fixed cancel/save visible in dark landscape. Repaired dark placeholders and blurred handle contrast based on native screenshots.
- Compared canvas/catalog preferences before/after QA: all original fields and card counts preserved. Existing load normalization added empty parcel/event/title defaults and a 60-minute interval to the unconfigured timetable; no course or artwork changes. Screenshots and personal preference snapshots remain outside the repository.
- Six model/service suites plus editor/layout CPU benchmarks pass; CPU numbers do not measure device rendering FPS. No device frame-rate claim is made.
