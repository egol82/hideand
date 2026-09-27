# Phase 6 verification status

2026-09-27. Published commit and remote CI must be recorded after readback, never inferred from a successful upload.

## Local real-engine evidence

Official Godot 4.4.1.stable.official.49a5bc7b6 on Linux. Engine archive was verified against its official SHA512 manifest before extraction.

- New graphics assertions: **78 checks, zero failures**. Material cache/mipmap/normal tiles, finite bounded weapon meshes, original vectors/contact samples, conservative bevel fallback, all three map/nav/collision fingerprints, repeat-open idempotence, preview antialiasing, view/world material separation, hidden actor shadows and unit weapon scale are covered.
- New default scene initialized with the actual shared `PHASE4_SMOKE_READY` marker.
- Seven staged 1280x720 renderer captures completed with `GRAPHICS_CAPTURE_PASS`. Warm lighting was reduced after inspection of an overexposed first iteration; detached authority shadow artefacts on the cosmetic weapon were also corrected. Current final captures contain no script/shader errors.
- Preserved original suites completed on the final local source: Phase 1 52, Phase 2 115, Phase 2 interactions 27, Phase 3 259, Phase 4 237, quality 238 assertions, all zero failures. With the new 78 checks this is 1,006 individual assertions, not independently designed human scenarios. Earlier scene smoke tests and map/mode autoplay runs also completed.
- Source hygiene: 309 static conditions passed; these are separate from engine assertions. Exact local suite logs were retained. Remote Windows/Linux verification is not inferred from these local runs.

## Evidence interpretation

Tests are individual assertions, not independent human usability scenarios. Prior suite's 110 bilingual field-presence checks remain included in its 928 count. Screens use Xvfb/Mesa software OpenGL with Dummy audio. They are staged actual engine scenes, not generated concept art or real participant sessions. No hardware frame-rate, Windows GPU, audio quality, human fun, accessibility or shipping-quality claim follows from these checks.

No physics, navigation, scoring, storage or input controller code changed. Test fingerprints nonetheless compare the composed final scene with the original controller on all three maps. Artistic contact planes are not baked illumination or SSAO. View shadows are intentionally cosmetic and separate from world materials.

Remote publication/Windows/Linux CI: pending actual retrieval. Legacy ObjectDB cleanup and unsupported software V-Sync warnings remain documented; do not describe the entire old/new suite as warning-free.
