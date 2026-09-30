# Seed21 round-reset physics synchronization

Scope: repair `63dad42af56146af54ffc2be46cc90d33d55474c` without changing layouts,
mechanisms, collision masks, scoring or round selection. Same stacked draft PR21 / Phase20 base.

## Reproduction and cause

On official Godot4.4.1, the unchanged Pine FIELD autoplay at seed17 finishes four rounds but
records only PH-v1-7, PH-v1-2 and PH-v1-1. Round2 PH-v1-6 is rejected as `occupied socket`.
The same CLASSIC input records all four. The failed upstream CI also misses a Pine FIELD
layout at seed8027. Completed matches alone were insufficient evidence of layout readiness.

Reading server transforms showed the reset CharacterBody node at its spawn while the
kinematic PhysicsServer transform still held the previous round's location. Calling only
`force_update_transform()` did not fix this: it submits the new kinematic target, but the
server integrates it on a physics step. That attempted fix and its rejection are retained
as diagnostic evidence, not a passing final result.

## Runtime change

Only scripts/seed21/game.gd changes production behavior. After the inherited reset it submits
the four transforms and remains in DRAW until their actual PhysicsServer transforms agree.
Then it runs the ORIGINAL validate_plan with the same mask, all occupants and all path checks.
It does not exclude players, clear arbitrary colliders, move an occupant or ignore a rejection.
Early drawing acceptance is queued until placement has been checked. A reset serial cancels
stale waiters when returning to the menu, selecting a map or starting a different round.
No mid-chase placement or new gameplay timer is introduced. Non-natural maps/practice retain
their prior path. Real occupancy continues to reject and leave the route unmodified.

## Regression coverage

- Existing 340 predicates and the existing `Expected four valid distinct natural rounds`
  assertion in tools/test_seed21.py are unchanged.
- New test_round_reset.gd deliberately places a real body at a future socket, then invokes
  the real inherited reset WITHOUT a test-side frame wait before the placement request.
  It checks pending DRAW, actual server/node agreement, exact selected layout, unchanged
  collision masks, genuine character/solid rejection, queued acceptance and cancellation.
- New test_seed21_rounds.py launches actual engine autoplay processes with no mocked round
  transitions. Seeds17/0, three nature maps and both modes are exercised. Pine17 in both
  modes repeats in a new process. All14 games must finish four rounds with exactly four
  distinct valid layout records, no rejection, correct provenance and equal mode manifests.
  Repeated same-input Pine results/layouts must also match. The original20-game suite at
  seed8027 is retained, including its previously failing provenance assertion.
- Older isolated mechanism/capture fixtures now wait for actual reset readiness BEFORE
  accepting a drawing or manually advancing their test clock. The original check/require
  expressions are unchanged. Without this setup adjustment they would advance DRAW instead
  of the intended HIDE interval. A bounded helper errors if synchronization never completes.
  This helper is not used by the actual autoplay regression and cannot conceal the original bug.
  Manually parked fixture players likewise wait for the same real server transform update before
  a passage-clearance assertion. A diagnostic run caught stale spawn bodies crossing the lane;
  the correction changes only fixture readiness, never the passage collision test or its result.
- Full dedicated4.4.1 Windows/Linux checks and existing PR regressions remain. Additional
  Windows/Linux4.7.2 jobs run the new reset/occupancy and actual-autoplay regression, rather
  than treating legacy-scene4.7.2 success as coverage for Seed21.

Run `python tools/test_seed21_rounds.py --godot /path/to/godot` for the new regression.
Run `python tools/test_seed21.py --matches --regressions` for preserved integrated checks.
The default CI installer remains4.4.1; GODOT_TEST_VERSION=4.7.2 is an explicit validated option.
Observed outputs and exact final HEAD CI results are recorded in PR21 and downloadable evidence.
No completion is inferred from this document or from the earlier failed CI.

Human gameplay balance/comfort and user hardware performance remain unverified. The reported
4.6.3 observation is the user's independent reproduction, not a local4.6.3 run in this fix.
No new maps, seed templates, mechanics, merge, deployment or new Cloud Codex environment.

Primary API/source basis: Godot4.4 Node3D.force_update_transform and PhysicsServer3D state
queries; actual kinematic timing is verified by the tests rather than assumed synchronous.
https://docs.godotengine.org/en/4.4/classes/class_node3d.html#class-node3d-method-force-update-transform
https://docs.godotengine.org/en/4.4/classes/class_physicsserver3d.html

## Renderer fixture follow-up (no additional runtime changes)

The first published fix2d564c3 passed all logic/reset/match checks on4.4.1 and4.7.2,
but its Linux rendering job failed at shutdown after producing the nine seed images:
six OpenGL texture-allocation errors were detected by the unchanged strict log checker.
Those renders and that failed job are not counted as successful final validation.

The capture scripts returned to the menu, selected a map and began the next round in
one continuation. Their staged setup now lets one process/render frame complete after
map selection and before starting the next round, rather than overlapping pending visual
initialization with a new preview. The seed views retain the same pixel predicates.
The Canyon identical-pose comparison also waits four actual render frames after setting
its camera/pose so deferred lighting has settled; its original return-error threshold is
unchanged. Both capture checks pass without log filtering. The precise internal native
allocation path is not asserted to have been repaired in the engine. No textures, graphics settings, error patterns
or gameplay code are changed. Extra teardown waits and cache-clearing diagnostic attempts
did not resolve the error and are retained separately, not shipped as runtime changes.
The final CI re-executes all requested stages on the final source. Its source checkout
includes three commits so the cumulative patch/bundle can still reference63dad42.
