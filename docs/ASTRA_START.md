# Astra — Phase 11 handoff

Continue on `phase11/hide-and-seek`. Read AGENTS.md, PHASE11.md and PHASE11_TEST_STATUS.md. Default scene: scenes/phase11.tscn. Do not rebuild the game from scratch.

- New seventh map is physically two-floor. Both ramp-backed stairs and graph paths must work; old six maps' geometry/assets remain.
- services.gd owns hiding exits, peek exposure, recorded decoys/traces, shared-cooldown seeker skills, short contextual transfers and coarse endgame clues.
- No exact hidden-player radar. Peek needs actual LOS/cone/range; maps are public-only. Sound snapshots preserve floor height and never chase an owner's new hidden position.
- Ambush is an ordinary queued attack after the shared FIELD reveal, not synthetic damage or time stop. Preserve cute paws, contact metadata/projection, AttackSpec, weapon samples/reach, HP/score/time.
- Don't describe the chute/private passage as free-physics crawling or the prototype art as production-complete. Bots currently use sound/inspection/limited relocation but do not plan every special passage.
- Run tools/test.sh, test_phase3.sh and Python runners phase4/quality/graphics/maps/grip/smash/sync/studio; run test_hideplay.py --matches and actual captures with --capture --video. Keep failing assertions, fix behavior or invalid fixtures explicitly.
- Extend tests for geometry and 30/60/120Hz presentation, options, resets, role restrictions, occupied exits and no clue leaks. Use real human sessions to judge fun and search balance.
- All old branches and LICENSE remain. Work on feature branches, no unrequested merge/force-push, no paid APIs/font binaries/engine caches/secrets. Report actual command/commit/log/capture rather than test count as a quality score.
