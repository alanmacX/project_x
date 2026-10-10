# Superseded by restored full-host layout

The user rejected the fixed-aspect fitted composition. See `2026-10-10-restored-full-host-layout.md` for the active policy. This record describes the intermediate attempt only.

# Desktop orientation background bands

## Cause

Commit `3a98384` correctly preserved the authored canvas aspect, but placed the background inside the same fitted viewport as cards. In a different desktop host aspect, the leftover area displayed only the outer fallback colour, producing top/bottom or side bands.

## Rendering contract

- Background and frame fill the physical Form host. Photo and generated multi-colour artwork use the existing Cover fitting; no additional blur, copies, or pixel processing are introduced.
- Cards alone use the centered authored viewport, preserving uniform scale, layout and the existing intentional off-canvas clipping.
- Transparent backgrounds remain transparent, including space outside the fitted artwork.
- Existing decode-gated background transitions, root launch action and render-group caching remain intact.

Different host aspects may show a different crop of the decorative background; card positions and proportions remain stable. This avoids changing the saved composition or cropping capability content just to fill the host.

## Validation

59/59 regression suites pass; native debug HAP builds successfully. The Form backdrop regression verifies both background transition layers are outside the authored viewport, and the frame is outside it as well. Geometry regression covers five authored aspects across five host shapes. Installed on the emulator and MatePad Mini. Physical landscape visual acceptance remains outstanding: the device was in another application during this run.
