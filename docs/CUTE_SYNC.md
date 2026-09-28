# Cute grip / big weapon / contact synchronization follow-up

2026-09-28. Branch `phase9/followup-cute-grip-sync`, default scene `scenes/phase9_followup.tscn`, based on Phase 9 commit `7e226e3`.

## Implemented, not an image overlay

- The protagonist now has a round mitten-like paw and tiny thumb pad instead of four anatomical finger loops. Wrists/sleeves use the existing real-grip fitting. Short shafts support the wrist, long shafts use the real second contact. No fake shaft is added.
- The resting first-person weapon is enlarged: its nominal displayed radial extent moves from the old 0.44m cap toward 0.68m, with bounded scales 0.32–0.46. These are camera-model units, not increased physical range or an exact percentage of character height. Original world weapon, strokes, samples, damage and balance are unchanged.
- The display uses the actual weapon orientation/path through attack phases, plus a safe near-camera anchor. A confirmed hit supplies its original drawing sample and sweep transform as presentation metadata. On the first shown contact frame, that sample is projected onto the actual contact's screen point. A 55ms visual correction blends out; camera input, simulation and attack timers do not freeze.
- The impact observer primes existing pooled particle transforms, labels and body pose with age zero at contact. No next-frame contact queue is used. Audio remains triggered by that same confirmed event; device/audio-driver latency is not measured or guaranteed.
- The new reaction begins with visible compression immediately instead of starting from an unchanged body. The original common-timeline spring/eyes/exit echo continue afterward.

## Why the previous unverified patch was not uploaded verbatim

It queued a contact until a render update and could read an eliminated actor after reset; that risks a missing response or an echo at a new position. This version preserves the original public contact snapshot and consumes it immediately. It also uses a simpler truly round paw rather than merely fattening the four old fingers. The original draft ZIP is not the tested deliverable.

## Safety boundaries

New behavior is opt-in via the follow-up scene. Earlier Phase 8/9 scenes retain their earlier grip/reaction choice. The shared contact resolver adds metadata only: contact acceptance, wall predicates, damage, reach, clocks, movement, score, map geometry, storage, controls and LICENSE are unchanged. The rig only reads the weapon authority transform. No global time-scale or camera shake is used to disguise mismatches.

Original test assertions are retained. The existing smash regression script gains a scene-selection flag so the same 100 assertions can also run against this new scene without copying or weakening them. New tests exercise actual input, collision and first-render contact projection at 30/60/120 physics-step intervals across three attack types; these are not hardware refresh-rate benchmarks.

## Run

Open project.godot and F5. For tests use `GODOT_BIN=/path/to/godot python tools/test_sync.py --matches`; for actual render evidence add `--capture --video` under a display or Xvfb. The renderer fixture drives actual mouse input and the practice physics/contact path inside three map scenes. It does not inject a hit or manually hide a finisher, but remains automated staging, not human play footage.

## Limits

Only the selected contact sample is screen-aligned on the first displayed hit frame, not every vertex over the whole swing. Arbitrary broad/curved/off-centre drawings can still occlude the view or intersect the mitten; this is not full hand/arm IK or a redesign of approximate collision. The enlarged weapon is cosmetic, not hidden extra attack range. An off-camera contact is not forced into view. Comfort settings still change only presentation. Stills/video use software OpenGL and Dummy audio; no actual Windows GPU/FPS, human feel/comfort or speaker latency certification is claimed. Prior ObjectDB/driver V-Sync warnings remain.

Technical APIs checked: Godot Camera3D.unproject_position and Transform3D affine transforms. The projection assertion is checked numerically in the engine, not inferred from concept art.
https://docs.godotengine.org/en/stable/classes/class_camera3d.html
https://docs.godotengine.org/en/stable/classes/class_transform3d.html
