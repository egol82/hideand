# Astra — Phase16 animation handoff

Use phase16/animation-ik and scenes/phase16.tscn. Read AGENTS.md, PHASE16.md and PHASE16_TEST_STATUS.md first.

The Phase13 mesh/18-bone rig, Phase14 shader and Phase15 baked GI remain unchanged. New native Animation clips affect bones only. One visual owner samples clips in manual mode from gameplay clocks, then applies IK and bounded secondary ears. Never reparent the weapon under a hand bone or feed root motion into the actor.

GripFit reads original shaft segments; support hands release when unreachable. Foot rays are cosmetic and world-planted during stance. Air/hidden/transit/reset must release stale plants. Pause freezes the final pose; reduced motion removes only new flourishes, not information or damage rules.

Run test_animation16.py --matches, all inherited runners and actual captures. Export editable native previews with tools/export_animation16.gd. Exported clips preview bone motion without live floor/weapon IK. No motion capture, universal anatomical grasp or perfect foot sliding claim.

Use existing shared contact event and AttackSpec for new motion work; do not add independent hit timers. Check actual attack/input and zero-age bone/effect onset. Preserve94 original sync assertions, not count reuse as new tests. Preserve original model and lightmap asset/source hashes, LICENSE and branches. No automatic main merge.
