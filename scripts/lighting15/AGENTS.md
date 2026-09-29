# Phase15 live GI extension

Read docs/PHASE15.md and PHASE15_TEST_STATUS.md. Default scene: scenes/phase15.tscn.
- Actual baked data and exact user-path meshes must be inside the gameplay map, not only a lab.
- Bake only fixed geometry; seeded furniture/actors/weapons receive probes and live shadows.
- Never change collision/navigation, draw vectors, weapon scale/transforms, skeleton, score or clocks.
- Keep material-generation comparison, old lighting restoration, hidden visibility and camera layers.
- Required bake must exit successfully; node presence/UV2/export alone are not completed GI.
- Test actual probe pixels with all direct and ambient illumination disabled, and real static B/C pixels.
- Grounding patches are disclosed supplements, not SSAO; floor checks and hidden visibility apply.
- Work on feature branch/PR, no force push or main merge. Include generated GI assets, not engine/fonts/caches.
