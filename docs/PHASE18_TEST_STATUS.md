# Phase 18 — verified contact-locked smash polish

Verified 2026-09-30. Exact runtime/test/capture snapshot: `a709d4984f7e870396372c066a6608eab9a23f29`.
Main Windows/Linux workflow: https://github.com/egol82/hideand/actions/runs/36680117526
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36680188701
PR: https://github.com/egol82/hideand/pull/18

This final commit updates verification documentation only. Runtime code, sound recipes, tests and assets are identical to the verified snapshot. The previous interrupted attempt had left only a Phase18 branch at the Phase17 commit. This turn implemented the actual presentation extension and published it without overwriting later Phase17 verification metadata.

## Observed execution

| Environment | Result |
|---|---|
| Local Linux / official Godot4.4.1.stable.official.49a5bc7b6 | 142 new assertions,94 reused contact assertions,default entry,14 matches and final serial actual-render run passed |
| GitHub Windows headless / official Godot4.4.1 | Model/GI manifest hashes,new and inherited tests,14 matches and core runners passed |
| GitHub Linux / official Godot4.4.1 | Same checks plus actual screenshots,216-frame video and event-timed reference audio mix passed |
| Separate historical PR workflow | Completed/success on Linux4.4.1/4.7.2 and Windows headless4.7.2; not evidence that the new142 tests ran on4.7.2 |

The local engine archive was restored from the previously mounted tools archive and matched its retained official SHA512 manifest. Remote installation also checks the official engine checksum. Engine and font binaries are not distributed.

```text
FEEL18_UNIT_RESULT: 142 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
FEEL18_CAPTURE_PASS: 10 screenshots / frames=216
FEEL18_AUDIO_PREVIEW_PASS 11 7.2 0.20291095972061157
FEEL18_SUITE_PASS
```

142 counts individual assertions, including45 PCM/cache/variant checks. These are not142 independent human play situations or a quality score. The original94 sync assertions are unchanged except for a scene-selector line and are not counted as new definitions. Separate static hygiene passed757 conditions. Runners check exit code,required markers,bounded timeouts and script/shader-error logs together. The downloaded final Windows/Linux logs contain no SCRIPT ERROR,Parse Error,ERROR or FAIL lines.

## Actual implementation and what the tests establish

The Phase18 scene extends existing contact presentation,not game authority. Smaller directional foam chips,short compact rings,puffs and labels use the recorded contact point and normal. Short trails sample actual rendered/world weapon motion during the original active interval and stop at contact or hiding. There are96 inherited particles/6 labels,24 additional puff instances,48 trail slots and6 positional impact voices. Stress tests check bounded scene allocation and expiry,not a measured hardware performance rating.

Impact sound is one authored PCM waveform containing a short felt transient,body thump and elastic tail. Quick/balanced/heavy/finish/blocked and three swing recipes have deterministic variants.39 additional cached PCM resources cover supported normal/muffled combinations; legacy bank resources also remain for the comparison path. A separate seeded RNG is used rather than the game's random state. The original swing handler changes only the played waveform; footsteps,hearing and event metrics remain inherited.

Actual mouse attacks and original swept collision establish three handling-specific hits,a real blocker and a genuine miss. On a hit,the sound timestamp equals the same contact clock,the existing victim reaction has age zero and is visibly compressed,the Phase16 bone state is HIT,and particles/labels are initialized immediately. A duplicate event cannot replay the hit. A wall uses the blocked sound without free target damage. A miss creates no impact sound/burst. The existing94 tests retain nine selected-sample,first-render contact cases at30/60/120 step intervals; this is not every point of every arbitrary weapon swing or physical audio-device latency.

The new hand recovery yields to the existing contact-alignment latch. It changes only the hand-root display position; camera transform,yaw,pitch,FOV,authoritative weapon transform,drawings,samples,damage,HP,score and clocks are checked unchanged. Small victim settling and star-size changes use the existing reaction age and add no gameplay stun. The comparison restores original presentation paths and star sizes. It is session-local,not a saved quality/performance preset.

An actual AudioStreamPlayer3D playback is started and verified before testing pause. Muting reaches already active impact voices. Idle voices with no playback are not mistaken for paused sound. Reduced-motion and zero feedback suppress animated additions while preserving damage. Occlusion uses a real camera-to-event ray and a quieter prefiltered sample; it is an approximation,not ray-traced acoustics or tracking of a hidden player's future position.

All seven maps in FIELD/CLASSIC completed14 matches of4 rounds. Downloaded Windows/Linux result JSONs equal the local final run and Phase17's prior fixed-seed result. All15 inherited Python runners and both original core scripts completed in the new workflow. This demonstrates regression behavior,not human balance or final aesthetic approval.

## Real media and precise audio limitation

The final remote run produced ten1280x720 screenshots: old/new balanced contact,quick/balanced/heavy hits,finish,blocked,miss,manor and comparison options. The old/new pair toggles the presentation on the same current game fixture; it is not a historical executable comparison. Positions and starting HP are staged,but the attack and hit come from actual input/physics rather than injected contact events. Comparison images only resize/arrange these pixels; there are no generated overlays or painted corrections.

The216-frame,30fps video lasts7.2seconds and shows six attacks:quick,balanced,heavy,finish,blocked andmiss. There are11 recorded audio events:six real swing events plus five confirmed contact events. The genuine miss has no contact event. Local and remote audio manifests/mix reports agree.

The video soundtrack is an explicitly labelled OFFLINE MONO REFERENCE MIX from the same exported PCM and recorded event times. It is NOT a recording of the audio device,the spatial renderer,reverb or speaker latency. Live gameplay uses normal positional AudioStreamPlayer3D playback. The offline mix peak before safety gain was0.20291096; no upward normalization was used. It does not certify sound-design quality or hardware clipping behavior.

Actual rendering uses Xvfb/Mesa llvmpipe software OpenGL with Dummy audio. These are staged automated captures,not manual playthroughs or Windows hardware measurements. Final remote comparison/media were visually inspected; local final captures also completed. No human listening/comfort/art acceptance is claimed.

## Source and asset verification

Downloaded artifact SHA256 digests match GitHub:
- Linux: `9d5245d04f973f9c869728010dc616fc59c6af30979050d5cb80bb3e2aa870ca`
- Windows: `c1cc385a5e7a87cc9b9948c6c6692f140ddfc5b8e74d90f7812624d6535d5f09`

The source ZIP comment and commit marker identifya709d498. It contains300 files. All21 intentionally changed paths match the final local tested files byte-for-byte. Comparing every archived path to the starting local tree finds only the previously finalized Phase17 verification document different:the distributed Phase17 runtime ZIP predates that documentation-only update. The Git tree correctly preserves the newer upstream document. This is not an unexplained gameplay or test change.

The original12 character/GI manifest entries match. LICENSE and original model,shader,animation,viewmodel,manor/furnishings,collision and storage code are unchanged. Only one selector line extends the old sync test. No fonts,engine executables,.godot caches,private saves or raw video frames are included in deliverables. Source ZIP remains the exact verified runtime snapshot; this later final record is also provided on the branch and separately in evidence. Artifact retention is7days; source remains on the feature branch.

## Rejected iterations and limits

An initial inferred-type parse error in the hand-offset expression was fixed before passing validation. A first scene check started before initial EXR import had finished and failed on missing imported dependencies; it is not counted as passing. The audio pause fixture originally demanded stream_paused on idle voices; it was corrected to start actual playback before checking. Missing original-star-scale restoration and delayed trail-slot initialization were corrected and checked in the final source.

An initial local renderer launched concurrently with heavy headless tests was terminated without its completion marker. It was not counted as successful. A serial rerun completed all10 captures/216 frames,followed by the exact-source successful remote run. Earlier incomplete frames are not the delivered video. Existing shader-UID fallback to a valid text path and software VSync warnings remain; the entire inherited project is not called warning-free.

The new particles are depth-tested but do not physically collide with decorative surfaces. Small chips can pass through geometry. The underlying character topology,first-person framing and large-drawing visibility limits are unchanged. No full-ragdoll redesign,new GI bake,physics-driven air effects,universal no-clipping guarantee,hardware FPS/VRAM/audio latency,live multiplayer,Steam or release executable is part of this milestone. Main and previous PRs are unmerged. License,visibility and permissions are unchanged.
