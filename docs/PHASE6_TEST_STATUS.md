# Phase 6 — verified graphics evidence

Verified 2026-09-27. Game/test source commit: `17ff62f3c69020106f22b425356807b39beb49e0`.

Successful CI: https://github.com/egol82/hideand/actions/runs/36317942098

This follow-up changes only this verification document. Future game/test changes require new evidence.

## Actual executions

| Environment | Result |
|---|---|
| Local Linux, official Godot 4.4.1.stable.official.49a5bc7b6 | Original suites, new graphics invariants, new entry and seven staged rendered screens passed |
| GitHub Linux, Godot 4.4.1 | All old/new assertions, entry checks and map/mode regressions passed |
| GitHub Linux, Godot 4.7.2 | Same checks passed; seven new graphics captures and previous scene captures completed |
| GitHub Windows headless, Godot 4.7.2 | All original suites, graphics assertions and entry checks passed |

Official engine archives were verified against official SHA512 manifests. The uploaded GitHub source archive was downloaded from the CI artifact and compared byte-for-byte with all 26 intended local changed files: zero mismatches. LICENSE, gameplay/input/storage/score controllers and earlier branch snapshots were preserved. Shared Art/weapon visual helpers intentionally affect Phase 4/5 entries on this branch.

## Assertions and markers

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE4_UNIT_RESULT: 237 checks, 0 failures
QUALITY_UNIT_RESULT: 238 checks, 0 failures
GRAPHICS_UNIT_RESULT: 78 checks, 0 failures
PHASE4_SMOKE_READY
GRAPHICS_CAPTURE_PASS
GRAPHICS_SUITE_PASS
```

1,006 individual assertions total, not independently designed human scenarios. The existing quality suite includes 110 bilingual copy-field checks. A separate source-hygiene script passed 309 static conditions. All runners require exit status, expected completion markers and no script errors. The new Phase 6 entry deliberately uses the existing controller's PHASE4_SMOKE_READY marker, not an invented Phase 6 marker.

New checks cover deterministic cached material/normal tiles and mipmaps, finite bounded weapon meshes, preserved original vectors/contact samples, conservative bevel fallback, three-map dimensions/active bounds/hideout IDs/obstacles/every nav-cell state/physics counts, map and preview idempotence, antialiasing, isolated view/world material copies, hidden actor grounding visibility and unit-scale authority weapons during cosmetic reactions.

Preserved fixed-seed FIELD/CLASSIC x three-map runs each completed four rounds using the unchanged controller and improved shared visual helpers. Earlier Phase 2/3 matches also completed. These are engineering regressions, not evidence of better balance or fun.

## Actual images and source

Artifact `godot-4.7.2-validation` contains the exact source ZIP, commit marker, logs and seven 1280x720 Phase 6 images: English menu/workshop/first-person/lounge/garden, Korean menu/workshop. Windows logs are in `godot-windows-4.7.2-validation`. Retention is seven days.

Captures use Xvfb/Mesa software OpenGL with Dummy audio. They are reproducible staged real Godot scenes, not generated concept art or human playthroughs. Local before/after images used the same camera/player/target placement. Initial overexposure and detached authority-shadow artefacts on view weapons were found by viewing renders and corrected. Final remote hero/workshop renders were inspected as well.

## Boundaries

Artistic contact planes are not LightmapGI, SSAO or a physical indirect-light bake. Authored placements with @tool-generated modules are editable, but a complete UV2/baked-scene pipeline is not implemented. Cosmetic view geometry intentionally does not receive world shadows; world weapons and other actors retain normal shadow receiving. No hidden actor coordinate is displayed by the contact planes.

No Windows GPU or hardware FPS benchmark, real audio audition, human mouse-feel/accessibility/fun session, multiplayer, Steam/export EXE, full hand/body IK, exhaustive clipping/occlusion fairness or commercial art completion is claimed. Legacy ObjectDB cleanup and unsupported software-driver V-Sync warnings remain; the whole old/new suite is not warning-free.
