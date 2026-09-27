# Hide & Smashing — implementation rules

Read README.md, docs/PHASE3.md, docs/TEST_STATUS.md and docs/ART_BIBLE.md first.

- Keep Godot Standard + GDScript and the user's LICENSE. No Unity migration, paid asset pack, runtime AI/network call, analytics, account or billing system.
- Phase 3 starts at scenes/phase3.tscn. Phase 2 remains at scenes/phase2.tscn. Phase 1 remains at scenes/main.tscn; do not erase it to hide regressions.
- Canonical weapon data is the player's vector strokes. No arbitrary replacement with predefined meshes. Phase 2's simple-loop extrusion is bounded geometry, not semantic 3D reconstruction.
- Weapon, character and room share matte toy materials and lighting. Do not paste a black 2D scribble into a realistic world.
- Match state and scoring belong to phase2/match_rules.gd. Visual and AI code must not independently award points or change phase. Test all transitions, including tie KO and timeout.
- Hiders are truly hidden while in a prop. Never use their hidden position to aim the seeker bot. AI may inspect known locations and react to exposed clues/visible targets.
- Preserve input/file size/point/stroke/ink/finite-coordinate bounds. Save only to user://. Do not bundle secrets, fonts or .godot caches.
- Run tools/verify_project.py, tools/test.sh and tools/test_phase3.sh (or their .ps1 equivalents). Inspect logs; a zero process exit without the expected test completion marker is NOT a pass.
- Regression tests include original weapon tests, Phase 2 rules/geometry/navigation, scripted mouse/E/pause interactions, scene smoke tests, and a full bot match.
- Actual CI screenshots are available as workflow artifacts. Generated concept art is not implementation evidence.
- Rendered captures use Dummy audio in CI, so they do not validate a real audio device. Windows headless checks do not prove a Windows release export or GPU rendering works.
- Work on a feature branch. Preserve unrelated user changes. Never force-push, change repository visibility or merge unreviewed work.
- Do not claim commercial visual quality, fun, multiplayer, frame rate or cross-platform shipping readiness without the corresponding evidence.

## Phase 3 invariants
- First-person camera follows a real player or explicitly labelled spectator subject. Exclude only that body/nameplate from the view, not physics or other actors.
- Camera display geometry is a cosmetic copy of the original drawn weapon. Never derive hit reach from its presentation scale; preserve world hit tests.
- Human discovery/interactions must use the view cone/nearby focus and wall occlusion. No automatic detection behind the camera.
- Map IDs/dimensions/timers are whitelisted, blocker/nav geometry stay paired, and hiding-point capsule clearance must pass on all three maps.
- Static map overlays may show own position and public hideout sites only. Never expose hidden occupants.
- Headless autoplay may skip invisible presentation, not the physics/rules/AI being tested.
