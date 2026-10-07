# Explicit normal state and free capability placement (2026-10-07)

Scene settings now identify the normal layout, the triggered target, and the return behaviour. Selecting a saved normal layout applies its geometry to the editable homepage. Subsequent base edits become the current normal arrangement without overwriting either saved layout. Storage retains the selection; canvas import remaps it; single-card export clears it.

Manual capability gestures activate an independent foreground within the full card bounding box. Concave silhouettes and transparent holes no longer block movement or crop that foreground. Position presets still return to a safe interior slot. Existing cards retain their placement until manually adjusted. App and widget hit tests include the foreground while preserving inactive transparent space elsewhere.

Readouts may enlarge up to twice their nominal size. Compact readability floors remain. Resize handles can grow a box beyond the room remaining at its current origin, shifting the origin to keep the enlarged box inside the card. Free foreground sizing no longer requires a large silhouette interior rectangle.

API24 Pura X Max simulator, release build: checked normal layout 1 / triggered layout 2; moved battery content; shrank then enlarged it; changed to an ellipse and confirmed complete foreground rendering. Found and fixed stale battery arc glyph coordinates during resizing: fixed character slots read current geometry. Screenshots are actual native app captures, not redrawn. No real-device FPS or live scheduled Form timing claims.

Validation: release assembleHap, all 26 tests/*.test.cjs suites, git diff --check. Added checks for normal selection/restoration/persistence, immutable saved layouts, import/export references; free foreground movement, transparent-area hit testing, snapshots/storage and enlarged readouts.
