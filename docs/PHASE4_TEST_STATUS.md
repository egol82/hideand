# Phase 4 — validation status

2026-09-27. Local real engine: official Godot 4.4.1.stable.official.49a5bc7b6 on Linux. The engine archive was verified against its SHA512 manifest. Remote CI status must be read on the exact published commit, not assumed from this local result.

## Executed locally

- `python tools/verify_project.py`: static source hygiene/resource checks; not an engine substitute.
- `bash tools/test.sh` and `bash tools/test_phase3.sh`: preserved 52 + 115 + 27 + 259 = 453 assertions and earlier smoke/autoplay regressions passed.
- `python tools/test_phase4.py`: 237 new assertions, zero failures; default scene import/smoke; six four-round physics/bot runs, all completed.
- `xvfb-run ... scenes/phase4.tscn -- --capture-phase4`: six 1280x720 real engine screens, correct current stage completion markers. These are reproducible staged scenes, not a manual playthrough.
- `godot --headless --path . --script res://tools/export_toy_room.gd`: editable room snapshot saved successfully in `user://`.

690 assertions total, not 690 independently designed player scenarios. Exact logs, engine version and source snapshot are required as evidence for future changes.

## Fixed-seed regression metrics (not balance claims)

| Mode | Map | Rounds | Duels | Hits | Captures | Escapes |
|---|---|---:|---:|---:|---:|---:|
| field | toy_home | 4 | 26 | 126 | 6 | 20 |
| field | warehouse | 4 | 39 | 196 | 7 | 32 |
| field | garden | 4 | 34 | 171 | 6 | 28 |
| classic | toy_home | 4 | 32 | 159 | 8 | 24 |
| classic | warehouse | 4 | 42 | 220 | 8 | 34 |
| classic | garden | 4 | 38 | 198 | 7 | 31 |

Autoplay keeps physics, AI, combat and timers. It skips invisible rendering in headless mode. Compact/full navigation and hiding-capsule clearance are covered separately; the six autoplay runs use default compact zones.

## Honest boundaries

Screens use Mesa software OpenGL / Dummy audio; not an FPS benchmark, Windows GPU run or real audio-device test. Legacy Phase 2 cleanup warnings remain and software OpenGL warns about unavailable V-Sync controls. Earlier scenes retain their historical design and bugs; the Phase 4 tests verify the new default implementation.

Human mouse feel, accessibility experience, fun, arbitrary drawing edge cases, frame pacing on actual target PCs, multiplayer latency, release export and commercial art quality remain unverified. Windows/Linux CI is configured to repeat engine tests but is not marked passed here until its run is retrieved.
