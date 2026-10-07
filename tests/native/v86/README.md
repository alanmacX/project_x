# Six content compositions — 2026-10-07

Bare text, badge, adaptive patch, negative-space cloud, hanging tag and information Dock are stored as readingBlend. Legacy material values are retained without automatic restyling. All non-album capabilities can choose the six styles. Album keeps its previously approved dedicated cover/FluidGradient composition; the inspector explains this exception.

- Native Select provides style choice; recommendations distinguish single readings from multi-row summaries. Comparison sheet includes all six.
- Photo colour is extracted from a 48px local decode via TaskPool on first style selection and persisted. It is never sampled while dragging or ticking. Missing photo uses material colour.
- Compact content measurement and intrinsic heights from v85 remain. Cloud/patch add only the padding necessary to keep their curved edges away from text. Badge is circular for battery and a capsule for multi-line readings.
- Smooth patch/cloud paths contain six cubic segments, independent of subject outline complexity. These are content-sized reusable silhouettes, not automatic tracing of the subject's contour. No generated raster artwork was needed.
- New compositions allow bounded placement outside the subject and rotation. Positions/angles/tint survive storage and sharing normalization. The capability frame remains recoverable; resizing does not snap external positions back inside.
- Rendering cache fringe now includes rotated external attachments. The comparison viewport also fits these bounds. Existing artwork bounds and legacy placement behavior remain unchanged.

Validation: release ArkTS build; full tests/*.test.cjs suite; native MatePad Mini read-only gallery with a user's existing local cutout, including all six representative styles and a populated timetable. Captures outside git preserve personal artwork. The native gallery used the shared Ability renderer, not the desktop Form host. Temporary gallery and launch route removed before production build.
