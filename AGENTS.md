# Hide & Smashing — implementation rules

Read README.md, docs/PHASE2.md, docs/TEST_STATUS.md and docs/ART_BIBLE.md first.

- Keep Godot Standard + GDScript and the user's LICENSE. No Unity migration, paid asset pack, runtime AI/network call, analytics, account or billing system.
- Phase 2 starts at scenes/phase2.tscn. Phase 1 remains at scenes/main.tscn; do not erase it to hide regressions.
- Canonical weapon data is the player's vector strokes. No arbitrary replacement with predefined meshes. Phase 2's simple-loop extrusion is bounded geometry, not semantic 3D reconstruction.
- Weapon, character and room share matte toy materials and lighting. Do not paste a black 2D scribble into a realistic world.
- Match state and scoring belong to phase2/match_rules.gd. Visual and AI code must not independently award points or change phase. Test all transitions, including tie KO and timeout.
- Hiders are truly hidden while in a prop. Never use their hidden position to aim the seeker bot. AI may inspect known locations and react to exposed clues/visible targets.
- Preserve input/file size/point/stroke/ink/finite-coordinate bounds. Save only to user://. Do not bundle secrets, fonts or .godot caches.
- Run tools/verify_project.py and tools/test.sh (or test.ps1). Inspect logs; a zero process exit without the expected test completion marker is NOT a pass.
- Regression tests include original weapon tests, Phase 2 rules/geometry/navigation, scripted mouse/E/pause interactions, scene smoke tests, and a full bot match.
- Actual CI screenshots are available as workflow artifacts. Generated concept art is not implementation evidence.
- Rendered captures use Dummy audio in CI, so they do not validate a real audio device. Windows headless checks do not prove a Windows release export or GPU rendering works.
- Work on a feature branch. Preserve unrelated user changes. Never force-push, change repository visibility or merge unreviewed work.
- Do not claim commercial visual quality, fun, multiplayer, frame rate or cross-platform shipping readiness without the corresponding evidence.
