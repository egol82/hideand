# Phase 12 — Drawn scale & the Toy Journal

2026-09-29. Feature branch `phase12/premium-interface`. Default entry: `scenes/phase12.tscn`.

## The user-requested change

The original drawing data already uses a fixed nominal 2.4 world-unit canvas scale, then caps reach at 2.20m and filled area at 2.6 square world units. The *first-person renderer*, however, applied an inverse-reach multiplier (`0.68 / reach`) which made substantially different drawings look similarly sized. This entry removes that visual normalization: **the same 0.40 presentation factor is used for every drawing**. A smaller drawing stays smaller, a larger drawing stays larger, until the existing shared physical limits apply. Tube thickness remains the original fixed thickness, so centreline proportions and outer bounding-box ratios are deliberately distinguished.

The shape/selected grip/original mesh/world reach/contact samples remain the same canonical data. Damage, timing, filled-area budget, storage and online/security boundaries are not secretly changed. In the workshop, current width, height and reach are shown; the user is told when a physical size cap applies. Preview framing is fixed rather than automatically zooming every drawing to the same size.

The resting weapon is moved down and outward, tilted toward the right, and translated farther down when its bounding corners would enter the central sight window. **This never rescales the drawing**. Very large or unusually oriented drawings may be cropped by the lower/right screen edge; the camera is not forced to fit every extreme weapon. At an actual hit, the existing 55ms selected-contact alignment deliberately takes precedence over resting visibility placement. A visible attack may therefore cross the centre; a completely unobstructed screen throughout an attack is not promised.

## Original native UI design

The new interface uses a deep forest palette, warm paper text, restrained brass/mint accents, simple original geometric health pips, spacious two-column compositions and consistent keyboard-focus states. The design is an original adventure journal, not a Zelda asset/layout replica.

- Title/menu: fewer choices at once, explicit hider/seeker starts, native map/mode selector and public map illustration, workshop/settings/help/art/language/quit.
- In-game HUD: local health/role, compact round timer, public remaining count and local score, one contextual tool/readiness panel. Old overlapping paragraphs are not drawn underneath. No enemy or occupied-hideout radar was introduced.
- Context prompts appear only for actions or reported events. Longer controls/rules live in the field guide and remapping page. Critical warnings and hiding/transit masks remain.
- Workshop: real drawing input, live 3D preview, explicit physical dimensions, shape/fill/handling controls and the same eight-slot save/overwrite/recovery handlers. Buttons are not decorative screenshots.
- Settings: view/sound and motion/comfort columns, original live sliders and callbacks, key remapping, accessible focus, art comparison.
- Atlas/result: original map linework with public layout/local position only; sorted actual scores with existing bonus badges. Neither page invents new stats or rewards.
- Korean and English use the existing SystemFont fallback. No font files are bundled. A persistent 1280x720 logical canvas is letterboxed/scaled by Godot; the tests project controls through the actual canvas/viewport transforms rather than confusing logical coordinates with physical 1120x680 pixels.
- New menu transitions are 140ms and disabled by reduced-motion. Their tweens belong to the disposable panel so rebuilding menus cannot leave orphaned transitions. Simulation clocks are unaffected.

## Reference basis (checked 2026-09-29)

Nintendo's official Zelda product/media pages and official Tears of the Kingdom tips were consulted for the separation of exploration view, status indicators, and controls available from a system menu. Information hierarchy, breathing room and contextual guidance are our design interpretation, not a claim Nintendo publishes a specific rule or a proven cause of commercial success.

- Nintendo, Breath of the Wild media: https://zelda.nintendo.com/breath-of-the-wild/media/
- Nintendo, Tears of the Kingdom: https://zelda.nintendo.com/tears-of-the-kingdom/
- Nintendo Support, general tips (controls in System Menu and Special Controls): https://en-americas-support.nintendo.com/app/answers/detail/a_id/62057/p/897/c/950

No game screenshot, franchise icon, logo, texture, music or typeface from those games is shipped. 'Premium' is the target art direction, not a measured or certified quality level.

## Structure / invariants

`premium/game.gd` is an explicit new entry adapter on the Phase11 controller. `premium/interface.gd` rebuilds the UI with the original action handlers and states. `skin.gd`, `backdrop.gd`, `hud.gd`, `map_stamp.gd` are presentation-only components. Shared `phase4/first_person.gd` adds a false-by-default `drawn_size_view` flag, so historical scenes retain their earlier view scale and layout. The existing sync test gets only a scene-selection flag; its assertions are unchanged.

Seven maps, hiding/peek/two exits, clues/decoys/search/ambush, original draw data, round-paw grips, matching hit events and reaction time, all previous files/scenes, and LICENSE remain. No new paid asset, remote API, analytics, physical scale or fake reach boost is added. Main/previous branches are not merged automatically.

## Run

Open `project.godot` in Godot Standard, F5. The new menu starts as hider/seeker or workshop. Escape opens settings; main guide Escape returns to the title.

`GODOT_BIN=/path/to/godot python tools/test_premium.py --matches`
Render via a display/Xvfb with `--capture`. Full observed commands and failures are recorded in `PHASE12_TEST_STATUS.md` after execution; source code alone is not passing evidence.
