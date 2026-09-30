# Phase 19 — consistent world finish across all seven maps

Default scene: scenes/phase19.tscn. Branch: phase19/world-finish. Reconstructed from the latest Phase18 branch after the prior Phase19 ZIP proved to contain status records only. The attached Phase18 runtime archive reconstructs exactly Git tree6b5cd191335c556a406e9903654af4a3d2624ae1 (a709d498); the remote parent is07fcaff6798c40a34f5a8c9b319feadfcf074148 with its later documentation preserved.

## Runtime implementation

The existing connected character, Phase14 materials, Phase16 animations/IK, Phase18 effects and first-person system already run on all seven maps. This milestone keeps that common stack and adds six bespoke finish recipes rather than copying the manor furniture into every setting:

- Sugar Market: painted cabinet relief, brass pulls, stitched counter edge and small plated pastries.
- Starlight Arcade: restrained cabinet bezel/speaker details, marquee studs and toy prizes; no flashing hidden-player tell.
- Pocket Station: carriage banding, rivets/window joinery and planter flowers.
- Toy House: low wall relief, original lounge cushion stitching and table books.
- Warehouse: parcel hardware, small shipping panels, deterministic barcode-like relief and shelf accents.
- Garden: hedge-top flowers and painted planter joinery, preserving all existing cover.

The old geometry, conservative collision, navigation and hiding sites remain. Added trim is decoration, not new interaction/collision. Nothing reads occupancy or player positions to generate art. The manor's native LightmapGI, UV2 source signatures and crafted furnishings remain unchanged; other six maps use separately authored direct-light presets through the existing material stack, NOT newly baked GI.

## Optimization and options

The new pieces use shared meshes/materials and MultiMesh batches separated into8m spatial cells. A batch has a full union AABB. It is not a whole-map all-or-nothing mega-batch. Regular finite parts are grouped rather than allocating one MeshInstance3D for every tiny rivet/petal. Only new small ornament uses optional0m(unlimited),18m or28m cutoff. Larger relief stays at unlimited range. Existing cover, hides, bodies and clue geometry is never distance culled by this component. Compatibility uses a hysteresis cutoff, not a promised smooth alpha fade.

Menu/pause -> Art settings -> Maps opens themed finish, direct lighting and small-detail range controls. They are session-local art choices, not measured hardware tiers. Batches rebuild only when the actual arena changes; material refresh follows profile/generation/microdetail changes. No per-frame geometry generation.

The before/after fixture compares complete Phase19 finish/direct lighting to the prior appearance. A separate full/near pair keeps all else equal for rendering-counter inspection. Draw calls and primitive counts describe that staged software-GL frame, not guaranteed faster FPS on every GPU.

## Tests and boundaries

`GODOT_BIN=/path/to/godot python tools/test_world19.py --matches` checks integration, all old-map signatures, deterministic decoration, exact small-detail targeting, materials, original18-bone bodies/proportional weapons and14 matches. `--capture` adds26 actual same-camera images with render counters. Original94 sync assertions are reused without weakening.

The original silhouette/core models, dynamic probe approximation for new decoration, imperfect shadow edges, large-drawing visibility and all prior user-experience limitations remain. No all-map GI bake, new gameplay rules, multiplayer, release executable or human art/performance acceptance is claimed. No paid assets, fonts or engine binaries are included.

Primary API basis: Godot4.4 GeometryInstance3D visibility ranges and MultiMesh. Individual instances cannot be independently frustum-culled inside a MultiMesh; spatial groups limit that tradeoff.
https://docs.godotengine.org/en/4.4/classes/class_geometryinstance3d.html
https://docs.godotengine.org/en/4.4/tutorials/performance/using_multimesh.html
