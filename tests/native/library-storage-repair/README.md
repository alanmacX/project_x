# Missing library investigation — 2026-10-27

## Physical tablet findings

The connected tablet ran App 1.2.0 / code 1002002. Before this repair, the gallery displayed a default empty canvas. The legacy module preferences contained five keys, including only one empty canvas and a default catalog. A zero-byte `fridge_store.broken` marker dated October 25 was already present. Three non-removed desktop bindings referenced different canvas IDs in the independent widget SQLite database. Source images and some old thumbnails/share images remained on disk.

Startup logs included NativePreferences `closed:Get`, `closed:Put`, `closed:FlushSync`. Existing production callers repeatedly removed `fridge_store` from the process cache while FridgeStore retained a Preferences handle. The SDK explicitly warns not to operate a removed handle. This is a verified application defect; the remaining evidence cannot establish whether an OS update caused the initial corruption, or exactly when prior canvas records disappeared. A desktop host cache is not proof that editable source documents remain.

A local October 11 XML backup contains older, different canvas IDs. It was not copied over the current tablet or rebound to its widgets. No current editable-source backup was found in the application sandbox. No full recovery is claimed.

## Repair

All artwork storage readers/writers now use per-operation sessions backed by the same transactional SQLite key/value database. Reads query committed rows; staged writes are committed atomically, and unrelated rows are not replaced. Legacy XML is imported once under a transaction; the import marker is rechecked inside the write transaction. The original XML is never rewritten by the new backend. Damaged legacy files or missing canvas bodies abort migration before initialization. Previous canvas/catalog rows are retained in a bounded recovery table (one prior row per key).

Preferences cache removal was eliminated from library paths. The separate Form delivery-receipt Preferences file has a single writer and no longer invalidates its own handle. Widget instance IDs, revisions, dimensions, bindings and tombstones were not rewritten by the repair.

## Validation

101/101 regression suites, native debug HAP and release APP compile, packaged production page audit. The new storage regression executes production SQL with independent module/session consumers, checks one-time migration, fresh cross-session reads, atomic rollback/retry, last-good row retention, damaged/missing input rejection and the absence of library cache invalidation.

The repair HAP was installed with `install -r`; no uninstall or data reset occurred. Actual damaged-source startup displayed an explicit stop-writing diagnostic rather than accepting a new empty library. Before/after legacy XML bytes matched. All widget database instance records and revisions matched. The new database had zero initialized values after the guard fired. Returning to the desktop after package replacement showed the host's selection placeholder on the visible form; therefore preserved binding identities must not be described as preserved cached artwork. Other source assets were backed up locally; no synthetic/reconstructed artwork was inserted.

Private raw logs, source files, original images, SQLite/WAL snapshots and UI captures are retained only in ignored `output/missing-gallery-20261027/`. Current version code is 1002003. The user's missing editable library remains unrecovered; resolving that requires an original export/backup or another intact copy, not silently inventing documents from thumbnails.
