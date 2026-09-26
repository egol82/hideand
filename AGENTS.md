# Agent instructions — Hide & Smashing

Read `README.md`, `docs/TEST_STATUS.md`, `docs/ART_BIBLE.md`, and `docs/ASTRA_START.md` before editing.

- This package is source-ready, not engine-verified. Do not claim a passing build from the included offline Python report.
- Stay on Godot + GDScript. Do not switch to Unity, a website, or an Android-only app.
- Keep player drawings as canonical vector strokes. Do not replace arbitrary drawings with a few predefined 3D weapons.
- The MVP art rule is shared matte toy geometry, not a black 2D scribble pasted onto a realistic scene.
- The Phase 1 geometry is rounded tubes along strokes. Do not advertise auto-filled solids or arbitrary semantic 3D reconstruction as implemented.
- Keep paid APIs, online services, analytics, ads and Steam integration out of Phase 1.
- No external font files or unexplained downloaded asset packs. Do not apply an open-source license to the user's whole project without their choice.
- Save drawings only under Godot `user://`. Validate file size, coordinate bounds, finite numbers, strokes and point limits before mesh generation.
- First run editor import, `tests/test_weapon.gd`, the `--smoke-test`, then a GUI playtest. Record exact commands, engine version, failures and screenshots.
- Never use reference/generated concept images as proof of an engine screenshot or of implemented features.
- Keep changes on a dedicated branch when an authorized repository becomes accessible. Do not force-push, delete unrelated files, change repository visibility or merge unreviewed work.
- Do not continue to multiplayer until the Phase 1 acceptance checklist is actually passed.
