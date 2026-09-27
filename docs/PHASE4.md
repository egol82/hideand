# Phase 4 — audit-driven reliability and feel

2026-09-27. This implements the supplied production audit, not a claim of finished production art.
Default scene: `scenes/phase4.tscn`. Earlier scenes and their source remain unchanged for comparison.

## 4A — four reproduced defects

| Audit | Phase 4 implementation | Regression evidence |
|---|---|---|
| P0-01 cumulative aim | `fighter.gd` owns absolute weapon transforms. View and authority consume `attack_spec.gd`. No additive pitch feedback. | Fixed 0.6 rad aim for two seconds at 30/60/120 Hz step intervals; no accumulation. |
| P0-02 escape farming | Escape +1 only once per hider per round; survival +3; never-found +2. Capture +3, all-caught seeker bonus +2. | Three escapes plus survival = 4, never-found survival = 5. Round awards are idempotent. |
| P0-03 incoming hit marker | Explicit attack ID, attacker, target, world point, normal, surface and outcome. Outgoing/incoming/blocked/miss are separate. | Opponent hit does not light outgoing marker; bot-vs-bot contact is not a human hit. |
| P0-04 comfort changes time | No presentation freeze in Phase 4 authority update. Reduced motion, sway, bob and contact animation affect only presentation. | Equal authority time for reduced-motion on/off after identical contact. |

These fixes apply to the new default Phase 4 game. Preserved historical Phase 3 code is not silently relabelled as fixed.

## 4B — representative scene and first-person handling

- Authored rounded meshes, smooth continuous vinyl body, simple eyes/mouth/ears and mitten-like thumb/cuff/grip geometry.
- Related but different material families: foam, vinyl, painted wood and fabric. Warm main/fill lighting and a small lounge with sofa, pillows, tables, lamps and framed shapes.
- Canvas, preview and equipped weapon use the original player vector paths. No paid assets, external image API or pre-made weapon substitution.
- Safe simple loops may become foam solids. Nested/intersecting contours remain outlines rather than incorrectly filling holes. Filled-area budget 2.6 world-square-units plus the existing reach/ink/point budgets.
- Quick/balanced/heavy handling changes windup, active, recovery, movement factor and knockback; all remain one damage per hit. Values are test hypotheses, not measured industry standards.
- A 100ms input buffer expires if pressed too early. Same attack timeline drives world and view presentation. Cosmetic weapon scale does not change hit reach.
- Swept sampled geometry against a moving capsule, obstacle tests toward contact instead of target centre, blocked swings and duplicate-hit protection. This is bounded approximate collision, not exact continuous arbitrary-mesh collision.
- Immediate mouse rotation; interpolated body translation; revision-based weapon caching replaces per-render drawing JSON serialization.
- Seven wall probes replace the single central probe. This is improved coverage, not a guarantee against every possible drawing's clipping.
- Compact nonblocking HUD, incoming direction cue, distinct outgoing/blocked markers; bounded 64-instance impact effect pool.
- Project-authored layered procedural sound variants, 12 spatial voices, footsteps, hide/taunt sounds. Sound-device quality has not been human auditioned in CI.
- Separate comfort controls and volume. Silent/reduced settings do not alter noise events perceived by bots or authority timers.

## 4C — playable comparison, not a proven design winner

Default `field`: 0.55s reveal at the discovery location and an 8s skirmish. No centre teleport, no human camera takeover. Other surviving hiders can keep moving/hiding. One seeker encounter is resolved at a time; uninvolved players do not deal damage in that encounter. Search time keeps running. Survive the interval or KO the seeker to escape; there is not a new distance-based escape win condition.

`classic`: centre arena, 5s duel, other participants paused as an explicit comparison rule. Both modes share the corrected score/feedback model. Draw time remains 25s.

Large worlds are retained. Optional four-player active zones fence and restrict navigation/search to connected tested regions:

| World | Full size | Compact playable zone |
|---|---:|---:|
| Toy House | 24 x 20 | 24 x 20 |
| Warehouse | 48 x 36 | 26 x 32 |
| Garden | 80 x 56 | 54 x 36 |

Public hideout locations remain stable IDs. Only active locations are assigned/searched. The title screen shows active/total counts. The map never reveals opponents. Actual footsteps emit short-lived approximate area clues; Ctrl quiet movement reduces clue distance. Deliberate C taunt exposes an area clue. Captured players still spectate the seeker; a next-round drawing/assist activity is deferred.

## Persistence and inspection

Eight bounded local toy slots include handling and use temporary-file replacement. Input size, finite coordinates, points, strokes and ink limits remain enforced. Phase 4 uses separate storage and does not overwrite older slots. Optional local metrics default OFF; bounded event metadata excludes drawings, names and network addresses. They export to `user://phase4_session.json` after a complete match when opted in. These are diagnostics, not remote analytics.

`tools/export_toy_room.gd` saves an editable snapshot under `user://phase4_toy_room.tscn`. This begins an editor-authoring path but is NOT a UV2/lightmap bake or a production asset pipeline. The live game still constructs its map in code.

## Still deferred

Baked indirect lighting/UV2 authoring, high-end character rig/IK, polished professional sound assets, manual fun/balance tests, real four-PC networking, Steam integration, gamepad/remapping/localization, distribution EXE, Windows GPU performance, next-round activity for captured players, public weapon sharing and full 4E art expansion. No success rate/FPS/art-percentage claim is supported by automated checks.
