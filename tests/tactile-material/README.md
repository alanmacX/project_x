# Tactile material prototypes

Preview: `previewer/material-demo.html` on the existing local preview server.

The browser uses the actual MicaMaterialStudy and CloudReadingGeometry models. Native ReadingBacking has the same fill, pigment, texture opacity, edge and thickness profiles. D (study 4) and E (study 5) are read-only experiments; schema restoration discards the study field. The editor's comparison offers existing / D / E without replacing saved artwork.

- D: warm translucent matte, restrained grain, 1.1 vp side edge.
- E: warm white fine paper, stronger fixed fibres, 1.8 vp side edge.
- Both retain original cloud geometry, composition gutters and actual hook holes.
- No live backdrop blur, timers, random per-frame geometry or texture regeneration.
- Browser drop shadows and font rasterization differ from native. Native pixel parity and frame rate were not verified this round.

The local-only `previewer/material-study-local.js` is an optional subject fixture from the user's .fridge and is deliberately excluded from commits. On another checkout, use the image input to supply a local subject. Demo event/course data is fictional.

Verification: signed native build; mica-material-study, cloud-capability and form-material-runtime suites; production preview bundle check. Browser interaction checked timetable, agenda and battery against the same subject.
