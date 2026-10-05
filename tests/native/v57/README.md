# Settings motion, control containment and widget delivery

Mate 80 RS API 26 emulator, HDC 127.0.0.1:5555. Physical device was not used.

Native portrait: opened floating tools, edited text, expanded layout section and scrolled through alignment, opacity and three order controls. All three order buttons fit the inspector; disclosure text stays inside its capsule padding. Switched background/content tabs and opened capability readability. Landscape: inspected native segmented controls, presets and comparison action after scrolling. Screenshots remain in /tmp, not the repository.

Home lift/popup now share physical spring parameters (.42/.74 opening, .36/.86 closing). Settings tab/layer/disclosure changes also animate. Removed manually painted white chrome borders and clipped filled colour-setting surfaces/segment selectors. Native HDS may still render its own material highlight.

Form pipeline: initial artwork delivery does not await registration flush; Form no longer imports editor Store and capability services load after first delivery. Native binding sends one atomic scene instead of redundant cards/legacy/background fields. Unchanged scene packets update the native rev binding without rebuilding artwork; changed same-canvas artwork uses 180ms rather than 520ms. Refresh scheduling occurs after artwork delivery. Tested a native canvas background change to dark: bound desktop widget displays the new background. No cold-start milliseconds or physical-device FPS claim.

Regression: 22 scripts, including deferred-registration initial delivery, single scene/image mapping, fd cleanup, unchanged packet reuse and switching back during an in-flight transition. Signed debug build succeeds.
