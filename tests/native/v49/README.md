# Fixed smart multicolour artwork — 2026-10-05

Remove the animated FluidBackdrop compositor and liveFluid prop/callsite. CanvasBackdrop now only displays the generated bitmap, using the light-fold composition reviewed at v48. No slow animation or 18% moving overlay remains. The fixed composition is deterministic, not a runtime animation screenshot or a randomly stopped frame. Blur/Overlay are baked into the off-thread generated bitmap shared with desktop FormKit and export. Existing v10 bitmaps remain valid because the bitmap composition is unchanged.

background-palette.test.cjs and album.test.cjs pass. Signed debug build succeeds and installs/starts on MatePad Mini. Confirmed no remaining FluidBackdrop/liveFluid references under entry/src/main/ets. No refresh-rate claim: no new frame timing capture was performed.
