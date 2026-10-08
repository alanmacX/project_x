# Future HTML draft — not importable yet

Read this only for an HTML request. Current v1 reader does not support HTML. Use `.draft.json` for a proposal and `.html` for an offline visual study, never a fake working `.fridge`.

Future HTML cards remain normal card instances with one capability source. They share host transforms, outline/white border, thickness/shadow, controls, grouping, source binding and export. HTML describes static local appearance; native data slots provide text/time/image/ring/progress/list. Do not build a mini website with internal scrolling or browser controls.

A draft describes target widget aspect, design profile, card geometry, local assets, slot bounds/units, required provider and fields, compact/normal layouts, safe area/overflow behavior, and empty/unavailable/stale presentation. Explicitly label all proposed keys as draft. App/desktop/share must use the same cached appearance and slot model; Web is only used to render templates at import/edit time, not as a live desktop component.

No user JavaScript, event attributes, iframe/object/embed, remote images/fonts/CSS, fetch/WebSocket, account login or filesystem bridge. Decorative HTML is distinct from the trusted host measuring script. Imported values remain text, not markup.

The advanced mode may use creative static gradients, typography and sanitized SVG, within readable bounds. Do not duplicate dynamic content in both HTML and native slots. Do not assume CSS filter/mask/transparent snapshots or fonts are verified: those need the real offline Web rendering prototype. Never say an ordinary browser screenshot proves Form support.

Design semantics should reference host token roles, not recreate app controls. Geometry updates do not re-render HTML on every drag; data changes update native slots. Keep the old cache until new appearance plus measured slots is ready.
