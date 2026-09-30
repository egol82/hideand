# Phase21C — Canyon increment and Wetland expiry boundary

Read docs/PHASE21C.md. Keep same phase21/living-nature and draft PR21, stacked on Phase20.
- Preserve Pine/Wet tests and numeric10-map geometry contracts; no remakes or new seed expansion.
- Reuse contextual travel: conservative full/next-segment capsule checks, occupancy refusal,
  same point on abort, no hidden status/grace and original hit/knockback behavior. No closing gate.
- Eight non-colliding wind toys return to authored transforms; cues store fixed past event positions.
  No live enemy radar, unbounded physical props, camera shake, footprint suppression or new damage.
- Expire short clues BEFORE inherited listener completion; freeze expiry on pause/inactive ticks.
  Keep the39-case wet boundary regression, including same-frame and just-before/after controls.
- Existing actor/map/art/GI contracts stay intact. Source ZIP/new-file-inclusive patch and actual
  logs come before remote publication. No fake CI success or human/hardware approval.
- Same stacked draft PR only. Full seed variation is explicitly deferred.

# Phase21B — Wetland second increment

Read docs/PHASE21B.md; same scenes/phase21.tscn and phase21/living-nature branch.
This increment explicitly authorizes Reedwater additions; Pine-only scope below is historical.
- Preserve Pine implementation, tests and four-second shared thicket budget. Reuse its service
  subclass and original movement sampler,24 tracks/32 sounds,investigation and round timers.
- Wet footprints live3s; wet boots expire2.5s after actual movement in water. Reeds react for1.5s.
  Rendering and investigation must expire together. Never follow current hidden-player positions.
- Four short sparse reed tufts are not cover or physics bodies; retain original opaque cores,
  actual collider/nav/home/spawn fingerprints and all10 maps. No new swimming or slowdown.
- No triggers from stationary,hidden,dead,airborne,transit or teleport actors. Pause freezes time.
  Comfort disables sway only,not finite visual clues or hearing authority.
- Run wetland21 focused/Pine126/sync94 tests and affected hide/maps/outdoor regressions.
  Preserve old assertions; their original-zone check excludes only separately verified new wet zones.
- Save source ZIP,new-file-inclusive patch and actual evidence before remote publishing.
  Same stacked draft PR only; canyon and broad seed variation are NOT part of this increment.

# Phase21A — Pine first increment only

Read docs/PHASE21A.md. Default scenes/phase21.tscn, target phase21/living-nature.
- Preserve all Phase20 contracts below. The two authored trail sound zones and time-limited
  contextual bushes are explicitly authorized gameplay additions, not generic art-only edits.
- Reuse existing sound/track pools,search/peek/ambush/duel/capture and timing. No hidden-target radar.
- Four-second allowance is per hider per round across both bushes,not per entry. Blocked exits
  may never extend concealment. Preserve fake sites,clearance,original collision and10 maps.
- No wetland/canyon/whole-seed-variation expansion in this first commit. Do not cite previous227 tests.
- Run test_pine21.py,unchanged94 contact checks and affected hide/map regressions. Keep source ZIP
  and an applicable new-file-inclusive patch BEFORE remote writes. Draft stacked PR only.

# Hide & Smashing — Phase20 nature playgrounds

Read docs/PHASE20.md, PHASE20_TEST_STATUS.md and ASTRA_START.md. Base is verified Phase19 (6f6c1e1; documentation7f51909), not a Phase18 recreation. Phase20 is the user's outdoor-map request, replacing the earlier proposed human-QA phase.

## Preserve prior milestones
- Retain all old7 maps and original geometry/navigation/hiding fingerprints. No original collider,score,time,damage,input,SafeStore backup or clue rule changes from art code.
- Keep model/GI manifest bytes,18-bone body/Skin,Phase14 shader,manor native326-user GI,animation/IK,Phase17 scenery and Phase18 effects/audio. No fake GI claims for new direct-lit maps.
- Original drawing/grip/hit samples,0.40 proportional lower-right paws and first-render selected-contact alignment remain. No invented handles,forced camera/FOV changes,free ambush damage or root motion.
- AttackSpec and confirmed contact own effects/audio/HIT onset. Preserve94 original sync predicates; only add a new scene selector. Mute/pause/comfort settings must not alter damage or AI knowledge.
- Concealment must hide body,face,shadows and trails. No occupancy-dependent decoration or current-position radar. Existing contextual passages/hideouts are not simulated interiors.
- Preserve bounded cached audio/particles/geometry,world-space stance targets and no animation-driven physics. Respect old component restoration paths and optional native preview limitations.

## New-map boundaries
- Cover art/collision/nav derive from one immutable plan. Round trunks use matching cylindrical colliders; other conservative cover dimensions share their plan footprint. Full free-cell connectivity and capsule-clear entries/exits are required.
- New maps are flat traversable loops with no required jump. Water bands are decorative,not swimming/death triggers. Visible embankments bound the playable region; distant ridges are backdrop only.
- Only small non-cover grass/flowers use distance culling. Never hide trees,rocks,opaque reed cores,hideout containers or clues with graphics quality. Use8m-cell/material instancing,not one unbounded global batch.
- No all-map GI rebake,physics foliage,final hardware FPS or human fun/visibility approval claim.

## Verification and delivery
- Run test_outdoor20.py --matches:10maps×2modes20 complete matches,actual movement/hide/exit/contact and unchanged sync checks. Compare old14 results with recoveredPhase19.
- Target affected World19/Hideplay/Premium/Feel18 regressions rather than re-running every historical stage. Successful prior CI remains historical evidence,not new local execution.
- Render actual game/aerial/contact/range views. Aerial/isolated collision fixtures are not new gameplay cameras or human playthroughs. SoftwareGL counters are not hardware performance certification.
- Record exact source,logs,markers,exit codes,known warnings and rejected iterations. No fabricated check totals or source-recovery claims.
- Feature branch/PR only. No merge,production deployment,payment,credential requests,new Cloud Codex,force-push,external paid art,engine/font binaries,caches,private saves or raw-frame dumps in deliverables.
