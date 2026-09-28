# Phase 10 — verified Toy Studio graphics and authoring

Verified 2026-09-28. Full remote game/test snapshot: `a1c6fe18abc10582d44b4bae40efc949d2022ebc`.
Main evidence: https://github.com/egol82/hideand/actions/runs/36427663075
Additional historical-regression CI: https://github.com/egol82/hideand/actions/runs/36427897006

Editor-only follow-up `0a43ba89bc1f6cab7835dca758f0b03ca6896d63` fixes saving from a deferred callback and adds explicit existing-bake verification. It changes no runtime game, shader, geometry or test predicate. Its local targeted evidence is separated below. This document is not a claim that every subsequent commit was rerun on remote GPUs.

## Actual engine verification

| Environment | Observed outcome |
|---|---|
| Local Linux / official Godot 4.4.1.stable.official.49a5bc7b6 | All previous runners,108 studio assertions,94 unchanged contact assertions,new entry,12 matches and actual GL captures passed |
| GitHub Linux / Godot 4.4.1 | All prior/new game assertions,UV2 export/reload,12 matches,11 A/B/C/detail stills and9 contact stills plus6-second video passed |
| GitHub Windows headless / Godot 4.4.1 | All prior/new assertions,UV2 export/reload and12 matches passed |
| Additional PR workflow / Linux4.4.1,4.7.2 and Windows headless4.7.2 | Historical engine regressions passed; these jobs do not run the new108 studio assertions |

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE3_UNIT_RESULT: 259 checks, 0 failures
PHASE4_UNIT_RESULT: 237 checks, 0 failures
QUALITY_UNIT_RESULT: 238 checks, 0 failures
GRAPHICS_UNIT_RESULT: 78 checks, 0 failures
MAP_PACK_UNIT_RESULT: 605 checks, 0 failures
GRIP_UNIT_RESULT: 198 checks, 0 failures
GRIP_SAFETY_RESULT: 17 checks, 0 failures
SMASH_UNIT_RESULT: 100 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
STUDIO_UNIT_RESULT: 108 checks, 0 failures
PHASE4_SMOKE_READY
STUDIO_UV2_EXPORT_PASS
STUDIO_EXPORT_VERIFY_PASS
STUDIO_CAPTURE_PASS
SYNC_CAPTURE_PASS
STUDIO_SUITE_PASS
```

Unique assertion definitions: **2,128 = 2,020 retained +108 new**. The same94 sync checks repeated against the new scene are not added twice. This includes110 inherited language-field checks and30 audio-sample checks; it is not2,128 independent human-play scenarios. Separate source hygiene reports486 conditions, not engine assertions.

All six maps in FIELD and CLASSIC completed four rounds through the new entry. Windows and Linux result JSONs agree and match the previous fixed-seed counts. A/B/C preserves authoritative transforms, HP, score, clocks, drawing vectors, weapon scale/samples, collision/navigation/hideout fingerprints and hidden-body visibility. Contact tests retain the selected-sample first-render projection check below0.1px in the nine original cases; not a whole-swing or hardware/audio-latency guarantee.

## Real editable geometry and UV2

The saved `scenes/art/sugar_island.scn` is a native editable PackedScene generated from project-owned code, not a screenshot. The complete static authoring export contains421 ArrayMesh nodes and74 unique unwraps. Linux output has242,079 vertices and Windows242,077; both have368,274 triangles. The difference is UV seam duplication, not missing geometry. Export and reload check every UV2 for finite in-range coordinates, plus source surface area and vertex bounds on every mesh. The export has no gameplay colliders or actors.

Do not equate an exported UV2 scene with a baked game. The exported room adds a LightmapGI node and editor lighting but is separate from all six playable maps.

## GI: generated data verified, automation and live integration have limits

The remote editor used Forward+/Vulkan with Mesa llvmpipe and actually computed lightmaps. The artifact contains a saved scene, `.lmbake` and EXR texture, with **421 populated LightmapGIData users**. However the experimental step uses `continue-on-error`: its overall green workflow badge is NOT sufficient GI evidence. The editor log contains progress-dialog/save-context errors and a renderer-finalize error; the process exceeded its external exit deadline. The intended CI post-bake render did not execute. The automation is therefore not recorded as cleanly passing.

The exact downloaded baked scene and data were subsequently imported locally, reloaded with421 users and rendered in Godot4.4.1 Compatibility. Its existing capture_bake.gd produced `STUDIO_GI_RENDER_PASS`, exit0, and actual paired GI-off/GI-on images, without runtime ERROR lines. These two images are LOCAL recovered-artifact renders, not claimed CI frames. Warnings include shader UID fallback to its valid text path and unsupported V-Sync. The authoring camera/exposure is not a final game-lighting setup.

The editor-only0a43ba89 fix calls the one-shot save from normal editor processing rather than call_deferred. `--studio-verify-bake` explicitly reloads and saves existing populated data without rebaking. Its local test exited0, reported `STUDIO_GI_VERIFY_PASS` with421 users and had no earlier progress-dialog/finalize errors. Local editor capability probes still reported missing Vulkan surface extensions; this is NOT an entirely error-free editor run. Full GPU recomputation with this final save patch was not repeated. The normal new-game import,108 studio assertions,94 sync assertions and scene entry were rerun locally after the patch and passed.

**Baked GI is not installed into live gameplay.** Working live improvements are the authored island/trim/floor, lighting presets and dedicated materials. The exported/baked map is supplied separately for authoring/integration. No dynamic player/weapon light-probe integration or production-quality GI polish is claimed.

## Screens, source and readback

20 original final-CI stills:11 A/B/C/detail images plus9 actual-contact images. A6-second1280x720 H.26430fps silent preview uses input-handler attacks and real swept collision, not injected hit effects. Staged actor positions/HP are not a manual playthrough. The two additional recovered-GI images bring the supplied still count to22; comparison montages only arrange/scale those pixels.

Downloaded artifact SHA256 digests match GitHub:
- Linux: e1385911d0943c9b1a5b37433df6a360e170f5444d9c8162f1d99208afcb45ea
- Windows: 9e20f12178384b9f2dd8521e34819cda2d966b013c599ab8d0198ae6fb86c0cf

CI source archive comment and source marker identifya1c6fe18. It contains181 source files. The33 changed paths were checked against the local implementation or generator dependency stamp; no unexplained differences. Two explicitly documented post-CI differences are the editor-only save patch and refreshed static report; the final verification documentation is also updated afterward. LICENSE equals the previous source. Source archives contain no font/engine binaries,caches,raw frame dumps or user saves. Separately packaged authoring data is intentional generated content.

Earlier failed iterations are not passes: published2-channel Color typo was fixed; an optimistic export marker after a PrimitiveMesh API error was rejected; platform-specific UV seam count assertions were replaced with geometric/UV validity; accumulated lighting state and leaked duplicate Sky resources were fixed. Test runners inspect process exit,required markers and error logs together. Known experimental editor issues are disclosed instead of hidden behind continue-on-error.

## Remaining boundaries

No human fun,comfort,accessibility/fairness session,real Windows GPU/FPS or audio-device benchmark,online/Steam/release executable,commercial-art completion or universal weapon/finger nonpenetration is claimed. Source remains Godot/GDScript with original drawn weapons. A/B/C preserves geometry but perceptual visibility fairness across every lighting preset needs human testing. Native authoring assets do not automatically solve shadow leakage,exposure or dynamic GI integration. Previous cleanup/software-driver warnings remain. No force push,main merge,LICENSE or visibility change was made.
