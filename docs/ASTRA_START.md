# Phase21 final handoff — seeded natural rounds

Read PHASE21D.md and AGENTS.md first. Same scenes/phase21.tscn; stacked draft PR21 stays on Phase20.
Reuse the exact verified1cfdfd70 base. New seed21/game.gd hooks only round preparation/menu teardown.
Existing fake-home RNG, six natural interactions, original colliders and10maps remain. Only two
validated extra cover bundles are added per nature map in DRAW. Full runtime connectivity/occupancy
checks and deterministic versioned sockets are mandatory. Do not broaden into new maps or mechanics.
Run test_seed21.py --matches --regressions and capture-only; preserve unchanged old tests and explain
legitimate new path/match differences. Human/hardware acceptance is not established by CI.

# Current increment: Phase21C

Read PHASE21C.md first. Current draft PR21 base remains phase20/nature-playgrounds.
Canyon adds exposed1.35s travel with occupancy/knockback cancellation and eight bounded wind toys.
Wetland's listener expiry order is corrected with a failing-before/passing-after boundary fixture.
Run test_canyon21.py --matches --regressions; use --capture-only for real rendered evidence.
No full Phase21 completion or new seed variation. Preserve earlier files and read exact delivery/CI evidence.

# Phase20 handoff

Start from phase20/nature-playgrounds/scenes/phase20.tscn. Read PHASE20.md and PHASE20_TEST_STATUS.md. Prior Phase19 code6f6c1e1 and its successful CI were recovered; do not recreate earlier milestones.

Plans in scripts/outdoor20/plans.gd own the three new cover/hideout layouts. Builder creates matched cover/collision/nav. Only tiny accents use the retained World19 batch distance setting. Never cull real cover,hidden markers or rewrite collision for quality settings. Actual game controller,weapon/attack/IK and old maps remain.

Run targeted new-map and original contact tests,20 matches and affectedWorld19/Hideplay/Premium/Feel18 regressions. Compare old14 match results against verifiedPhase19,without counting prior successes as new local tests. Actual capture is required for visual claims. Follow no-merge/no-deploy/no-payment. Preserve original model/GI hashes and no font/engine/cache distribution.
