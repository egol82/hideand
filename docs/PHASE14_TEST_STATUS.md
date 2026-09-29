# Phase 14 — candidate validation

2026-09-29. Local engine official Godot4.4.1.stable.official.49a5bc7b6 restored from the existing mounted tools archive. ZIP bytes match the retained official SHA512 manifest; engine binaries are not part of any deliverable.

Observed candidate results:175 material/state assertions and94 unchanged contact assertions pass. Fourteen controlled OpenGL pixel assertions pass: each family is black with all lights off, opaque-wall image difference is zero in the fixture, and shadowed material luminance is lower than unshadowed. Actual 1st/2nd generation and same-pigment render fixtures compile the shader and produce real pixels.

All inherited suites,14 new-entry matches,final renders and exact remote SHA/source readback will be recorded after observing completion. Do not infer GPU tests from headless imports or finished CI from an upload alone.

New visual recipes have not received human art/visibility acceptance,Windows hardware profiling,audio-device measurement or newGI/full-animation validation. The corrected revision-driven equip test does not manually force a graphics-profile switch to hide a stale world material. Known inherited cleanup/software-driver warnings are separate from script/shader errors.
