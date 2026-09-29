# Phase 12 — verified proportional drawings and native adventure UI

Verified 2026-09-29. Runtime/test source commit: `c896f950138106555f8cdf51beabb1b0f1a60a02`.
New Windows/Linux workflow: https://github.com/egol82/hideand/actions/runs/36525769429
Historical regression workflow: https://github.com/egol82/hideand/actions/runs/36525854248
PR: https://github.com/egol82/hideand/pull/12

This final follow-up changes the verification document only. The exact game/test code is the remotely verified source above, not an untested new gameplay patch.

## Observed environments

| Environment | Result |
|---|---|
| Local Linux / official Godot4.4.1.stable.official.49a5bc7b6 | All earlier runners,133 new UI/size assertions,94 reused contact assertions,entry,14 matches and15 rendered screens passed |
| GitHub Linux / official Godot4.4.1 | New133 and unchanged94,all previous runners,14 complete matches,core tests,static hygiene and15 actual captures completed/success |
| GitHub Windows headless / official Godot4.4.1 | New133 and unchanged94,all earlier Python/core suites and14 complete matches completed/success |
| Additional PR workflow / Linux4.4.1,4.7.2 and Windows headless4.7.2 | Historical regressions completed/success. These jobs do not run the new133 assertions on4.7.2 |

The local engine was restored from the existing tool archive and checked against its retained official SHA512 manifest. Remote installers compare the downloaded engine with the official manifest. No engine/font files are shipped with the project or evidence package.

## New checks and scope

```text
PREMIUM_UNIT_RESULT: 133 checks, 0 failures
SYNC_UNIT_RESULT: 94 checks, 0 failures
PHASE4_SMOKE_READY
PREMIUM_CAPTURE_PASS
PREMIUM_BASELINE_PASS
PREMIUM_SUITE_PASS
```

The inherited assertion definitions total2,385; with133 new definitions the total is2,518. The same94 contact assertions executed again on the new scene are not counted twice. Inherited counts include110 copy-field checks,30 audio-sample checks and repeated seeded/shape cases. Counts are not independent human-play situations or quality ratings. Separate source hygiene reports555 conditions, not engine assertions.

- Three same-grip line drawings of normalized lengths0.20,0.40,0.65 all use the same0.40 first-person scale. The below-cap0.40 line has twice the projected centreline length of0.20 within test tolerance. Fixed tube thickness means outer mesh bounding boxes are not claimed to have the same exact ratio.
- Original drawing dictionaries,grip,world geometry and contact samples remain unchanged. Existing2.20m reach and area/ink limits still apply; the workshop exposes dimensions and cap status. It never silently adds a handle or increases damage.
- Sampled mesh vertices of fish,hammer and pan leave the protected central idle sight window. The hand/weapon pose moves downward instead of shrinking the drawing. This is not proof of every triangle/all possible drawings/FOVs or uninterrupted clear sight while attacking.
- The original actual-input/swept-collision suite passes its nine first-render selected-contact projection cases with the new lowered pose. No sync assertion was removed or weakened; only a new scene selector was added.
- Korean/English UI is checked at physical1120x680,1280x720 and1920x1080 using Godot's actual logical-to-physical viewport transform. Title panel,canvas and equip action remain on-screen. Native focus states and real drawing/equip/settings/remap/resume/result callbacks are exercised.
- Menu guide Escape and guide-to-keybinding navigation return to the correct pause/menu state. Old overlapping HUD labels are hidden rather than covered by a decorative image.
- All seven map menu/HUD entries and concealment masks are checked. The atlas receives public arena layout and optional local player position,not enemy/occupancy state. Presentation updates do not alter HP,score,time or weapon authority and do not rebuild hand geometry every frame.

## Matches and actual pixels

FIELD/CLASSIC x7 maps completed14 matches of4 rounds each through scenes/phase12.tscn. Downloaded Windows/Linux result JSONs match each other and the local result. These are fixed-seed regression observations,not evidence of balanced win rates or improved fun.

There are12 new1280x720 renders: Korean menu,workshop,practice HUD,small/large drawings,settings,atlas,keybindings,results,guide,English menu and live HUD. Three same-condition historical-entry renders provide menu/workshop/HUD comparisons. Baseline scenes keep their earlier view/HUD flags. Comparison images only place/crop those rendered pixels; no generated or retouched Zelda imagery is used.

Captures use actual Godot Compatibility rendering under Xvfb/Mesa software OpenGL with Dummy audio. They stage state,positions and example result scores to inspect the interface. They are not manual playthroughs or hardware/audio benchmarks. No new gameplay video is claimed.

## Source verification

Both downloaded artifact digests match GitHub:
- Linux SHA256:51d184e23a0235f02fbffdfb8b0e90e7e19b495eea2bb155a7491172ad5d7293
- Windows SHA256:0df151575ce8242872624e253883993fe089e946483af3a493a024c9eea30004

The exact source archive comment and commit marker identifyc896f950. It contains206 files. All21 intentionally changed paths were compared byte-for-byte with the final local version: zero differences. LICENSE matches the previous archive. No fonts,engine executables,.godot cache,user saves or raw frame dumps are bundled; the tracked ci-artifacts/.gdignore marker is harmless project metadata,not captured output.

The source ZIP is the CI-verified snapshot; this later verification record is also available separately in the final evidence package and on the branch. Main and previous PRs remain unmerged.

## Rejected iterations and limits

An early local capture assigned an untyped Array to typed scores; it failed and was corrected with Array.assign. Initial small-window checks mistakenly compared logical rectangles with physical pixels; they were corrected to use the actual viewport transform. An inherited canvas minimum caused a crowded workshop; the final explicit size was set after node initialization and rerendered. Early unbound page tweens produced freed-target warnings during rapid synthetic navigation; final transitions are bound to their own panels. The final local targeted run and downloaded new logs contain no script errors or those tween warnings. Older cleanup/software-driver warnings remain,so the entire project is not called warning-free.

Premium denotes the art-direction target,not certification of Zelda/commercial quality. No copied Nintendo icons,logos,fonts,textures,audio or screenshot assets are included. The reference-to-design distinction and official sources are in PHASE12.md.

No human usability/accessibility/fun/comfort session,all-drawing clipping elimination,whole-swing perfect visual collision,real Windows GPU/FPS,audio-device latency,gamepad completeness,network multiplayer,Steam/release EXE or new live GI integration is claimed. Large/extreme drawings may extend below/right of the screen; active strikes deliberately prioritize existing contact alignment. Physical limits remain explicit rather than promising unlimited size.