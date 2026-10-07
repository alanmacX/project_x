# Local album library and rotation — 2026-10-07

Each album card persists a bounded 12-cover library, including titles, artists and paired precomputed FluidGradient images. Existing single-cover cards enter the library automatically. Native photo selection supports batch import. Removing a library entry deliberately does not delete its file: another card or duplicated canvas may reference it. Interrupted worker output is discarded and cleaned up; completed items are retained if a later batch item fails.

Default cover width is 84% of the shorter card edge; native segmented presets offer 94%, 84%, and 70%. Grid row height follows actual available width. Rotation supports off, 1 hour, 3 hours, 6 hours, and every 24 hours from selection. Wall-clock calculations survive relaunch; selecting a cover reanchors the sequence. A manual next-cover action exercises the same transition. Paired images wait for loading before a 420ms crossfade, then release the previous view. No gradient calculation or per-card recurring timer runs during transitions.

Form payloads project the currently due album before opening image descriptors and omit the rest of the library. Album boundaries participate in existing native refresh scheduling. This is local FormExtensionAbility delivery, not server push; system quotas, visibility and scheduling may delay updates. Device refresh timing and animation smoothness are not guaranteed by simulator testing.

Both card and canvas editable file exports carry every referenced library cover/background, with deduplication and the existing size/asset-count limits. Imported paths are remapped; playlist IDs and time anchors remain portable.

Chinese cover sources now open directly through UIAbilityContext.openLink in an external application. Checked the primary pages of [iSearch](https://i.oppsu.cn/) (Chinese search, resolution selection, no signup) and [CoverBox](https://coverbox.henry-hu.com/) (Chinese keyword search). Mainland connectivity across operators has not been independently measured. Source browsing is external and needs internet; imported media, palette generation and rotation operate on local files. No music-platform API or networking client was added to the app.

API24 Pura X Max simulator, release HAP: exercised native image picker with existing local images, imported two separate covers, selected/advanced covers with paired backgrounds, set the hourly option and expanded the source links. No downloaded internet demo images. Captures contained personal gallery material and were not retained in the repository. Build and model test results are recorded by the task; no real-device FPS claims.

Model checks cover precise rotation boundaries and wraparound, manual reanchoring, deterministic reopening, refresh scheduling, malformed/remote asset rejection, adjusted cover sizing, and full four-asset editable-file roundtrip. All tests/*.test.cjs suites pass.
