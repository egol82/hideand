# Phase 13 — verification record (candidate)

2026-09-29. Engine: official Godot4.4.1.stable.official.49a5bc7b6 restored from the mounted earlier tools archive; SHA512 matched its retained official manifest. No executable is distributed with source/evidence.

The local candidate implements actual weighted geometry/Skeleton3D, not an image edit. Earlier pose inspection revealed cross-limb weighting on the low-hanging paws; the arm/leg anatomical masks were separated and dedicated regression checks were added. A rest-pose check originally assumed uncompressed float weights; the measured maximum displacement was0.050mm from compressed ArrayMesh weights. The final bound is0.2mm, and normalization/indices are independently checked. These failed iterations are not counted as passes.

Final local/remote results and exact commit IDs will be appended after executing and retrieving the corresponding output. The current pipeline checks125 new assertions, reuses94 unchanged contact assertions and can run14 matches across seven maps/two modes. Render fixtures stage a comparison, front/back/A/ready poses, actual game/workshop and real-contact reaction; a four-second turning model is not manual gameplay.

No human-reviewed art acceptance, hardware GPU/FPS, full body IK, universal skin deformation or all-arbitrary-weapon grip guarantee is implied by test counts.
