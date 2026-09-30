# Phase20 — three outdoor nature playgrounds

This milestone replaces the earlier proposed human-QA phase with the user's explicit outdoor-map request. It builds on the preserved, published Phase19 implementation6f6c1e1, not a Phase18 recreation. New default scenes/phase20.tscn uses the existing game and only selects an outdoor-aware graphics subclass.

## Playable maps (metres)

- Pine Hollow / 솔방울 숲,34x30: a great tree as a strong central occluder, offset logs/rocks, a ring around the trunk and a long quiet moss flank. Open crossing versus concealed circling.
- Reedwater Bend / 갈대 물굽이,40x32: two separate opaque reed islands with north/middle/south crossings forming a figure-eight. Noisy boardwalk stripes versus quiet outer banks. The water band is decorative shallow scenery, not swimming, falling damage or inaccessible islands requiring jumps.
- Amber Canyon / 노을 협곡,42x34: two offset tall mesas, S-shaped inner routes, wide outer sand detours and a high arch landmark. Rock pillars support visual line breaks; gravel routes are louder.

Each map has10 distinct contextual hiding sites and two capsule-clear exit choices. Existing seeded fake-site rules can temporarily seal2 sites. Homes are toy-styled forest caches,reed baskets and expedition caches; they are not freely walkable interiors. They use the existing hide/peek/search/decoy/trace/ambush and encounter handlers without new invulnerability or damage rules. Plans are fixed original layouts, not palette-swapped copies or random terrain generation.

## Collision and pathing

Every trunk/log/rock/reed-island core creates a matching opaque mesh and solid collider from the SAME plan dimensions plus a conservative0.46m navigation clearance. Four-neighbour navigation is unchanged. Full free-cell connectivity, hiding floor/exit checks, alternate loop paths after a corridor-cell closure, actual character traversal to a site and real input/contact are tested. All walking routes are single-level and require no jump. The high stone lintel is above reachable head height. Visible planted boundary walls contain the playfield; scenery outside is a backdrop, not a promised traversable mountain.

## Preserved art and performance boundary

Phase13 body,Phase14 materials,Phase15 manor lightmaps,Phase16 animation/IK,Phase17 scenery and Phase18 VFX/audio remain. Phase19 six-map finish and distance settings stay available. The new maps have authored direct daylight/ambient palettes, not freshly baked GI. Do not call them all-map GI completion.

Low grass/flowers and outside ridges use the existing mesh/material/8m-cell MultiMesh system. Only small non-cover accents use18m/28m/full culling. Trunks,canopies,rocks,reed cores,hiding containers and markers do not vanish with detail selection. Cover casts real shadows; little ornaments are not particle or rigid-body objects. No per-frame mesh regeneration is added.

The test budgets cap arena node count and require accent batch counts below instance counts. Captured-frame draw-call/primitive metrics are software-OpenGL observations, not a hardware FPS,VRAM or human visibility guarantee. New foliage does not read hidden occupancy. Existing model/GI manifest hashes must remain identical.

## Usage and targeted validation

F5 -> choose any of the three new bilingual map entries -> seeker or hider. Both FIELD and CLASSIC use the original encounter modes. The existing free-practice button still opens ToyHouse; the outdoor contact tests use explicitly isolated original practice physics on an outdoor arena without silently claiming the practice menu supports every map.

Run `GODOT_BIN=/path/to/godot python tools/test_outdoor20.py --matches`; `--capture` needs a display/Xvfb. Ten maps x two modes gives20 full matches. The old14 results are compared against recovered Phase19 evidence. Reused94 contact predicates stay unchanged; new map-specific hits are separate. Selected affected regressions:World19,Hideplay,Premium,Feel18. The successful historical Phase19 CI is reused as prior evidence, not endlessly rerun.

No merge/deploy/payment,new Cloud Codex,credentials,external paid art,engine/font binaries or personal saves. Remaining human fun,balance,art/visibility and actual-device performance QA are not reported as completed.

Primary API references: Godot4.4 MultiMesh and AStarGrid2D documentation. The implementation uses the retained4.4.1 engine and existing game conventions.
https://docs.godotengine.org/en/4.4/classes/class_multimesh.html
https://docs.godotengine.org/en/4.4/classes/class_astargrid2d.html
