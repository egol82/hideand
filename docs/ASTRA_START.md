# Astra handoff — Phase 3

Continue `phase3/first-person-maps`, built on the unmerged Phase 2 branch. Do not recreate the game or discard existing work.

1. Read AGENTS.md, README.md, docs/PHASE3.md and docs/TEST_STATUS.md.
2. Import project.godot in Godot Standard. Default scene: scenes/phase3.tscn. Keep scenes/main.tscn and scenes/phase2.tscn runnable.
3. Run tools/verify_project.py, tools/test.sh and tools/test_phase3.sh; Windows equivalents are test.ps1 and test_phase3.ps1. Require completion markers and inspect error logs.
4. Actually play both seeker and hider on all three maps. Inspect focused E interactions, wall/behind-camera discovery rejection, pause/cursor recapture, captured-player spectating, original-drawing geometry and world hit registration.
5. Preserve original vector drawing, bounded data, toy materials, custom weapon library and no paid/runtime AI dependencies.
6. Tune first-person hands, world/view weapon alignment, animation/comfort and large-map pacing using real rendered screens and actual playtests. The camera view model is cosmetic, not a replacement for authoritative world weapon geometry.
7. The minimap must never reveal other player or hidden occupant coordinates. Bots may use public geometry, not hidden occupancy or unseen positions to aim/search.
8. Do not claim a polished commercial FPS, multiplayer, complete Windows shipping, manual input QA or performance from headless tests alone.
9. Make a feature branch and a PR. Preserve LICENSE and unrelated changes; do not force-push or merge without user review.

First-person controls: WASD, mouse look, LMB swing, Shift dash, E focused hide/inspect, C taunt, M map, Esc pause/settings, F11/F12. No jump/crouch/firearms are implemented.
