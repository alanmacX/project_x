# Editor motion and UI refinement — 2026-10-05

MatePad Mini, 1600 × 2560, 120 Hz; native HDC/UITest, on-device ace/graphic hitrace and RenderService composer frame timestamps. Test gestures ran in a disposable copy of the user's canvas; private images, raw traces and layouts stay outside this repository.

## Verified changes

- Canvas chooser uses a warm tinted native immersive popup host, subtle selected rows and shared text tokens; menu actions avoid nested black fills. Canvas creation, duplication, switching and deletion were exercised.
- Native background/upstream segmented controls, rounded section surfaces and neutral control fills were inspected in the card editor; solid background and HDS anchored color popup opened successfully.
- Regular text and photo-subject text drag, resize and rotation were exercised, with undo between samples. Live geometry now updates the observed layer and its handles; card snapshots, history and storage are committed on completion. Shadow/sidewall backing is cached independently.
- The comparison route renders three detached copies of the same actual photo-subject/count-up card: feather, local scrim and glyph halo. It does not save changes. The blend setting is normalized and preserved by the normal card serialization path; app, widget and export share the renderer.
- System capability refresh is held off during gestures/hero transitions, including results that return after a gesture starts. Photo-backed secondary labels retain full glyph opacity.

## Measurements and limits

| Gesture sample | Duration | Compositor FPS | UI task p95 | UI task max |
|---|---:|---:|---:|---:|
| Regular text resize | 763 ms | 119.9 | 3.49 ms | 3.89 ms |
| Regular text rotation | 913 ms | 119.9 | 3.21 ms | 3.77 ms |
| Photo-subject text resize | 815 ms | 119.9 | 4.55 ms | 4.97 ms |
| Photo-subject text rotation | 796 ms | 119.9 | 3.92 ms | 4.51 ms |

Hitrace clipped the first pan-start in both final recordings, so the drag segment is not reported quantitatively. The supplied parser merges/deduplicates all three composer dumps before mapping their monotonic timestamps into trace time: indexing dump number by recognized gesture number was invalid after that clipped event. Only recognized complete windows are reported. UI values include nested `UIVsyncTask` scopes, following the earlier v42 parser; they are not exclusive total frame CPU or GPU time.

Earlier short pre-change resize/rotation traces had p95 17.26/20.97 ms and maxima 18.46/22.14 ms. Their durations differ, so this is supporting evidence of an expensive path, not a matched percentage improvement benchmark. The current short samples do not establish sustained frame-rate guarantees, cold-load performance, all devices, or every page/state. No claim that all UI is now 120 fps.

## Validation

Debug assembleHap; model, capability framework, editor motion isolation, appearance lifecycle, cold render cache, local sharing, PNG export, editable template packages, timetable display, background palette, multi-canvas capabilities, sketch contour and time capabilities tests.
