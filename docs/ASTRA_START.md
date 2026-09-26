# Astra — continue Phase 2, not a rewrite

Checkout `phase2/offline-match` (or main only after its PR is merged). Read AGENTS.md, README.md, PHASE2.md, TEST_STATUS.md and ART_BIBLE.md.

1. Read the actual current CI result and artifacts; do not rely on historical Phase 1 pending notes.
2. Open project.godot in Godot Standard and run the full test script. Keep both Phase 1 and Phase 2 tests.
3. Play manually as seeker first, then hider first. Verify real mouse drawing, equipped shape, hiding, inspection, reveal, attacks, capture/escape, scoring, restart, pause and local slots. The CI integration is scripted, not a human playtest.
4. Compare the same weapon in the canvas, 3D preview and combat. The shape must be recognizably the user's input, with shared toy material and lighting. Fix view/grip issues without replacing drawings with pre-made weapons.
5. Use real engine screenshots and a recording of a full match. Reference illustrations are not proof of rendering quality.
6. Tune five-second duels, escape grace and seeker pursuit. Record why a number changes. Add regression tests when fixing rules.
7. Keep LICENSE, engine and no-paid-runtime-service constraints. Use a separate branch and report commit/PR, tested OS/engine, commands, screenshots and remaining limits.

Useful commands:

```text
godot --path .
godot --path . res://scenes/main.tscn
godot --headless --path . --script res://tests/phase2/test_phase2.gd
godot --headless --path . --script res://tests/phase2/test_interactions.gd
godot --headless --fixed-fps 60 --quit-after 45000 --path . -- --autoplay-test
godot --path . --audio-driver Dummy -- --capture-phase2 --seed=8027
```

Headless autoplay controls all four characters as bots and logs PHASE2_AUTOPLAY_RESULT. The capture mode stages five real engine screens and exits; it is not the normal playable mode. Normal play is the first command with no special arguments.
