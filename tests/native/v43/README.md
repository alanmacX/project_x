# Group pan and irregular capability sizing — 2026-10-05

MatePad Mini, physical display 1600×2560. HDC native input, UITest layouts, Hitrace and compositor statistics; tests run in a duplicate canvas, which was deleted afterwards. Raw traces and personal canvas screenshots remain outside the repository.

## Reproduction and correction

- Selected group frame swallowed subsequent member drags. Only its two handles participate in hit testing; its interior passes touches through.
- Only the touched member was lifted above other cards. All members now lift together, retaining their relative stacking order beneath the controls.
- Drag bounds and release/reload clamping assumed a fixed canvas height and treated members separately. Bounds use the actual host aspect; commits and reload recovery preserve a shared displacement.
- Irregular-card minima compounded reading padding, silhouette interior and the white edge. Constraints now use an 80% compact typography floor, a 4-unit feathered reading inset, and the white edge at the target size. Timetable and agenda text, gaps and row heights adapt together.

## Native results

Four consecutive alternating drags after selection: each member moved by the same displacement within 1 physical pixel of integer accessibility-bound rounding. Both reverse drags returned to the original bounds. Group rotation handle responded; single-card resizing respected the readable floor. Original grouped canvas had exactly equal text bounds before and after force-stop/relaunch. Duplicate test canvas removed.

| Drag | Duration ms | Compositor FPS | UI Vsync p95 ms | UI max ms |
|---|---:|---:|---:|---:|
| 1 | 846 | 115.1 | 3.65 | 5.85 |
| 2 | 855 | 112.8 | 3.74 | 5.16 |
| 3 | 888 | 113.0 | 3.65 | 5.06 |
| 4 | 799 | 118.6 | 3.45 | 5.11 |

These are measured gesture windows on this device, not a guaranteed frame rate on all hardware. The package built successfully. Model, capability framework, timetable display, time capabilities, canvas capabilities, appearance lifecycle, album, holiday and local-sharing regression suites passed. Regression coverage includes host-dependent bounds, rigid group recovery, readable floors, silhouette padding and dense timetable content.
