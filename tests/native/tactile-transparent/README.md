# Warm paper material and transparent Form integration

## Implemented

- Warm paper is the default host reading surface; matte is portable and selectable through actual native card thumbnails. Geometry, minimum sizes, hook holes and album design remain independent of material.
- Sharing allowlists retain material/tint and exclude source cache keys. Normalization strips all experimental material IDs.
- Subject tint sampling runs sequentially on taskpool with 48px thumbnails after settled edits, and validates canvas/card/source identity before merging. No sampling runs in dragging or a Form frame.
- A 512px derivative of the existing fibre asset reduces shared decoded texture footprint from approximately 6MB to 1MB. No per-frame blur or noise generation.
- Canvas background mode `transparent` round-trips through local storage, .fridge, the app renderer, native Form, and browser renderer. App blank space reveals its own surface; desktop blank space reveals wallpaper. Social share images intentionally retain a light matte/signature footer.
- Form declares `transparencyEnabled: true`; root transparent mode removes the white fill and both background image branches. Opaque-to-transparent transitions fade the outgoing background rather than painting an empty layer over it. Widget taps still route to EntryAbility across the whole slot.
- Empty transparent scenes show a visible 72% × 28% add-card prompt. Authored nonempty scenes still require actual pixel-coverage QA (>=10% visible area); model bounds are not a coverage certificate.

## Verification and limitations

Signed debug build compiles with the existing old profile. This does not prove the approved Form entitlement is present. No device connected this round; desktop transparency, performance and light/dark wallpaper legibility remain unverified.

Huawei's official guide (updated 2026-08-29) requires manual signing for both debugging and distribution, approved capability enabled/saved in AGC and a Profile containing it. DevEco Studio previewer does not show the real transparent effect.

Source: https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-ui-transparent-backplate-form-development

## Finish real-device acceptance

1. In AGC, enable/save approved Back transparent card capability.
2. Create/download a debug Profile using the current app bundle, debug certificate and test device. Keep release Profile/certificate separate; never switch signatures on installed user data without a migration plan.
3. Point local signing configuration to that Profile and its matching certificate/key. Keep secrets and profiles out of Git.
4. Build/install. Remove/re-add the widget if the launcher retains the old form metadata.
5. Select 透明 under 画布背景. Test empty, typical cutout, dense timetable, tiny/offscreen cards, scene transitions, cold add, refresh, whole-slot tap and app return on bright/dark wallpapers. Check actual visible pixel coverage, no unexpected white/blur region, shadows and holes.

Repository skill contract is version 4. Its material and transparency rules are shared with the previewer; no separate unversioned design rules were installed globally.
