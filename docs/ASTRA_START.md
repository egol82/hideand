# Astra — Phase 15 handoff

Work from `phase15/manor-lighting-gi`. Read AGENTS.md, PHASE15.md and PHASE15_TEST_STATUS.md. Do not reimplement the game or merge earlier branches implicitly.

The default scene is scenes/phase15.tscn. Real native manor lightmaps are tracked under assets/lighting15 and loaded into the actual arena. B/C differ only in the actual LightmapGI resource; profiles A/B/C and material generation I/II remain separate controls.

Preserve the Phase13 connected skinned model, Phase14 shader, Phase12 proportional0.40 weapon display/lowered pose and contact correction, all hiding rules and map authority. Exclude randomized cabinets from fixed bake; preserve Build15.signature and exact manifest hashes. A changed fixed layout/pigment requires explicit rebuild/bake, not a fake success with stale data.

Run tools/test_lighting15.py --matches and all inherited tests. Use --capture with a display for real GI/probe pixels. Headless probe schema checks are not equivalent to lighting proof. Inspect room/empty-room/feet and isolated actual body/world/view-weapon probe pairs.

The original bake saved data but failed on editor shutdown; recovery validates those exact resources. Do not claim the entire original editor process was error-free. Read the final record before changing the bake tool. User source never bundles fonts, engine binaries, caches or saves.

The next planned stage is animation/IK, not automatic inclusion in Phase15. LightmapGI covers the static manor but not a dynamic rebake of shuffled cabinets or all-seven-map redesign. Keep contact supplements honest and hiding-safe.
