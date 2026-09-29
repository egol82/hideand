# Phase 15 — recovery candidate verification

Recovery: 2026-09-30 KST. Full final remote evidence is pending this candidate's next commit.

Original implementation ea8d989 computed real manor lightmaps on GitHub in run36588371682. Its editor log reached LIGHTING15_BAKE_PASS with326 users but then failed at renderer finalize. That run is not reported as cleanly successful. The exact artifact SHA256 is c1e27c2e3d28642dff297b6be9da2b85d47b157da1d8ee9e6af89c52d2c1635a.

The first recovery correctly required full live checks and failed because a test resolved ../Static paths from the bundle instead of the LightmapGI node. That test was fixed, retaining its all-users requirement; the next asset job published validated native resources as3b44c546. The next Windows check identified Git CRLF conversion on a manifest-tracked source. Explicit LF attributes preserve the original byte hashes; the hash check is not removed.

Local exact-source initial recovery passed105 lighting assertions and94 unchanged actual-input/contact checks. An actual OpenGL capture completed all13 images and isolated body/world-weapon/camera-weapon probe pairs with direct and ambient lights off. Its measured difference demonstrates real probe illumination, not node presence. The final candidate adds filmic highlight mapping, a correctly empty beauty fixture and extra provenance/renderer-probe checks; it is being revalidated.

The local official Godot4.4.1 archive was recovered from the retained tools package and SHA512-checked before extraction. Actual rendering uses Xvfb/Mesa llvmpipe software OpenGL and Dummy audio, not Windows GPU hardware or a human playthrough.

Headless Dummy rendering returns empty capture arrays; the state suite checks the native probe schema there and the actual render test separately requires populated points/SH. An intermediate incorrectly placed content assertion was rejected rather than counted as passed.

Final counts, exact runtime/source commit, Windows/Linux matches, render values and file readback must be recorded after observation. Historical shader-UID path-fallback and software V-Sync warnings remain possible. No fonts, engine binaries, caches or private saves are delivered.
