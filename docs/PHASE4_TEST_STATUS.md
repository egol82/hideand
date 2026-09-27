# Phase 4 — verified engine evidence

Verified 2026-09-27. Game/test source commit: `129d9888d7137b68fdcd47bddf25c36cf3b0de21`.

CI: https://github.com/egol82/hideand/actions/runs/36295220240

This update changes only the verification document. Future game/test source changes require their own evidence.

## Executed environments

| Environment | Actual result |
|---|---|
| Local Linux / official Godot 4.4.1.stable.official.49a5bc7b6 | Import, preserved regressions, new tests, six matches and actual rendering passed |
| GitHub Linux / Godot 4.4.1 | All engine tests and six Phase 4 matches passed |
| GitHub Linux / Godot 4.7.2 | All engine tests, six matches, six new rendered captures and preserved captures passed |
| GitHub Windows headless / Godot 4.7.2 | All engine tests and six Phase 4 matches passed |

Official engine archives were verified against official SHA512 manifests. The exact GitHub source archive was downloaded and compared byte-for-byte against all 30 intended local changed files: zero mismatches. Existing Phase 1/2/3 source and LICENSE were preserved.

## Assertions and completion markers

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE4_UNIT_RESULT: 237 checks, 0 failures
PHASE4_SMOKE_READY
PHASE4_SUITE_PASS
```

690 individual assertions total, not 690 independently designed player scenarios. A separate static hygiene pass checked 233 conditions; these are not engine assertions. Test exit codes, error logs and required completion markers are checked together.

New checks include all four audit defects, fixed-pitch repetition at 30/60/120 step rates, buffer expiry/consumption for three attack styles, shared attack timeline, feedback attribution, comfort-independent timers, actual swept contact, duplicate-hit rejection during an active swing, hole/area/reach limits, active/full-map paths and hideout capsule clearance, field encounter continuity, revision-based view caching, and opt-in bounded local diagnostics.

The editable room snapshot helper also successfully saved a scene locally under user://. It is not a baked-lighting or UV2 authoring tool.

## Fixed-seed physics/bot regressions — not balance benchmarks

| Mode | Map | Rounds | Duels | Hits | Captures | Escapes |
|---|---|---:|---:|---:|---:|---:|
| field | toy_home | 4 | 26 | 126 | 6 | 20 |
| field | warehouse | 4 | 39 | 196 | 7 | 32 |
| field | garden | 4 | 34 | 171 | 6 | 28 |
| classic | toy_home | 4 | 32 | 159 | 8 | 24 |
| classic | warehouse | 4 | 42 | 220 | 8 | 34 |
| classic | garden | 4 | 38 | 198 | 7 | 31 |

Local and remote Linux/Windows runs recorded the above outcomes. Autoplay keeps physics, AI, combat and timers; it skips invisible presentation in headless mode. The six matches use default compact zones; full/compact navigation and hiding clearance are separately covered.

## Artifacts

The CI artifact `godot-4.7.2-validation` includes authentic 1280x720 Phase 4 menu/drawing/lounge/reveal/swing/settings captures, execution logs, source commit marker and the exact `git archive` source ZIP. Windows logs are in `godot-windows-4.7.2-validation`. GitHub artifact retention is seven days.

These are staged reproducible Godot scenes, not generated concept art or a manual playthrough. Rendered captures use Mesa software OpenGL and Dummy audio. They do not measure hardware FPS or verify a Windows graphics/audio device.

## Boundaries and unfinished work

No human mouse-feel, fun/balance or accessibility session was performed. No real four-PC multiplayer, Steam integration, release EXE, Windows GPU performance, professional audio audition, baked indirect lighting/UV2, full hand/body IK, commercial art quality or exhaustive arbitrary-drawing collision proof is claimed. Field escape is timeout or seeker KO, not a new distance-based escape condition. Captured players still spectate the seeker; next-round drawing/assist activities are deferred.

Legacy Phase 2 cleanup warnings and software renderer V-Sync warnings remain. Preserved historical scenes keep their older behavior; fixes apply to the new default Phase 4 game. The whole suite must not be described as warning-free.
