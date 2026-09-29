# Astra — Phase 12 handoff

Continue on `phase12/premium-interface`, default `scenes/phase12.tscn`. Read AGENTS.md, PHASE12.md and PHASE12_TEST_STATUS.md. Do not recreate the game.

- Same0.40 camera presentation multiplier for every drawing. Existing world nominal2.4 canvas scale/reach2.20/fill-area2.6 limits stay. Never normalize all drawings to equal apparent size.
- Resting weapon is translated down/right, never reduced by a visibility fit. Contact alignment overrides rest pose during real swings. Verify different sizes and narrow/wide/split drawings; disclose cropping limits.
- Native premium interface preserves original callbacks: hidden exits/peek/skills, settings/remaps, save confirmation/recovery, draft timing, map privacy and result scores. No decorative fake interactions.
- Keep information hierarchy and generous spacing; do not restore overlapping paragraphs on the HUD. Additional guidance belongs in the guide/settings. Localize new copy in Korean/English.
- UI layout tests must use the viewport's final transform; Godot uses a1280x720 logical canvas. Buttons/canvas/primary action must remain visible at1120x680 and larger. Avoid per-frame node creation, through-wall info, global time or player-state writes from UI.
- Run every existing test runner and test_premium.py --matches. Reuse94 existing sync assertions with --premium. Real captures are staged engine evidence, not concept art or manual playthroughs.
- No Nintendo asset, font, music or logo may be copied. No paid services/telemetry/engine migration. LICENSE/main/other branches preserved. Commit on feature branch and PR; no unrequested merge/force push.
