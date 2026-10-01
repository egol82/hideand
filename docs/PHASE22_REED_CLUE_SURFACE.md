# Phase22 — reed-clue surface visibility

Base: `c35feba78c5f259064cd6701f79c64196b27999c`, tree
`b250c573b543066b8d3ac4479a74236ccdff7781`, draft PR22. The user approved
this additional visual-only correction after the existing defect was shown:
in reduced-motion mode the finite reed trace lay below the decorative mound.

## Placement, without changing clue authority

The three existing clue meshes retain their mesh/material and pooled parent.
Each strand samples the actual rendered mound triangles. Its heading is fitted
to the local surface, then the complete rectangular footprint is clipped against
all overlapping triangles to obtain exact support, including facet seams and
rims. A 3 mm minimum contact gap avoids intersection. This is computed support,
not a universal height offset; wholly bare-ground strands retain their exact
authored transform. Floor clearance also bounds tilted ends.

Only the strand transform follows its sampled decorative mound's original sway.
The event point, track parent, sound position, 1.5-second lifetime, expiry order,
investigation, colliders and all water clues are unchanged. Surface bindings and
transforms are cleared on every reused slot and round reset. Existing terrain,
mound geometry, vegetation, materials, cameras and seed selection are untouched.

## Additive validation

- `test_reed_clue.gd`: 217 assertions, including 108 actual-mesh placement cases
  over all four tufts, nine inside/outside/rim positions and three headings;
  independent barycentric height checks; bent-origin rim sway/comfort clearance;
  the original buried-placement negative
  control; real movement, sway/comfort, pause, exact expiry; every one of 24 slots
  reused as water/leaves/ordinary/reed; reset and map change
- `capture_reed_clue.gd`: 27 assertions and nine actual images. Three normal
  1.48 m standing eyes, original FOV72, 1280×720, seed8027/RW-v1-2, real movement
  and reduced motion. Each live/expired pair requires at least 25 pixels over
  3/255 contrast and peak contrast32/255. Hiding only the clue must produce at
  most two changed pixels versus expiry, rejecting scene/UI noise
- Both are additive in `tools/test_wetland21.py`. The pixel suite runs with
  `--capture`; the existing Phase22 Linux capture job inherits it. All old tests
  and their assertions remain unchanged

Actual local Godot4.4.1 and4.6.3 integrated runs pass Wet105, North58, Polish16,
Reed217, Playability110, Pine126, Sync94 and entry smoke. Original expiry39 and
round-reset165 also pass on both engines. Static project verification reports
972/0. Godot4.4.1 was downloaded from the official release and SHA512-verified.

On Godot4.6.3, the exact baseline fails the three new visibility predicates
(0/0/0 changed pixels), while the corrected source passes (37/376/226 pixels
from south/east/north, peak contrast153/121/127). Hidden controls change zero
pixels over3/255. Godot4.4.1 also passes all27 pixel assertions, with37/376/226 changed pixels.
The original six-view render assertions also pass, including
water expiry and dynamic reed settling. These are actual softwareGL captures
from the dot cloud desktop, not simulated images or human playtest approval.

Independent scenery comparison confirms all302 WetArt nodes,290 mesh
instances/surfaces and164 distinct resources are identical, excluding only
non-rendering attachment metadata. Mesh arrays, transforms, materials, texture
pixels, visibility, shadows and GI settings match the exact baseline.

Independent review additionally tested968 position/heading cases and43,560
surface samples, then96 placements/four subsequent sway poses across all386
unique vertices per strand:444,672 vertex checks. No terrain penetration or
floor-clearance violation remained. An initial center-only tangent approach
was rejected because it could sink a strand end at the rim; the complete
footprint and floor guards address that finding. Its failing logs are retained
outside source, alongside corrected evidence.

Reproduction from the repository root:

```sh
python tools/test_wetland21.py --skip-import
python tools/test_wetland21.py --skip-import --capture
godot --headless --path . --script res://tests/wetland21/test_expiry.gd -- --quality-test
godot --headless --path . --script res://tests/seed21/test_round_reset.gd -- --quality-test
```

No new remote result, Windows validation, human acceptance, target-hardware FPS,
merge or deployment is implied by this local evidence. Existing manor shader
UID text-path fallback and software-driver V-Sync warnings remain. Generated
import defaults, caches, engine binaries, private saves and raw-frame dumps are
excluded from source delivery.
