# Fold orientation QA · 2026-10-12

Native target: Huawei_TripleFold, HarmonyOS 7 API26. System orientation lock OFF; no app restart between folding changes.

- Single: rotate emulator left; app remains 1008×2232 portrait.
- Double: orientations change between 2232×2048 and 2048×2232.
- Triple: orientations change between 2232×3184 and 3184×2232.
- From triple landscape fold directly to single: app returns 1008×2232 portrait.
- Unfold again: auto rotation resumes without restart.

EntryAbility lifecycle tests execute the production DevicePolicy and verify ordinary phone, ordinary fold, wide fold, triple single/double/full, half-fold active inner/outer display, unknown form and tablet. They also verify serialized orientation IPC, deduplication, foreground retry, exact listener removal and destroyed-window stale completion.

Ordinary-fold and wide-fold policy is covered by automated API-state regression here; not claimed as native execution on those two emulators in this run.

Official reference: https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-purax-12
The active fold display and physical posture are distinct; current window width is not used to guess folded status.
