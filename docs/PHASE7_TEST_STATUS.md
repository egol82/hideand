# Phase 7 — validation status

2026-09-27. Exact published source and remote CI are to be recorded after upload/readback. Local evidence is not an automatic remote pass.

## Local executed evidence

Official Godot 4.4.1.stable.official.49a5bc7b6 on Linux; engine archive was checked against its official SHA512 manifest before extraction. Original suites (52 + 115 + 27 + 259 + 237 + 238 + 78 = 1,006 individual assertions) passed during development. The current final test counts and exact results are retained in ci-artifacts logs.

The map suite checks catalog/timing, all 42 new hiding approaches, real E hide/exit/inspect actions, conservative collision bounds, every free navigation cell's connectivity, loop waypoints and sight blockers, compact/full topology, terrain hearing and hidden-actor clue suppression. Six fixed-seed FIELD/CLASSIC × new-map runs completed four rounds in local development. Synthetic handlers and bot regression are not human usability or balance tests.

Twelve real 1280×720 captures: each map's menu, FPS, route view and diagnostic overhead cutaway. Overviews hide the ceiling and are explicitly not the normal player camera. The rendering process must finish without script/shader/errors and with the required marker. Software-GL V-Sync and old legacy ObjectDB warnings are not described as absent.

## Pending final verification

Read the exact latest CI run and its source commit. Do not claim an unobserved remote result. Windows headless, Linux matrices and source byte readback are required for a published verification update.

## Not verified

Human fun, balanced capture rates, every possible weapon/occlusion combination, live audio, Windows GPU performance, network latency, controller usability, Steam export or commercial map-art quality. Existing language-field checks are included in inherited totals; counts are assertions, not independently designed game scenarios.
