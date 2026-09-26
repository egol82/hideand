# Phase 2 architecture and handoff

## Implemented scope

Offline four-participant match (one human, three bots), six prop hiding locations in one 3D room, rotating seeker, drawing, timed hiding/search, reveal, five-second duel, capture/escape and a four-round score screen. The human can begin as seeker or hider. On capture the human spectates until the next round. The previous valid custom weapon survives round transitions and restarting from the title.

### Initial tunables

| Rule | Value |
|---|---:|
| Drawing | 25 seconds |
| Hiding | 10 seconds |
| Searching | 65 seconds (paused during a duel) |
| Reveal | 1.2 seconds |
| Duel | 5 seconds, 3 hits to knock out |
| Escape grace | 5 seconds of search time |
| Participants / rounds / hiding spots | 4 / 4 / 6 |

A discovery transfers the two duelists to the central rug. Other players stop. The seeker returns to the discovery position afterward; an escaped hider gets a clear re-entry point and a head start. This is an explicit prototype rule, not seamless world-space group combat. Duel timeout and simultaneous KO favor the hider.

## Code map

| Module | Responsibility |
|---|---|
| match_rules.gd | Pure phase/time/life/score authority; no engine scene references |
| game.gd | Scene composition, input, bots, discovery, duel orchestration |
| arena.gd | Six hiding locations, aligned collision/navigation bounds, AStar paths, line of sight |
| fighter.gd | Existing actor extended with match-controlled life, hiding, names, weapon reveal |
| combat.gd | Relative-motion sampled strikes, per-swing deduplication, wall checks, dash immunity |
| drawing_data.gd | Backward-compatible drawing flag for closed-loop fill |
| weapon_form.gd | Bounded simple contour detection, triangulation/extrusion and matching interior hit samples |
| drawing_canvas.gd | Drawing input reuse, fill preview, throttled 3D update signal |
| weapon_library.gd | Eight validated local JSON slots, temporary-file save then rename |
| interface.gd | Native UI, drawing/preview, menus, help, results and HUD |
| sound_bank.gd | Six short effects synthesized locally |
| preferences.gd | Volume, reduced motion and local best score |

## Deliberate limits

- No network transport, Steam integration, online services, gamepad support or Korean UI yet.
- New weapons are shallow foam-like extrusions, not full semantic 3D reconstruction. One loop per stroke; no hole subtraction. Unsafe, self-crossing or oversized contours keep their tubes.
- Collision is a bounded sampled sweep against the target center, not exact arbitrary-mesh continuous collision. Thin features/extreme movement need additional testing.
- Navigation obstacles are hand-aligned with this one procedural room. Moving furniture or new maps require updating these bounds.
- No weapon-stat build system beyond bounded reach/shape; attack damage and cooldown are shared. Optimal-shape balance is not solved.
- Current bots and five-second timeouts favor escaping. Automated success means the match terminates, not that the balance is enjoyable.
- UI is English and mouse/keyboard. 1280×720 captures are checked; small windows, DPI, ultra-wide and accessibility require a device matrix.
- Save/settings APIs return errors, but interrupted writes and Windows permissions need explicit failure-injection tests before shipping.
- Generated mockups are visual references, not a promise that this procedural prototype matches their quality.

## Next priorities

First play a full match manually as both roles, including starting/restarting, pause while drawing, empty ink, long/crossed lines, capture and escape. Tune the duel balance and camera from recorded sessions. Next improve avatar faces/poses, rounded furniture and weapon grip orientation while preserving input geometry. Only after a stable local loop should networking be introduced, with authoritative match state and validated drawings.

Do not expand all of these at once. Keep the current independent rules module and regression tests intact.
