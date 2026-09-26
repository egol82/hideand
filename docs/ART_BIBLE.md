# Art Bible — shared toy world

Player drawings must look native to the world, not like flat black stickers pasted onto a rendered room.

## Shared rules

- Avatars: rounded shapes, tiny limbs, simple expressive face, mint/pink/yellow/blue.
- Weapons: original stroke paths, rounded tubes and optional shallow filled simple loops. Five common colors. No realistic metal or photographic texture.
- Materials: roughness 0.8, metallic 0, metallic_specular 0.25. The same material vocabulary is used by characters, props and weapons.
- Lighting: warm key light, restrained cool fill and low ambient energy. Validate in the actual Compatibility renderer; avoid clipped white walls, rug and toy faces.
- Room: small readable diorama, clear hiding locations, plain wood/cardboard/plant colors. Keep the fighting rug unobstructed.
- UI: cream panels, dark ink, mint confirmation buttons. Explicit colors for checked/hovered states, not just normal state. Minimal readable match HUD.
- Feedback: generated short effects, squash, small particles, optional shake. Reduced motion disables shake and preview rotation.

## Geometry promises

Stroke positions and relative shape are preserved. Grip translation, common tube thickness and maximum reach normalization are expected transformations. Filling only applies to validated simple closed loops; complex shapes remain tubes. Hollow and solid modes must both match their hit samples.

## Verify visually

Use CI's actual 01_drawing, 02_seeking, 03_reveal, 04_duel and 05_result captures or F12 screenshots from the game. Check clipping, label size, button contrast, body/weapon contact and camera framing. Captures from a scripted scenario do not replace testing animated motion and input during normal play.

This is currently a procedural prototype. The earlier high-detail generated living-room illustrations remain a direction reference, not the current rendered quality or an implemented asset pack.
