# Phase 14 — material/shader v2 verification

Verified 2026-09-29. Runtime/test/capture snapshot: `8cb0cfe7799efd2f1b50407a48001e14c1455683`.
New material workflow: https://github.com/egol82/hideand/actions/runs/36576600970
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36576737798
PR: https://github.com/egol82/hideand/pull/14

This final documentation commit records observed evidence and changes no game, shader, test predicate or assets.

## Actual execution

- Local official Godot 4.4.1.stable.official.49a5bc7b6: 175 material/state assertions, 94 unchanged contact assertions, default entry, 14 new-entry matches, inherited runners and actual GL captures passed. The final shader values were rerun through material/contact/pixel/capture tests. Final exact-source match evidence comes from the remote run below.
- GitHub Linux / official Godot 4.4.1: new material/contact checks, 14 complete matches, all inherited core/Python runners, static hygiene, 14 actual GLSL pixel checks, 15 comparison/gameplay stills and 120-frame surface demonstration passed.
- GitHub Windows headless / official Godot 4.4.1: same new material/contact/state checks, 14 matches and all inherited core/Python runners passed. No Windows GUI/GPU rendering test is implied.
- Separate historical PR workflow: completed/success on Linux Godot 4.4.1/4.7.2 and Windows headless Godot 4.7.2. It runs historical suites and is not additional evidence that the new material tests ran on Godot 4.7.2.

The local engine was restored from the already mounted tools archive and checked against its retained official SHA512 manifest. Remote installers verify downloaded engine archives. No engine or font files are included in user deliverables.

```text
MATERIAL_UNIT_RESULT: 175 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
MATERIAL_RENDER_RESULT: 14 checks, 0 failures
MATERIAL_CAPTURE_PASS
MATERIAL14_SUITE_PASS
```

Counts are individual assertions, not human-play scenarios or a visual quality score. The 94 contact assertions are reused rather than rewritten or counted as new. The inherited 2,643 definitions plus 175 material/state assertions give 2,818 headless-capable definitions; the 14 actual rendered-pixel checks are separate. Inherited language-field/audio-sample/repeated shape and seed checks remain included. Static hygiene has 626 conditions and is not an engine assertion count.

## What is established

Six distinct opaque material recipes, unchanged source resources, independent camera/world/body/cutout instances, cache reuse, five bounded mipmapped data textures, material generation and microdetail switches, original seven-map collision/hiding/navigation state, the original eighteen-bone character mesh/skin, hidden face/body behavior, fixed 0.40 proportional view scale and rounded paws are checked. Re-equipping a drawing refreshes the world material without requiring a manual profile toggle. Per-frame checks confirm no steady-state mesh/material/texture rebuilding in the tested scene.

The unchanged actual-input/contact suite passes its nine first-render selected-sample alignment cases. This does not establish perfect alignment of all vertices throughout every arbitrary weapon swing, nor audio-device latency.

All seven maps in FIELD/CLASSIC completed four rounds through scenes/phase14.tscn. Windows/Linux match JSONs match each other and the local result exactly. These fixed-seed results check completion and regression behavior, not tactical balance, fun or human visibility fairness.

## Actual shader pixels, not headless-only checks

The Linux test renders a controlled sphere under a directional light, removes all illumination, places a fully opaque wall in front, and then tests an actual shadow caster. Six recipes render when lit and produce mean zero in the tested region with all illumination off. The full-image sampled difference with the sphere behind the opaque wall versus absent is 0.0. Shadowed mean luminance is 0.04087146 versus 0.27305479 without the caster. These measurements are limited fixtures, not every map, lighting angle or hardware combination.

No ALPHA/EMISSION output, depth disabling, vertex displacement, screen reads, global-time motion or hidden-player outlining was added. Vinyl diffusion is an artistic lit-side approximation, not physical subsurface scattering or baked GI. The existing view-only directional shadow exception remains; world attenuation and point-light falloff are not bypassed.

## Images, video and source provenance

Fifteen 1280x720 stills: character generation I/II; six same-pigment/same-shape material samples I/II; microdetail off; foam/fabric close-up; three game maps I/II; workshop; comparison dialog; and a real input/swept-contact reaction. The 4-second 30fps silent video moves only the sample gallery's directional light to show material response. It is not gameplay footage. Stills stage actors/poses but the contact still uses actual input and collision, not an injected hit event. No generated image overlays or retouching were used. Comparison montages only resize/arrange existing pixels.

Artifacts were downloaded and SHA256 checked against GitHub:
- Linux: f2c98caed16c12f741dab29145da817af329256e7268ec4b9636051f917081a3
- Windows: 660d72d74f16956b63dafb459d239144be680ea874a935e0759c7466a85a6e3e

The archived source comment and commit marker identify 8cb0cfe7. It contains 235 source files; all 20 changed paths match the final local implementation byte-for-byte, and LICENSE plus Phase13 native body/rig/manifest are unchanged. The updated verification document is subsequent to that exact runtime snapshot. No fonts, executables, .godot cache, user save data or raw video frame dumps are distributed.

The first remote run was superseded after a capture-only correction moved the foam/fabric captions above the gallery floor. The final successful run includes that correction. Earlier iterations are not substituted for the final published-source result. A local aggregate command exceeded a tool wait window but its completed process logs and markers were subsequently read; the remote result does not rely on that interrupted wait.

## Boundaries

This is a material milestone. Character topology/shape, furniture models, light placement, live GI, animation/IK and gameplay are not redesigned. The new specular response can expose existing mesh irregularities and coarse shadow bias rather than repairing them. High-frequency detail fades with screen footprint but universal anti-aliasing or measured frame-rate improvement is not claimed. Microdetail OFF is an appearance preference, not a validated hardware tier.

No human art approval, accessibility/visibility/fun/comfort session, real Windows GPU/FPS measurement, audio-device audition, online/Steam/release executable or commercial-quality certification is claimed. Known inherited cleanup/software-driver warnings remain; new shader/script errors are not ignored by the runners. Main, earlier branches and repository visibility/permissions are unchanged.
