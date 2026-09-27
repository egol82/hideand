# Astra — continue Phase 5

Work on `phase5/playability-and-recovery`. Read AGENTS.md, docs/PHASE5.md and docs/PHASE5_TEST_STATUS.md. Default entry is scenes/phase5.tscn using the improved Phase 4 controllers and standalone scripts/quality components. Do not restart the game or add an extra inheritance layer just to increment a phase number.

## Verify first
1. Set GODOT_BIN to an official Godot Standard executable.
2. Run tools/verify_project.py, test.sh, test_phase3.sh, test_phase4.py and test_quality.py (Windows .ps1 equivalents for the two shell scripts).
3. In a graphics session run test_quality.py --capture; inspect the actual screenshots and warnings.
4. Manually try both languages, default and rebound keys, untimed practice, field/classic, captured next-round drawing, and return to title.
5. Save two versions of a toy in a test slot, damage a copied test primary, and verify backup recovery with a clear warning. Do not damage a player's real files to test.

## Invariants
Original drawings remain vectors and actual geometry. Body cosmetics never scale authority weapons. Presentation and locale cannot change rules. Practice has no score/time limit. Captured drawing cannot affect current play and must survive round-end/menus without losing the last valid draft. Normalized JSON digest and semantic validation must agree after a JSON number round-trip.

## Next priorities
Human input/audio/FPS testing, proper sculpted/rigged hands and contact alignment, lighting authoring (UV2/baked GI is NOT complete), real four-PC networking, release export, remaining world-message localization and full controller/menu accessibility. Do not claim these from automated engine tests.

Publish exact source SHA, platform/engine, passed and failed commands, genuine screenshots and explicit unfinished scope. Preserve feature branches, user LICENSE and unrelated changes. No unrequested merges or paid runtime services.
