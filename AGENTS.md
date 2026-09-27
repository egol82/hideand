# Hide & Smashing — Phase 4 implementation rules

Read README.md, docs/PHASE4.md, docs/PHASE4_TEST_STATUS.md and docs/ASTRA_START.md first.

- Default scene is scenes/phase4.tscn. Preserve older scene/source snapshots; do not relabel historical code as fixed.
- Godot Standard + GDScript, original user-drawn vector geometry and the user's LICENSE stay. No Unity, paid packs/APIs, runtime AI/network calls, remote analytics or secret credentials.
- Phase 4 owns absolute fighter transforms and one AttackSpec for both view/authority. No cumulative pitch adjustment. Cosmetic scale and comfort options cannot change reach, HP, score or clocks.
- Contact events carry attack ID, attacker, target, world point, normal, surface and outcome. Incoming/outgoing/blocked/miss feedback must stay distinct.
- Score/state changes belong to phase4/match_rules.gd. Escape awards are capped per round, never-found survival is meaningful, resolution is idempotent.
- Field encounter stays in place; unrelated surviving actors remain active; no forced camera takeover. Classic centre duel remains a labelled comparison. No parallel unbounded encounters.
- Hide positions are not private oracle input for seeker AI. Only public sites, visibility and actual emitted clues may drive search. Maps show no opponent coordinates.
- Preserve file/coordinate/point/stroke/ink/area/reach/mesh budgets. Save only user://. Do not silently replace or fill ambiguous drawings.
- Bound effects, voices and diagnostic history. Local diagnostics are opt-in and contain no drawings, account IDs or addresses.
- Run static checks, original test.sh/test_phase3.sh and new python tools/test_phase4.py. Windows equivalents for the originals are available. Process exit AND completion markers AND error logs are required.
- A scripted render is implementation evidence, not human playtesting. Dummy audio/headless/software OpenGL cannot prove real audio, Windows GPU performance, commercial art, fun or online readiness.
- Exported editable room snapshots are not baked LightmapGI/UV2. Keep representative-room authoring as follow-up, not a completed checkbox.
- Work on feature branches. Preserve unrelated user changes, LICENSE and visibility. No force push or unrequested merge. No font files or engine cache in deliverables.
