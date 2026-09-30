# Phase17 crafted environment rules

Read PHASE17.md and PHASE17_TEST_STATUS.md first. New entry scenes/phase17.tscn only adds Environment17 to the existing Phase16 game/Phase15 graphics stack.
- Keep the old326 static bake users, native assets and original generator hashes. New fixed furniture art is a probe-lit detail shell over old fixed cores, not a rebaked substitute. Never claim unrelated geometry uses the original UV2 lightmap.
- Dynamic home replacements inherit the same parent/collider/ports and cast real direct shadows. Preserve RoundParcel and Grounding15, exclude clue/visibility/occupancy state from art recipes.
- Keep new small geometry in authored furniture/wall envelopes, not in walking lanes or peek exits. Test capsule/floor clearance, unchanged nav and actual hiding/exit handlers.
- Cache and material-batch recipes. Rebuild only on arena/furnishings identity changes, release stale references, preserve independent lighting/material/scenery toggles.
- Exported native scenes are optional art inspection outputs; normal F5 needs no export. Fixed shell exports need their old cores; manual edits do not silently replace the runtime generator.
- Preserve all character/GI/weapon/animation invariants below. Add environment tests and real same-light captures; do not replace actual source/engine verification with generated images.
- No unrequested main merge, external assets, fonts, engines, caches, private saves, secrets or paid services.

# Hide & Smashing — Phase16 animation and IK

Read docs/PHASE16.md, PHASE16_TEST_STATUS.md and ASTRA_START.md. Default scenes/phase16.tscn opts into the new pose adapter. Previous scene entries remain; read PHASE13/14/15 docs before changing their assets.

## Authority and preservation
- Bone animation is cosmetic only. Never reparent/scale/move weapon_pivot, FacingRoot or colliders from animation. No root motion, damage/method tracks or independent hit timers.
- AttackSpec elapsed and the confirmed contact/reaction age own action timing. HIT is sampled in the consume-event call. KO follows the existing short echo lifecycle, never delaying elimination.
- Preserve original connected18-bone body/weights/native manifests, Phase14 shader, Phase15 lightmap/UV2/data hashes, fixed0.40 proportional lowered view weapons, original vectors/grips/hit samples and contact alignment.
- Keep seven-map physics/navigation/hiding fingerprints, actual stairs, public-only clues/atlas and hidden body/face/shadow logic. Pose changes cannot reveal a hidden body or add free ambush damage.
- Preserve score, damage, clocks, input remaps, bounded SafeStore backups, untimed practice and next-round-only captured workshop. No telemetry, paid assets/APIs, hidden remote persistence or new gameplay RNG use.

## Motion implementation
- Native clips target Skeleton3D bones only. The library is cached once; AnimationPlayers and poses are independent. One final pose owner follows the old compatibility bridge.
- Positional IK clamps unreachable hands without limb scaling. Support hand must use an actual connected drawn shaft; release if it cannot reach. Do not add an invented handle or claim universal anatomical grip.
- Ground rays and stance targets never move physics. Clear plants for air, concealment/transit, teleport/reset. Pause freezes final bones; reduced motion suppresses extra breathing/ears without changing rules or readable attack states.
- Keep scene nodes/materials/mesh resources bounded when previews and ghosts change. Exported native editor previews are optional; normal F5 generates clips once and needs no bake/export.
- Do not change lightmap source assets for animation. Lighting B/C still use identical direct lights/environment and differ in actual baked data. Contact supplements remain artistic patches, not SSAO/ray tracing.

## Verification and delivery
- Run test_animation16.py --matches plus every existing core/phase3/phase4/quality/graphics/maps/grip/smash/sync/studio/hideplay/premium/character13/material14/lighting15 runner. Preserve94 original contact assertions unchanged except scene selector, and do not count reuse as new definitions.
- Verify actual floor movement on both stair directions, finite bounded bones, original authority, native clip export/reload, pause/reset and real contact onset. Headless matches may skip invisible pose updates; render/state checks separately exercise them.
- Distinguish studio-pose inspection, open collision test pad and live-map gameplay captures. No generated imagery or retouched screenshots as implementation proof. Require exit codes, completion markers, bounded timeouts and clean script/shader-error logs.
- Record rejected iterations, exact commits and source/asset hashes. Staged renders are not human playtests, all-drawing contact guarantees, commercial art approval or hardware FPS/audio benchmarks.
- Preserve LICENSE, repository permissions and old branches; feature branch/PR only. No force push or unrequested main merge. Never include fonts, engines, .godot caches, raw frame dumps, secrets or player saves.
