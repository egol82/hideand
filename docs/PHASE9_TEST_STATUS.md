# Phase 9 — verified smash / reaction evidence

Recovery and final verification: 2026-09-28.
Game/test source commit: `8b2ba4974910d39eefc51cc9549cb2db6880751e`.
Successful CI: https://github.com/egol82/hideand/actions/runs/36371333695

The interrupted implementation had already published the game code and completed CI. This follow-up recovered the exact source and artifacts, rechecked the primary reference sources, reran the new engine tests and all twelve new-entry matches locally, inspected actual stills, and completes the delivery/PR. It changes documentation only, not gameplay or test code.

## Actual execution environments

| Environment | Observed result |
|---|---|
| GitHub Linux / Godot 4.4.1 | All original and new assertions, entry checks and map/mode regressions passed |
| GitHub Linux / Godot 4.7.2 | Full assertions and twelve new-entry matches passed; eight Phase 9 stills and a six-second silent renderer preview generated |
| GitHub Windows headless / Godot 4.7.2 | All old/new assertions and twelve new-entry matches passed |
| Recovery session Linux / official Godot 4.4.1.stable.official.49a5bc7b6 | Exact recovered source: import, 100 smash assertions, actual default scene entry and twelve four-round matches passed again |

All three remote jobs were retrieved as completed/success. The local engine archive was verified against its official SHA512 manifest before extraction. The final local recovery runner exited 0 with SMASH_SUITE_PASS. Earlier capture steps were deliberately skipped in this Phase 9 CI; older engine/gameplay regression suites were NOT skipped. Do not describe the run as regenerating every historical screenshot.

## Completion markers and counts

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
PHASE4_SMOKE_READY
SMASH_CAPTURE_PASS
SMASH_SUITE_PASS
```

1,826 preserved + 100 new = **1,926 individual assertions**, not 1,926 independently designed human-play scenarios. Thirty of the new assertions concern generated audio length/amplitude headroom; the inherited total includes 110 bilingual field-presence checks. The independent static source-hygiene pass reports 424 conditions, not engine assertions. Completion markers, process return codes, script errors and timeouts are checked together.

## New behavior covered

- Actual mouse-handler attack plus swept geometry reaches the new presentation observer and applies the original one-hit damage; practice awards no match points.
- Hit, incoming hurt, blocked and miss outcomes stay distinct. Repeated delivery of one contact cannot multiply the VFX. Misses do not invent a target reaction.
- Visual-only reaction layer changes body art, not the weapon ancestry, original drawing, contact samples, world weapon transform, HP, score or clocks.
- Closed-form reaction poses agree at common elapsed time for 30/60/120Hz updates and return to rest. Hidden targets suppress following stars/face immediately.
- Reduced-motion or zero effect-strength clears new moving effects without changing authority state. Pause freezes presentation lifetime; reset clears particles, labels, audio and recent event identities.
- Final-hit exit echo appears only after the authoritative actor disappears and remains at the stored public contact transform. It does not track a hidden or respawn position and has no collider.
- Repeated hits do not grow scene-node count. Limits: 96 active particle slots, six labels, four reaction layers, four exit echoes, six sound voices and 128 recent contact identities.
- Generated audio is non-silent with sample headroom. This is not a real device/listening-quality test.

## Twelve complete fixed-seed physics/bot matches

| Mode | Map | Rounds | Encounters | Hits | Captures | Escapes |
|---|---|---:|---:|---:|---:|---:|
| FIELD | toy_home | 4 | 27 | 130 | 6 | 21 |
| FIELD | warehouse | 4 | 40 | 199 | 6 | 34 |
| FIELD | garden | 4 | 39 | 194 | 8 | 31 |
| FIELD | sugar_market | 4 | 31 | 147 | 7 | 24 |
| FIELD | starlight_arcade | 4 | 36 | 176 | 6 | 30 |
| FIELD | pocket_station | 4 | 34 | 160 | 6 | 28 |
| CLASSIC | toy_home | 4 | 32 | 159 | 8 | 24 |
| CLASSIC | warehouse | 4 | 40 | 205 | 8 | 32 |
| CLASSIC | garden | 4 | 38 | 198 | 7 | 31 |
| CLASSIC | sugar_market | 4 | 55 | 277 | 7 | 48 |
| CLASSIC | starlight_arcade | 4 | 73 | 368 | 6 | 67 |
| CLASSIC | pocket_station | 4 | 47 | 229 | 8 | 39 |

Remote Linux and Windows result files agree. The recovery session's local twelve-match rerun produced the same outcomes. Physics, AI, contact and timers execute; only invisible presentation is skipped in headless autoplay. These observations test regression, not better balance or increased fun.

## Exact artifacts and images

Downloaded artifact SHA256 hashes match the digests returned by GitHub:

- Linux: `fe47a984d8f71401d06e223738d805fe02d8a8be36f4eeda5b3b7fd062385110`
- Windows: `09c2ac1793e9c32f56898bb68201cc9b3e0f8259dfa5b277d74c5ebff0175aa3`

The source ZIP comment and phase9-source-commit.txt identify 8b2ba497. All 149 archived source files were compared against the recovered files: zero mismatches. No engine binaries, fonts, .godot caches or local saves are in the source archive. LICENSE matches the prior source and is not part of the gameplay diff.

CI artifact `godot-4.7.2-validation` includes the exact source ZIP, logs, match metrics, eight 1280x720 PNGs and `phase9_smash_demo.mp4`. The MP4 is H.264, 1280x720, 30fps, six seconds, with no audio track. The eight stills show before, balanced impact/rebound, heavy impact/rebound, finishing hit, blocked hit and reduced-motion mode. These are actual Godot Compatibility renderer scenes under Xvfb/Mesa software OpenGL with Dummy audio. The visual fixture injects reproducible contact events and disappearance; it is not manual player footage or proof of exact weapon-contact alignment. A separate gameplay test uses real input dispatch and swept collision.

Heavy-impact and finishing-hit stills were inspected during recovery. A comparison montage may crop/scale these images for presentation but does not add or repaint effects. The preview does not audition the synthesized in-game sound. Windows logs are a separate artifact. GitHub artifact retention is seven days.

## Reference review and boundaries

Party Animals, Boomerang Fu, Stick Fight's developer press kit, Fatshark's animation blog, GDC's Don't Juice It or Lose It and Microsoft XAG117 were rechecked during recovery. The references support design principles, not copied assets, measured competitor effect timing or proven causes of commercial success. See PHASE9_REFERENCE.md.

No human fun/comfort/accessibility session, hardware FPS or Windows GPU benchmark, actual audio-device audition, real-player networking, Steam/release EXE, fully skinned physical ragdoll/IK or commercial-art completion is claimed. All hit reaction motions are cosmetic; they do not add stun or change knockback/attack timing. Particles can intersect nearby geometry. Depth-tested labels and hidden-target guards are not proof of tactical fairness on every sightline. Legacy ObjectDB cleanup and software V-Sync warnings remain; the full suite is not described as warning-free.

Earlier scenes retain their earlier effects because they do not attach SmashDirector. The new default Phase 9 scene uses the observer. Main and prior PRs are not automatically merged.
