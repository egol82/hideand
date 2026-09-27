# Phase 6 — graphics polish

2026-09-27. Default entry: `scenes/phase6.tscn`. Base: Phase 5. This is a visual upgrade to the actual offline game, not a replacement concept image or a production-complete art claim.

## Scope

A `GraphicsDirector` child attaches to the existing controller. Gameplay, input remaps, storage, scoring, AttackSpec and navigation remain unchanged. Existing Phase 4/5 entries on this branch share the improved Art/weapon skin helpers, while the new scene adds the environment and dressing component. Earlier branch snapshots are preserved.

- Authored placement scene `scenes/graphics/lounge_dressing.tscn`: three framed windows with stylized sky, pleated curtains and ties, geometric framed artwork, two shaded lamps and stacked books. `@tool` modules rebuild their visible geometry in the editor. Positions are editable; this is not a fully baked asset pipeline.
- Representative house: wainscoting, trim, ceiling coffers, layered textile rug, upholstery seams and improved floor boards. Replaced obsolete flat window/lamp visuals without changing corresponding cover/physics. Warehouse receives the floor/material treatment; garden retains its terrain and layout.
- Related material families for foam, vinyl, painted wood, fabric, plaster and ceramic. Deterministic seamless 128x128 albedo/normal tiles with mipmaps; material and texture caches. No downloaded textures, runtime image API, font files or new asset licenses.
- Calibrated warm key and cool fill, procedural sky reflections, four-split directional shadows and small artistic grounding planes. These planes are an inexpensive visual helper, not SSAO or physically baked GI. Hidden actor grounding helpers inherit their actor's visibility and reveal no private location.
- Camera-hidden authority/view geometry is excluded from key shadow casting. Cosmetic hand/weapon clones disable shadow receiving to avoid detached-world-weapon shadow artefacts; world weapon materials remain separate and normally shadowed.
- Higher radial resolution in display tubes (12 versus 8 sides), safer rounded caps, bounded inset bevel on simple filled contours. If inset topology changes or collapses, fill falls back rather than changing the drawing. Original contours, reach, area budget, attack samples and grip are unchanged.
- Smoother shared character/hand meshes, rounded mitten silhouette, cloth cuffs, finger-pad/stitch accents. No full hand IK or new character animation library is claimed.
- Preview turntable receives matching lighting, a plinth and grounding. Panels/buttons keep the same layout, language and input behavior with soft borders and state-dependent elevation. Four-sample MSAA in the game and preview reduces edge stair-stepping.

## Safety and fairness

Visual dressing never creates a CollisionObject. Three-map fingerprints compare dimensions, active bounds, public hideout coordinates/IDs, obstacle data, every navigation-cell state and physics node count against the undressed controller. Maps must remain fully playable at the same scale. Added wall ornaments remain close to existing wall/prop surfaces. Cosmetic shadows, textures or view scale do not write HP, clocks, scoring, contact events or player drawing data.

Meshes/materials are regenerated from source; no screenshot is used as the game background. Previews and map replacements have instance/revision guards so repeated UI/map openings do not accumulate lights or furniture. Materials used only by the view copy are duplicated before changing shadow flags.

## Execution

Open `project.godot` with Godot Standard, F5, then Practice or Play. Phase 5's untimed workshop, captured-player next-round drawing, key remapping, language switching, save recovery and both encounter modes are retained.

```sh
python tools/verify_project.py
bash tools/test.sh
bash tools/test_phase3.sh
python tools/test_phase4.py
python tools/test_quality.py
python tools/test_graphics.py
# Linux real renderer; Xvfb is only necessary without a display:
xvfb-run -a python tools/test_graphics.py --capture
```

Set `GODOT_BIN` to the engine executable. `tests/graphics/capture.gd` produces seven staged real screenshots (EN menu/workshop/first-person/lounge/garden, KO menu/workshop), not a manual playthrough. The new entry still prints the shared controller's `PHASE4_SMOKE_READY` marker; do not invent a Phase 6 smoke marker.

## Explicitly unfinished

No LightmapGI bake, UV2 asset pipeline, real-time GI, full-body/hand IK, new networking, Steam export, hardware FPS benchmark or professionally auditioned audio is provided. This is still a stylized procedural prototype with improved art, not the earlier high-end generated concept rendered exactly. Software GL screenshots cannot verify Windows GPU performance. Visual inspection and source invariants reduce risk but do not prove exhaustive clipping/occlusion fairness for every camera or drawing.
