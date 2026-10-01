# Phase22 checkpoint v2 — targeted geometry and capture corrections

This is a minimal correction of the preserved first Reedwater Bend checkpoint,
not a new art pass. No GitHub operation or local Godot process was run for v2.

## Immutable inputs

- Phase21 base: `8737d6e2009f28990e554ffa6c81c5650237afb5`
- Phase21 tree: `8239be06e4a85f47987fdf06e6f10c30769725b2`
- Preserved v1 source SHA256: `e7e6500ecf0b55f92dec2db200190fa6ac6e8eaf43345cef394737370108fbdb`
- Preserved v1 patch SHA256: `a393684b3dfffa55aad6e757952af53b574f051bf2a24c0aed1d71638cf7866c`

## Targeted corrections

1. Reed and rock cores now contain the complete original collision box. The
   existing rounded-mesh helper receives the collider dimensions plus 0.12m on
   each axis and a 0.06m bevel, leaving its inner box equal to the collider.
   For 2m cover the continuous opaque core reaches 2.06m, including the former
   upper-corner gaps. Existing crown pieces are raised to retain the stepped
   mud/stone profile. Reed feet around 1.88m overlap this solid soil.
   Collision shapes, layers, masks, navigation rectangles and hide ports are
   unchanged; this is not a reduction of the 2m collider.
2. Reedwater boardwalk backing is lowered to a 0.002m top. Planks are 0.04m
   thick while retaining the old 0.0425m deck top. Exposed side rails, posts
   (0 to 0.055m) and cross-beams (0.002 to 0.024m) replace buried supports.
   Structural pieces are not culled as small grass. This remains a shallow
   cosmetic walkway over the original flat floor, not an elevated bridge.
3. The comparison fixture reuses Wetland21's map/menu render-flush ordering
   before starting a match and waits for real PhysicsServer placement. It
   restores `camera.transform = Transform3D.IDENTITY` before gameplay follow,
   checks the actual player eye and all four clear actor positions, and keeps
   other actors out of solid islands. Close/mid camera poses are unchanged.
4. Both CI comparison launches require `--quality-test --match-seed=8027`
   before game `_ready`. Each fixture starts round index 0 with that same seed.
   The original placement/occupancy validator must finish successfully.
   Each saved PNG logs the actual layout descriptor and camera/actor transforms.
   JSON manifests are compared recursively: exact discrete/layout values and
   at most 0.00001 numeric tolerance for floating transforms. Gameplay eye must
   be `(5.9, 1.48, -2.5)` with zero local camera translation.

## Preserved scope

Only `builder.gd`, the comparison capture, its workflow and this document are
changed from v1. `scripts/wetland21/art.gd` and `scripts/outdoor20/studio.gd`
are byte-identical to v1. The six-file cumulative change set versus Phase21
still contains three added files, three modified files and no deletions.

All pre-existing tests and game/seed/clue implementations remain unchanged.
No weapon, hand, drawing proportion, collision, RNG algorithm, timer or
occupancy predicate is replaced. The fixture seed reset is test-only.
Existing wetland expiry/reed pixel-difference thresholds are unchanged.
Before/after art pixels are expected to differ; comparison-condition equality
is enforced independently and does not claim visual quality.

## Execution and evidence status

V2 has only Python file, diff, checksum and source-level validation in WEB.
Godot compilation, runtime collision behavior, captures and visual quality
remain UNVERIFIED for this v2. Earlier independent 4.6.3 findings describe v1,
not a successful v2 run.

The existing Windows/Linux 4.4.1 and 4.7.2 CI jobs and regression commands are
retained. On a future approved push, Linux 4.4.1 additionally captures the real
Phase21 scene at the pinned base and current HEAD with the same fixture.
CI will retain `before_*.png`, `after_*.png`, both JSON manifests, strict engine
logs, a conditions log, exact HEAD/tree, source ZIP, full-index patch and bundle.
These are planned CI outputs, not artifacts claimed to exist in this turn.

The recovered v1 ZIP/patch are kept intact. The v2 cumulative patch is based on
Phase21 and includes all three new files; a separate v1-to-v2 incremental patch
records only these four targeted corrections.
