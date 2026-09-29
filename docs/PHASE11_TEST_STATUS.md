# Phase 11 — verified hide-and-seek implementation and recovery

Implementation: 2026-09-28. Recovery and final verification: 2026-09-29.
Game/test source: `b4195839894913b9fe17fbd26f4d11561b48608c`.
Main Windows/Linux CI: https://github.com/egol82/hideand/actions/runs/36441918757
Historical regression CI: https://github.com/egol82/hideand/actions/runs/36442117275
PR: https://github.com/egol82/hideand/pull/11

The interrupted conversation had already published the implementation and opened PR11. This retry recovered the exact CI source, inspected the implementation, downloaded and verified both operating-system artifacts, reran the new tests and fourteen matches, inspected the actual rendered images, and completes the delivery record. This follow-up changes documentation only, not gameplay or test predicates. Earlier pending-publication text is superseded by the observed results below.

## Actual execution environments

| Environment | Observed result |
|---|---|
| Original local Linux / Godot4.4.1 | All old runners,257 new hide/search checks,94 reused sync checks,default entry,14 matches and rendered states passed |
| GitHub Linux / official Godot4.4.1 | All old/new engine assertions,14 matches,9 real images and6-second staircase video passed |
| GitHub Windows headless / official Godot4.4.1 | Same old/new assertions and14 matches passed; no Windows GUI capture claimed |
| Separate historical CI / Linux4.4.1,4.7.2 and Windows headless4.7.2 | Original regression jobs completed/success; these jobs do not add evidence for the new257 checks on4.7.2 |
| Recovery Linux / Godot4.4.1.stable.official.49a5bc7b6 | Exact source imported;257 hide/search and94 unchanged sync assertions plus14 matches rerun, exit0 and HIDEPLAY_SUITE_PASS |

A fresh public download was unavailable in the recovery container, so the existing engine archive from the earlier attached tools package was restored. Its bytes matched the retained official SHA512 manifest before extraction and its runtime version was checked. No engine executable is included in the user source or evidence deliverables.

## Completion markers

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE4_UNIT_RESULT: 237 checks, 0 failures
QUALITY_UNIT_RESULT: 238 checks, 0 failures
GRAPHICS_UNIT_RESULT: 78 checks, 0 failures
MAP_PACK_UNIT_RESULT: 605 checks, 0 failures
GRIP_UNIT_RESULT: 198 checks, 0 failures
GRIP_SAFETY_RESULT: 17 checks, 0 failures
SMASH_UNIT_RESULT: 100 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
STUDIO_UNIT_RESULT: 108 checks, 0 failures
HIDEPLAY_UNIT_RESULT: 257 checks, 0 failures
PHASE4_SMOKE_READY
HIDEPLAY_CAPTURE_PASS
HIDEPLAY_SUITE_PASS
```

2,128 retained +257 new = **2,385 individual assertion definitions**, not independent human-play scenarios or a quality score. The repeated94 sync checks against the new scene are not counted twice. Counts include inherited110 language-field and30 audio-sample checks and repeated seed/site cases. The separate static-hygiene report has517 conditions and is not an engine assertion count. Process exit,required markers,script errors and timeout bounds are checked together.

## What is exercised

- Real CharacterBody3D motion up and down both ramp-backed stairs. No teleport is used to pass the stair tests.
- Three seeds test all12 manor hiding approaches and24 exit ports for capsule clearance,floor support,connected graph,repeatability and usable capacity.
- Actual hide/exit/ambush input; no synthetic free damage or invisibility attack. Ambush triggers the ordinary FIELD reveal and queued swing,then ordinary collision.
- Peek exposure needs actual hunter range,cone and line of sight. A wall can block discovery; hidden hands,nameplates and exposed-eye rendering are separated.
- An occupied exit is rejected. Destination eligibility is tested before contextual passage entry; the passage is not a general physics tunnel or full mid-transit collision solver.
- Decoy sound uses the stored deployed location,not the owner's subsequent position. Sounds preserve the correct floor height. Old footsteps/traces expire; no indefinite live-target radar.
- Three-second stationary listening and movement cancellation;normal0.65s inspection versus noisy immediate inspection;shared15s cooldown;role/charge-limited passage use and resets.
- Twelve manor candidates include two filled sites per round. Bounded furniture shifts and filled status shuffle without generating an untested new floor plan.
- Late-game30s/12s clues disclose a broad region by an explicit rule,not an exact occupied cabinet. This is soft search pressure,not a physical shrinking map.
- Tested active old-map hideouts also have different capsule-clear exit points. This does not guarantee two tactically independent escape routes in every inactive/full-map position.
- Extra contextual keys avoid existing saved bindings. Old storage,input,weapon/contact and graphical-profile assertions remain unchanged.

All approved proposals are mapped to their actual implementation and limits in `PHASE11.md`. The seventh map is new; the original Toy House and five other maps are preserved rather than silently replaced. Two floors,stairs,chute,private passage and positional shuffle belong to the manor; shared exit/peek/decoy/trace/search/pressure behavior is also available in old maps through the new entry.

## Fourteen complete fixed-seed matches

| Mode | Map | Rounds | Encounters | Hits | Captures | Escapes |
|---|---|---:|---:|---:|---:|---:|
| FIELD | toy_manor | 4 | 16 | 80 | 7 | 9 |
| FIELD | toy_home | 4 | 29 | 141 | 8 | 21 |
| FIELD | warehouse | 4 | 29 | 137 | 7 | 22 |
| FIELD | garden | 4 | 30 | 152 | 7 | 23 |
| FIELD | sugar_market | 4 | 39 | 188 | 8 | 31 |
| FIELD | starlight_arcade | 4 | 41 | 198 | 3 | 38 |
| FIELD | pocket_station | 4 | 48 | 238 | 4 | 44 |
| CLASSIC | toy_manor | 4 | 9 | 45 | 3 | 6 |
| CLASSIC | toy_home | 4 | 52 | 263 | 7 | 45 |
| CLASSIC | warehouse | 4 | 75 | 382 | 4 | 71 |
| CLASSIC | garden | 4 | 53 | 273 | 7 | 46 |
| CLASSIC | sugar_market | 4 | 63 | 312 | 5 | 58 |
| CLASSIC | starlight_arcade | 4 | 69 | 356 | 7 | 62 |
| CLASSIC | pocket_station | 4 | 70 | 346 | 7 | 63 |

The downloaded Windows and Linux JSONs agree. The recovery local rerun produced the same14 outcomes. Physics,bot movement,contact and match clocks execute; invisible presentation is skipped in headless autoplay. These figures verify repeatable completion,not human fun,fairness or optimal balance. In particular old-map escape-heavy counts still warrant human tuning.

## Exact source and rendered evidence

Both artifact SHA256 hashes matched the digests returned by GitHub:
- Linux: `7af17099af41ed2554c1528662456da3ac00160fb242cdf2ac57317847eb5958`
- Windows: `982cfabf5125291f5d5954fcc6ecece4df8841ca4916a704e9cf94ab9448e80b`

The source ZIP comment and commit marker identifyb4195839. All193 archived files were compared byte-for-byte with the restored source before updating this record: zero mismatches. LICENSE matches the earlier Phase10 source. Source packages omit engine/font binaries,.godot caches and personal saves. This documentation-only completion is newer than the exact CI code snapshot; game and test code are unchanged.

The Linux artifact contains9 actual1280x720 images:menu,living room,kitchen,stairs,upper floor,hidden view,peek,decoy and two-floor map. The H.264 staircase video is1280x720,30fps,6seconds and has no audio track. It uses actual input and CharacterBody movement from staged starting positions. Stills are deterministic staged engine scenes,not generated concept art or a manual play session. They were not repainted during recovery; original CI images were inspected and packaged. No new recovery-session renders are claimed. GitHub artifact retention is7days; separate downloadable copies preserve the delivered evidence.

## Earlier rejected attempts and remaining limitations

A blocked hardcoded staircase graph connection was replaced by a clear same-floor landing connection. A hearing test originally outside its own12m limit and an unreachable ambush fixture were corrected rather than adding free hits to the game. An earlier tool wait expired during a preview; only the completed final runner and observed markers count as evidence.

Hiding is a contextual camera/exit state,not a physically walkable cupboard interior. Peek is a constrained slit view;curtain traces do not simulate cloth physics. Passages are short authored transitions. Endgame narrowing is a zone hint rather than changing lights,locking rooms or damaging a circle. Furniture shuffle is bounded,not procedural rebuilding of the entire mansion.

Bots traverse stairs,inspect and follow genuine sound snapshots,with limited decoy/relocation behavior. They do not yet strategically select every new tool or special passage. The manor is original toy-style prototype art; no live baked GI was added. Human fun/comfort/accessibility/fairness,hardware FPS,Windows GUI/audio latency,full hand/arm IK,network multiplayer,Steam and a shipping executable are not validated. Existing cleanup/software-driver warnings remain.

The default entry is `scenes/phase11.tscn`. Main,previous PRs,LICENSE and repository visibility are unchanged. Recovery completes the feature-branch delivery rather than merging unrequested work.
