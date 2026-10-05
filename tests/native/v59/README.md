# Reading-field parity on MatePad Mini

Physical device HDC 5KLBB25C19200110, 1600×2560. Compared the existing yellow canvas in App and desktop before/after installation; private screenshots remain in /tmp. The clock/timetable reading fields were visually broader/hazier on the desktop before the patch. Replacing native radialGradient with bundled alpha textures removed the obvious extra pale field behind the clock on the captured desktop and brought timetable backing closer to the app.

Both hosts now use the same precomputed 256×256 RGBA field, scaled identically; feather/scrim and all four contrast colours remain supported. Text contrast halos and substrate shadows remain intact. Eight small bundled PNGs require no network or per-frame generation. This is a visual fix on the observed canvas, not proof of the underlying FormKit gradient implementation or perfect pixel equivalence across all devices.

Signed debug build succeeds; installed and started on the physical device, returned to desktop and checked widget clock/battery refresh. Screenshots exclude repository storage.
