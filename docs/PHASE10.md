# Phase 10 — Toy Studio on Godot

2026-09-28. Base: phase9/followup-cute-grip-sync at 9e5b691. Branch: phase10/toy-studio. Default: scenes/phase10.tscn.

This is a working graphics/authoring layer on Godot, not a newly written engine. The user's production audit sections 5/6 require shared art rules, editable meshes/UV2, unchanged authority and real same-camera comparisons. Later explicit requests for simple round paws and a larger cosmetic weapon take precedence over the old audit's more anatomical hand suggestion.

## A / B / C comparison in the game

The new Graphics comparison button appears in the menu or during explicit pause. A restores the former art/material/light values; B uses new scene finishes with standard materials; C (default) uses a custom soft-toy shader. The choice is stored in bounded, separate user://toy_studio_v1.cfg; synthetic tests do not alter personal settings. No new gameplay keys are reserved.

Six families distinguish foam, vinyl, painted wood, fabric, plaster and ceramic. The shader preserves depth and world-light attenuation, with restrained value grading, filtered procedural detail and broad highlights. Ink/transparent effects are preserved. There is no displaced geometry, through-wall outline, see-through character highlight or artificial glow exposing a hider. View-only materials remain isolated from authoritative world-weapon materials and keep the prior shadow workaround.

The representative Sugar Market gains an editable saved cake-island PackedScene: rounded display pedestal, inset panels, plate, three cake tiers, piped icing and small strawberry forms. Existing counters receive inset trim and back walls receive fixed menu boards. The original island and all additions can be switched back to A. No collider, hiding approach, navigation cell, hearing region or gameplay obstacle is added/removed. The other maps keep their geometry and receive the shared material/light options only. This is not a rebuild of all six maps.

A calmer tile shader replaces strong floor lines in B/C Sugar Market. Warm key / modest fill and exposure are tuned as a group. Thin overhead decorative rods stop casting distracting needle shadows in B/C; actual furniture/character shadow rules remain. These authored lights are NOT baked indirect illumination.

The original camera transform, round paws, enlarged weapon, raw vector strokes, weapon mesh/scale, attack definitions and selected-contact correction are preserved. A/B/C do not shift contact timing. Populated exit-echo materials also use the same material family.

## Editable assets and real UV2 pipeline

- scenes/art/sugar_island.scn is a compressed native Godot PackedScene, editable in the editor, not a flattened screenshot or external proprietary asset.
- tools/build_studio_asset.gd regenerates that asset from scripts/renderlab/patisserie.gd and indexed rounded geometry.
- tools/export_studio_room.gd makes a separate complete static authoring snapshot. All visible non-cosmetic meshes become ArrayMesh with real UV2 via lightmap_unwrap. Shared geometry/basis pairs reuse unwrap results. It adds a LightmapGI node, static fill lamps and a review camera, but no player or collision body.
- Export destination: assets/renderlab/generated/sugar_static.scn. Generated outputs are ignored by Git; CI packages them separately. The source package does not claim that this static scene is already baked or loaded by the live game.
- The optional editor plugin responds only to --studio-bake. It invokes the actual editor Bake Lightmaps UI, handles its save dialog and requires populated LightmapGIData before reporting success. The bake experiment has its own report and can fail independently of working gameplay; consult PHASE10_TEST_STATUS.md and studio-bake.json.

Using Forward+ explicitly enables SSAO/modest glow in the live studio profile. Compatibility remains the default; unsupported effects are not claimed active. Forward+ and the editor lightmapper need their own device/driver checks. This update does not silently change the game's renderer or promise hardware performance.

## Tests and actual evidence

Run GODOT_BIN=/path/to/godot python tools/test_studio.py --export --matches.
Use --capture for the same-camera A/B/C screenshots; --contacts produces actual-input/real-collision render frames with the new graphics (no injected hit packets). The earlier 94 sync assertions can run unchanged against this entry with --studio. The renderer test uses Xvfb/Mesa and Dummy audio; not a human playthrough or a hardware/audio benchmark.

108 new studio assertions check source-material isolation, opaque/shadow-aware shader behavior, editable no-collider art, all six original map fingerprints, original-light restoration across repeated switches/maps, unchanged HP/score/clocks/transforms/drawing/contact samples, round paws/weapon scale, hiding visibility, UI lifetime and bounded typical resource counts. Export/load checks inspect every UV2 vertex separately from that assertion total.

## Boundaries

This remains stylized procedural prototype art, not a commercial-art completion claim. The static export is a production pipeline step, not automatic GI in the six live maps. A/B/C preserves geometry but no human testing has established equal perceptual visibility across all lighting profiles. Existing approximate weapon collision and extreme-drawing clipping remain. No multiplayer, Steam, shipping EXE, external paid asset, font file, engine binary or secret is introduced. Historical cleanup/software V-Sync warnings are not described as a warning-free engine. Earlier scripts stay on their branches; main/previous PRs are not merged.

Technical primary references checked 2026-09-28:
- https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/4.4/classes/class_arraymesh.html
- https://docs.godotengine.org/en/4.4/classes/class_lightmapgi.html
- https://docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html
The implementation is executed against Godot 4.4.1, not assumed compatible from newer documentation.
