Native verification on MatePad Mini, API 26, 2026-10-03:

- Temporary QA page uses the actual ArkWeb engine and bundled URP / Strongwise providers; no FridgeStore writes.
- URP fixture: explicit periods 11–12, 20:00–21:40, interrupted weeks [1,2,3,5,7,9,10,11]. Native preview preserved all occurrences.
- Full production dialogs exercised via a temporary loopback fixture server: choose generic URP → enter URL → open page → read → native provider prompt → preview → missing-semester validation → native date picker → confirm. This is fixture verification, not an authenticated school account test.
- Strongwise fixture includes colspan header, rowspan morning label, two Wednesday courses with odd/even weeks; both remained Wednesday after extraction. Missing period times remained blank for confirmation.
- Catalogue and browser dialogs visually inspected on the device in portrait. School account login, actual school SSO/captcha, and every directory entry remain unverified.

To repeat, copy SchoolImportQA.ets to entry/src/main/ets/pages, temporarily register/load pages/NativeV28QA, build, and restore the production entry/page profile immediately afterward. Fixture code is outside the shipped app. Never store credentials or real account HTML as test fixtures.
