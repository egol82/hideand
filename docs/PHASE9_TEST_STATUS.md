# Phase 9 verification — local results / publication pending

2026-09-28. Official Linux Godot 4.4.1.stable.official.49a5bc7b6 was extracted only after checking its archive against the bundled official SHA512 manifest.

Observed locally:
- SMASH_UNIT_RESULT: 100 checks, 0 failures.
- Actual new entry emits the existing PHASE4_SMOKE_READY marker.
- Eight 1280x720 real renderer stills and 180 sampled frames completed with SMASH_CAPTURE_PASS and SMASH_SUITE_PASS under Xvfb/Mesa software OpenGL / Dummy audio.
- Heavy-impact and finish stills were visually inspected. The first test iteration had two false comparisons against a pre-reset actor position; the test now snapshots the current authoritative transform before each comfort comparison. No check was removed.

The new checks include distinct contact outcomes, real input-handler/swept contact, no duplicate VFX, hidden-actor suppression, closed-form frame-step independence, bounded pools, pause/reset behavior, original drawing/samples/weapon transform, unchanged clocks and scores, exit echo pinned to last contact, and generated audio sample headroom. Of the 100 checks, 30 cover bounded audio samples rather than gameplay scenarios.

All earlier suites passed locally: 1,826 prior assertions plus 100 new assertions = 1,926 individual assertions. New default-entry FIELD/CLASSIC matches on all six maps (12 matches, four rounds each) completed, and the aggregate run ended with LOCAL_FULL_SUITE_PASS. Exact final published commit, remote CI jobs, source readback and final totals must be recorded after observing them; a successful push is not execution evidence.

Synthetic handlers / fixed-seed bot runs are not human fun or balance tests. Staged captures are not manually played combat. No audio-device audition, GPU frame-rate, complete ragdoll/IK or shipping-readiness claim. Prior warning boundaries remain in the historical test documents.
