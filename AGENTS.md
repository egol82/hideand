# Hide & Smashing — Phase 6 graphics implementation rules

Read README.md, docs/PHASE6.md, docs/PHASE6_TEST_STATUS.md and docs/ASTRA_START.md.

- Default entry: scenes/phase6.tscn with GraphicsDirector. scenes/phase5.tscn remains available. It reuses improved scripts/phase4 controllers rather than adding another inheritance layer. On this branch phase4.tscn shares that controller; the old Phase 4 snapshot remains in its branch. Preserve Phase 1–3 source, LICENSE and user changes.
- Godot Standard/GDScript and original drawn vectors stay. No paid assets, runtime AI replacement, online telemetry, billing, credentials or engine migration.
- FacingRoot is rotation-only. Cosmetic body squash/bob/blink MUST NOT change weapon geometry, contact samples, reach, HP, clocks or score. AttackSpec remains shared between display and authority.
- Contact events keep attacker/target/outcome identity. Scores and phase transitions remain rule-owned. Field mode remains in-place; unrelated survivors stay active.
- Practice is untimed/unscored. Its hits must come from real geometry contacts, not a button that increments a fake demo counter.
- Captured workshop is a next-round draft only. Do not pause the match, equip it early, reveal hidden opponents or consume it more than once. Last-round and living players cannot use it.
- Physical action remaps must update InputMap and hints, reject duplicate/reserved codes, release held actions on pause and preserve a fixed way out of menus. No gamepad support claim until tested.
- SafeStore writes only bounded user:// JSON, verifies normalized JSON digest, keeps the previous valid generation and never rotates corrupt primary data over a good backup. Digest is accidental-damage detection, not authentication or guaranteed power-loss durability. Legacy data stays read-only until explicit save.
- Settings writes are debounced; diagnostics default OFF and never upload. Test storage uses isolated user://quality_tests only.
- Main UI copy supports English/Korean via SystemFont; never bundle or share font files. Do not call partial localization exhaustive.
- Run static hygiene, test.sh, test_phase3.sh, test_phase4.py, test_quality.py and test_graphics.py. Require exit codes, expected markers AND no script errors. Keep behavioral assertions separate from bilingual-copy field checks in reports.
- Real captured screens are staged engine evidence, not human playthroughs. Software GL/Dummy audio/headless do not prove Windows GPU performance, audio quality, fun, accessibility usability or commercial art.
- Work on a feature branch and PR. No force-push, unrequested merge, visibility/license changes, secrets or engine caches.

## Graphics invariants
- GraphicsDirector owns presentation only. Never write authority transforms, clocks, scores, physics or drawings from it.
- Shared Art/weapon skin helpers affect Phase 4/5 visuals on this branch; their exact earlier snapshots remain in previous branches. Do not pretend their pixels are unchanged.
- Keep all three map fingerprints unchanged: obstacles, collision nodes, navigation cells, hideout IDs/positions and active bounds.
- Runtime weapon mesh polish is cosmetic: same original strokes, safe contours and contact samples. Fall back on ambiguous inset topology. Do not substitute pre-made weapons.
- Duplicate cosmetic view materials before changing shadow receiving. World weapon shadow flags and other players must remain independent. Hidden actor grounding planes inherit visibility and cannot expose hidden locations.
- Editor @tool dressing modules are authored placements with generated meshes, NOT LightmapGI/UV2/baked assets. Artistic contact planes are not physical GI.
- Report actual staged captures and measured tests. No inferred percentage similarity to concept art or FPS promise. Never bundle fonts, engine binaries, .godot caches or local save data.
