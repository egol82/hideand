# Phase 3 validation status

2026-09-27. Local development checks below are actual executions, not predictions. See CI links added after remote verification for the exact published commit.

## Local engine

Official Godot 4.4.1.stable.official.49a5bc7b6, Linux. Official SHA512 manifest verified before extraction. GUI captures use Xvfb + Mesa software OpenGL with Dummy audio. This is not Windows GPU evidence or an FPS benchmark.

- Preserved regression assertions: Phase 1 weapon 52; Phase 2 unit 115; Phase 2 input integration 27; zero assertion failures.
- New Phase 3 assertions: camera/layers/input/aim, every-map navigation and all 46 hideout capsule clearances, timers, occlusion/focused E, original weapon preservation, pause, map switching and spectator flow. Current exact count is recorded in the execution log.
- All three maps complete four rounds in fixed-seed physics/bot matches. Engineering metrics are not balance claims.
- Headless Phase 3 audio is muted to avoid untested audio-device teardown; this does not verify real sound output. Legacy Phase 2 headless runs may report resource cleanup warnings and must not be advertised as warning-free.
- Seven scripted real first-person UI/gameplay screenshots. They are staged reproducible engine scenes, not a recorded manual playthrough.

## Not verified

Human mouse handling/feel, nausea, Windows GPU rendering, real audio output, hardware frame rate, controller, networking, Steam/release export, commercial art quality, exhaustive arbitrary-drawing world/view alignment and large-map balance.
