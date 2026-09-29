# Phase 13 — Connected skinned toy character

2026-09-29. New entry: `scenes/phase13.tscn`, branch `phase13/skinned-character`.

## Implemented scope

Phase 13 is a character-model/rig milestone. It does not silently include the proposed future shader/GI/full-animation stages.

- A project-authored implicit surface blends the head, torso, shoulders, arms, round paws, pelvis, legs, feet and ears into **one connected indexed body**. This is not disconnected primitives merged into one draw call. The generated body has 10,024 vertices and 20,044 triangles; topology tests require a single connected closed two-manifold surface and consistent winding.
- A real `Skeleton3D` with 18 named bones, `Skin` rest bindings and up to four weighted influences per vertex. MeshInstance3D explicitly references the skeleton. Arm changes deform vertices, rather than merely moving separate arm objects. The body mesh is shared across actors; each actor has independent bindings/poses.
- Face features are small separate meshes attached to the head bone: eyes, glints, cheeks, nose, mouth and ear insets. Existing blinking, squint/spiral expression and KO overlays remain. A tiny chest marking follows the spine. “One body” does not mean that eyes and every decorative detail share the body surface.
- Default neutral pose, restrained idle motion, A-pose inspection and a right-arm ready-pose fit to the existing grip point. Left/right BoneAttachment3D sockets are available for later work. The right-arm fit has bounded reach, does not own/move the weapon and is NOT a complete hand/body IK system or full animation library.
- Existing body/foot/arm reaction controls are empty compatibility nodes. Their existing visual movement is mapped to bones; the original actor code and authoritative hierarchy are unchanged. The original large first-person round paws remain as the separate first-person viewmodel requested previously.
- All four world participants, actual workshop previews and short KO echoes use the same model. Hidden body, face, sockets and shadows inherit the existing visibility/layer logic. The local camera never sees its own head/body.

## Art and asset pipeline

`mesh_builder.gd` uses a bounded deterministic field, marching tetrahedra, analytic-gradient normals, edge reuse and position welding. It contains no random-state or paid/external asset dependency. Offline building takes the same generator used by the cached fallback. Surface coordinates are simple procedural-material coordinates, not a production hand-painted texture atlas or new lightmap unwrap.

`tools/build_character13.gd` saves:
- `assets/character13/buddy_body.res`: native weighted ArrayMesh.
- `assets/character13/buddy_rig.scn`: editable standalone rest skeleton, skin, sockets and attached face, without runtime game-controller scripts.

Open the native rig in Godot to inspect bones and pose them; the runtime Avatar adapter supplies the current game's controls. The source generator remains authoritative for regeneration. Authored assets are included on the feature branch by the branch-scoped asset job. Engine binaries, font files, caches and player saves are never included.

## Safety boundaries

Physics capsules, collision masks, old seven-map geometry/navigation, hearing/peek/exit/search rules, original drawings, handgrips, weapon mesh/scale/samples/reach, AttackSpec, damage, clocks, score, UI callbacks and persistence remain unchanged. The new skeleton is below `body_art` and never above FacingRoot or weapon_pivot. No bone can move the authoritative weapon. The first-person 0.40 scale, lowered position and contact correction remain.

The new scene adapter installs new art only; previous entries keep their previous model. No project-wide avatar factory override or engine change is used. Existing tests are retained. Only a scene selector is added to the existing contact suite so its identical 94 assertions can exercise Phase13.

## Implementation limitations

This is an actual skinned, smooth toy mesh, not a final human-reviewed commercial character. The surface is generated triangle topology, not manually retopologized deformation loops. Extreme shoulder/hip bends, whole-body IK, ground-aware foot placement, fully animated crawling/hiding and every arbitrary drawn-handle grip need the later animation stage. Basic locomotion/reaction compatibility is retained, not described as a new polished motion library. The ready pose follows an existing point; it is not guaranteed finger contact for every weapon contour.

No new material/GI polish, performance rating, hardware FPS/audio-latency test, network/Steam/release EXE or human fun/comfort review is claimed. Headless autoplay can skip invisible pose updates; captures and unit pose tests exercise actual skin/rig separately. The existing rendering/cleanup warnings are not hidden.

## Verify

`GODOT_BIN=/path/to/godot python tools/test_character13.py --matches`
With a display or Xvfb: `python tools/test_character13.py --capture`.
Keep the old core, first-person, phase4, quality, graphics, maps, grip, smash, sync, studio, hideplay and premium runners. See `PHASE13_TEST_STATUS.md` for observed results, failures and exact source SHA.

## Primary technical references consulted

- https://docs.godotengine.org/en/4.4/classes/class_skeleton3d.html
- https://docs.godotengine.org/en/4.4/classes/class_surfacetool.html
- https://docs.godotengine.org/en/4.4/classes/class_boneattachment3d.html

APIs are validated in Godot4.4.1, not inferred from newer documentation. LICENSE and existing branches remain; no unrequested main merge or force-push.
