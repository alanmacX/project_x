# System cloud / school import review — 2026-10-19

MatePad Mini, HarmonyOS/API 26, landscape 2560×1600. All installations used `hdc install -r`. No uninstall, store reset, binding reset or school credentials were used.

## Offline release checkpoint

`fa38973a97287eac20550d4cd285cf4b7ecdeab1` precedes all cloud/network changes. Its signed debug HAP is preserved locally under output/releases/local-final-2026-10-19. Source and package boundaries, checksum and production signing caveat are in RELEASE_CHECKPOINTS.md. This is a recoverable offline source checkpoint, not a claim that a debug HAP is an AppGallery release artifact.

## Actual device checks

### Single-tablet test build follow-up

- Read-only check of the actual system cloud UI found this app registered as **冰箱贴桌面小组件**, listed under 使用云空间的应用 after expanding 更多, with **未开启** status. The installed cloud-space package is **7.0.0.303**. The account has a basic-service plan. No subscription, trial, cloud toggle, account or privacy setting was changed.
- Added **检查系统同步** to the production dialog. It requests native FileSync startup without initializing a cloud vault, writing a cursor or publishing new local documents. It does not prove an upload completed or prevent the system from processing previously queued cloud files.
- On the actual tablet, the probe returns **22400001** and displays the setup path. The action re-enables after failure, repeated probing works, and 完成 returns to the gallery. Evidence: ignored `output/cloud-probe-native-result.png`, `output/system-cloud-toggle-disabled.png`, and `output/cloud-probe-gallery-return.png`.
- The panel identifies this as a **manual-sync test version** and explains that edits need another explicit sync. Network, low-battery and IPC errors have distinct messages. Mock tests additionally prove the probe does not publish artwork or create account cursors and rejects concurrent check/sync operations.
- Updated native build and production-package audit pass; **94/94** suites pass. Installed with `hdc install -r`; no reset or uninstall. The signed debug test package is `output/releases/cloud-single-tablet-2026-10-19/entry-default-signed.hap`, SHA256 `863f09ea0b059ca0d8d4d1b3113b9e91be53a4c8d658b3e5f95ee32feee89a27`.
- With the system app toggle disabled, successful native upload/download remains blocked. A second device is unavailable by the user's confirmation. Neither situation is represented as a successful cloud round trip.

- Production gallery More → Huawei cloud panel opens with scope/consent text, native controls and clear local/remote completion distinctions.
- FileSync.start is actually invoked. On this tablet it returns **22400001 / Cloud status not ready**. The app shows the system-account/cloud-toggle instruction and re-enables the action. No cloud directory initialization, asset publication or incoming merge occurs after that error.
- Production existing course card → Edit → Data → Timetable → Import → School catalogue. School search and selection work; ZJUT's actual academic login page loaded inside incognito ArkWeb. No credentials were entered, no import was confirmed. The bundled ZJUT login URL was cleaned of the upstream `kickout=1` presentation flag after seeing its confusing forced-logout message in the unauthenticated page.
- The archived NativeV28QA harness was temporarily registered to run the real current bundled providers and bridge in ArkWeb. URP fixture: interrupted weeks and periods 11–12 with 20:00–21:40; strongwise fixture: two Wednesday courses with odd/even weeks. Both displayed **PASS native ArkWeb → provider → local preview**. The strongwise output retained first/last weeks 1–7 odd and 2–8 even, with missing slot times still blank for explicit confirmation.
- Temporary page, page registration and entry override were restored/removed before the final production build. Package audit explicitly rejects NativeV28QA in ABC; source and package retain the normal Index, WidgetBinding and ReceiveTemplate pages.

Ignored output/ contains the native screenshots, parsed fixture JSON, build logs and test logs. Fixture JSON was copied out and its temporary on-device file removed. It contains synthetic courses only.

## Automated checks

94 test suites pass. New suites execute the actual protocol, coordinator, file transport and store commit paths using platform mocks and actual local file I/O. Coverage includes private course/countdown retention, asset SHA256 deduplication, cloud-only download completion, partial writes, corrupt asset repair/preservation, cross-device edit convergence, deterministic conflict copies, concurrent deletion/edit, repeated sync, last-canvas preservation, preference flush rollback, failure after conflict preparation, unavailable system cloud and vault-separated cursor storage. School catalogue tests check all 237 entries / 249 adapters for resources, syntax and provenance. These are not substitutes for cloud service or actual authenticated school tests.

## Material limits

- **Real cloud upload, remote download, two-device agreement and real system-account changes are not verified.** The current tablet's cloud service is not ready and only one device is connected. The app does not silently change system-account settings.
- Sync is explicit per invocation. It waits up to eight seconds for the system pull completion signal; otherwise it merges available metadata and clearly asks for a later retry. File close/rename publication is delegated to system cloud sync; a returned start request is not global completion.
- No background auto-publish, cloud history compaction or orphaned asset collection. Old immutable records are retained. Metadata has bounded input limits to prevent unbounded allocations.
- The catalogue is a pinned MIT snapshot. Site updates, campus-network rules, SSO and captcha remain school-specific. Two synthetic provider tests do not establish 249 real-school successes.
- AppGallery acceptance of system cloud and school web networking remains unconfirmed. The separate offline commit supports a real feature rollback without pretending that a hidden toggle makes the experiment the old offline package.
