# Phase19 — verified world finish, recovered without duplicate implementation

Verified runtime/test/capture commit: 6f6c1e10308625d54991d039213e94d80e3bf983.
PR: https://github.com/egol82/hideand/pull/19
Dedicated workflow: https://github.com/egol82/hideand/actions/runs/36700799133
Historical workflow: https://github.com/egol82/hideand/actions/runs/36700858421

The interrupted delivery was recovered from the successful dedicated Linux artifact. No Phase18-based duplicate implementation was made during this recovery. The exact source archive and its commit marker are preserved. This follow-up changes verification text only.

## Observed results and count correction

Both dedicated Windows/Linux jobs on official Godot4.4.1 completed successfully. The actual source and logs contain:
- WORLD19_UNIT_RESULT: 102 checks, 0 failures — the NEW Phase19 suite.
- SYNC_UNIT_RESULT: 94 checks, 0 failures — unchanged contact predicates reused against this entry.
- ANIMATION16_UNIT_RESULT: 144 checks, 0 failures and ANIMATION16_GROUND_RESULT: 18 checks, 0 failures — separate inherited motion/ground regressions, NOT new Phase19 tests.
- Fourteen matches (seven maps × FIELD/CLASSIC), each four rounds, completed.
- Other selected inherited hideplay/premium/material/lighting/environment/feel suites and the dedicated rendered comparison completed.
- Static hygiene:787 conditions; not an engine assertion count.

Earlier progress text described246 NEW local checks. No log establishing246 as a distinct new Phase19 suite was recovered. The final checked-in suite actually reports102 on both operating systems, and the current candidate document also says102. 102+144 happens to equal246, but that arithmetic alone does not prove the source of the earlier claim; nor would adding the inherited144 make246 new tests. The definitive final/new count is102. This is not a platform-specific count difference.

The separate historical workflow succeeded on Linux4.4.1/4.7.2 and Windows4.7.2. It does not mean the new102 World19 checks were run on4.7.2.

## Implementation and scope

The recovered code includes themed finish on the six non-manor maps, material/pigment/8m-cell MultiMesh batching and distance choices for small decorative trim only. Cover, hiding sites and collision remain present at every distance. Shared characters/materials/motion/feel18 are retained, and the original manor GI is not replaced. The six other maps use authored direct-light palettes, NOT newly baked lightmaps.

New ornament instances / spatial-material batches: Sugar232/66, Arcade261/108, Station306/56, House150/38, Warehouse352/78, Garden880/48. These describe added ornament batching, not whole-game FPS.

26 actual same-camera before/after and range comparisons plus renderer-count logs are in the successful artifact. Those controlled software-OpenGL counters establish batching behavior, not a hardware FPS/VRAM guarantee. No human fairness/art/comfort acceptance or all-map GI bake is claimed. These boundaries do not require a duplicate implementation before Phase20.

## Source provenance

Recovered Linux artifact11090237456 has SHA256 f0787474bbf9942d44f6594e5339aa034f20b28800c0043dcdb8e7e661b5ab9c14, matching GitHub metadata. The source ZIP comment identifies6f6c1e1. Windows artifact11090665265 belongs to the same commit; its completed job independently reports102/94 and fourteen matches.

The original102 local tests and26 renders preceded publication; this recovery reads their successful remote evidence rather than unnecessarily rerunning every historical suite before Phase20. Subsequent code changes need their own tests. The original over-bright preview and incomplete import attempt are not substituted for final evidence. Existing shader-UID path fallback/software VSync warnings remain possible.

No merge, production deployment, permission change, payment, engine/font distribution or credential request. Phase20 starts from this verified Phase19 source, not from Phase18.
