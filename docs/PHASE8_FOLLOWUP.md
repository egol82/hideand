# Phase 8 — final grip review and verified follow-up

Verified 2026-09-28. Final game/test source commit: `2e76f4a64956223587d4e8958bc738b59e4045f6`.

Successful CI: https://github.com/egol82/hideand/actions/runs/36368314032

This verification update changes documentation only. The code/source ZIP verified below remains 2e76f4a. Historical original-grip evidence for a0371312 remains in PHASE8_TEST_STATUS.md; use this document for the final follow-up.

## Preservation and compatible changes

During the implementation session, another completed Phase 8 commit appeared on the feature branch. Its natural-grip implementation and PR #7 were preserved rather than overwritten with a separate local candidate. The final follow-up is based on `bd5d41d6d05df98acdc9440ab6c7af60fc6bfabf` and retains its hand silhouettes, real-shaft two-hand grip and short-shaft wrist support.

- Reject negative/zero/non-finite display scale and singular/non-finite drawing frames before fitting.
- Give sleeve/finger tubes meaningful per-corner UVs, indexed vertices and tangent vectors. Flat and round caps have winding consistent with outward normals.
- Sleeve fabric uses local UVs and restrained normal-map strength so the cloth pattern stays attached as the arm frame rotates.
- Guard zero-length/tiny wrist-to-elbow links so their basis remains nonsingular.
- Add 17 focused assertions without removing the original 198 grip assertions or any prior suites.

These changes are cosmetic/safety refinements, not a replacement of the approved user's drawing. No invented handle or new physics shape is added. Maps, scoring, attack timing, original weapon form/contact samples, input, storage and LICENSE stay unchanged.

## Actual execution evidence

| Environment | Result |
|---|---|
| Local Linux / official Godot 4.4.1 | Original 198 grip assertions, 17 safety assertions, actual entry and 14 staged rendered grip poses passed |
| GitHub Linux / Godot 4.4.1 | Full prior/new suites and map/mode regressions passed |
| GitHub Linux / Godot 4.7.2 | Full suites, all 14 grip renders and retained earlier captures passed |
| GitHub Windows headless / Godot 4.7.2 | Full prior/new suites and map/mode regressions passed |

All three jobs of CI run 36368314032 were retrieved as completed/success. Downloaded Linux and Windows logs both contain:

```text
GRIP_UNIT_RESULT: 198 checks, 0 failures
GRIP_SAFETY_RESULT: 17 checks, 0 failures
PHASE4_SMOKE_READY
GRIP_SUITE_PASS
```

The Linux rendered run additionally contains GRIP_CAPTURE_PASS. The entry uses the actual shared controller marker, not an invented Phase 8 marker. Runners check exit status, errors, required markers and timeouts together.

There are 215 hand-related assertions, plus the preserved 1,611 assertions: **1,826 individual assertions total**. The inherited total includes 110 bilingual copy-field checks and repeated shape/map checks; it is not a count of independent human-play scenarios or an aesthetic quality score.

## Rendered evidence and exact source readback

Fourteen new 1280x720 images were regenerated on the final code: idle views in Sugar Market, Starlight Arcade and Pocket Station; quick/balanced/heavy windup, active and recovery; a long-shaft drawing and a sideways drawing. They are staged real Godot engine output under Xvfb/Mesa software OpenGL with Dummy audio, not edited reference images or a manual playthrough. The final Sugar Market capture and the before/after grip comparison were visually inspected.

GitHub artifact SHA256 hashes were verified:

- Linux: `a072294d81bae4a70fbde2a65679bcd94be7b1050d10ef93d39d27b29f412e9a`
- Windows: `8f4fa953d0bde9d33bfc649c2669205d0a90c891b47aab83919370584edb56bb`

The source ZIP comment and source-commit marker identify 2e76f4a. All five edited code/test files were byte-compared against the local final version with zero mismatches: grip_fit.gd, grip_rig.gd, hand_mesh.gd, test_grip_safety.gd and tools/test_grip.py. LICENSE matches the preceding source. The sixth changed file was this follow-up document.

CI artifact godot-4.7.2-validation contains source, logs and screenshots; Windows logs are in godot-windows-4.7.2-validation. Retention is seven days. Source deliveries do not include engine binaries, fonts, .godot caches or user saves.

## Boundaries

The hands are stylized multi-part geometry, not a fully skinned anatomical hand/body IK solver. Extreme wide/tiny/self-crossing/off-centre drawings can still intersect fingers; stable contact transforms and finite-mesh checks do not prove zero penetration for every drawing. The historical authority collision remains approximate. No new baked GI/contact-shadow system is claimed.

No human mouse-feel, fun/accessibility/comfort session, Windows GPU/FPS benchmark, actual audio audition, multiplayer/Steam/release EXE or commercial-art completion is claimed. Legacy ObjectDB cleanup and software V-Sync warnings remain. The entire suite is not warning-free. No force push, unrequested merge, repository visibility change or LICENSE change was made.
