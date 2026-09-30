# Phase 16 — In-place skeletal animation and bounded hand/foot IK

New entry: `scenes/phase16.tscn`. Branch: `phase16/animation-ik`.

## Implemented

The Phase13 connected body and18-bone rig now have twelve project-authored native Animation clips: idle, walk, run, hide, peek, weapon_ready, windup, attack, hit, recover, ko and air. An AnimationPlayer samples the shared library in manual mode. Clips contain only bone rotation and pelvis-position tracks; no root motion, damage events, visibility or audio tracks. Blending between locomotion states lasts100ms. Existing gameplay still owns movement, attacks and elimination.

Actual displacement advances locomotion phase; holding a key against a wall does not itself advance the cycle. Walk/run arm and torso motion, crouched concealment/peek poses, three attack stages, contact-driven recoil, a short KO pose and restrained ear follow-through are implemented. Running is selected at actual dash/high speed; this does not introduce a new unlimited sprint ability.

AttackSpec determines windup/active/recovery directly. The first confirmed contact triggers the hit pose through the existing consume-event call, at the same zero-age onset as the retained particles/reaction layer. KO uses the existing short exit-echo lifecycle rather than delaying elimination or making a new ragdoll. Hide/peek poses never make the concealed full body visible; the authorized separate exposed-eye marker still owns detection.

## IK boundary

A two-bone analytic solver fits real skeletal arms to the current real drawn shaft. It handles parent rotation and clamps targets outside limb reach without scaling bones or moving the weapon. The primary grip stays near the selected original stroke. A long contiguous shaft can receive a second hand only when a reachable section exists; an unreachable support releases. Short/disconnected drawings are not enlarged or given a fake handle. This is bounded positional IK, not anatomical finger/contact simulation or a universal two-handed grasp.

Feet raycast the actual collision floor, use stance targets in world space, lift on the swing half, orient to acceptable floor normals and release while airborne, hit or in contextual transit. Large jumps/teleports clear the plant state. Both ramp-backed manor staircases are exercised by actual CharacterBody motion up and down. The visual foot target is not an extra physics collider and does not turn stairs into individual physical steps. Fine contact on arbitrary moving surfaces and perfect foot-slide elimination are not guaranteed.

The old reaction bridge runs first; the new pose owner replaces its bone poses, then adds bounded floor/hand IK and ear motion. Original body_root squash remains outside the authority hierarchy. Skeleton, face, GI receivers and existing foot-shadow nodes stay attached to the same body. Pause freezes final poses. Reduced motion suppresses new breathing/ear flourish while keeping gameplay-readable walk/attack motions. No extra forced camera motion or first-person hand redesign is introduced.

## Editable assets

Clips are generated once into a shared AnimationLibrary; actors have independent AnimationPlayers and pose state. The generator is `scripts/animation16/clips.gd`. Normal F5 needs no export, paid asset, plugin or network request.

For native editing, run:

```sh
godot --headless --path . --script res://tools/export_animation16.gd
```

This creates `assets/animation16/generated/toy_motion.tres` and `buddy_motion.scn`, then reloads the scene and verifies that playing WALK changes a real leg bone. Open that scene's AnimationPlayer16 in Godot. The exported scene previews clips; runtime IK requires the live game adapter and actual floor/weapon. Exported previews are supplied in validation artifacts rather than silently committed by a privileged workflow.

## Preserved

The Phase13 body/skin/bindings, Phase14 materials, Phase15 native lightmaps and manifest, Phase12 proportional0.40 lowered first-person weapon, contact correction, original drawings/hit samples, damage/timing/scoring, seven-map geometry, concealment clues and storage/remaps are unchanged. Old scene entries retain the old pose bridge. No renderer migration or animation-driven authority writes.

## Verification and boundaries

Run `python tools/test_animation16.py --matches`; add `--capture --video` with a display/Xvfb for actual renderer evidence. All inherited runners are retained. Reusing the original94 contact checks on Phase16 does not make94 new assertion definitions.

This is a working first animation/IK pass, not motion-captured or human-approved final commercial animation. Procedurally generated triangular skin topology still limits extreme shoulder/hip bends. Some hand penetration, limited support-hand reach and imperfect foot contact remain possible. No online play, Steam/EXE, hardware FPS or human comfort/balance review is claimed. See PHASE16_TEST_STATUS.md for measured results and rejected iterations.

Primary APIs checked against pinned Godot4.4 documentation:
- https://docs.godotengine.org/en/4.4/classes/class_skeleton3d.html
- https://docs.godotengine.org/en/4.4/classes/class_animationplayer.html
- https://docs.godotengine.org/en/4.4/classes/class_animation.html
