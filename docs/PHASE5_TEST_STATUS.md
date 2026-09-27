# Phase 5 — verified engine evidence

Verified 2026-09-27. Game/test source commit: `ba25a858d159a383c9739c63bc279a9855ba29de`.

CI: https://github.com/egol82/hideand/actions/runs/36300165262

This follow-up changes the verification document only. New game/test changes need new execution evidence.

## Executed environments

| Environment | Actual result |
|---|---|
| Local Linux / official Godot 4.4.1.stable.official.49a5bc7b6 | Existing assertions, new entry, quality tests, six matches and rendered screens passed; an aggregate shell timeout required the legacy Phase 3 garden match to be rerun separately, which completed |
| GitHub Linux / Godot 4.4.1 | Full old and new suites, entry checks and all map/mode matches passed |
| GitHub Linux / Godot 4.7.2 | Full suites and nine new Korean/English rendered screens passed; previous scene captures also generated |
| GitHub Windows headless / Godot 4.7.2 | Full suites, entry checks and all map/mode matches passed |

Official engine archives were checked against official SHA512 manifests. After publication, the GitHub source archive was downloaded and compared byte-for-byte against all 27 intended changed files: zero mismatches. LICENSE and Phase 1–3 source were preserved. The previous Phase 4 snapshot remains in its original branch; this branch improves shared Phase 4 controllers.

## Completion markers

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE4_UNIT_RESULT: 237 checks, 0 failures
QUALITY_UNIT_RESULT: 238 checks, 0 failures
QUALITY_SUITE_PASS
```

928 individual assertions total, not 928 independently designed player scenarios. Of the 238 new checks, 110 verify paired English/Korean copy fields exist; these do not prove translation quality. The 128 other new assertions cover storage, physical input, actual UI handlers, practice, workshop isolation and weapon transforms. The capture variant repeats the suite and adds nine image-save checks, reporting 247. A separate static hygiene check reported 262 conditions, not engine tests.

The new `scenes/phase5.tscn` entry is actually launched and checked for the shared controller's `PHASE4_SMOKE_READY` marker. No invented Phase 5 marker is claimed. Required markers, exit status, log errors and process timeouts are checked together.

## Behavior verified

- A previous hurt response scaled the world weapon to about `(1.08,0.91881,1.072515)`. Rotation-only FacingRoot now keeps it `(1,1,1)` while body_art still squashes. Repeated 30/60/120 Hz step tests passed.
- JSON truncation, invalid schema/numbers, oversized files, path traversal and uncommitted temporary files are rejected. A corrupt primary cannot overwrite a valid backup. Actual slot UI asks before overwriting and identifies recovered backups.
- Key bindings reject conflicts/reserved codes; synthetic engine input dispatch confirms press/release affects movement. The actual key-capture menu was exercised.
- Practice does not run a countdown or award match score. Its hit count comes from a real swept weapon contact, not a fake increment button. Reopening the editor preserves progress.
- Captured players can queue a clone for next round while current clocks and bots run. Current actor weapon stays unchanged. Pause, round-end and next-round transitions retain and consume the sketch once.
- Restarting practice clears old caught/hurt notifications, audio voices and contact particles.

These are handler-level/synthetic tests and fixed-seed simulations, not human usability sessions.

## Four-round physics/bot results

| Mode | Map | Rounds | Duels | Hits | Captures | Escapes |
|---|---|---:|---:|---:|---:|---:|
| field | toy_home | 4 | 27 | 130 | 6 | 21 |
| field | warehouse | 4 | 40 | 199 | 6 | 34 |
| field | garden | 4 | 39 | 194 | 8 | 31 |
| classic | toy_home | 4 | 32 | 159 | 8 | 24 |
| classic | warehouse | 4 | 40 | 205 | 8 | 32 |
| classic | garden | 4 | 38 | 198 | 7 | 31 |

The current Linux/Windows runs produced these outcomes. These metrics are regression observations, not proof of balance or increased fun. Older Phase 2/3 map matches were also rerun successfully.

## Real artifacts

`godot-4.7.2-validation` includes the exact source ZIP, execution logs and nine 1280x720 Phase 5 screens: Korean title, drawing, practice, key controls, next-round drawing, results; English title, practice and settings. These are staged Godot Compatibility-renderer captures under Xvfb/Mesa software OpenGL and Dummy audio. Windows logs are in `godot-windows-4.7.2-validation`. CI artifact retention is seven days.

Korean captures were inspected for legible text and layout. CI uses an installed OS CJK font package. No font files or engine caches are included in the source archive.

## Boundaries

No human input-feel, fun/balance or accessibility session, Windows GPU performance, real audio-device audition, gamepad, real four-PC multiplayer, Steam, release EXE, baked GI, full IK, commercial art or exhaustive power-loss durability guarantee is claimed. Some inherited world/incidental/debug strings remain English. Korean needs a CJK-capable installed system font. Legacy ObjectDB cleanup warnings and software-driver V-Sync warnings remain; the whole suite is not warning-free.
