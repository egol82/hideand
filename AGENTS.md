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
