# Gradient history comparison — 2026-10-05

Reviewed the renderer and compositor at ecda621, b82a472, be4b215, 975984a, 1a0f2be and 214eda2. The controlled comparison image uses identical three-colour anchors/weights/positions for every renderer; it isolates visual compositing, not changes in image sampling. Columns: ecda621, b82a472, 1a0f2be, 214eda2, this revision.

The first recovery at 214eda2 still differed from b82a472: it introduced a dark/desaturated foundation and restored only 65% of Overlay lighting. The 1a0f2be worker also globally merged all perceptually similar colours, collapsing distant clouds to one centre. These were substantive departures, not just blur adjustments.

Restore dominant-source foundation, strongest-first ordering, full-strength Overlay and isolated native offscreen blending from b82a472. Keep measured palette proportions and visible-area voting, with relative weight exponent .75 to suppress tiny accents rather than the historical 55% minimum opacity. Merge only similar colours whose centres are <.2 apart; retain at most six clouds. Preserve 180-second slow animation, 8% native movement range and static bitmap dominance in App to avoid a large visual mismatch with FormKit. This restores the historical compositing approach, not pixel-identical historical output or exact Apple Music rendering.

The worker/cache and native renderer share the foundation, ordering and opacity equation. fluid-v10 invalidates old output. No palette generation on drag or per-frame JavaScript added.

Validation: background palette, album and canvas capability checks passed; signed debug build successful; installed and started on MatePad Mini. Actual portrait screenshot /tmp/fluid-history-restored.jpeg inspected. Native Overlay performance and desktop update timing were not measured again this turn.

Regression checks include: original dominant foundation colour, single-hue nonflat light folds (>2 Lab lightness span, replacing v47's arbitrary >8 aesthetic target), minority red does not dominate yellow, and two far-apart yellow cards retain distinct clouds. The supplied comparison is synthetic; personal native captures remain outside Git.

Reference implementation: Cindori/FluidGradient BlobLayer.swift and FluidGradientView.swift, MIT (see THIRD_PARTY_NOTICES.md). The source uses radial solid cores, two layers, Overlay and final blur.
