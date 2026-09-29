# Hide & Smashing — Phase14 material/shader rules

Read README.md, docs/PHASE14.md, docs/PHASE14_TEST_STATUS.md and docs/ASTRA_START.md. Default entry scenes/phase14.tscn uses the Phase13 character controller with a material-only ToyStudio override. Read historical scope/invariants in PHASE13.md, PHASE12.md, PHASE11.md and CUTE_SYNC.md before changing those systems.

## Material authority boundary
- Preserve the exact connected body/18-bone skeleton/Skin, first-person round paws, fixed0.40 drawing multiplier, lowered view and selected-contact correction. Do not alter meshes, vertex positions, weights, collision samples or cameras from shader code.
- Material generation I/II comparison must use the same light/model states. Keep historical shaders and A/B/C restoration. Sources are immutable; separate view/world/body/fill material cache entries.
- No ALPHA/EMISSION, vertex displacement, disabled depth, enemy outlines, screen-reading hacks or global-time motion in the new surface shader. World ATTENUATION and local-light falloff remain; only view-only directional shadows use the existing exception.
- Refresh newly equipped WORLD weapons by actual revision/instance changes. Do not rebuild materials/meshes/tiles each steady frame. Mipmapped deterministic data tiles have a bounded five-key cache and must not consume gameplay RNG.
- Microdetail OFF changes fine surface shading only, not information, input, damage, score, clocks or geometry. This option is not a measured hardware performance tier.
- TrueGI, new topology and full IK/animation are not part of this milestone. Do not describe artistic lit-side wrap as physically accurate SSS.

## Preserve gameplay and prior assets
- Skeleton and face stay below cosmetic body_art, never above FacingRoot or weapon_pivot. Bodies may deform; authoritative weapons/capsules may not. Preserve source drawings, grips, reach/area/ink limits, AttackSpec, contact identity and original damage/time/score rules.
- Keep all seven maps, actual two-way stairs, public map data, hidden-body/face/shadow logic, peek range/cone/LOS, capsule-clear exit checks and sound-event snapshots. No live hidden-player radar, fake free ambush damage or decorative clue leaks.
- Contextual passages remain role/charge/destination checked, not arbitrary teleports or extra invulnerability. Pause freezes rule/service timers. Endgame hints remain broad explicit information.
- Practice is untimed/unscored and uses actual collision. Captured workshop is next-round only, without equipping early, pausing others or revealing hidden players.
- Keep native UI callbacks, saved physical remaps/conflict handling and a fixed escape from menus. SafeStore retains valid backups and bounded local data; no secret/remote saves or telemetry upload.
- Native Phase13 models and Phase10 island remain tracked project assets with generator/manifest provenance. No paid assets/APIs, competitor art, engine/font binaries, caches, raw frame dumps, secrets or user saves in deliverables.

## Validation and delivery
- Run all inherited core/phase3 and Python phase4,quality,graphics,maps,grip,smash,sync,studio,hideplay,premium,character13 runners. Add test_material14.py --matches and actualGL --capture checks. Require exit status, completion markers, timeouts and clean script/shader-error logs together.
- Reused94 contact assertions are not new definitions. Pixel fixtures check no-light darkness, opaque occlusion and real shadow response, not every map/GPU/human perception.
- Real staged engine images are not generated art or human playthroughs. Distinguish headless, softwareGL and actual WindowsGPU evidence. Report known warnings, artistic limitations and untested comfort/fairness/performance honestly.
- Work in a feature branch and PR. Preserve user edits, LICENSE, repository visibility and earlier branches. No force-push, unrequested merge or permission changes.
