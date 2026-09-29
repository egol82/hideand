# Phase 15 — live manor lighting and LightmapGI

The new `scenes/phase15.tscn` entry retains the Phase13 avatar, Phase14 materials, proportional
lowered weapons, UI, original collision, hiding, scoring and contact timing. It extends the existing
ToyStudio rather than replacing gameplay.

## Implementation

- Fixed manor shell, stairs and fixed furniture: 326 matching UV2 meshes are baked. The live map
  instantiates these exact meshes and resolves LightmapGI user paths on them. Original visible
  copies are disabled, NOT their independent physics bodies.
- The source generator validates geometry/material signatures. Seeded RoundFurniture is not in
  the bake, so a shuffled cabinet does not leave its old baked shadow behind.
- LightmapGI bakes indirect lighting with three bounces. All seven authored local lights use
  BAKE_DYNAMIC, so direct light and dynamic shadows remain real-time in both B and C.
- Warm interior window portal spots and soft ceiling practicals replace the manor's flat global fills.
  The legacy window panes are sealed geometry: portal lights represent incoming window light;
  this does not claim physical sunlight passing through a hole in the original collision/visual wall.
- 254 manual probe positions plus automatic sparse probes cover both floors. Live skinned bodies,
  original world weapons, actual camera-held weapons and shuffled furniture use GI_MODE_DYNAMIC.
- Contact grounding combines real-time shadows/baked occlusion with optional subtle paired foot
  patches. Foot patches follow actual floor-ray results and fade when feet rise. They are artistic
  contact supplements, NOT SSAO or physically traced contact shadows. Parent visibility/layers
  suppress them for hidden/local-camera actors. All cabinet patches are identical regardless of occupancy.
- Lighting A restores the older lighting; B is the new direct-light setup; C adds the real baked data.
  B/C share the same direct light and environment. Material I/II, A/B/C material profiles and contact
  support remain separately selectable. No lighting preference is advertised as a performance tier.

## Scope

The representative lower living room is the visual review target. To close light paths and support
real stairs/probes, fixed geometry of both floors is baked. The six other maps keep their original
lighting/geometry. The scenery topology, collider shapes and hiding ports are not redesigned.
The fixed source signature is insensitive to sub-0.1mm platform float differences; source manifest
hashes additionally guard asset/generator provenance.

## Build and verify

`tools/build_lighting15.gd` builds the UV2 source.
The explicit editor flag `--bake-manor15` invokes the actual Bake Lightmaps action via
`addons/manor_bake15`; ordinary games never run the editor tool. The workflow requires successful
exit, populated GI data and clean script/shader error logs. A green continue-on-error bake is NOT used.
`tools/test_lighting15.py --matches` checks integration and all seven maps in both modes.
`--capture` also renders B/C comparison, empty-room/feet views, and isolates dynamic body,
world-weapon and camera-weapon probe pixels with direct and ambient lights disabled.
Read PHASE15_TEST_STATUS.md for the actual observed execution, not assumptions from node existence.

## Limits

No universal human visibility/fun/comfort or hardware GPU/FPS acceptance is inferred from tests.
Probe interpolation is approximate; dynamic actors do not become new bounced-light emitters.
Cabinet direct shadows move with cabinets but they do not rewrite the fixed indirect bake.
The sealed-window portal representation, existing low-detail furniture and character topology remain.
No material V3, full animation/IK, multiplayer, Steam integration or release EXE is part of this step.

Technical basis: Godot4.4 LightmapGI/LightmapProbe/GeometryInstance3D documentation; these APIs
are tested in Godot4.4.1. All assets are project-generated and LICENSE remains unchanged.
https://docs.godotengine.org/en/4.4/classes/class_lightmapgi.html
https://docs.godotengine.org/en/4.4/classes/class_lightmapprobe.html
