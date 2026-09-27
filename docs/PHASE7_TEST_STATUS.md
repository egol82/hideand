# Phase 7 — verified map-pack evidence

Recovery and final verification: 2026-09-28. Game/test source commit: `dcb073e7eed7c42bc13abaa32690bc4398b1a27c` (2026-09-27).

Successful CI: https://github.com/egol82/hideand/actions/runs/36329552804

The prior interrupted conversation had already published the game code. This follow-up recovered that exact source, inspected completed CI artifacts and rendered maps, reran the new map suite locally, and completes the verification record and PR. This commit changes documentation only; it does not claim another gameplay implementation or rerender.

## Executed environments

| Environment | Verified result |
|---|---|
| GitHub Linux / Godot 4.4.1 | All original/new assertions, default-entry checks and map/mode matches passed |
| GitHub Linux / Godot 4.7.2 | Same checks passed, with 12 new map-pack renderer captures and previous captures |
| GitHub Windows headless / Godot 4.7.2 | Original/new engine suites and six new-map matches passed |
| Recovery session Linux / official Godot 4.4.1.stable.official.49a5bc7b6 | Exact source recovered from CI; map import, 605 assertions, actual default entry, and six new-map matches rerun successfully |

The locally used official Godot 4.4.1 archive was checked against its SHA512 manifest before extraction. The downloaded Linux artifact SHA256 is `b23864b4a8ec9eb49289ea1f20a259737bee55ed221852834a118d8c4c397542`; Windows is `c491a41ecba55d66aed022e67102ec715bf5708a59e3414b235a5ab094bc9a3d`. Both match the digests returned by GitHub. The source ZIP comment and commit marker identify dcb073e7. All 125 extracted source files were compared byte-for-byte with that archive: zero mismatches. LICENSE matches the prior Phase 6 source. No fonts, engine binaries or .godot caches are bundled in the source deliverable.

## Actual completion markers

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE4_UNIT_RESULT: 237 checks, 0 failures
QUALITY_UNIT_RESULT: 238 checks, 0 failures
GRAPHICS_UNIT_RESULT: 78 checks, 0 failures
MAP_PACK_UNIT_RESULT: 605 checks, 0 failures
PHASE4_SMOKE_READY
MAP_PACK_CAPTURE_PASS
MAP_PACK_SUITE_PASS
```

Total: **1,611 individual assertions**, not 1,611 independently designed human-play scenarios. The inherited total includes 110 bilingual copy-field presence checks. The separate static source-hygiene pass checks 357 conditions and is not counted as an engine assertion. The new entry intentionally uses the existing shared controller's PHASE4_SMOKE_READY marker. Runners check exit status, error logs, timeouts and expected completion markers together.

## New map checks

- All six map IDs remain supported; historical map metadata, public prop centres and existing regression suites are preserved.
- Sugar Market 30 x 26 / 10 hideouts; Starlight Arcade 40 x 32 / 14; Pocket Station 52 x 40 / 18.
- Stable prop IDs, paired conservative collision bodies, in-bound footprints and clear player spawn/classic-duel positions.
- Every free navigation cell belongs to the spawn-connected component on each new map.
- All 42 new hiding approaches have capsule clearance, a navigable route, non-distant nav snapping and at least two free neighbouring cells. Actual first-person E focus/hide/exit handlers are tested at all 42 sites. This does NOT prove two independent tactically safe escape routes against a human.
- Seeker E inspection discovers a hidden occupant; FIELD reveal retains the discovery position.
- Central landmark blocks sight while the designated surrounding loop waypoints are reachable.
- Rebuilding or toggling compact/full does not cut the new authored loops; old maps retain their previous active-zone behavior.
- Actual step handling emits approximate public clues; hidden actors do not emit phantom footsteps. Terrain radius is independent of audio volume and comfort settings. On tested terrain, normal walking uses 13.2m on loud tiles and 4m on quiet runners; Ctrl applies the existing quiet-movement base range first.
- Public menu/map preview data has no opponent coordinates or occupied-hideout state.

## Six complete fixed-seed physics/bot matches

| Mode | Map | Rounds | Encounters | Hits | Captures | Escapes |
|---|---|---:|---:|---:|---:|---:|
| FIELD | sugar_market | 4 | 31 | 147 | 7 | 24 |
| FIELD | starlight_arcade | 4 | 36 | 176 | 6 | 30 |
| FIELD | pocket_station | 4 | 34 | 160 | 6 | 28 |
| CLASSIC | sugar_market | 4 | 55 | 277 | 7 | 48 |
| CLASSIC | starlight_arcade | 4 | 73 | 368 | 6 | 67 |
| CLASSIC | pocket_station | 4 | 47 | 229 | 8 | 39 |

Downloaded Linux and Windows logs and the recovery-session local rerun agree on these results. Physics, AI, combat and clocks run; only invisible presentation is skipped in headless autoplay. These are regression observations, NOT evidence of better fun or balanced capture rates. Existing map/mode regressions also passed in the published CI.

## Actual screens and source

The CI artifact `godot-4.7.2-validation` contains the exact source ZIP, logs, map/navigation metrics and twelve 1280x720 Phase 7 images: each map's menu, first-person view, route view and overhead cutaway. `godot-windows-4.7.2-validation` contains Windows logs. Artifact retention is seven days.

These are reproducible staged real Godot Compatibility-renderer captures under Xvfb/Mesa software OpenGL with Dummy audio. Overhead evidence temporarily hides only the ceiling; normal FPS gameplay keeps the ceiling. The three final first-person maps were visually inspected during recovery. They are not generated concept art or a recorded manual playthrough.

## References and limits

Official Boomerang Fu, Witch It and Party Animals descriptions/developer notes were rechecked during recovery; see docs/PHASE7_MAP_RESEARCH.md for the design/source distinction. Original scene geometry and art were not copied. The user's audit section 8 informs landmarks, loops and event density, not a demand for sheer map area.

No human fun/accessibility/comfort session, live audio audition, Windows GPU/FPS benchmark, network latency test, gamepad validation, Steam/release EXE, baked GI or commercial map-art completion is claimed. All three additions are single-level. Trains are stationary cover, cannot be boarded and are not moving hazards. Every map uses the existing one-human/three-bot offline rules. Complex arbitrary-weapon clipping and tactical fairness still need human tests. Legacy ObjectDB cleanup and software-driver V-Sync warnings remain; the whole suite is not described as warning-free.
