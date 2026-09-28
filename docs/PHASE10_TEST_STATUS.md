# Phase 10 verification — local evidence, remote pending

2026-09-28. Official Godot 4.4.1.stable.official.49a5bc7b6 on Linux, archive checked against official SHA512 manifest.

Observed locally on the candidate code:
- STUDIO_UNIT_RESULT: 108 checks, 0 failures.
- Unchanged SYNC_UNIT_RESULT: 94 checks, 0 failures on the new scene. First-contact selected-sample projection remains below 0.1px in the nine original fixtures.
- Actual new entry emits PHASE4_SMOKE_READY.
- Static authoring export and reload: 421 ArrayMesh nodes, 242079 vertices with finite in-range UV2, 74 unique unwraps. No physics, no LightmapGIData yet. STUDIO_UV2_EXPORT_PASS and STUDIO_EXPORT_VERIFY_PASS.
- Eleven actual A/B/C stills and nine actual-contact stills plus180 sampled frames completed under software OpenGL with final STUDIO_SUITE_PASS. Their callbacks use real rendered geometry; contact fixture drives input/physics rather than injecting effects. Dummy audio is not sound audition.
- Initial overexposed material/lighting iterations were rejected. Repeated profile/map changes previously accumulated light state and duplicated Sky resources; baseline restoration and shared Sky resource handling were corrected, rerendered and checked without the earlier leaked-texture errors.
- An initial UV2 exporter called an ArrayMesh-only function on PrimitiveMesh and failed despite an optimistic marker. That run is rejected. The corrected complete exporter and reloader passed with no script errors; runners require both markers and clean error logs.

Original suite results, exact published SHA, remote Windows/Linux jobs, optional real editor bake status and source readback must be updated after observation. Do not treat the experimental bake's continue-on-error workflow setting as a passing bake result. Read its independent JSON/log and verify nonempty LightmapGIData.

These counts are assertions, not human gameplay scenarios or quality percentages. Human aesthetics/comfort/fairness, actual Windows graphics/audio performance and real-player multiplayer remain unverified.
