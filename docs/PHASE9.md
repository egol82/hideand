# Phase 9 — comic smash reactions

2026-09-28. New default entry `scenes/phase9.tscn`; feature branch `phase9/smash-reactions`.

## Implemented

- Actual contact-driven star/chip bursts and short expanding rings, with distinct quick/balanced/heavy presentation. Normal, blocked and finishing contacts are not interchangeable.
- Short localized world-space comic labels: BOP/BONK/CLONK/SMASH and corresponding Korean copy. They are depth-tested, pooled and transient, not enemy tracking overlays.
- A cosmetic layer between each actor's FacingRoot and body art: directional squash/rebound, little arm flails, squint/spiral eyes and three orbiting toy stars. It does not parent or resize the weapon.
- A last-hit accent and 0.54-second toy exit echo when the authoritative actor actually disappears. The echo uses a captured PUBLIC contact transform; it never follows a hiding or respawn position. Surviving actors are not replaced with ghosts. This is a non-colliding animation, not a new physical ragdoll or a change to elimination.
- Original synthesized thump/rubber squeak/wood-clonk layers with three deterministic variations and a six-voice spatial pool. No sampled game audio, paid API or network access.
- Existing first-person hit/hurt/blocked feedback remains separate. Misses retain the existing air-swish behavior and do NOT trigger a fake impact or target response.
- Reduced motion or zero contact-effect strength clears new moving VFX/reactions. Core minimal hit/hurt HUD and inherited low-level animation behavior remain; game clocks and damage do not change. Pause freezes presentation lifetime; restarting/menu/round transitions clear state.

## Integration

`game.gd` exposes `smash_contact`, `smash_frame`, and `smash_reset` presentation signals and an opt-in scene flag. The observer receives a duplicated event with handling and pre-damage last-hit context. Original event history, authority contact geometry, score rules and damage remain unchanged. Prior scenes use their prior effects because they do not attach SmashDirector. The new scene composes GraphicsDirector, GripPresentation and SmashDirector instead of adding a new gameplay inheritance layer.

The existing audio bug where a capture always played the escape sound is suppressed only in the new scene. The distinct finishing-contact cue already covers that outcome. No capture is delayed to show an animation and no one loses camera control.

## Budgets / readability

96 active particle slots distributed across three instanced mesh types (star, chip, ring), 6 pooled text labels, 4 actor reaction layers, 4 exit echoes, 6 sound voices and 128 recent event identities. Stars/letters have no collision and depth-test normally. No per-hit nodes, followers of hidden targets, permanent confetti, global time-scale, damage changes or extra invulnerability.

Existing data, storage, hand grip, six map layouts, active bounds and bot hearing are retained. New sounds are presentation only, not extra AI hearing events. The final source contains no generated frame dump, external font, engine binary or credentials.

## Verification

`GODOT_BIN=/path/to/godot python tools/test_smash.py`

`python tools/test_smash.py --matches` runs the new default scene in both modes on all six maps. `--capture --video` under a display/Xvfb captures eight stills and 180 sampled render frames. The workflow encodes a six-second silent preview and removes the frame dump before artifact upload.

Read PHASE9_TEST_STATUS.md for observed results. Captures are staged deterministic engine sequences (the visual fixture injects a contact) and are not manual player footage. A separate test uses real mouse input dispatch and swept collision to reach the same event consumer.

## Limits

No real-player fun/comfort/accessibility or audio-device audition, hardware FPS/Windows GPU benchmark, online/Steam/release EXE, fully skinned physics ragdoll or universally penetration-free weapon/hand contact is claimed. Confetti is cosmetic and can intersect nearby geometry; labels are depth-tested but do not provide a proof of every sightline's tactical fairness. Exit echo is a fixed-location theatrical fall, not a new gameplay displacement. Effects are original procedural toy graphics, not commercial-art completion. Prior engine cleanup/software V-Sync warnings remain documented.
