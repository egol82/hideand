# Astra — continue Phase 4, do not restart the game

Use `phase4/production-feel`. Read `AGENTS.md`, `docs/PHASE4.md` and `docs/PHASE4_TEST_STATUS.md` before changes. Default is `scenes/phase4.tscn`; all older scenes are historical comparisons.

The user's production audit is the basis: absolute aim, capped escape rewards, classified contact feedback and comfort-independent clocks are mandatory. Keep the user's original drawing as geometry, Godot/GDScript and the existing LICENSE. No paid service, runtime AI call, analytics upload or Unity migration.

## First run

1. `python tools/verify_project.py`
2. Set `GODOT_BIN` to an official Godot Standard executable.
3. `bash tools/test.sh` and `bash tools/test_phase3.sh` (Windows .ps1 equivalents exist).
4. `python tools/test_phase4.py`
5. Open `project.godot`, F5; try SEEK FIRST and HIDE FIRST in FIELD and CLASSIC.
6. Render evidence using `python tools/test_phase4.py --skip-matches --capture` in a graphical environment; CI uses Xvfb/software OpenGL.

## Next effort

Human test first: draw an odd weapon, tune grip/handling, attack/miss/block/dodge, find a hidden friend, counterattack in-place and leave. Compare field and classic with actual participants before choosing a final rule. Prioritize authored hands/body animation, physically plausible contact, meaningful spatial sounds and one art-complete room rather than more maps.

The editor snapshot helper is only a starting point; UV2, baked lighting, IK and production-quality asset authoring are not complete. Online four-player play is not implemented. Do not imply otherwise from bot tests.

Report exact source SHA, engine/platform, commands, failures/warnings, authentic captures and remaining limits. Never turn off a test just to produce a passing report. Keep changes on a feature branch/PR without forced pushes or unsolicited merges.
