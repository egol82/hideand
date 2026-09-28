# Phase 8 verification status

2026-09-28. Local official Godot 4.4.1.stable.official.49a5bc7b6 on Linux. The engine ZIP SHA512 was compared with the official manifest before extraction.

## Observed local checks

- New hand-fit and cosmetic-isolation tests: `GRIP_UNIT_RESULT: 198 checks, 0 failures`.
- New actual scene entry: `PHASE4_SMOKE_READY` (the shared controller marker, not a fabricated Phase 8 marker).
- Actual software-OpenGL capture: `GRIP_CAPTURE_PASS`, three map idle views, nine attack-stage views, a long-shaft and a sideways drawing (14 PNGs).
- An initial aggregate capture call exceeded its tool wait window; the subprocess completed and the required final capture/suite markers were subsequently checked. No incomplete run is counted as passing.

All original runners completed locally with zero assertion failures: 52 + 115 + 27 + 259 + 237 + 238 + 78 + 605 = 1,611 preserved assertions. Together with 198 new checks this is 1,809 individual assertions, not independent human scenarios. FIELD/CLASSIC matches on all six maps also completed four rounds and matched the earlier fixed-seed results. Remote Windows/Linux CI is pending the exact published commit; upload alone is not engine evidence.

## Interpretation

The approved generated images remain visual references only. Captures are actual reproducible Godot scenes, staged rather than manual playthroughs. Linux Xvfb/Mesa uses software OpenGL and Dummy audio; Windows headless cannot establish Windows GPU/FPS or real audio quality. Old ObjectDB/unsupported V-Sync warnings remain; no warning-free claim is made.

Contact stability tests assert transforms and shape invariants. They do not prove anatomical perfection or zero clipping for every possible user drawing. No original weapon geometry or authority code is deliberately changed. Source readback and actual CI references must accompany publication.
