# Astra — Phase18 smash polish handoff

Use `phase18/smash-polish`, default `scenes/phase18.tscn`. Read AGENTS.md, PHASE18.md and PHASE18_TEST_STATUS.md. Preserve all earlier snapshots and user changes.

The new adapter overrides only presentation. The shared atomic contact path still owns effects/audio/reaction; phase16 applies its HIT bones from that same event. Keep the94 sync predicates unchanged. No new damage clocks, camera shakes, time_scale edits or hit-stop.

Impact18 extends the old pool; bounded puffs/trails add modest detail. Audio18 uses one mixed waveform per contact and the original six positional voices. The old swing handler retains footsteps/hearing/metrics and changes only its played waveform by handling type. Camera position/yaw/pitch/FOV and all original weapon authority remain untouched; hand recovery yields to contact alignment.

`Smash polish` is session-local comparison and must restore old star sizes as well as sound/effect paths. Master mute/pause must reach active positional impact streams, not just generic game audio. Actual audio occlusion is an approximate ray from the camera to an old contact event, never live hidden-player tracking.

Run test_feel18.py --matches, all inherited runners, actual captures and source readback. The optional event-timed mono soundtrack made by mix_feel18_preview.py is not an audio hardware recording or full spatial mix. Distinguish it from real device/latency QA.

Original model/GI manifests, materials, proportional0.40 lowered paws, animation/IK, manor detail, all seven maps, hide/search/decoy/exit rules, input/saving and LICENSE are unchanged. No force-push/main merge, paid assets, engine/font/cache/private files.
