# Phase 8 — actual first-person grip polish

2026-09-28. Default scene: `scenes/phase8.tscn`, branch `phase8/viewmodel-polish`.

## What was implemented

The approved image edits were visual references, not game assets or proof of implementation. This update replaces the detached two-mitten layout in the shared Phase 4 first-person renderer with actual procedural 3D gripping hands. It keeps the Phase 7 maps and every game rule.

- Four rounded swept fingers and an opposing curved thumb around the existing drawn shaft, a wider palm, tapered wrists, separate cream fabric sleeves and ribbed cuffs.
- `grip_fit.gd` reads the original drawing near its selected grip. Only contiguous almost-collinear intervals count as usable shaft; distant disconnected strokes cannot justify a floating support hand.
- A sufficiently long real shaft uses two shaft grips. Short shafts use a main grip with the other hand supporting the wrist. Very short local runs use a compact pinch-like grip. This is geometric fitting, NOT semantic reconstruction or a universal anatomical IK solver.
- Hands stay attached to their solved contacts during shared AttackSpec windup/active/recovery. Sleeves bridge the actual wrist sockets to two distinct lower-screen forearm anchors. Meshes are created only on equip/revision changes, not per rendered frame.
- Palette, world lighting and the existing material family stay. Cosmetic mesh materials remain isolated and do not receive shadows from the detached authoritative weapon. Cuff shape/material contrast is not a new physically baked contact-shadow solution.
- Key hints move to the upper-right under the score on the new entry; health stays lower-left. This is a presentation component, not a gameplay/UI controller rewrite.

## Preserved invariants

The original weapon vectors, selected grip, world mesh, collision samples, reach, damage, timing, score, movement, map navigation, storage and input bindings are unchanged. No artificial shaft is added and no weapon is replaced with a stock model. No paid assets/APIs, remote services, font files or engine binaries are introduced.

`first_person.gd` is a shared helper, so Phase 4–7 entries on this branch also use the improved hands. Their exact historical snapshots remain in the earlier branches. Only Phase 8 attaches the new HUD-clearance component. Phase 1–3 source and LICENSE remain untouched.

## Files

- `scripts/viewmodel/grip_fit.gd`: bounded, read-only geometric fitting.
- `scripts/viewmodel/hand_mesh.gd`: smooth finger/arm meshes and cosmetic materials.
- `scripts/viewmodel/grip_rig.gd`: contact-anchored hands and connected wrists/sleeves.
- `scripts/viewmodel/hud_clearance.gd`: keep key hints away from gripping arms.
- `scripts/phase4/first_person.gd`: integrates the grip without changing authority.
- `tests/viewmodel/`: actual engine invariants and staged captures.
- `tools/test_grip.py`: logs, required markers, exit/error/timeout checks and optional renders.

## Verification and limits

Run `GODOT_BIN=/path/to/godot python tools/test_grip.py`. Add `--capture` under a real display or Xvfb for rendered evidence. Preserve the original test runners listed in AGENTS.md. Read PHASE8_TEST_STATUS.md for observed results.

The new tests cover eight drawings, empty input, three attack types at 30/60/120 step intervals, original shape/samples/unit scale, hidden-hand visibility, six maps, material isolation, unchanged clocks and stable scene-node/rebuild counts. These are assertions and synthetic engine interactions, not manual comfort or anatomical reviews.

Known limits: stylized multi-part hands, not a fully skinned hand/body IK system. Some extreme self-crossing, wide, tiny or off-centre drawings can still intersect fingers. Short handles intentionally brace the wrist instead of inventing a second shaft. The existing cosmetic weapon scale and limited wall probes remain. Real-world GPU performance, human mouse feel, sound, fun, online/Steam and shipping EXE are not validated by this work.

Geometry API references: Godot SurfaceTool and Basis documentation. The implementation is tested in the engine rather than assuming the newest documentation is compatible.
- https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/surfacetool.html
- https://docs.godotengine.org/en/stable/classes/class_basis.html
