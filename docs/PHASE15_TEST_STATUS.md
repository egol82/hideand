# Phase 15 — verified live manor LightmapGI and completed recovery

Verified 2026-09-30 KST. Exact runtime, test and native-asset snapshot: `e058559c3eaf35b1a324c6c6b9c99483c56e84fb`.
Main workflow: https://github.com/egol82/hideand/actions/runs/36640682453
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36640687135
PR: https://github.com/egol82/hideand/pull/15

This final follow-up updates verification documentation and the regenerated static report only. The verified runtime and native lighting resources do not change.

## Actual execution

| Environment | Observed result |
|---|---|
| Recovery Linux / official Godot 4.4.1.stable.official.49a5bc7b6 | 109 lighting assertions, 94 unchanged contact assertions, actual default entry, fourteen complete matches and thirteen rendered states passed |
| GitHub Linux / official Godot 4.4.1 | Exact asset hashes, 109 lighting assertions, 94 reused contact assertions, fourteen matches, all inherited core/Python runners, static hygiene and actual rendering passed |
| GitHub Windows headless / official Godot 4.4.1 | Exact asset hashes, the same new/old state and contact suites, fourteen matches and original core/Python runners passed |
| Separate historical workflow | Completed/success on Linux 4.4.1/4.7.2 and Windows headless 4.7.2; those jobs do not run the new lighting suite on 4.7.2 |

All three jobs in the main workflow completed successfully. Runners require exit status, completion markers, bounded timeouts and no script/shader ERROR or FAIL lines. The local engine archive was restored from the earlier tools package and verified against its retained official SHA512 manifest. No engine or fonts are distributed.

```text
LIGHTING15_UNIT_RESULT: 109 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
LIGHTING15_RENDER_PASS
LIGHTING15_CAPTURE_PASS
LIGHTING15_SUITE_PASS
```

The existing controller's PHASE4_SMOKE_READY marker is intentional. New 109 assertions are not 109 independent human scenarios. The same 94 contact definitions are reused without deletion or weakening and are not counted twice. The inherited 2,818 headless-capable definitions plus 109 are 2,927 definitions; previous copy/audio/seed checks are included. Actual rendered probe checks are separate from headless assertions. Static hygiene reports 650 conditions, not engine assertions.

## Real lightmaps in the playable map

326 fixed meshes retain valid UV2 and uniquely resolve their baked user paths relative to the actual LightmapGI node. The saved scene is instantiated beneath the LIVE arena; original fixed visuals are hidden only after their geometry/material signature matches. Original colliders and navigation remain. This is not just an editor review scene or the Phase10 separate bake demo.

The native export contains 167,247 vertices and 264,192 triangles, with 34 unique unwraps. The original real GPU bake used LOW sampling, three indirect bounces, a maximum 2048 texture size and directional lightmaps. It saved an EXR, LightmapGIData and matching scene. There are 254 authored manual probe nodes; the real rendering backend reports 295 saved probe points and 2,655 SH coefficients after automatic probe generation.

All seven authored local lights use BAKE_DYNAMIC: direct light and moving shadows are real-time; indirect light is baked. B and C have identical direct lights and environment, including the same filmic mapper/white4/exposure1; only the actual lightmap/probe resource changes. A restores the previous lighting. Material I/II and the separate contact-support switch are retained.

Randomized hiding furniture is excluded from the fixed bake. It receives probes and real-time direct shadows instead, so a new round does not leave its old cabinet silhouette baked at the wrong location. It does not update indirect occlusion or become a newly bounced-light source. Fixed geometry of both floors closes light paths; the representative review target is the first-floor living room.

## Actual rendered proof

Thirteen 1280x720 native Godot images cover old/direct-only/GI lighting, the genuinely empty room, feet/contact support, upstairs, comparison UI and three isolated probe pairs. Empty-room capture hides entire actors including name labels only within the explicit fixture. No generated images or painted-over effects are used; montages only resize and arrange those pixels.

For the isolated pairs, all direct lights, ambient light and sky reflections are disabled. The environment meshes are hidden and only the real connected body, the actual world weapon, or the actual camera-held weapon is shown. With real light_data attached versus null, the sampled image values differ:

| Sampled ROI | Probe ON mean | Probe OFF mean |
|---|---:|---:|
| Actual skinned body | 0.02284975 | 0.00021514 |
| Actual world weapon | 0.02059491 | 0.00021514 |
| Actual camera-held weapon | 0.00925278 | 0.00000000 |

The unchanged overlays can account for the small nonzero OFF residual; the comparison measures the actual difference, not a claim that every image pixel is black. Live-room B/C mean absolute sampled RGB difference was 0.08345427. These fixture values establish real illumination, not perceptual quality, lux, performance or all-position interpolation accuracy.

The Dummy/headless renderer returns empty capture arrays. Therefore the headless test checks the native schema and the rendering test separately requires nonempty points/SH and actual changed pixels. A prior attempt to require GPU-array population in Dummy mode was rejected, not counted as passing.

Local and remote renders use Xvfb/Mesa llvmpipe software OpenGL with Dummy audio. They are staged validation views, not manual playthroughs or Windows hardware/audio benchmarks. Local final renders independently passed the same checks; small software-renderer pixel differences are not forced to zero.

## Gameplay and contact preservation

Seven maps in FIELD and CLASSIC complete fourteen four-round matches. Downloaded Windows/Linux JSONs equal the local recovery results and the prior Phase14 fixed-seed results. This is regression evidence, not balanced human win-rate evidence.

The tests retain original drawings, the fixed0.40 proportional view scale, lowered view and contact alignment, 18-bone body/skin, hit samples, collision/navigation/hideout state, camera, HP, score and clocks through mode changes. Re-equipped world and view weapons receive the dynamic GI setting. Hidden characters do not expose body or new grounding patches. Repeated lighting/material changes do not accumulate light state or rebuild hands every frame.

Contact support is a small artistic shadow supplement combined with real-time shadows and baked room occlusion. Per-foot patches follow floor-ray positions/normals and fade with height; cabinet patches are identical regardless of occupancy. This is NOT newly implemented SSAO, physical foot IK or ray-traced contact shadowing.

## Recovery provenance and rejected attempts

Original implementation ea8d989 produced real bake data in run36588371682. The editor reached its populated326-user save marker but failed during renderer finalization. That original process is still recorded as a failure. Its exact artifact SHA256 is c1e27c2e3d28642dff297b6be9da2b85d47b157da1d8ee9e6af89c52d2c1635a. Recovery validated those exact resources rather than inventing or silently rebaking different data.

The first recovery test incorrectly resolved ../Static paths from the bundle root; it was fixed to resolve from the LightmapGI node without removing the all-users check. Native assets were then published in3b44c546. A subsequent Windows precheck caught CRLF conversion of a manifest-tracked generator; explicit LF attributes fixed the bytes while preserving the hash assertion. The final successful workflow uses the already committed assets and no longer needs an expiring recovery artifact. Ordinary F5 does not launch the bake tool.

The original editor-shutdown issue is not represented as a clean full rebake. Future changes to fixed geometry, pigments or bake lights require a new explicit build/bake and matching manifest. The saved runtime data and their clean game reload/render are what this release verifies.

## Exact source and delivered artifacts

Downloaded artifacts matched GitHub SHA256 digests:
- Asset/source validation: e5b4bebba8b8a3935b08c9274d90dfd7922a90e9297f1d2be1e873a5e3af94b7
- Linux final: 4f1380041e4a9c338e33c9fe430c2b1aafac4fa9e5ba36d877cce41f26bd605d
- Windows final: dc2d68af6550b9e5f4cb14cb87f18715eb2fdea7fd298f235937258d1efd3003

The two independently downloaded source ZIPs identify e058559c and contain the same258 files byte-for-byte. Comparing all archived files to the tested local work found only the regenerated static report (626 to650) different; runtime, tests and assets matched. This documentation-only follow-up reconciles that report. LICENSE, the Phase13 body/rig/manifest, Phase14 shader, existing viewmodel and manor authority remain byte-identical to the previous source. No unexplained code differences, fonts, executables, .godot caches, user saves or raw-frame dumps are included.

Source ZIP is the exact remotely verified snapshot. Final verification documentation is supplied separately and on the branch. CI artifacts have seven-day retention; the source and native lightmaps are permanently tracked on the feature branch.

## Remaining boundaries

The old windows are opaque scenery; internal portal lights represent warm incoming daylight rather than physical glass transmission or new holes in walls. Geometry, furniture detail and character animation are not redesigned. Some bright ceiling hotspots, coarse shadow edges, light leakage and perceptual hiding fairness still need art/human review. LOW bake sampling and sparse probes are not a claim of final commercial-quality lighting.

No hardware FPS/VRAM guarantee, human comfort/fun/accessibility acceptance, fully dynamic GI, all-seven-map lighting redesign, multiplayer/Steam or release executable is claimed. Known shader-UID fallback to its valid text path, cleanup and software V-Sync warnings are disclosed; these are not hidden script errors. The repository license, visibility and existing branches are unchanged. No force push or main merge was performed.
