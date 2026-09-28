# Cute sync — verified publication and renderer evidence

Verified 2026-09-28. Game/test source commit: `9005c513dc25d8e4767418274fe4ec9537c90ef2`.

- Focused Windows/Linux run: https://github.com/egol82/hideand/actions/runs/36408878612
- Preserved regression workflow: https://github.com/egol82/hideand/actions/runs/36408878458

This follow-up changes documentation only. The source ZIP and execution results below identify the game/test commit above, not a later untested gameplay change.

## Actual executions

| Environment | Observed result |
|---|---|
| Local Linux, official Godot 4.4.1.stable.official.49a5bc7b6 | All old suites, new sync assertions, same smash assertions on new scene, twelve new-entry matches and actual-input rendering passed |
| GitHub Linux and Windows headless, Godot 4.4.1 | Focused sync workflow completed/success on both jobs; twelve new-entry matches on each OS |
| GitHub Linux Godot 4.4.1 and 4.7.2, Windows headless Godot 4.7.2 | All three original regression jobs completed/success; earlier assertions and map/mode regressions preserved |
| GitHub Linux software OpenGL, Godot 4.4.1 | Nine new 1280x720 stills and six-second silent actual-contact video generated |

The official local engine archive and focused workflow engine downloads were checked against official SHA512 manifests before extraction. Old cleanup/software V-Sync warnings remain; passing is not a warning-free or hardware-performance claim.

## Contact synchronization checks

`SYNC_UNIT_RESULT: 94 checks, 0 failures` passes on local Linux and downloaded remote Windows/Linux logs. The same original smash test also passes against the new scene via `--sync-followup`: `SMASH_UNIT_RESULT: 100 checks, 0 failures`. Its assertions were not removed or weakened.

Across three attack styles and 30/60/120 physics-step intervals, nine real mouse-handler/physics/swept-contact scenarios confirm:

- The victim is already visibly compressed at contact age zero before a render advance.
- Pooled particle transforms and comic-label positions are populated on that same contact call, not left at a reused or default location until the next frame.
- The first displayed contact projects the selected original drawing sample to the observed contact's screen point, with error below 0.1px at 1280x720 in these fixtures.
- Original drawing data, hit samples, one-hit damage, score, clocks and world weapon transforms remain unchanged by presentation updates.
- Clearing/restarting feedback clears the contact correction; round paws replace individual finger loops and the resting display weapon is larger than the old display cap.

Completion markers:

```text
SYNC_UNIT_RESULT: 94 checks, 0 failures
SMASH_UNIT_RESULT: 100 checks, 0 failures
PHASE4_SMOKE_READY
SYNC_CAPTURE_PASS
SYNC_SUITE_PASS
LOCAL_ALL_SYNC_SUITE_PASS
```

The last marker is local only; the others are from actual engine/runner logs. The smoke marker is the existing shared controller marker, not an invented new phase marker. Process exits, timeouts, script errors and required markers are checked together.

Preserved tests contain 1,926 individual assertions; the new suite adds 94, totaling 2,020 distinct assertion definitions counted across suites. Repeating the existing 100 smash assertions against the new scene is not counted as another 100 unique checks. These counts include inherited language-field checks and repeated shape/map scenarios; they are not human usability sessions. Static source hygiene separately reports 443 conditions.

## Matches and real-input capture

Both FIELD and CLASSIC run on all six maps, twelve matches of four rounds each. Downloaded remote Linux/Windows outcome dictionaries match the local rerun exactly. These are regression observations, not proof of improved fun or balance.

The capture drives InputEventMouseButton into the actual input handler, then advances practice physics and real swept collision inside Sugar Market, Starlight Arcade and Pocket Station. Positions and initial HP are staged; contact effects and the finishing disappearance are not injected. This is an automated physics scenario, not a manual playthrough or a full match recording.

Nine images show idle/impact/reaction per map. The six-second MP4 is H.264, 1280x720, 30fps, with no audio track. Capture metrics record actual first-contact frame 15 for the balanced Sugar Market scenario and 17 for the heavy arcade/station scenarios. Device audio latency was not measured or corrected by these frames. The game still synthesizes contact sound on the same event call.

The final remote impact still and round-paw rest pose were inspected. An earlier local whole-world projection iteration was rejected because it obscured too much of the view. The final implementation uses bounded camera depth with an original-drawing contact anchor.

## Exact source readback

Downloaded artifacts match their GitHub-reported SHA256 values:

- cute-sync-Linux: `31889d1598b826843fa98cf9b4847743548554176ac0443838181a0badaf5a48`
- cute-sync-Windows: `e01e538c5d02aa6c664a10a0d91bd92dd11e30d9b0c5937849192a2785879840`

The source ZIP comment and cute-sync-source-commit.txt both identify `9005c513dc25d8e4767418274fe4ec9537c90ef2`. All 20 intended changed files were compared byte-for-byte with the locally tested files: zero mismatches. LICENSE matches the preceding source. No engine binaries, fonts, .godot caches or private save files are included in source delivery.

Focused artifacts contain the exact source ZIP, logs, match metrics, nine images and cute_sync_actual_contacts.mp4. Retention is seven days. The original regression workflow also rerenders its Phase 9 fixture, not every historical screenshot.

## Honest scope

The weapon enlargement is cosmetic first-person presentation: nominal displayed radial extent increases from the old 0.44m cap toward 0.68m, with bounded scales. Physical range, source drawing and damage do not increase, and not every arbitrary drawing is made exactly equal to character height.

Only the selected contact sample is screen-aligned on its first displayed impact frame. This does not prove every vertex, moving target, off-camera contact or the entire swing has perfect alignment. A 55ms presentation correction blends out without freezing gameplay or camera input. Wide/tiny/off-centre drawings can still intersect a paw or obscure the view. This is not complete anatomical IK or a replacement of the approximate authority collision system.

No human fun/comfort/accessibility session, hardware FPS/Windows GPU benchmark, live audio audition or speaker-latency guarantee, multiplayer/Steam/release EXE or commercial-art completion is claimed. The larger model has no hidden extra attack range. No force push, unrequested merge, visibility change or LICENSE change was performed.
