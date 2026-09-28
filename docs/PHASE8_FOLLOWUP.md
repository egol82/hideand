# Phase 8 — final grip review

2026-09-28. Based on `bd5d41d6d05df98acdc9440ab6c7af60fc6bfabf`.

During this implementation session, another completed Phase 8 commit appeared on the feature branch. The already published natural-grip implementation and PR #7 were preserved instead of being overwritten by a separate local candidate. This follow-up makes compatible, small improvements on that exact published version.

## Additional changes

- Reject negative/zero/non-finite display scale and singular/non-finite drawing frames before fitting. Invalid presentation inputs cannot create inverted or degenerate grip geometry.
- Give sleeve/finger tubes meaningful per-corner UVs, indexed vertices and tangent vectors. Both flat and round cap winding is aligned to outward normals.
- Sleeve fabric now uses local UVs and a restrained normal-map strength. The cloth pattern stays attached to the sleeve as its arm frame rotates. This changes presentation only, not reach or the source drawing.
- Guard zero-length/tiny wrist-to-elbow links so their basis remains nonsingular.
- Add 17 focused assertions to the existing grip runner without removing the original 198 grip assertions or any prior suites.

## Local execution

Official Godot 4.4.1 on Linux: original 198 grip assertions and 17 additional checks passed; the actual Phase 8 entry emitted PHASE4_SMOKE_READY. All fourteen existing staged grip captures were rerendered successfully under Xvfb/Mesa software OpenGL with Dummy audio. They are real engine output, not edited reference images or a manual playthrough.

Remote verification of this exact follow-up commit must be read before being called passed. Prior CI results in PHASE8_TEST_STATUS.md apply to their documented historical commit only. Completion markers, exit codes, error logs and timeouts are required.

No changes to the approved hand silhouette, original weapon data/form, collision, attack timing, maps, score, input, saves, LICENSE or visibility. Full anatomical IK, every-drawing penetration guarantees, human controls/comfort and real Windows GPU/audio performance remain outside the verified scope.
