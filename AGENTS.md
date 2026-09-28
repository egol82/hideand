# Hide & Smashing — Phase 11 hide/search rules

Read README.md, docs/PHASE11.md, docs/PHASE11_TEST_STATUS.md and docs/ASTRA_START.md. Historical graphics/weapon evidence remains in PHASE10.md, CUTE_SYNC.md and their test-status documents.

## Authority and scope
- Default entry scenes/phase11.tscn uses scripts/hideplay/game.gd as an explicit adapter. Keep all historical entry scenes/controllers and six old map geometries. The seventh manor is allowed new two-floor geometry and 3D navigation by the user's explicit request.
- Godot Standard/GDScript and original drawn vectors stay. No paid APIs/assets, runtime AI replacement, telemetry upload, credentials or engine migration.
- Preserve LICENSE and user edits. Feature branch/PR only; no force push, unrequested merge or permission/visibility changes.
- FacingRoot is rotation-only; body squash/peek art/materials never change weapon shape, original grip, samples, reach, HP, score or clocks. AttackSpec and contact identity remain shared. Keep the user's simple round paws, enlarged cosmetic weapon and selected-contact alignment.
- Practice remains untimed/unscored with real geometry hits. Captured workshop is a next-round draft only; no early equip, pause of other players, hidden-position reveal or repeated consumption.

## Hiding/search
- Entry and chosen exits require real capsule/floor clearance. Occupied exits fail safely; no forced overlaps. Tiny camera slits are contextual concealment, not simulated furniture interiors.
- Peeking needs exposure delay, actual hunter distance/cone/LOS. Hidden players must not be revealed by unexposed eyes, nameplates, hands, shadows or cached render state. Maps receive static public layout and local position only.
- Clues are stored world events. Never substitute current hidden-target coordinates for old sounds/decoys/tracks. Preserve floor height. Explicit late-game hints reveal a broad zone only, twice per round, not an occupied cabinet.
- Normal inspection is cancellable; instant loud inspection has a real information/noise tradeoff and shared cooldown. Ambush queues one ordinary post-reveal attack and adds no guaranteed damage, invulnerability or global pause.
- Passage/chute endpoints are authored, role/charge/phase checked and destination-clear. They are short contextual transitions, not free-physics crawling. Ordinary stairs require actual CharacterBody motion both ways.
- Keep clue, trail, eye and decoy pools bounded. Reset on menu/round/practice; pause must freeze their clocks. Graphics/audio/comfort settings must not change information or damage rules.
- New bots may act on recorded noises but cannot read living hidden-player positions to shortcut search. Do not claim tactical mastery from fixed-seed match completion.
- Existing saved physical remaps and hints stay; avoid extra-key conflicts and retain a fixed menu escape. No gamepad-complete claim.

## Graphics and assets
- Keep ToyStudio/GraphicsDirector, A/B/C profile restoration, immutable original materials, separate view/world materials and no hidden-actor contact-plane leaks.
- The six original maps retain collision, navigation, hearing surfaces and stable hiding IDs. Manor visuals and conservative blockers come from the same authored plan.
- Original weapon forms remain, with safe fallback for ambiguous contours. No stock weapon substitutions, hidden shaft additions, authority scale changes or full-swing perfection claims from one selected-sample test.
- New manor lights are authored fill, not baked GI. The Phase10 UV2/exported bake is separate; do not claim it is integrated into live maps. Any optional editor bake needs its own result and populated LightmapGIData, not a continue-on-error green badge.
- Do not ship fonts, engine binaries, .godot caches, raw frame dumps, credentials or user saves. The previously authored sugar_island.scn is intentional project content.

## Storage and validation
- SafeStore writes bounded user:// JSON and preserves the last valid backup. A digest is damage detection, not authentication or power-loss durability. Legacy save data remains read-only until explicit save. Settings are debounced; diagnostics stay opt-in/local.
- Keep test.sh, test_phase3.sh and Python runners phase4/quality/graphics/maps/grip/smash/sync/studio. Add test_hideplay.py --matches and real render checks. Require process status, completion markers, timeout bounds and clean script-error logs together.
- Check both physical stairs up/down, seeded graph connectivity and all entry/exit clearances; all seven maps and both modes must finish. Test peeking behind walls, old remaps, occupied exits, sound snapshots, cooldowns, ordinary vs quick inspection and no free ambush damage.
- Existing sync assertions are reused via a scene-selection flag, not rewritten/weakened. Record exact commit, commands, results and source readback.
- Staged captures and bot runs are not human playtests or hardware/audio benchmarks. Counts include repeated seed/shape/copy tests and are not quality scores. Report contextual passages, limited shuffle, prototype art, bot limitations and soft-pressure hints honestly.
