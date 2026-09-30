# Hide & Smashing — Phase19 seven-map integration

Read docs/PHASE19.md, PHASE19_TEST_STATUS.md and ASTRA_START.md. Default scenes/phase19.tscn extends the verified Phase18 stack; previous scenes remain. Historical implementation boundaries are in PHASE13 through PHASE18.md and their test records.

## Preserve authority and existing assets
- No changes to collision, navigation, hideout identity/ports, movement, HP, score, clocks, saved drawings/controls or game RNG for a graphics change.
- Keep the original connected18-bone body/weights, Phase14 shader, Phase15 manor lightmaps/UV2/generator manifest, Phase16 animations/IK, Phase17 furnishings and Phase18 contact/audio behavior.
- Original user strokes/grip/hit samples and fixed0.40 proportional lowered round-paw view stay. AttackSpec and confirmed contact remain the only damage/action clock. No new forced camera motion, FOV, time scale or root motion.
- Hidden bodies, faces, grounding patches and trails must not leak occupancy. Public clues use original event snapshots. Preserve real stairs, hiding exits, peek LOS, role/charge-checked passages, practice and next-round-only workshop behavior.
- Preserve remaps and SafeStore valid backups. No telemetry, credentials, remote player saves or paid asset APIs.

## New decoration and lighting
- World19 owns ONLY new decorative pieces and authored direct-light profiles for six existing maps. The manor retains actual LightmapGI. Other-map direct light is not a GI rebake.
- Only tagged small ornament gets a distance limit. Existing structural cover, hiding models, clues, characters and original silhouettes NEVER enter cull batches. Recipes do not read occupied/fake/hidden state.
- Batch by cached mesh, immutable material/pigment and8m spatial cell. Keep finite transforms/full bounds. MultiMesh culls groups, not individual items. No per-frame batches, meshes, textures or PCM generation.
- Preserve independent material, lighting, scenery and smash comparison. Session-local art options are not verified hardware tiers. Cull hysteresis in Compatibility is not alpha fading.
- Fixed manor detail remains probe-lit shells over original baked cores. No unrelated model gets the old lightmap. Seeded furniture stays outside the static bake. Any future structural bake change must update native resources/provenance explicitly.
- Cosmetic IK does not move/stretch authoritative weapons or capsules. Contact supplements are artistic patches, not SSAO/ray tracing. Preserve pause/mute and reduced-motion behavior.

## Validation and publishing
- Compare all7 Phase18 collision/nav/hideout signatures against Phase19. Keep94 original contact predicates unchanged except new scene selection.
- Run tools/test_world19.py --matches, all inherited core and Python runners, and actual --capture separately. Check exits, required markers and no script/shader errors. Headless assertions and render counters are not hardware FPS or human playtesting.
- Keep actual source hashes, known warnings, rejected iterations and precise scope. No generated/retouched picture substitutes for runtime evidence.
- Publish feature branches and PRs only. No force push, unrequested merge/deployment, payments, credentials, fonts, engine binaries, .godot caches, personal saves or raw frame dumps in deliverables.
- Phase20 is now multiple outdoor natural maps per latest user instruction, not the earlier human-QA-only plan. Begin implementation after Phase19 code and PR are published/verified.
