# Phase 18 — contact-locked smash effects, sound and restrained view response

Entry `scenes/phase18.tscn`, branch `phase18/smash-polish`. This is an opt-in extension over the actual Phase17 game, with its original animation/IK, manor GI and scenery.

## Implemented scope

The original confirmed contact pipeline remains: attack input -> original swept collision -> immutable contact fact -> effects/audio/reaction -> Phase16 bone pose. No new hit timer, damage, root motion, global time scale or hit-stop is introduced. The original 94 selected-contact assertions are reused without changing their predicates.

- Short directional foam chips and stars use the contact normal, a compact ring and a soft three/four-lobe puff. Labels are smaller and shorter-lived than the old version. Blocked attacks use a sparse cool ring/dry chips; misses do not create impact bursts. There is no new light, camera flash or screen-wide effect.
- Short trails sample the visible weapon's actual movement only during its active attack interval. They are not replacement weapon geometry. The local subject uses the displayed weapon; others use their actual world weapon. Trails stop on contact and clear when an actor is hidden, after invalid movement, and on reset. All geometry remains depth-tested. Thin trails are intentionally subtle and are not a physical air/fluid simulation.
- Victim reaction still uses the existing reaction age. A small directional settling movement and restrained dizzy stars refine the existing squash and Phase16 hit pose. No extra stun or knockback is added. Quick hits stop displaying dizzy stars earlier than heavy/finishing hits.
- Camera yaw, pitch, transform and FOV are untouched. A small hand-only recovery offset starts after the original contact-alignment latch; the initial hit frame is never moved away from its actual contact. The original round paws, fixed0.40 proportional drawing scale and lowered idle pose remain.

## Sound

Project-authored deterministic PCM recipes combine a felt transient, low body thump and a short elastic tail into ONE waveform per impact. Quick/balanced/heavy/finish/blocked each have three variants. Swings have separate three-variant waveforms whose energy envelope peaks near that handling type's existing active interval. The original swing event handler still emits one sound and retains footsteps/hearing/metrics; its played waveform is temporarily substituted, not accompanied by another duplicate swoosh.

Hit sounds use the existing six positional voices, bounded volume and an optional prefiltered quieter variant when an actual camera-to-event floor/wall ray is obstructed. This is a one-ray audio approximation, not physical acoustics. Voices stay at the recorded contact point, never a hidden opponent's future position. It does not change the AI's sound-clue rules. Master mute and pause reach already active impact voices. Hiding a Node3D alone is not relied upon to stop audio. No global audio-bus settings or external samples are modified.

39 small cached PCM resources cover the eight recipe names and supported muffled variants. They use an independent seeded RandomNumberGenerator, not game RNG. No per-frame audio generation or unbounded scene allocation.

## Comparison and bounded resources

Menu/pause -> Graphics comparison -> **Smash polish** toggles the new recipes and view response, returning to the old effect/audio paths when disabled. The new switch shares the existing scenery row without increasing window height. This is a session-local art comparison, not a saved performance tier. Material, lighting and scenery selections remain independent.

Retained impact pool:96 particles and6 labels. Additions:24 puff instances and48 short trail segments. Six impact AudioStreamPlayer3D voices remain. Nodes are reused. Reduced-motion or zero feedback strength removes animated additions; damage and sound-clue authority do not depend on that preference.

## Verification and media

`GODOT_BIN=/path/to/godot python tools/test_feel18.py --matches` runs state/audio/contact tests, the unchanged94 sync assertions, default entry and14 actual four-round matches. `--capture --video` under a display/Xvfb renders real before/after/contact/miss/room/options views and six automated attacks.

`tools/mix_feel18_preview.py` produces a clearly labelled **offline mono preview mix** from the same exported PCM and the capture's recorded event timestamps. The media pipeline can mux this into the real engine video. This is not a recording of the audio device, spatial renderer, reverb or actual output latency. The live game itself uses normal positional AudioStreamPlayer3D playback.

## Preserved and limitations

No changes to original weapon vectors/grips/samples/reach/damage, collider or map geometry, score/clocks, animation clips or bones, model/GI manifests, shader materials, hide/search/peek/exit/decoy rules, saving or remapping. The old entry scenes still use the original effects. No copied game assets, fonts, engine binaries, personal saves or online services are included.

This is a functioning polish pass, not final human-reviewed sound/animation/art or a hardware performance certification. Small particles may cross decorative surfaces; their depth test is not particle collision simulation. Extremely large drawings may still obscure the view while attacking. No new rig topology, GI rebake, foot IK redesign, live multiplayer, Steam or shipping EXE. See PHASE18_TEST_STATUS.md for exact observed results and rejected attempts.

Primary API references checked against pinned Godot4.4:
- https://docs.godotengine.org/en/4.4/classes/class_audiostreamplayer3d.html
- https://docs.godotengine.org/en/4.4/classes/class_multimesh.html
