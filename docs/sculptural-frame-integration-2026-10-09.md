# Approved sculptural frame integration

Recipe: stone, study width 600, width 18, depth 16, grain 20, bevel 33. Wall/ratio/content are demo viewing conditions, not settings that overwrite a canvas.

`CanvasBackground.frameStyle` is independent of mode: none/light/dark/auto. Missing fields migrate from `transparentFrame` only on legacy transparent backgrounds. Ordinary old canvases keep no frame. Solid/photo/preset/smart/blend changes and palette worker output preserve the selected frame; `.fridge` exports retain the setting.

App, Form, settings thumbnails, square-corner social exports and browser renderer use the same baked hollow tiles. Eight image strips/corners retain antialiasing and the shader's inner/outer bevel lighting. The center has no bitmap or material pass. Geometry scales with canvas width. Native auto style resolves base/dark resources; explicit white stone stays white in dark mode.

Offline reproduction: with Playwright and Sharp available, run `node tools/bake-frame-study.cjs`, then `node previewer/build.cjs`. The baker starts its own localhost server. It uses the real accepted study shader, not an image generation approximation.

Native QA on MatePad Mini: build, replace-install, App display and actual desktop display verified. Native Stack alignment did not place individual rails; explicit numeric coordinates fixed it. Form's initial fallback dimensions did not match the host slot; the frame now measures its own actual area using onAreaChange. There are no live texture calculations, full-canvas blur or shadow layers in CanvasFrame. This is an implementation cost reduction, not a measured refresh-rate guarantee.

Local screenshots: `output/frame-integration-2026-10-09/app.jpeg` and `desktop.jpeg`. Screenshot data is kept out of Git.
