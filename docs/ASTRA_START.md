# Phase19 handoff

Use phase19/world-finish and scenes/phase19.tscn. Read AGENTS.md and PHASE19.md before changing code.
World19 adds bounded small-detail batches and six-map direct-light themes over the unchanged Phase18 game. Manor keeps its actual native GI. Cover/clues/hidden players must never be in optional distance-cull batches.
Use tools/test_world19.py --matches and --capture plus all inherited regressions. Preserve original94 sync predicates, source/asset hashes and old scene entries. Runtime has no requirement for a new Codex Cloud environment or the user's PC original files.
Phase20 now means multiple outdoor natural maps per latest user request, not the old proposed human-QA-only milestone. Implement it on a separate branch only after19 is published; no merge/deployment/payments/credential requests.
