# Astra — Phase 10 Toy Studio handoff

Latest branch phase10/toy-studio; default scenes/phase10.tscn. Read AGENTS.md, docs/PHASE10.md and docs/PHASE10_TEST_STATUS.md. Continue existing implementation; do not restart the game or engine.

Preserve round paws, enlarged cosmetic weapon and confirmed-contact sync. A/B/C only changes presentation. Original vectors, damage, reach, weapon samples, maps, hiding, clocks, controls and saves remain intact.

The authored cake scene is scenes/art/sugar_island.scn; its generator is tools/build_studio_asset.gd. tools/export_studio_room.gd exports real UV2 ArrayMesh static geometry to assets/renderlab/generated/sugar_static.scn. This is an authoring scene, not an automatic replacement of active maps. Bake it in the editor; the optional --studio-bake plugin uses the real toolbar operation. Verify actual LightmapGIData before saying baked.

Run all prior suites and tools/test_studio.py --export --matches. Use --capture for same-camera A/B/C screenshots and --contacts for actual-input hit frames. Software rendering is not a hardware benchmark. Compare materials/visibility as well as CPU/GPU frame time on a real target PC.

No auto merge/force push/license change. Report exact tested source SHA, actual captures, failures and unfinished GI/gameplay integration honestly.
