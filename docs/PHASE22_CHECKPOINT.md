# Phase22 checkpoint v5 — sculpted wetland cover and shoreline replacement

This v5 source starts from the clean CI-passing v2 checkpoint and replaces only
Reedwater Bend art code and this note. No GitHub push or Godot process was run
in this WEB turn; runtime and pixels remain unverified here.

## Preserved baseline

- Phase21 base commit: `8737d6e2009f28990e554ffa6c81c5650237afb5`
- Published v2 Phase22 tree: `bc60b2d99330513bef78b6423fbcaae040edbaa9`
- Local v2 source ZIP SHA256 used as input:
  `fd5693ace3dfe152c75203d8ee5a8c3c2f10ab1f7ba0e23d00cd2de14bdb8716`

## Scope of v5 changes

Modified files only:

- `scripts/outdoor20/builder.gd`
- `scripts/wetland21/art.gd`
- `docs/PHASE22_CHECKPOINT.md`

No other gameplay scripts, tests, workflows, weapons, hand proportions, seed/
round logic, collisions, navigation rectangles, ports, spawns or clue timings
were intentionally changed.

## Art changes

### 1) Reed islands / rock cover in `builder.gd`

- Replaced the large visible boxy reed and rock masses with SurfaceTool-built
  closed meshes composed of multiple horizontal rings plus top and bottom caps.
- The contour generation is based on a square/super-rectangular footprint,
  not an ellipse, so the generated opaque shell encloses the original box
  collider footprint instead of shrinking away from the corners.
- The collider itself is unchanged and is still created by the original
  `Toy.collider(...)` path.
- Added irregular low water skirts, shoreline mud and moss cap shaping to the
  reed islands while keeping them purely visual.
- Rock cover now uses a guaranteed enclosing main closed mass and overlapping
  secondary lobes for visible ridges/surfaces.
- Large cover materials now use tuned `plaster`/`ceramic`/`foam` variants so
  the prior dominant `fabric` tiling does not drive the whole mound face.

### 2) Wetland shoreline in `wetland21/art.gd`

- Replaced the previous box-and-row shoreline treatment with low-profile,
  irregular closed meshes for shore, damp margin and water surface.
- Surface zones, clue/service logic, audio, `wet_print`, `reed_print`, tuft
  bending and all no-physics constraints are preserved.
- Water visuals remain shallow and non-blocking; no hidden walls or collision
  objects are introduced.

## Source-level validation performed in this WEB turn

Python-only validation was run on the final bytes after writing the files:

- duplicate top-level function names: checked
- nested named function definitions: checked absent
- mesh generator sample validation (mirrored in Python):
  - triangles are non-degenerate
  - every undirected edge in closed sample meshes is paired exactly twice
  - reed and rock sample meshes span from ground `y=0` to above collider top
  - square-footprint coverage was checked at the original collider corners
  - shoreline meshes remain low-profile
- final ZIP / patch / file-hash manifests were regenerated from the written
  final bytes

## Important limits of this turn

- Godot parser validation: **NOT run here**
- Godot scene runtime / actual rendering: **NOT run here**
- CI / screenshot comparison: **NOT run here**

The next approved step is external publication of these exact bytes followed by
real engine execution and image review.
