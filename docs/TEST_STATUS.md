# Test status — Phase 2

Update date: 2026-09-27 (Korea).

## Verified engine evidence before the final input-test expansion

Commit `5023c752497e8e621b4cfae4ea61c6235ae76e87`, workflow run `36256830061`:

- Godot 4.4.1 and 4.7.2 Linux import, original weapon unit tests and Phase 2 unit tests passed.
- Godot 4.7.2 log: `PHASE1_UNIT_RESULT: 52 checks, 0 failures` and `PHASE2_UNIT_RESULT: 115 checks, 0 failures`.
- Both Phase 1 and Phase 2 scene initialization markers were present.
- Four-round physics/AI autoplay completed. Recorded 4.7.2 result: 51 duels, 281 registered hits, 6 captures and 45 escapes. This is a single fixed-seed engineering regression, not a balance benchmark.
- Five real game screenshots were generated under Xvfb/software OpenGL. The first render exposed overbright lighting and poor checked-label contrast; a subsequent source change corrected these. The first capture also fell back from an absent CI audio device; current capture explicitly uses Dummy audio.

Commit `f29ab19f21e1f9be623efa328412ef8466e9f402`, run `36257261801`: both Linux jobs and rendered capture passed; the new Windows bootstrap failed while reading the checksum text response. The bootstrap now reads a downloaded text file instead. Do not describe that historical Windows run as passing.

## Current branch verification

The workflow now additionally runs scripted drawing/E/pause/restart input integration and Windows headless checks. Read the latest workflow run for the exact current commit; these new checks are not proven merely by the historical numbers above. Completion markers and nonzero/error-log checks are mandatory. CI artifacts include actual logs, screenshots and an exact `git archive` source snapshot.

## Not verified

Human playtesting, fun/balance, real audio output, Windows GPU rendering, gamepad control, online networking, Steam distribution, Windows release export, target-device frame rate, commercial art quality and exhaustive storage failure handling remain unverified or out of scope.
