# Phase 11 — local verification / publication pending

2026-09-28. Local official Godot4.4.1.stable.official.49a5bc7b6 on Linux; its archive was verified against the official SHA512 manifest.

Observed on the implementation candidate:
- New hide/search suite: 257 checks, zero failures.
- Existing contact-sync suite against the new scene: 94 checks, zero failures. No assertions removed or weakened; only a scene-selection flag is added.
- Physical CharacterBody3D traversal up and down both ramp-backed staircases, not test teleports.
- Three seeds check twelve hiding entries and24 exit ports for capsule clearance/floor support, full graph connectivity, seeded reproducibility and true-site capacity.
- Actual hiding/exit/ambush input; peek LOS and range; occupied exit fallback; bounded clue lifetime; decoy's saved source position; stationary listening and interruption; ordinary versus loud quick inspection; role/charge-limited passage, laundry transfer, preserved floor-height sound; anti-spam caps; saved-key conflict avoidance; old active hiding sites.

All fourteen new-entry map/mode matches finished four rounds, including real bot movement and contact. All previous engine runners passed with their original assertions: 2,128 retained +257 new =2,385 individual assertion definitions. The repeated94 sync checks are not counted twice. The full local runner exited0 with HIDEPLAY_LOCAL_ALL_PASS. The actual default-entry smoke also returned PHASE4_SMOKE_READY. Nine1280x720 stills and180 actual-input staircase frames completed with HIDEPLAY_CAPTURE_PASS; a6-second silent MP4 was encoded. A separate early preview call exceeded its tool wait window; the final complete runner is the evidence, not that partial wait result. Source readback and exact remote results remain to be recorded after publication.

Initial failures were investigated rather than ignored: a blocked hardcoded staircase graph connection was replaced with a same-floor clear landing connection; a hearing fixture was outside its stated12m range and was corrected to put the listener within range; the ambush contact fixture was positioned at a real weapon-reachable distance. No guaranteed hits or artificial damage were added to production code.

Counts include repeated seed/site checks and are not independent human-play scenarios. Stills are staged real engine scenes; stair footage uses actual input/physics but is an automated scenario. No audio-device audition, Windows GPU/FPS measurement, human fun/fairness/comfort, full two-floor lighting bake or network testing is implied. Final precise counts and commit/CI references follow observation.
