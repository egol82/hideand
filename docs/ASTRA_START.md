# Astra — Phase14 handoff

Latest `phase14/material-shaders`, default `scenes/phase14.tscn`. Read AGENTS.md, PHASE14.md and PHASE14_TEST_STATUS.md.

This milestone changes material response, not model/rig/animation or liveGI. It retains the exact Phase13 weighted body, Phase12 proportional0.40 lowered view and contact alignment, seven maps and hide/search rules.

New recipes are in scripts/material14/materials.gd. The C profile has Materials I/II comparison with identical light/model states. Microdetail is optional. No source material is mutated; camera/world instances are independent. The material director must refresh newly equipped world weapons using their real revisions, not rebuild every frame or wait for the user to toggle a profile.

Run all inherited runners plus test_material14.py --matches. Use --capture under a display/Xvfb for actualGL pixel tests and comparison screens. The existing94 contact assertions are reused by --material14, not counted as new tests. Keep depth/shadow and no-light/no-emission tests.

Do not add rim emission, displacement, hidden-player outlines or material-driven attack changes to hide visual shortcomings. TrueGI, final skeletal animation/IK, human fairness/comfort and hardware performance are later work. Report exact SHA and remaining limitations. Preserve LICENSE and previous branches; no force-push or unrequested merge.
