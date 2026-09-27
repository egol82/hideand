# Art Bible — shared toy world

Player drawings must look native to the world, not like flat black stickers pasted onto a rendered room.

## Shared rules

- Avatars: rounded shapes, tiny limbs, simple expressive face, mint/pink/yellow/blue.
- Weapons: original stroke paths, rounded tubes and optional shallow filled simple loops. Five common colors. No realistic metal or photographic texture.
- Materials: roughness 0.8, metallic 0, metallic_specular 0.25. The same material vocabulary is used by characters, props and weapons.
- Lighting: warm key light, restrained cool fill and low ambient energy. Validate in the actual Compatibility renderer; avoid clipped white walls, rug and toy faces.
- Environments: readable toy-scale house, warehouse and garden. Plain wood/cardboard/plant colors. Keep the central fighting rug unobstructed; provide recognisable navigation landmarks in large maps.
- UI: cream panels, dark ink, mint confirmation buttons. Explicit colors for checked/hovered states, not just normal state. Minimal readable match HUD.
- Feedback: generated short effects, squash, small particles, optional shake. Reduced motion disables shake and preview rotation.

## Geometry promises

Stroke positions and relative shape are preserved. Grip translation, common tube thickness and maximum reach normalization are expected transformations. Filling only applies to validated simple closed loops; complex shapes remain tubes. Hollow and solid modes must both match their hit samples.

## Verify visually

Use CI's actual 01_drawing, 02_seeking, 03_reveal, 04_duel and 05_result captures or F12 screenshots from the game. Check clipping, label size, button contrast, body/weapon contact and camera framing. Captures from a scripted scenario do not replace testing animated motion and input during normal play.

This is currently a procedural prototype. The earlier high-detail generated living-room illustrations remain a direction reference, not the current rendered quality or an implemented asset pack.

## Phase 3 first-person presentation

Perspective camera at 1.48 world units above the player. The right-lower view model shows two simple toy hands and the exact drawn weapon geometry with a bounded cosmetic display scale; real world reach stays unchanged. Share lighting/materials with the world, preserve depth testing, retract near walls, and avoid a weapon blocking most of the screen. Keep reticle and native prompts legible. Reduced motion disables camera-weapon bob/sway. Environments are single-level authored geometry, not realistic PUBG-style assets.

Real evidence: phase3_00_map_menu, phase3_01_drawing, phase3_toy_home_fps, phase3_02_reveal, phase3_03_swing, phase3_warehouse_fps and phase3_garden_fps in CI artifacts. These are engine captures; no generated image may substitute for them.
