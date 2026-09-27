# Phase 7 — original playful map pack

Default entry: `scenes/phase7.tscn`. Builds on Phase 6, with the same Godot/GDScript controller, original drawn weapons, field/classic modes, practice, remapping and local storage. New map code lives in `scripts/maps/`; it does not add another gameplay inheritance layer.

## Playable maps

| ID | UI name | World dimensions | Hideouts | Hide / seek seconds |
|---|---|---|---:|---:|
| sugar_market | 슈가 마켓 / SUGAR MARKET | 30 × 26 | 10 | 17 / 105 |
| starlight_arcade | 별빛 오락실 / STARLIGHT ARCADE | 40 × 32 | 14 | 21 / 135 |
| pocket_station | 포켓 기차역 / POCKET STATION | 52 × 40 | 18 | 26 / 165 |

The three previous maps are preserved. New maps are purpose-built for 1 human + 3 bots and are designed to use the entire authored region; pacing still needs human testing. Compact/full toggle deliberately leaves their topology unchanged. All modes, old maps and saved map IDs remain supported through a six-ID whitelist.

## What changes decisions

- Sight-blocking cake/cabinet/carriage islands and traversable loops around them.
- Loud striped terrain emits a distinctive chime-style footstep and expands the public noise radius to 1.65 × normal. Quiet mint/blue runners use soft steps and 0.5 × radius. On a normal walking step this is 13.2m versus 4m. These are test values, not human balance evidence.
- Ctrl quiet movement multiplies the base range from 8m to 3m before terrain. Audio volume and comfort options never change bot hearing. Only the existing real-footstep handler emits the approximate area clue; hidden actors, idle actors and teleport corrections do not produce phantom footsteps.
- Menu previews and in-game map legends explain public terrain. They never receive opponent positions/occupancy. English/Korean main labels and tips are supported; some world signs remain English.

## Art and implementation

`plans.gd` is the single layout source for solid footprints, hideouts, approaches, coloured landmarks and terrain. `builder.gd` produces the world mesh, conservative blockers and navigation together. `props.gd` supplies original rounded pastries, cabinets, a planet display, parked carriages, kiosks, clock and containers using the existing cached toy materials. No paid asset pack, copied layout or runtime generation API is used.

Stable IDs normalize punctuation before creating scene nodes; metadata retains a single identifier across visual/collider/plan. Indoor maps have walls and ceilings; the station has a closed outdoor boundary. Decorations below feet or overhead do not introduce unlisted walking blockers. The collision representation is intentionally conservative, not per-triangle furniture collision.

The graphics director reuses its world Environment while applying theme values. Recreating Sky environments on each scene refresh exposed a software-GL shutdown texture leak; reusing the same environment removed the observed errors. Loudness is functional; signs, pennants and ceiling stars are static and cannot reveal occupants. Sky/lighting is stylized, not baked GI or a commercial-art claim.

## Where to edit

- `scripts/maps/catalog.gd`: IDs, dimensions, UI copy, timing.
- `scripts/maps/plans.gd`: geometry, hideout/access positions, sound regions.
- `scripts/maps/props.gd`, `builder.gd`: visual construction, paired collision.
- `scripts/maps/preview.gd`, `board.gd`: public tactical view only.
- `scripts/phase4/game.gd`: integrates map selection and public terrain into existing footstep events.
- `tests/maps/test_maps.gd`: maps, every hiding approach, actual E interactions, clue handling and loops.
- `tools/test_maps.py`: tests, default entry, six four-round fixed-seed matches and optional actual render capture.

## Limits

No moving platforms/trains, jump-dependent routes, multilevel traversal, parallel multi-party combat, online/Steam, release EXE, professional sound audition, Windows GPU/FPS or manual fun/accessibility evaluation was added. Captures are staged engine scenes. Overviews temporarily hide only the ceiling for a diagnostic cutaway; ordinary FPS gameplay always keeps the ceiling. New environment geometry is an improved procedural toy prototype, not finished commercial art.
