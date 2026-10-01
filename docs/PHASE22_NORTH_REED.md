# Phase22 — Reedwater north landform

This increment starts from the user-selected, CI-passing checkpoint
`c46581a47079f70d7d53c6698d5906e96f88270f`, on
`phase22/wetland-art-slice` and draft PR22. It does not use the later rejected
web candidates. The historical checkpoint record describes earlier iterations;
this document records the approved north-only collision exception.

## Approved scope

Only Reedwater Bend's `reed_north`, centered at `(0,-7)` within its original
7×6m footprint, changes its opaque terrain and physical shape. Its old 2m
`BoxShape3D` is replaced, not retained alongside the new collider. The south
island, other maps, water, clues, camera, seeds and services are preserved.

`north_reed_profile.gd` authors four irregular elliptical rings (64 points),
from ground to a 1.90m crest. Godot's convex hull supplies both the physical
`ConvexPolygonShape3D` and all 108 visible terrain triangles. Mud and moss
occupy two material surfaces of that same closed mesh; no elevated moss plate
or second enclosing box is created. Geometry is cached, deterministic and
independent of match RNG. Outward normals and upper-surface moss are checked.

The original 24 stems, 24 heads, 12 leaves, five moss tufts and six roots remain.
All 35 planting anchors sample the actual hull height. Reed heads/leaves share
their tilted stalk frame. Roots follow the bank gradient and embed in soil.
The old nonphysical water skirt is reused without changing its geometry.

The original conservative navigation rectangle remains unchanged. It is an
AI clearance margin, not a physical wall: four removed square corners are
ray-tested to the original floor. Existing routes, ports and seeded sockets
keep their full prior checks. Layer1/mask0 are retained on the new static body.

## Integration and validation

The shared `tests/pine21/test_pine.gd::geometry()` serializes Convex points as
sorted integer coordinate tuples at 10µm precision, alongside every existing
shape and world transform. Wetland comparison replaces only the uniquely
identified north collider with an independent exact point contract. It still
requires the complete remaining geometry and exactly two selected Seed21
boxes/rectangles; no old predicate is removed or filtered arbitrarily.

The dedicated `test_north.gd` checks 58 predicates: serializer ordering and
displacement, exact live profile, a single enabled body/shape, original layer
and mask, hull/render congruence, normals, all planting anchors and decoration
counts, physical surface heights, open old corners, occlusion and clearance
above the new crest. `tools/test_wetland21.py` runs it on both CI engines.

An additional local comparison instantiates all ten maps from actual `c46581a`
and current source, recording shapes, layers/masks, navigation solids, obstacle
rectangles, hide entries/exits, spawns, plans and sound zones. Only the north
shape data and its local origin height (old box center1m → hull origin0m)
differ. Its helper scripts and JSON evidence are retained under
`ci-artifacts/phase22/`.

Actual commands (from repository root; `GODOT_BIN` is an official Standard
engine, verified against its SHA512 manifest):

```sh
"$GODOT_BIN" --headless --path . --editor --import
"$GODOT_BIN" --headless --path . --script res://tests/test_weapon.gd
python tools/test_wetland21.py --skip-import
python tools/test_seed21.py --skip-import --matches --regressions
python tools/test_seed21_rounds.py --skip-import
```

Local graphics use Xorg's existing dummy driver with Mesa llvmpipe. For each
exact source snapshot, with `DISPLAY` pointing to that display:

```sh
"$GODOT_BIN" --path . --audio-driver Dummy --rendering-method gl_compatibility \
  --fixed-fps 30 --script res://tests/wetland22/capture_checkpoint.gd -- \
  --quality-test --match-seed=8027 --prefix=before
# Current source uses the identical command, with --prefix=after.
"$GODOT_BIN" --path . --audio-driver Dummy --rendering-method gl_compatibility \
  --fixed-fps 30 --script res://tests/wetland21/capture.gd -- \
  --quality-test --match-seed=8027
```

The close/mid/gameplay manifests match seed8027, round0, RW-v1-2 layout,
1280×720, all camera transforms/FOV and actor transforms. Actual inspected
images show the large square cliff replaced by a rounded muddy bank and
domed moss summit with planted reeds/roots. The preserved rectangular water
skirt remains. Movement-produced water rings disappear and reeds return to
rest in actual rendered pairs (RGB mean changes 0.000303965 / 0.004525621).
Comfort retains finite visible clues. This is rendered evidence, not a claim
of human acceptance or hardware performance certification.

## Evidence limits

The supplied run36839243956/artifact11150499311 metadata confirms exact
`c46581a` and successful Linux/Windows jobs. Its ZIP download host
`productionresultssa2.blob.core.windows.net` returns proxy CONNECT403; original
remote pixels could not be downloaded or inspected. The local before images
are a fresh actual engine reproduction of that exact commit, not extracted
from the remote artifact.

Known warnings are the preserved manor shader UID text-path fallback and
software-display Vsync availability. No engine/script/shader error is accepted.
Godot4.7.2 editor import adds two compression defaults to a tracked manor
import file; those unintended changes are restored and original asset/GI
manifest hashes checked before delivery. Engines, caches and personal saves
are excluded from source delivery. Final test counts and exact remote HEAD/CI
are reported with the PR; publication does not imply merge or deployment.
