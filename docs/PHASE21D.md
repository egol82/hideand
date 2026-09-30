# Phase21 final increment — reproducible safe round layouts

Base source: `1cfdfd70eb7183807a381c1d74b35f8008d1bbf3`, exact tree
`b7275d6e3e3da0c5777b2161b0ff93f873235431`. Same `phase21/living-nature`,
stacked draft PR21 against `phase20/nature-playgrounds`. No rebuild of earlier milestones.

## Reuse the existing round seed, do not add a competing random generator

The original game already chooses fake hideouts and manor parcel positions from
`match RNG seed + round_index * 991`. That code and call order are unchanged. The new game
adapter parks its own props before the inherited `_prepare_round`, lets the original service
reset budgets/clues and move players to their existing spawns, then installs two route-cover
bundles while still in DRAW. No layout changes are accepted during active chase/combat.

`layouts.gd` maps the UTF-8 map/seed string through bounded integer arithmetic; the round index
selects a versioned combination. It uses no RandomNumberGenerator or global random call. Same
map/seed/round returns the same positions even if AI, audio or art consumes random numbers.
There are three pre-authored sockets for each of two props: nine combinations per nature map.
Consecutive rounds select different combinations (period nine). Different seeds can select the
same one of these finite nine choices; unique arbitrary-seed layouts are not promised.

`--match-seed=8027` explicitly sets the existing match RNG seed for reproduction before a match
starts. Without that argument the previous game randomization is retained. `ROUND_LAYOUT21`
JSON records the match seed, original round seed, map, round, versioned layout ID, positions,
size and fingerprint. A small read-only in-game line shows seed / round / layout ID. No enemy
positions or private occupancy information are added to it. The existing public map reads the
same updated obstacle rectangles and therefore includes the two props.

## Actual route change, bounded scope

Two 1.6 x 0.85m, 1.65m-high solid toy bundles are placed at one of three sockets each:
- Pine: west/east approaches around the existing great tree; original leaf strips stay free.
- Reedwater: west and east island flanks, outside water/reed response strips and the boardwalks.
- Canyon: a western inner approach and northeastern approach; the original exposed lane and
  both gust pads remain free.

Their position changes actual depth-tested cover, capsule collision and AStar paths. The
27-template test finds a real pair of reachable endpoints whose shortest grid route is longer
than without the prop, and walks a detour with the unmodified CharacterBody on every map.
The change is not a color shuffle or an unused random variable. These are optional small
obstructions, not new hide-in containers, rotating gates, movable mid-round walls or new maps.

Every candidate is checked against original conservative obstacles, all surface mechanisms,
spawn/entry/exit clearance, central duel pad, boundary, canyon lane and gust pads. A temporary
navigation grid must have one connected free-cell component. A physical box query rejects an
unexpected occupied socket. Invalid future geometry leaves the original routes open and logs
`ROUND_LAYOUT21_REJECT`; it does not silently choose a new random outcome or move occupants.
All27 shipped combinations pass those checks. Added cover stays visible at all detail distances.

Two pooled physics bodies and twelve visible meshes are reused per arena; there is no per-frame
layout allocation. Removing them removes only their two rectangles. Navigation is explicitly
cleared before rebuilding: calling update with unchanged AStarGrid2D dimensions otherwise retains
stale solid cells. The new guards and tests caught that during implementation. Original landmarks,
trunks/islands/mesas, hideout geometry, two-exit handling and permanent alternate loops are retained.
Tiny top parcels are decorative and are not additional colliders.

## Preservation and honest contract extension

Pine leaves and shared4s bush allowance, Wet3s water/1.5s reeds and expiry-order fix, Canyon lane
and bounded gusts remain byte-identical. Every new round uses their existing reset method; no
new timers or damage/score/random-win logic. Seeded route choice can legitimately change bot
encounters and match results. Tests check rule invariants and deterministic layouts, not forced
score equality with a map that has no extra cover.

The old Wet test compared every live collider with Phase20 before seeded colliders were authorized.
That ONE predicate now requires the complete numeric original geometry PLUS EXACTLY the two
selected box transforms/sizes and navigation rectangles. It does not skip arbitrary colliders or
turn the test into a count-only check. All other old predicates remain. Menu-state10-map checks,
27-template protection tests, actual movement and all existing Phase21 mechanism suites remain.

## Actual verification and delivery

Run `python tools/test_seed21.py --matches --regressions`. It runs the new340 assertions,
unchanged Canyon289/expiry39/Wet101/Pine126/sync94 tests, default scene, all10maps x2modes,
and affected hide257/map612/outdoor262 regressions. Recorded four-round layout manifests must
match between FIELD/CLASSIC; both have the same seed and do not consume each other's RNG state.
This is in addition to existing inherited GitHub PR regression. Exact observed execution/CI
results belong in the PR and delivered logs, not inferred from this checklist.

`--capture-only` under Xvfb produces nine actual images: two same-camera round layouts plus a
capsule-clear first-person view per nature map. Pixel differences must be nonzero for the three
layout pairs. The actor-free aerial view is a diagnostic capture, not a new in-game camera.
Renderer counters on software OpenGL are descriptive only, not hardware FPS/VRAM benchmarks.

The source ZIP, full-index new-file patch, incremental Git bundle and log/render evidence are
saved before remote writes. Branch publishing uses supported GitHub tools without a merge,
deployment, token request, paid service or separate Cloud Codex/notebook environment.

## Limitations

Nine bounded combinations per map are not arbitrary procedural terrain. Original hideouts keep
their own existing seed selection; new props do not create invulnerable/indefinite hiding. Generated
art remains stylized prototype art. Human fun/balance/readability/audio comfort and actual user
hardware performance remain UNVERIFIED. The approved Phase21 scope is six natural interactions
plus this bounded round variation; further game features are not part of this increment.

API basis: pinned Godot4.4 AStarGrid2D (clear before rebuilding fixed-size solids), physics shape
queries and the original project lifecycle. A dedicated integer selection avoids depending on
Godot's documented implementation-detail RNG algorithm for versioned socket selection.
https://docs.godotengine.org/en/4.4/classes/class_astargrid2d.html
https://docs.godotengine.org/en/4.4/classes/class_randomnumbergenerator.html
