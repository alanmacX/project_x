# Native share receiver and render dependency regression — 2026-10-09

## Production changes

- Custom UTD is `com.fridgewidget.app.template`, matching the application owner. The previous `com.fridgememo.template` failed native registration: querying `.fridge` returned a dynamic `flex.*` descriptor and Files did not offer this application.
- ShareExtension accepts exactly one record of that UTD. General file/image/text types are deliberately absent. Anonymous granted file URIs are accepted only after type validation.
- Receiver reads the UIExtension session LocalStorage through its UIContext, stages and inspects in TaskPool, releases abandoned copies, transfers ownership before starting the app, and terminates its native receive panel after handoff.
- Ordinary non-foldable phones use portrait orientation. Tablets and foldables retain automatic rotation.
- Storage serialization no longer deep-clones nested payloads before serializing. Interactive snapshots remain detached.
- Board geometry is reused until size, scale, or card data changes. Static/daily/album capability clocks only invalidate at their visible update granularity.
- Native style candidate generation detaches large course/element payloads once, instead of copying them for each variant.

## Native observations

MatePad Mini, 1600×2560, 120Hz:
1. Files → Share `.fridge` → all applications includes 冰箱贴桌面.
2. Receiver correctly displays one card / zero assets and opens the production import confirmation.
3. Import was cancelled; existing canvas was not replaced or modified.
4. Negative image share initial application rows did not contain this app. Full all-app negative panel verification was interrupted by locking/surface change and is **not claimed complete**. Exact-type rejection is covered by model/manifest regression.

Pura X Max emulator, folded 1264×1848: home canvas and album editor reviewed. No new expanded-screen native capture after emulator disconnected. Responsive layout regression covers 16 windows plus both screens/orientations of Pura X Max and Mate X7.

## Performance observations and limits

A warm widget → app → Home sample, main thread only, contained 9 UIVsync tasks: maximum 6.65 ms, p95 1.04 ms. This is a narrow warm no-edit observation, **not a 120 FPS claim**.

Opening the album editor had a 117.24 ms initial UIVsync task (39.72 ms Index rerender and 44.49 ms layout scheduling); the subsequent captured 380 ms animation window had 18 tasks, maximum 9.32 ms, one over 8.33 ms. This sample was taken before the final style-candidate copy reduction. First editor construction remains a measured outstanding bottleneck. Final code compiled and was reinstalled; no numerical improvement from the last reduction is claimed without another capture.

## Reproduction and privacy

`ShareProbe.ets` is a test-only harness using a synthetic one-card .fridge and plain text. It is absent from production page registrations and routing. Native traces, account data, layout dumps and user screenshots are not committed. Do not apply the synthetic card to a user canvas.

Relevant official references:
- https://developer.huawei.com/consumer/en/doc/harmonyos-guides/share-sec-panel
- https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-purax-12
- https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/window-rotation
