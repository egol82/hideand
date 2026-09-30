# Phase 17 — verified crafted manor environment

Verified 2026-09-30. Exact runtime/test/capture snapshot: `3473fb808ded0c5ab5a6c78a7d180537aa801c00`.
Main Windows/Linux workflow: https://github.com/egol82/hideand/actions/runs/36654648372
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36654695759
PR: https://github.com/egol82/hideand/pull/17

This final commit updates verification documentation only. It does not modify the verified geometry, runtime, existing GI assets or test predicates.

## Observed execution

| Environment | Actual result |
|---|---|
| Local official Godot 4.4.1.stable.official.49a5bc7b6 | 116 new assertions, 94 unchanged contact checks, actual default entry, sixteen native exports/reloads and fourteen complete matches passed; runner exit 0 |
| GitHub Windows headless / official Godot 4.4.1 | Original model/GI hashes, all new state/geometry checks, native export, fourteen matches and every inherited core/Python runner passed |
| GitHub Linux / official Godot 4.4.1 | Same checks plus fifteen actual same-light rendered images passed; both main workflow jobs completed/success |
| Separate historical workflow | Completed/success on Linux 4.4.1/4.7.2 and Windows headless 4.7.2. This is not a claim that the new environment assertions ran on 4.7.2 |

The local engine was restored from the retained tool archive and verified against its official SHA512 manifest. The remote installer also verifies the archive. Neither engine binaries nor fonts are delivered.

```text
ENVIRONMENT17_UNIT_RESULT: 116 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
ENVIRONMENT17_EXPORT_PASS: 16 native scenes saved and reloaded
ENVIRONMENT17_CAPTURE_PASS: 15
ENVIRONMENT17_SUITE_PASS
```

The shared controller's PHASE4_SMOKE_READY marker is intentional. Runners check process exit, completion markers, timeouts and script/shader errors together. The 116 new checks are individual assertions, not independent human-play scenarios or a quality score. Repeated execution of the existing 94 contact assertions is not counted twice. The inherited 3,089 headless-capable definitions plus 116 give 3,205 definitions; prior language/audio/seed fixtures remain included. Static source hygiene has 716 conditions and is separate.

## Actual environment implementation

Sixteen deterministic art recipes implement crowned/pressed cushions, piping, upholstered fronts, wood plinths, pulls, domestic props, fluted lamp shades, shaped curtains, original relief pictures and architectural panelling. Recipe geometry is cached and merged by material/pigment. The tested recipes use 3 to 12 mesh instances each; the sum of triangles across one copy of every distinct recipe is 166,080. That is not a measured frame cost or the triangle count of a whole played map. The new geometry helper built 28 distinct cached surfaces and the kit built 16 recipes during the suite.

Only the new scene adds Environment17. The original Phase16 game/animation adapter and Phase15/14 graphics stack are retained. Manor art has an independent session-local checkbox in the existing Graphics Comparison dialog. No new map, gameplay ability, light rig, audio or first-person model is introduced.

Fixed sofa/bed/counter refinements are probe-lit detail shells around retained original fixed cores. All 326 original baked UV2 users, native lightmap data, geometry signatures and original source hashes remain. New unrelated surfaces are NOT assigned old UV2 lightmaps or represented as freshly baked geometry. Fine fixed trim intentionally does not cast extra needle shadows; the original closed cores still supply the large shadows/indirect occlusion. Dynamic hiding-furniture replacements cast real direct-light shadows and receive probes. This preserves a working indirect solution but does not calculate new bounced occlusion for every added seam or cushion.

## What the new tests establish

- Finite vertex/normal/index data, bounded material batches, world-only layers and dynamic-GI settings for all sixteen recipes; no new collision objects in art.
- Twelve existing hiding sites use six stable art types while retaining their parents, collider, entry/exit/peek positions and original RoundParcel nodes. Art recipes never read occupancy or fake-site state.
- Scenery toggles preserve actual collider/transforms, original drawings and hit samples, character mesh/skin, camera, scores, HP, clock, map sites and gameplay RNG. Repeated toggles and steady frames do not regenerate geometry.
- Lighting and material options do not override the independent scenery checkbox. The fixed bake signature remains unchanged through these switches and three round seeds.
- Seeds 123, 8027 and 419 retain twelve crafted sites without accumulating previous copies. Each seed checks the twelve entry and twenty-four exit points for original capsule/floor clearance. This checks movement-space invariants, not every visible decorative triangle.
- An actual hide and second-exit call succeeds. The crafted art's mesh/material/transform/visibility is unchanged by occupancy; hidden body visibility remains suppressed. This is not exhaustive visual-cue fairness testing from every camera.
- All seven real map selections remain active as requested. New manor dressing does not appear on the six other maps.
- The unchanged contact suite passes all nine selected-contact first-render projection cases for quick/balanced/heavy at the existing sample intervals. Only a new scene selector was added; assertions were not removed or weakened.

All previous core and phase3 suites and Python phase4, quality, graphics, maps, grip, smash, sync, studio, hideplay, premium, character13, material14, lighting15 and animation16 suites passed in the main workflow. The Phase16 animation, Phase15 GI resources, Phase14 shader and Phase13 model/rig remain unchanged.

## Matches and actual images

Seven maps in FIELD and CLASSIC complete fourteen four-round matches. Downloaded Windows/Linux results equal the local run and the prior Phase16 fixed-seed results. This establishes regression behavior and completion, not human fun, balance or environmental readability.

Fifteen 1280x720 images show scenery OFF/ON at the same camera, actor state, materials and lighting: first-person, living room, sofa, windows, hiding furniture, kitchen and upstairs bedroom, plus the native options dialog. OFF restores the original art; it is a same-build baseline rather than a separately modified older executable. Empty-room fixtures hide whole participants and UI, not gameplay geometry. The final remote sofa/living-room images and comparison sheets were visually inspected after download.

Comparison sheets only arrange the original pixels with labels. There is no generated image, repaint, relighting, fake UI overlay or new video. Rendering uses Godot Compatibility under Xvfb/Mesa software OpenGL with Dummy audio; Windows validation is headless. These are staged automated captures, not manual play recordings or hardware FPS/VRAM tests.

## Native art and source verification

The optional export writes sixteen Godot .scn art scenes and reopens every one to check geometry and GI-receiver structure. They are available in the final Linux artifact and the separate editable-scenery delivery. Normal F5 constructs and shares the same recipes directly, so no export or download is required. Fixed furniture exports are detail shells that belong with their retained cores; they are not complete replacement colliders/lightmap scenes. Editing an optional export does not automatically change the source generator or live game.

Downloaded artifact SHA256 hashes matched GitHub:
- Windows: dbcfb1629016b4b7d11d11b707e1f7d3bccb686c47693227327edc571df5806a
- Linux: 8ed3cc8cb542d04a8105c081812feaa8c15bf0ed19f12f431d97242c517dfeb3

The archived source comment and marker identify 3473fb808ded0c5ab5a6c78a7d180537aa801c00 and contain 286 files. All twenty Phase17 changed paths match the tested local version byte-for-byte. Across the whole archive, the only working-tree difference is the already-finalized Phase16 verification document: the starting distributed Phase16 ZIP predates that docs-only update, while this branch correctly inherits it. No runtime/test/asset difference is unexplained.

All twelve original character/GI manifest entries and LICENSE bytes were checked. No engine/font binaries, .godot caches, private saves or raw video frames are bundled. The source ZIP remains the exact CI-verified runtime snapshot; this later verification document is available separately and on the branch. Main and earlier PRs remain unmerged.

## Rejected iterations and boundaries

An initial inferred-type parse error in the lathe helper was corrected before the successful run. Partial assertion output from the errored run was not counted. Dynamic cabinet shadow casting was explicitly retained and tested, unlike thin fixed trim. Initial importer/tool wait windows expired; a supervised import subsequently exited 0. An early 600-second local render wrapper timed out while its child continued and eventually produced fifteen images; that wrapper is NOT counted as a clean passing suite. The final capture waits for one process frame and RenderingServer.frame_post_draw per image, has a bounded 1800-second renderer budget, and completed cleanly in the published CI. The final evidence uses that successful exact snapshot, not the earlier timed-out run.

This milestone improves manor detailing rather than replacing every large structural silhouette or rebuilding all seven maps. Existing ceiling hotspots, coarse shadow boundaries, low-detail fixed cores, approximate indirect effects of new shells and occasional small decorative overlap remain art-review topics. Detail protrusions are not new physical surfaces. The original parcel nodes are retained, but all-angle silhouette/readability validation is not claimed.

There is no new full GI bake, dynamic cloth, interactable cup/book system, universal collision/visual matching, human art/accessibility/comfort/fun acceptance, hardware performance tier, multiplayer/Steam or shipping executable. Known inherited shader-UID fallback to a valid text path and software VSync/cleanup warnings are disclosed; actual new script/shader errors are not ignored. Repository license, visibility and existing branches were not changed, and no force push or main merge was performed.
