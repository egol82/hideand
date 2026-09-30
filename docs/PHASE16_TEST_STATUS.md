# Phase 16 — verified skeletal animation and bounded hand/foot IK

Verified 2026-09-30. Exact runtime/test/capture source: `20198603361a0063f661d443fdb523711ba867b3`.
New Windows/Linux workflow: https://github.com/egol82/hideand/actions/runs/36648406403
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36648410871
PR: https://github.com/egol82/hideand/pull/16

This final documentation update records observed verification only. It does not change runtime code, clips, IK, original assets or test predicates. The first implementation was868cb559; two subsequent commits correct inspection-floor/camera fixtures without changing gameplay.

## Observed execution

- Local official Godot4.4.1.stable.official.49a5bc7b6:144 new animation/IK checks,18 physical-ground checks,94 unchanged contact checks,default entry,native export/reload,fourteen four-round matches and final actual capture passed.
- GitHub Windows headless / official Godot4.4.1:exact model/GI source hashes,new checks,all fourteen matches and all inherited core/Python suites passed. No Windows GUI/GPU capture is implied.
- GitHub Linux / official Godot4.4.1:the same state/physics tests and inherited suites plus the final actual rendered poses,physical motion and contact footage passed.
- The separate historical workflow also completed successfully on Linux4.4.1/4.7.2 and Windows headless4.7.2. It does not establish that the new motion suite ran on4.7.2.

The local engine archive came from the already mounted prior tools package and matched its retained official SHA512 manifest before extraction. Remote installation also verifies the official checksum. No engine or font binaries are distributed.

```text
ANIMATION16_UNIT_RESULT: 144 checks, 0 failures
ANIMATION16_GROUND_RESULT: 18 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
ANIMATION16_EXPORT_PASS
ANIMATION16_CAPTURE_PASS: frames=165
ANIMATION16_SUITE_PASS
```

144+18 are162 new individual assertions, not independent human-play scenarios or quality ratings. The original94 contact assertions are reused unchanged except for one new scene-selection flag and are not counted twice. The inherited2,927 headless-capable definitions plus162 give3,089 definitions; earlier language/audio/seed cases are included. Static hygiene has689 conditions and is separate. Exit status,required markers,timeouts and script/shader-error logs are checked together.

## What the tests establish

- Twelve real native Animation clips with18 rotation tracks and one pelvis-position track each. Track paths address the existing Skeleton3D bones only,not the camera,physics root,weapon,visibility or damage functions. The cached library is shared; AnimationPlayers and poses are independent.
- Repeated pose evaluation at30/60/120 step intervals remains finite with unit bone scale. This is not measured rendering FPS. Resetting from KO verifies both the state label and the assigned AnimationPlayer clip.
- Analytic two-bone IK handles a rotated parent,clamps unreachable/degenerate requests and rejects nonfinite input. Original upper/lower limb lengths are retained. Reachable endpoints are checked independently of drawing preservation.
- Windup/active/recovery sample the original AttackSpec times for all three weapon handling types. A real mouse attack and original swept collision put the victim into zero-age HIT pose in the existing contact-consumption call,before render advancement. Original particle/reaction/view-contact assertions remain.
- Main/support grips use original drawing coordinates. A reachable long connected shaft uses two hands; an unreachable support releases without stretching the arm or adding a handle. Actual same-runtime supplementary inspection also confirmed two-hand mode during ordinary late heavy windup,not only an arbitrarily rotated test pivot.
- Foot rays hit the real collision floor. Both manor staircases are traversed up and down using actual CharacterBody.step motion. The test checks real slope traversal and repeated two-foot support,not teleporting actors between landings. A stationary world plant survives visual body bounce; airborne motion clears planted feet.
- No pose update changes capsule/velocity,original drawing/hit samples,weapon transform,HP,score,time or camera. Steady-state node counts remain fixed. Pause freezes final bones/clocks. Reduced motion suppresses new idle/ear flourish while essential walking/attack states remain readable.
- Actual hidden/peek states keep the body and face hidden. Their diagnostic pose photographs do not represent a newly visible hidden opponent. All seven real game entries retain the original18-bone rig and proportional0.40 first-person weapon.

## Native editing

The export tool saves a real AnimationLibrary `.tres` and an editable native rig `.scn`,reloads them,and verifies that WALK moves the original leg bone. The library has12 clips/228 bone tracks. Normal F5 generates and caches this same library once and does not require an export or download. The source generator remains authoritative; editing a preview copy does not automatically modify the runtime generator.

The native preview is supplied separately in the CI artifact and delivery package. It previews bone clips without the live game's actual floor/weapon IK. It does not include new character topology,paid motion assets,fonts or engine executables.

## Actual scenes and video

The final CI produces16 images:ten isolated clip poses,one actual manor view,two physical-locomotion inspection views and three actual-input contact views. The165-frame,H.264,1280x720,30fps silent video is5.5seconds. First2.5seconds use the original CharacterBody movement on an explicitly separate open test pad; last3seconds use mouse attack input and original collision for quick/balanced/heavy strikes in the existing practice room. This is staged automated evidence,not a manual player recording.

The ten isolated pose images omit live floor/weapon IK so the clip can be inspected. Hide/Peek full-body poses are visible only in this diagnostic studio. The gameplay concealment rules remain unchanged. Additional local grip inspection contributes two clearly separated screenshots and its harness/log; these are not mislabelled as CI output or included in the normal runtime.

Local and remote renders use Xvfb/Mesa software OpenGL and Dummy audio. The video has no soundtrack; neither it nor the headless checks prove speaker latency or hardware performance. Comparison/pose sheets only crop/arrange these actual pixels; they are not image-generated concepts or painted corrections.

## Gameplay and source provenance

FIELD/CLASSIC across seven maps completes14 matches of4 rounds. Downloaded Windows/Linux JSONs match the local final results and the prior Phase15 fixed-seed results. Headless autoplay can skip invisible pose updates,so it is regression evidence for game completion,not proof that all animations were watched; dedicated pose/IK checks and real renders exercise those separately.

Original first-person code,Phase13 body/rig/manifest,Phase14 shader,Phase15 lightmaps/generator manifest,manor geometry and LICENSE are unchanged. Existing contact assertions differ only by their scene-selection option. Source and asset hashes are checked independently of visual inspection.

Downloaded artifact SHA256:
- Windows:510169a81d1e8e06762409fce985ab0d9b70ca0b46d846b47317fd07c2145493
- Linux:ef60474d45e98497ce9591fdaa2c8ed7da7a16d6651a0ba699aa2f3cf7cfa3f5

The archived source comment and commit marker identify20198603361a0063f661d443fdb523711ba867b3. It contains273 files. All22 Phase16 changed paths match the local verified implementation byte-for-byte. Comparing every archived file to the original working tree finds only the already-finalized Phase15 verification document different because the starting distributed ZIP predates that documentation-only update; runtime,test and asset files match. The twelve original character/GI manifest entries also match. No fonts,engine executables,.godot cache,user save data or raw video frames are included. The source ZIP remains the exact verified snapshot; this subsequent final verification document is available separately and on the branch.

## Rejected iterations and boundaries

Two initial inferred-type parse errors were fixed before any passing run. A concurrent local test/render attempt ended without its required completion marker and was not counted as passing. The final tests yield between map replacements. A state-label/assigned-clip mismatch after reset was corrected and covered by a new regression.

An early locomotion camera was obscured by a room sign. The final inspection uses a separate explicit physics pad,waits for its collision to register and requires the actor to settle. The pad is removed before combat; the ordinary first-person camera is restored and the opponent's screen position is required to be in frame. Empty or misframed older captures are not substituted for final evidence. A prior map fixture called practice and reset to ToyHouse; the final unit fixture starts actual matches and asserts each selected map identity.

This is a functioning first animation/IK milestone,not motion capture,artist-approved final animation,anatomical fingers,universal hand grasp,perfect foot-slide removal or fully dynamic moving-platform IK. Short limbs and the original generated skin topology limit extreme bends; some intersections and imperfect contact can remain. Unreachable support hands intentionally release. Existing body squash and short KO echo are retained rather than replaced by a new ragdoll. No new forced camera motion or whole-first-person-hand rebuild is claimed.

No human fun/comfort/accessibility/visibility acceptance,hardware FPS/VRAM benchmark,real audio latency,network multiplayer,Steam or release executable is claimed. Known inherited shader-UID fallback to a valid path,cleanup and software VSync warnings may remain; actual new script errors are not ignored. Main and earlier PRs remain unmerged; license,visibility and permissions are unchanged.
