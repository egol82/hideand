# Astra — continue Phase 6

Repository egol82/hideand, branch `phase6/graphics-polish` (not the stale main branch).

Read AGENTS.md, README.md, docs/PHASE6.md and docs/PHASE6_TEST_STATUS.md. Open project.godot with Godot Standard. Default entry is scenes/phase6.tscn.

This branch adds a presentation component to the real Phase 5 controller. Do not replace it with a static image/web mockup, change the engine or replace user vector drawings with stock weapons.

First reproduce the existing tests and actual 1st-person/workshop render. Preserve original input/storage/score behavior, cosmetic/authority isolation, private hiding information, all map/nav/physics fingerprints and the user's LICENSE. Keep prior regression suites and add `python tools/test_graphics.py`; use --capture on a real display or Xvfb.

Art follow-up priorities:
1. Inspect actual mouse-driven movement and swinging on a target Windows GPU, including wide/concave drawings near walls. Current renders are staged software GL, not that test.
2. Use scenes/graphics/lounge_dressing.tscn as the editable art-placement starting point. Extend stable authored prop IDs rather than adding arbitrary objects in traversable lanes.
3. For baked indirect lighting, build a real UV2/mesh/bake pipeline and test dynamic probe lighting; it is NOT already implemented by Studio.environment or contact planes.
4. Refine custom hand gripping/animation without changing AttackSpec or actual reach. Current round mitten components are not full IK.
5. Expand the house art standard to warehouse/garden after a representative room is actually approved. Avoid photoreal textures or an unrelated black-sticker weapon style.

Work on a feature branch and PR, not force push or automatic merge. Record source SHA, exact engine version, exit status/completion markers, genuine captures and limits.
