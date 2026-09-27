# Phase 3 — verified engine evidence

Verified 2026-09-27. Game/test source commit: `50c69a828c1935d9dfbd3e24e3fffad0ca852c6e`.

CI: https://github.com/egol82/hideand/actions/runs/36286075381

This documentation update does not change game code. Future source changes require their own CI evidence.

## Executed environments

| Environment | Result |
|---|---|
| Local Linux / official Godot 4.4.1 | Import, all regression and Phase 3 tests, all map matches, actual rendering passed |
| GitHub Linux / Godot 4.4.1 | Import, original tests, Phase 3 assertions and all map matches passed |
| GitHub Linux / Godot 4.7.2 | Same tests passed; preserved Phase 2 and new first-person screenshots generated |
| GitHub Windows headless / Godot 4.7.2 | Original tests, Phase 3 assertions, smoke and all three map matches passed |

Official engine archives were verified against the official SHA512 manifests before execution. The uploaded source snapshot was compared byte-for-byte with locally tested source files: zero mismatches.

## Completion markers

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE1_SMOKE_READY
PHASE2_SMOKE_READY
PHASE3_SMOKE_READY
```

453 individual assertions total, not 453 independently designed scenarios. A separate static source-hygiene script checks 140 conditions; those are not counted as engine assertions. Required markers, exit codes and error-log checks are enforced.

New assertions cover perspective/view layers, mouse look and pitch/clamps, yaw-relative movement, original weapon preservation, authoritative weapon pitch, focused E/hiding, no discovery behind camera or through walls, pause, map selection, wall weapon retreat, local escape return and spectator subject selection. All 46 hideout approach points are tested for reachability and player-capsule clearance. Real human input is not simulated by these handler-level tests.

## Actual physics/bot match results

Fixed seed 8027, four rounds per map. Linux and Windows logs recorded the same results:

| Map | Rounds | Duels | Hits | Captures | Escapes |
|---|---:|---:|---:|---:|---:|
| toy_home | 4 | 51 | 267 | 5 | 46 |
| warehouse | 4 | 36 | 192 | 5 | 31 |
| garden | 4 | 29 | 153 | 6 | 23 |

These numbers are engineering regression outcomes, not fun/balance benchmarks. Headless autoplay skips invisible presentation only, not physics, bot logic, combat or timers. Large-map pacing and the escape-heavy duel balance need human testing.

## Real screenshots and source

The `godot-4.7.2-validation` artifact contains logs, a `git archive` of the exact source commit, five preserved Phase 2 captures, and these seven 1280×720 Phase 3 captures:

- phase3_00_map_menu.png
- phase3_01_drawing.png
- phase3_toy_home_fps.png
- phase3_02_reveal.png
- phase3_03_swing.png
- phase3_warehouse_fps.png
- phase3_garden_fps.png

They are actual Godot Compatibility-renderer scenes under Xvfb/Mesa software OpenGL, with Dummy audio. Screenshot mode stages reproducible scenes; it is not a manual playthrough. The `godot-windows-4.7.2-validation` artifact contains Windows logs. CI artifact retention is seven days.

## Warnings and limits

The software renderer warns that V-Sync control is unsupported. Preserved Phase 2 headless tests report 8/6/12 ObjectDB instances leaked on different process exits. The new Phase 3 headless tests mute audio and do not report that warning; they do not validate a real audio device. Do not describe the full legacy suite as warning-free.

Human mouse handling/feel, nausea, Windows GPU rendering, real audio output, hardware frame rate, controller, networking, Steam/release export, commercial art quality, exhaustive arbitrary-drawing world/view alignment and large-map balance are not verified. The first-person wall retraction uses a central ray and is not exhaustive clipping prevention for every possible drawing. The view model is cosmetic; world collision geometry remains authoritative.
