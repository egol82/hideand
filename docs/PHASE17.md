# Phase 17 — Crafted manor environment

New entry: `scenes/phase17.tscn`. Branch: `phase17/crafted-manor`.

## Implemented scope

The representative manor is dressed in three scales, using the established toy palette/materials:
- Large/readable structure: sofa/bed upholstery and wood-frame detailing, kitchen/wardrobe/play/bath fronts, wall panelling and railing caps. Original fixed cores stay intact.
- Medium: crowned cushions, tilted accent pillows, book stacks, cups/basin/faucet, folded towels, toy blocks, fluted lamp shades, window drapes and framed original relief art.
- Small: piping/seams, recessed-panel relief, brass pulls, cuff-like curtain ties, plinths and feet.

Six dynamic hiding-furniture recipes replace only the old decorative mesh children at the twelve existing manor sites. Their parent, collider, entry/exit/peek positions, shuffled parcel and original hide/search controller remain. Recipes depend on stable site type only, never occupancy or fake-site state. The curtain uses actual shaped cloth geometry, not a moving transparency effect. This does not turn contextual hiding into a simulated cupboard interior.

The new Environment17 component uses the existing Phase16 game adapter and Phase15/14 graphics stack. Only the new scene activates it. Other six maps and previous entry scenes are not remodelled in this milestone. No new map, lighting rig, player motion, sound or HUD rewrite is introduced.

## GI and cover boundaries

Phase15's 326 fixed UV2 meshes, source signatures, lightmaps and probes remain byte-identical. New nested art is intentionally excluded from fixed-mesh discovery. Fixed sofa/bed/island detail shells are placed over the same old closed cores; they receive existing lightmap probes. They are NOT a new baked UV2 replacement. No old lightmap is falsely assigned to unrelated new geometry.

Fine fixed detail shells do not cast extra needle shadows. Original fixed cores still supply their original direct shadows and baked occlusion. Dynamic hide-furniture replacements keep real direct-shadow casting and receive probes, as the old unbaked furniture did. Small decorative relief/pillow changes are approximate with respect to the retained indirect solution. A future silhouette/structural change needs a real rebake. This preserves working GI rather than claiming new physically accurate light transport for every stitch.

No collider/nav/hearing/peek/exit/timing/RNG/weapon values are altered. Added structural relief hugs existing walls or is mounted on existing furniture, not loose blockers in walking lanes. Very small protrusions remain visual detail, not additional collision surfaces. Existing conservative colliders/contextual hiding limitations still apply.

## Production structure

`geometry.gd`: bounded cached curved pillow, piping, turned/fluted profile and drape meshes.
`kit.gd`: deterministic original art recipes, assembled then merged by material/pigment to reduce separate mesh instances. No source images, paid texture pack, fonts or online generation.
`director.gd`: attaches manor-only art after the existing graphics system; rebuilds site art on a real RoundFurniture identity change and prunes old references. No per-frame mesh creation.

The native graphics comparison dialog includes `Crafted scenery`. Toggle it to compare exactly the same camera, lights and gameplay with the old environment. Material and lighting switches are independent. The switch is session-local, not a benchmarked low/high hardware tier.

`tools/export_environment17.gd` writes sixteen editable native `.scn` art scenes and reopens each to verify its geometry/GI settings. Fixed furniture exports are DETAIL SHELLS for the old core, not complete standalone replacement collision/lightmap assets. Editing the optional export does not automatically overwrite the runtime generator. Normal F5 needs no export.

## Verification

Run `GODOT_BIN=/path/to/godot python tools/test_environment17.py --matches`; add `--capture` with a display/Xvfb. Required markers, process status and error logs are checked. Existing contact suite adds only a new scene selector. All older runners remain.

Tests examine finite normals/indices, bounded material batches, source/GI signatures, dynamic shadow flags, repeated toggles/maps/seeds, entry/exit clearance, concealment without occupied-box tells, original RoundParcel visibility and actual contact. Fourteen matches exercise all seven maps/two modes. Headless assertions are not a visual-quality score. Same-light paired actual screenshots and source readback are separately recorded in PHASE17_TEST_STATUS.md.

## Limits

This is focused manor modelling/detail, not all-map replacement or final commercial art approval. Original low-detail fixed cores, approximate baked indirect effects of small shells, existing camera/actor topology and contextual hide restrictions remain. There is no new whole-GI bake, moving cloth, interactable books, hardware FPS claim, manual four-player session, online/Steam or shipping EXE. Do not describe automatic screenshots as human playtest evidence.

Technical references consulted: Godot4.4 SurfaceTool/ArrayMesh (clockwise faces and vertex attributes) and GeometryInstance3D GI modes. Implementation is run in pinned4.4.1 rather than assuming newer APIs.
https://docs.godotengine.org/en/4.4/classes/class_surfacetool.html
https://docs.godotengine.org/en/4.4/classes/class_geometryinstance3d.html
