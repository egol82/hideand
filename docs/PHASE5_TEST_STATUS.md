# Phase 5 — verification status

2026-09-27. Publication is not a substitute for execution. Exact remote commit/CI references are to be recorded after the published source is checked.

## Local evidence

Official Godot 4.4.1.stable.official.49a5bc7b6 on Linux, engine archive checked against its official SHA512 manifest. Actual new-entry initialization, existing regression assertions, practice/keyboard/file recovery/workshop tests and software OpenGL captures were executed during development.

- Preserved assertions: 52 + 115 + 27 + 259 + 237 = 690. The Phase 4 suite now exercises the improved shared controller.
- New quality checks: 238 assertions, of which 110 are paired English/Korean copy field-presence checks. They are not all independently designed gameplay scenarios.
- Nine real staged screenshots add nine save-result checks (247 in capture mode). Scene entry smoke is checked separately with a required completion marker.
- Six FIELD/CLASSIC × three-map physics/bot matches completed four rounds. Older Phase 2/3 assertions and map completion markers were also checked. Fixed-seed outcomes are regressions, not balance proof.
- New regression: previous hurt response scaled the world weapon to about (1.08,0.91881,1.072515); with rotation-only FacingRoot it remains (1,1,1) while body_art still squashes. Tested with repeated 30/60/120 Hz steps.
- Actual UI flows cover overwrite confirmation, backup warning, bindings, no-score/no-timer practice, active current round behind captured drawing, pause/round-end sketch preservation and once-only next-round consumption.
- A capture exposed stale CAUGHT/hurt/particle effects after practice restart; clearing transient presentation and its regression checks were added.

## Remote verification

Pending exact published source run. Linux matrix and Windows headless jobs are configured to repeat all suites. Do not describe an unobserved remote job as passed.

## Limits

Screens are Linux Xvfb/Mesa software OpenGL with Dummy audio. They are scripted staged scenes, not a manual playthrough. Existing legacy ObjectDB cleanup warnings and unsupported software-driver V-Sync warnings remain. No hardware frame-rate/audio quality, Windows GPU, human controls/comfort/balance, fully localized world strings, gamepad, real four-PC online, Steam, release EXE, baked GI, full IK, commercial art or every-filesystem power-loss guarantee is claimed. CJK text requires a suitable installed OS font; no font files are shipped.
