# Restored historical full-host desktop composition

The user preferred the original host-adaptive layout over the fixed authored viewport introduced in `3a98384` and the intermediate backdrop-only correction in `f9e751f`. The active Form rendering and App ratio selection now restore that historical policy (as present before `3a98384`, including the frame anchoring work in `0f4f881`).

The physical host is the canvas. Background and frame fill it. Card centres use normalized X/Y placement across its width and height; card dimensions use a single width-based scale, preserving card and text proportions. There is no contained/letterboxed logical canvas. Changing host aspect therefore changes the spacing between card centres, as in the historical version. Existing intentional off-canvas clipping remains.

The root launch action sends the actual current host ratio to the App. App geometry prefers this live ratio, then the stored Form dimension ratio, then the document fallback. Startup, document switches, timed scene editing and resume use one helper. This replaces the former fixed-aspect choice without reverting capability fit improvements, scene race fixes, desktop selection repairs, or native frame anchors. Reading host geometry does not clamp or reposition persisted cards.

Validation: 59/59 regression suites pass, the added production-helper test passes live/cached/fallback ratio selection and proportion-preserving normalized placement over portrait and landscape shapes. Native debug HAP builds successfully. Installed on the emulator. MatePad Mini disconnected before installation; the physical device has not received this restoration and physical rotation visual acceptance remains outstanding.
