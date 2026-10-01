# Phase22 — north island playability regressions

Base: `925d6d29178774f0e2097843c991c63f5f70515a`, tree
`33879ceaa0c0a91f16e08593f9acb34cdd1b90e3`. This increment changes tests and
their runner only. Gameplay, terrain, collision, graphics and clue code remain
byte-identical; every prior assertion is retained.

`tests/wetland22/test_playability.gd` promotes the independent runtime QA into
102 gameplay cases: four open corners walked and dashed in both directions,
two 32-waypoint perimeter circuits, 16 contact/retreat cases, 64 oblique slides
and 12 actual sight-discovery cases. The eight occluded sight pairs are fixed,
capsule-clear, in-range positions rather than a search using the ray predicate
under test. Open corners must both expose the ray and trigger discovery.

The real Phase21 scene uses seed 8027, round 0, RW-v1-2. Other fighters are parked
away; the automatic controller is frozen. Each original Fighter.step executes
once on a distinct 60 Hz physics tick and retains its actual move_and_slide.
Dash legs reset cooldown independently and require active dash ticks in both
directions. Walk reversals and perimeter waypoints retain momentum. Each
contact case must first collide with the actual north body.

Arrival budgets are 90 ticks per corner, 40 per perimeter waypoint or retreat;
slides have 90 ticks to make over 5 m tangential progress. Routes permit at most
0.20 m perpendicular deviation, eight consecutive sub-2 mm movement ticks and
0.12 m vertical displacement. These physics/distance assertions have margin for
engine/platform differences; elapsed wall time is not a gameplay assertion.

Four controls use a disposable independent World3D and the same real Fighter
and predicates: an empty route passes; restoring a 7×6×2 m square box forces a
corner detour and fails; a wall prevents arrival within 90 ticks; a blocked
slide fails its progress/stall bounds. No control mutates production nodes or
source. Together with three fixture checks and a count guard, the suite has
110 assertions and writes `ci-artifacts/wetland22-playability.json`.

`tools/test_wetland21.py` runs the suite headlessly with `--fixed-fps 60`, so
the existing Phase22 Linux/Windows and 4.7.2 jobs inherit it without another
workflow or long match matrix. A local Godot 4.6.3 run took 14.1 s for 110/0; the
integrated runner passed Wet105, North58, Polish16, Playability110, Pine126,
Sync94 and entry smoke in 42.9 s. Local performance is informational, not a CI
limit or hardware benchmark. Cross-platform/4.7.2 confirmation remains CI's
responsibility.

```sh
godot --headless --path . --editor --import
python tools/test_wetland21.py --skip-import
```

Final accepted logs have no engine/script errors; the existing manor shader
UID text-path fallback remains. Earlier local environment-path and script
inference failures are retained as rejected iterations outside source.
Generated import defaults are restored, and caches, logs and private saves
are excluded from delivery. No merge or deployment is part of this change.
