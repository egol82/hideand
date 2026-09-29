# Phase 13 — verified character model, rig and completed recovery

Implementation and recovery verified: 2026-09-29.
Exact runtime/test/native-asset snapshot: `a0846375b8571f02c1a782127b6430f913a3f0a1`.
New character workflow: https://github.com/egol82/hideand/actions/runs/36549391811
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36549567738
PR: https://github.com/egol82/hideand/pull/13

The interrupted attempt had already committed the character implementation, generated the native assets and opened PR13. This recovery inspected the saved implementation and real renders, downloaded and checked the successful Linux/Windows evidence, reran the character/contact tests and all fourteen matches, and finalizes the delivery record. The recovery commits change documentation only. They do not recreate the character, weaken tests or claim another untested runtime update. PHASE13.md also corrects the normal-generation wording: gradients are estimated with central finite differences, not computed analytically.

## Observed execution

| Environment | Verified outcome |
|---|---|
| GitHub Linux / official Godot 4.4.1 | Native generation and asset/source hashes, new 125 assertions, reused 94 contact assertions, all previous runners, fourteen matches and actual renders passed |
| GitHub Windows headless / official Godot 4.4.1 | Same asset/source verification, new and old engine checks and fourteen matches passed; no Windows GUI capture is claimed |
| Separate historical-regression workflow | Completed/success on the same implementation SHA; it does not replace the new character-specific tests |
| Recovery Linux / Godot 4.4.1.stable.official.49a5bc7b6 | Exact downloaded source imported; 125 character assertions, 94 unchanged contact assertions, actual default entry and fourteen full matches rerun; exit 0 and CHARACTER_SUITE_PASS |

The recovery engine was restored from the previously mounted tools archive. Its ZIP bytes matched the retained official SHA512 manifest before extraction, and its actual --version output was checked. No engine binary is included in the source or evidence deliverable. The native asset build job succeeded on the published implementation; recovery used those exact assets rather than silently regenerating different files.

```text
CHARACTER_UNIT_RESULT: 125 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
CHARACTER_CAPTURE_PASS
CHARACTER_SUITE_PASS
```

The default scene deliberately uses its existing controller's PHASE4_SMOKE_READY marker. Runners check process exit, required completion markers, timeout bounds and script-error logs together. The recovery log has exit 0 and no SCRIPT ERROR, Parse Error, ERROR or FAIL lines.

The previous definitions total 2,518; adding 125 new ones gives 2,643 individual assertions. Repeated execution of the same 94 contact assertions is not counted twice. The inherited total includes 110 copy-field checks, 30 audio-sample checks and repeated shape/seed fixtures. It is not a number of independent human-play scenarios or a visual quality score. The separate static-hygiene rerun passed 588 conditions and is not part of the engine assertion total.

## What the model tests establish

- The body is one indexed surface with 10,024 vertices and 20,044 triangles. Connectivity traversal reaches every body vertex; every triangle edge has two incident faces; winding agrees with the outward normals. This is more than combining disconnected primitives into one draw call, but not a proof of ideal animation topology for every pose.
- Skeleton3D contains 18 named bones with corresponding Skin binds and a resolving MeshInstance3D skeleton path. Every body vertex has four stored influence slots with valid indices, nonnegative weights and normalized totals.
- Moving the right arm bone actually deforms a hand vertex by more than 0.10m while a sampled head vertex stays within 0.1mm. Sampled rest-pose skinning reproduces the stored body within the 0.2mm compressed-weight tolerance.
- Low paws cannot accidentally inherit leg weights and feet cannot inherit arm weights in the tested anatomical regions. These assertions were added after an earlier real render revealed cross-limb weighting.
- Right-arm ready fitting reaches the existing target within 2cm in its fixture without moving the authoritative weapon. Left/right BoneAttachment3D grip sockets are available. This is a bounded pose helper, not universal hand/body IK.
- All four world actors, workshop previews and KO echoes use the same new body. Body mesh resources are shared; each actor has independent skin/pose state. Eyes and comic overlays follow the head attachment.
- Body art adds no colliders and remains outside the authoritative weapon hierarchy. Pose updates preserve actor/capsule state, drawing dictionaries, hit samples, weapon transform, HP, scores and clocks. No per-frame mesh/node rebuilding occurs in the tested loop.
- Pause and reduced-motion settings stop the new idle phase. Hidden faces/bodies remain hidden, local first-person subjects use the existing excluded layer, and returning to normal visibility restores the world layer.
- All seven map entries and actual workshop weapon parenting are exercised. The previous Phase12 entry retains its original body rather than being silently replaced.

## Matches and actual pixels

FIELD and CLASSIC across toy_manor, toy_home, warehouse, garden, sugar_market, starlight_arcade and pocket_station completed fourteen matches of four rounds each through scenes/phase13.tscn. The downloaded Linux and Windows result JSONs match each other and the recovery rerun exactly. This establishes fixed-seed regression consistency, not human-tested balance or sophisticated tactical AI. Invisible pose updates can be skipped by headless autoplay; separate unit tests and rendered scenes exercise the actual skin.

The successful Linux artifact contains eight actual 1280x720 images: comparison, front, back, A-pose, ready pose, game, workshop and real-contact reaction. It also contains a 1280x720, 30fps, 120-frame/four-second turntable video. The reaction fixture drives attack input and original swept collision; the turntable is a posed model inspection, not gameplay. Captures are staged Godot Compatibility renders under Xvfb/Mesa software OpenGL with Dummy audio, not generated artwork or a manual playthrough. Recovery visually inspected the existing published captures; it does not claim a new rendered run.

## Source and native-file provenance

Both downloaded artifact SHA256 values match the GitHub-reported digests:
- Linux: 923a5ef266159c56e722e42fb57a4f4beea47e1a884cc01f641e6244378fbd34
- Windows: f2bf85a307c41aeb980a135696e54a5064c6dac9b662afe06bb990f7dd7ea42a

The exact source archive comment and marker identify a0846375. Its 222 files were safely extracted, compared byte-for-byte with the archive and remained unchanged after the recovery tests. The four recorded SHA256 entries for buddy_body.res, buddy_rig.scn, mesh_builder.gd and avatar.gd match the source/asset manifest. The downloaded native model directory was independently compared with GitHub's contents listing using Git blob hashes:
- buddy_body.res: 55769d4eb3e9a381145a7463f1f8aab2d2d5b09f
- buddy_rig.scn: 24b2b37ea15cbb2af76894dbbe55a89baac89c3f
- manifest.json: 921d4076d32a2381e805636a0087d41bfb5ba8e8
- asset README.md: 08c733b562e9bd8f61798f16b2b2a275253b904c

GitHub comparison against the final Phase12 branch reports 23 changed paths. Comparing with the older distributed Phase12 source ZIP additionally shows its later Phase12 verification-document update; that is not an unexplained gameplay change. LICENSE bytes match Phase12. Source/evidence packages exclude engine/font binaries, imported caches and player saves. The generated native model files are intentional deliverables, not caches.

## Rejected iterations and remaining limits

The first Windows asset check failed because checkout line-ending conversion changed generator hashes. The character-generator directory now has an explicit LF attribute; the source-hash check was retained and the successful run verified it on both operating systems. Earlier cross-limb weighting and compressed-weight rest precision were diagnosed rather than counted as passing. This recovery initially attempted a terminal streaming session unavailable in the container, then launched the same bounded runner normally and verified its final exit marker; the failed terminal allocation is not an engine result.

This is a generated smooth skinned toy model, not a final artist-approved commercial character or manually retopologized joint mesh. Extreme shoulder/hip deformation, ground-aware feet, complete hand/body IK, every arbitrary handle shape and a polished locomotion/attack library remain later work. The existing first-person round paws, fixed 0.40 drawn-size multiplier, lowered pose and contact correction are unchanged. New shader/GI stages were not added. Historical cleanup/driver warnings can remain, so the whole project is not described as warning-free.

No human usability/fun/comfort/accessibility review, real Windows GPU/FPS or audio latency benchmark, online play, Steam integration or release EXE is implied by these results. Main and previous PRs remain unmerged; no force push, LICENSE or visibility change was made.
