# Phase 3 — first person and three maps

## Scope

Built on Phase 2 without replacing its scripts/scenes. The default is now `scenes/phase3.tscn`. One human + three bots, offline only. This is a first-person camera/control change, not a PUBG asset/weapon/royale reproduction.

## Maps

| ID | Dimensions | Hideouts | Hide/search seconds | Structure |
|---|---|---|---|---|
| toy_home | 24×20 | 8 | 14 / 80 | connected rooms and partial partitions |
| warehouse | 48×36 | 14 | 22 / 135 | shelf aisles, lockers and crossing routes |
| garden | 80×56 | 24 | 32 / 210 | open garden paths, hedges, trees and arches |

Dimensions are authored world units, presented as metres. Both indoor maps have ceilings and four physical boundary walls. The garden is outdoors with boundary walls. All maps are single-level; there are no jump, climb, drive or procedural terrain systems. The central 7.5×7.5 duel area is reserved, with all hideouts outside it. All three map layouts and all 46 hideout approach points are tested for nav reachability and capsule clearance.

Each blocker is paired with an inflated navigation rectangle. The grid covers the full map; the bot tour orders publicly known hideouts by distance and never uses hidden occupancy to choose the next target. More space does not silently enlarge player movement/weapon reach. These remain four-player maps; pacing on the garden still needs human testing.

## First-person rules

- Eye-height perspective camera, captured raw mouse movement, yaw-relative movement, normalized diagonal speed, pitch clamp.
- Visible original drawn weapon and two rounded toy hands. Self body/nameplate excluded using a render layer, not by hiding other players or disabling physics.
- Native aim reticle, compass, focused E prompts, damage feedback. Discovery requires range, a forward view cone and a clear wall ray.
- The view weapon is a **cosmetic copy** built from the same canonical data and geometry routine. Camera display scale does not change real range or hit geometry. World weapon yaw/pitch and swept hit samples remain authoritative. This is not a full IK hand/weapon simulation; cosmetic/world motion can differ and needs feel tuning.
- Nearby-wall probe lowers/retracts the view model; extreme proximity hides it rather than drawing through a wall. This is a central-ray mitigation, not exhaustive per-vertex collision for every possible drawing.
- Mouse is released for drawing/menu/pause/focus loss/exit. Sensitivity, vertical field of view (55–90°), invert Y, reduced motion and volume save under user://.
- M displays a paused map with static obstacles, public hiding places and **own** location only. No other-player or hidden-occupant coordinates.
- If two other players duel, or the human is captured, the camera spectates the seeker with an explicit label. It returns to the human when applicable. Free spectator roaming is not implemented.

## Match continuity

Map-specific hiding/search timers, dynamic hideout assignment, four rotating-seeker rounds, original scoring and 5-second duel rules are retained. On discovery the two duelists move to the central arena, face each other, and remain in first person. An escaped player returns to a reachable point near the original encounter rather than being teleported to the centre of a large map.

## Modules

`map_catalog.gd`: whitelisted dimensions/timers/prop locations.
`arena.gd`: geometry, physics blockers, navigation, hideouts.
`first_person.gd`: camera, mouse look, cosmetic original-drawing weapon and hands.
`fighter.gd`: local view layers and world weapon aim.
`game.gd`: composition, focused interactions, first-person discovery, dynamic maps, spectator flow and regression harness.
`interface.gd`, `reticle.gd`, `map_board.gd`: playable native UI.
`preferences.gd`, `match_rules.gd`: bounded settings and map-specific timings.

## Validation commands

```text
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/phase3/test_phase3.gd -- --phase3-test
godot --headless --path . res://scenes/phase3.tscn -- --phase3-smoke
godot --headless --fixed-fps 60 --path . res://scenes/phase3.tscn -- --phase3-autoplay --map=garden
godot --path . --audio-driver Dummy res://scenes/phase3.tscn -- --capture-phase3
```

Headless autoplay skips invisible camera/UI work only; it runs the same physics, bot decisions, rules and combat. Fixed seed 8027 is an engineering regression, not a fun/balance benchmark. Screenshot mode deliberately stages documented scenes; it is not proof of a human playthrough. Tests use input-handler calls, not OS cursor automation.

## Not included / remaining

Online/P2P, Steam SDK, controller, Korean localisation, release EXE, terrain/elevation, crouch/jump, FPS guns/ADS/reload, full-body IK, expensive assets, generative-runtime APIs and new artwork generation are absent. Matte procedural graphics are intentionally honest prototype assets. Actual audio device output, live Windows GPU, human mouse feel, motion sickness and balanced large-map pacing need hands-on testing.
