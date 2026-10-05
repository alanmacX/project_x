# App/Form relief scale parity

Found deterministic scene-size discrepancies in shared rendering: cardDepthScale clamped to .65–1.5, so smaller hosts did not retain the same shadow/sidewall proportions; rectangular substrate corners stayed at 16vp independent of artwork scaling. Both now scale linearly with the artwork across CardFace and CardCanvas, including the mask clip and backing.

Reading fields are shared CardCanvas radial gradients, not a widget-specific background blur. CanvasBackdrop displays the same generated bitmap. No evidence yet identifying all reported fuzzy regions: a matching real-device screenshot pair is still needed to distinguish launcher/native material behavior from reading-field appearance. Do not claim all visual divergence eliminated.

22 regression scripts and signed debug build pass. Added normalized relief and corner geometry checks for scale .25–3. No device FPS or screenshot pixel-equivalence claim.
