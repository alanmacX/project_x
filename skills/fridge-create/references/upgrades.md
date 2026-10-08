# Authoring through app and design updates

The release contract is generated from production models, renderer sources, material assets and AppScope metadata. `contractVersion` describes this metadata artifact; it is not the `.fridge` container version. Its `identity` changes during pre-release visual polishing even if app version remains 1.0.0.

Before authoring in the repository:

1. Run `node previewer/build.cjs --check`. If stale, regenerate using `node previewer/build.cjs`, inspect the source change and generated contract, then perform the relevant visual regressions. Rebuilding a hash does not approve new visuals.
2. Read the generated capability/style list, fields and design tokens. Use current-format.md for semantics. Neither an added field nor a new capability means the browser automatically supports its appearance. Check `preview.supportedCapabilities`; unsupported renderers block QA.
3. Read packages with the actual production reader. Preserve the original input before any normalization/migration. Reject unknown required behavior rather than silently converting it.
4. Use `FridgeHarness.getCardMetrics()` (or `FridgeReadouts.inspectCard(normalizedCard)`) to inspect actual available content dimensions, compact mode, minimum size and fit. Do not guess from the outer card width. Check rendered long text, empty data, overlap and target aspect too.
5. Save editable output and a separate QA receipt identifying the contract, package checksum, fixed preview tick/timezone/size, screenshot path and actual review outcomes. Never place those extra fields in a v1 package.

For a release, compare the archived contract against the current one using `node scripts/fridge-contract-diff.cjs previous.json current.json`. Capability/style/field removal and protocol changes need compatibility review; changed model/material/browser/native identities need visual review. The comparison never approves a release, rewrites artwork or updates image baselines.

Current limitation: v1 packages follow current host design defaults; they do not persist a design profile. Keeping a receipt proves what was reviewed, not that a future host looks identical. If a future redesign must preserve old appearances, implement explicit profile migration in both app reader and renderer before authoring that field. Preserve original packages/assets and manually approved baseline images so a later update can be compared or re-rendered.

Frontend reuse is separate from editable app works: `FridgeWeb.renderLayers()` exposes the same rendered card groups and shared SVG definitions for external animation. Keep camera/timing/data overrides in the external project's files, never in the v1 `.fridge`. Static frames do not implement live app behavior, and HTML cards remain unsupported until an actual versioned reader/renderer is shipped.
