# Phase19 — local candidate and publication checks

2026-09-30. Actual prior Phase19 source could not be recovered: its available evidence archive contained only two failure-status records. This is a new implementation from remote Phase18 HEAD07fcaff6798c40a34f5a8c9b319feadfcf074148, preserving its newer documentation in the Git tree. The mounted runtime archive reproduced exact Phase18 tree6b5cd191335c556a406e9903654af4a3d2624ae1 before editing.

Local official Godot4.4.1.stable.official.49a5bc7b6 was restored from the retained tools archive after SHA512 verification. The first import command exceeded its wait window; a clean subsequent import completed. No failed/unfinished process is counted as passing.

Observed local results:102 new world/state assertions,94 unchanged contact assertions,default entry and14 matches of4 rounds passed. Rendering produced26 actual images. The first visual iteration was too bright; direct-light energies were reduced and linear tone mapping retained, then all26 final views were regenerated successfully. Original test runners are being completed; final exact-commit remote status will be appended after observation rather than assumed from publication.

New decorative pieces versus spatial/material groups: Sugar232/66, Arcade261/108, Station306/56, House150/38, Warehouse352/78, Garden880/48. These counts describe NEW ornaments rather than a claimed whole-game FPS gain. Full/near render counters are separate captured-frame evidence. Real rendering uses Xvfb/Mesa software OpenGL and Dummy audio, not user hardware or human play.

Coverage: unchanged map geometry/collider/nav/hide points, original character and weapon representation, material/light reset without accumulation, bounded cached batching, small-only distance culling, no dynamic occupancy input and stable frame updates. Existing326-user manor bake and original native character/GI manifests remain unchanged. Other-map lighting is authored direct light, not new baked GI.

Remaining scope: human art/fun/visibility approval, hardware CPU/GPU/VRAM/frame-time benchmarking, all-map GI baking, all-drawing clipping and multiplayer/Steam/EXE. Old valid-path shaderUID fallback and softwareVSync warnings are not suppressed. No engine/fonts/caches/saves are distributed.
