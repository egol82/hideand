# Phase 5 — playability, recovery and cosmetic isolation

2026-09-27. Based on the production audit's focus on trustworthy feedback, low waiting time, readable controls and bounded local data. This is a playable-quality increment, not commercial-release certification.

## Changes and boundaries

### A. Cosmetic geometry bug
The Phase 4 body and world weapon shared a scaled parent. A hurt response changed weapon global basis scale from `(1,1,1)` to approximately `(1.08,0.91881,1.072515)`. The new FacingRoot only rotates; body_art is its cosmetic child and the world weapon is a sibling. Repeated hurt/aim steps at 30/60/120 Hz verify unit world weapon scale while visible body squash remains. This is a new functional fix beyond the earlier accumulated-pitch correction.

### B. First-use workshop
The title offers an untimed, unscored practice scene before the timed match. The checklist measures actual equip/movement/dodge/three contacts. Contact outcomes come from the same combat code as the match. A pink target is reset after being defeated; Tab reopens the drawing canvas without erasing progress. The chosen match map/mode are restored on leaving practice. No automatic claim that a human has learned the controls is made by the checklist.

### C. Captured players can prepare
Before the final round, captured players press the workshop action (default Tab). Bots and the current timer continue; cursor is released for editing. A clone is queued for the next round, never applied to the current actor. Esc/pausing/round end preserve the most recent valid sketch, and the next drawing phase consumes it once. Empty later edits do not erase a previously queued valid sketch. No hidden-opponent coordinates, support powers, revived player or concurrent player combat were added.

### D. Controls and readable UI
11 physical keyboard/mouse actions can be rebound with conflict/reserved-key checks, reset and persistence. Supported codes: letters, numbers, arrows, Space/Shift/Ctrl/Alt/Tab and primary/secondary/middle mouse. Esc/Enter/F11/F12 remain fixed. Mouse wheel, chords, gamepad, side buttons and arbitrary hardware scan codes are not implemented. On-screen hints use current bindings. Menu buttons have visible focus styling; complete gamepad navigation is not claimed.

Major title/drawing/practice/settings/remap/results copy supports English and Korean. Windows Malgun Gothic, macOS Apple SD Gothic Neo or an installed Noto CJK font is requested through SystemFont. No font is bundled; a target without a CJK-capable system font can lack Korean glyphs. CI installs its OS font package only for Korean rendering. Some inherited world labels and incidental/debug strings remain English.

### E. Local persistence
New settings and controls live at `user://phase5/*.json`; eight toys live at `user://phase5_toys`. Files are capped at 64 KiB and semantic bounds remain enforced. A normalized-JSON SHA256 digest detects accidental edits/damage. Writes go to a checked `.tmp`, then rotate a valid current file to `.bak` and promote the temp. Corrupt current bytes cannot overwrite a good backup. Recovery is reported in toy UI and when settings/controls recover. Overwriting a valid slot needs a second save click.

Legacy Phase 4 toys and preferences are read-only migration sources. The new format never automatically rewrites the old files. A corrupt new toy slot is not silently replaced by stale legacy data. Settings sliders save after a debounce and on leaving the menu rather than rewriting three inherited files per tick. Diagnostics remain opt-in and local-only.

Limits: no power-failure proof for every filesystem, no cryptographic authentication, no multi-process writer locking or cloud sync. Both generations corrupt means rejection/defaults, not invented recovery. Tests use `user://quality_tests`, not real player slots.

### F. Visual increment
Named eye/glint parts, subtle blink and attack/hurt mouth/body lean; deterministic 64x64 foam/wood/fabric surface tiles generated in code with mipmaps; shared sphere geometry instead of separate identical primitive resources; additional non-colliding geometric wall art. Returning to the title or practice clears previous contact particles, sounds and caught/hurt notifications. No photo textures, downloaded packs or externally generated replacement weapons. This remains a procedural toy-world prototype without baked GI/full IK/production assets.

## Architecture
Phase 5 entry uses the existing controllers under scripts/phase4 to avoid adding another inheritance layer. New independent components under scripts/quality own storage, actions, practice tracking, next-round queue and UI copy. Phase 1–3 game source is unchanged. Phase 4's exact older behavior is preserved in its branch, not in an unchanged phase4.tscn on this new branch.

## Verification meaning
`tools/test_quality.py` verifies the actual new entry scene, storage failures, InputMap/events, practice combat, workshop timing/isolation, overwrite/recovery UI and cosmetics-independent weapon scale. Paired-copy checks confirm fields exist, not linguistic quality. Render tests additionally save nine staged 1280x720 screens. Existing physics/AI matches remain part of CI. None of this substitutes for actual human input feel, four-PC online play, Windows GPU rendering, sound audition, accessibility study or a commercial art review.
