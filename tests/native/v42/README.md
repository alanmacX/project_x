# Native performance checks — 2026-10-05

Tests use HDC/UITest, native Ace/RenderService trace slices and compositor timestamps. They are not host-side timing benchmarks.

`transition_bench.py LABEL` records three entry/exit cycles. Override `HDC` to locate the device tool. It uses fixed coordinates for the tested MatePad landscape layout (2560×1600): layer-row Edit at 2260,404 and editor Done at 2400,180. **Confirm the app is foreground, the correct layout is visible and these coordinates are still valid before running. On the home screen the Done coordinate hits Add.** Use a disposable duplicate canvas. Locked devices, overlays, changed row positions and interrupted gestures invalidate samples.

`trace_fps.py LABEL...` parses `/tmp/LABEL.trace` and the six `/tmp/LABEL-entry-N.fps` / `exit-N.fps` files. It filters to the 380/340ms native animation windows rather than averaging idle time. `trace_slices.py` reports UI work. `trace_gestures.py LABEL PID...` reads pan windows with `/tmp/LABEL-N.fps` dumps; an empty result means no recognized gesture, not excellent performance.

`results.json` contains sanitized measured values. Raw traces, screen captures and image fixtures remain local because they can contain user content. Pressure testing cloned cards in memory with unique local image files and disabled persistence; that harness is not in production code. Original canvas data was preserved and the disposable interaction-test canvas was deleted.

Compositor FPS includes system composition, so it does not prove every card follows touch at 120Hz. Debug build, one tablet, short samples; no low-end phone or long-duration thermal guarantee. See `PERFORMANCE_AND_SHARING.md` for interpretation.
