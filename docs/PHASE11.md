# Phase 11 — Hideaway Manor / hide-and-seek choices

2026-09-28. Branch `phase11/hide-and-seek`, default entry `scenes/phase11.tscn`.

This implements the user-approved hiding/search idea set as a playable offline prototype, not a claim of human-tested balance or finished commercial art. The original six maps and Phase 10 ToyStudio remain. A new seventh map carries the two-floor changes so old map geometry and saved assets are not replaced.

## Feature-to-implementation map

| Approved idea | Implemented behavior | Scope / deliberate boundary |
|---|---|---|
| Two-exit hideouts | Interact exits left; Dash binding selects right; an occupied exit is rejected rather than overlapping actors | All 12 manor sites and tested active hiding sites on the six old maps; old inactive sites fall back safely when no route exists |
| Fast/noisy versus quiet route | Manor carpets use the existing 0.5 hearing multiplier and chime tiles 1.65, with ordinary wood between | Does not alter speed or sound-cue rules through audio/graphics options |
| Peek | Hold Quiet while hidden to widen a narrow local slit; after 1.1s a small pair of eyes becomes visible | Real hunter range/cone/LOS is required. Release hides eyes. Not an X-ray camera or fully simulated opening cupboard |
| Ambush smash | Attack from hiding near a visible seeker leaves cover and requests normal FIELD discovery; one ordinary swing is queued after the shared reveal | Actual collision/damage only, no free hit, no extra immunity or hidden attack, not available in CLASSIC |
| Fake sound | One wind-up toy per hider per round; clear placement in front, 0.8s wind-up, one squeak from the stored toy position | The owner may move; the sound does not follow them. Finite four-toy pool |
| Traces | Actual moving grounded actors leave temporary footprints; leaving cover creates a disturbed-cover clue | 24 pooled records, eight-second expiry; Quiet walking leaves no step trace. Decorative curtain physics is not simulated |
| False hiding places | Two seeded cabinets are packed with toys and cannot be entered; searching finds no occupant | At least three true sites remain. False status is not shown on the map |
| Risky shortcut | Upstairs laundry chute reaches the lower laundry landing, with loud start/landing sound | Contextual 1.1s transfer through fixed waypoints, not a free-physics sliding tube |
| Sight breaks | Furniture islands and short partition walls create alternate routes on both floors | No moving walls, random opaque fog or low-quality setting that deletes blockers |
| Round shuffle | Bounded ±0.30m furniture placement, parcel variation and which two sites are filled change by seed | Manor placements only; not a new random floor plan. Old maps retain original geometry and shuffle filled status |
| Endgame narrowing | At 30s and 12s remaining, publish one broad room/quadrant clue and retarget the AI search tour to that region | Soft information pressure; no damaging circle, forced teleport or exact occupied cabinet marker |
| Private passage | One contextual toy passage lets a hider bypass a partition once per round; seeker follows normal routes | Manor only, one authored passage. No crouch-capsule or universal vent network |
| Seeker investigation | Listen stationary for 3s, inspect a recent visible footprint, or noisily inspect a cabinet instantly; shared 15s cooldown | Listen uses recorded sound <=5s old, not a live player radar. Normal cabinet check takes 0.65s and movement/blocked LOS cancels |
| Two-floor toy mansion | Living/kitchen/playroom below, bedroom/wardrobe/bath above, two ramp-backed physical stairs | 28×26m footprint, upper floor at4m, no jumping/elevators required. Existing navigation is adapted with AStar3D, not a flat-grid floor hack |

The map has 12 candidate hiding sites, two filled each round, leaving ten usable. Hiding starts at28 seconds, seeking160 seconds; these values are tuning hypotheses. The original point rules and anti-farming caps remain. Catching and escaping still use the existing game rules.

## Controls and readability

Existing eleven remappable actions remain. While hidden, Interact is exit1, Dash is exit2, Quiet is peek and Attack attempts ambush. Extra ability and cycle keys normally use Q/R but automatically choose unused keys if those conflict with saved bindings. They are contextual extra keys, not new saved remapping fields. The HUD shows the current bindings.

Manor map view shows two labelled floor plans, public furniture/stairs and the player's own position only. It receives no opponent/occupancy data. Broad late-game hints are explicit rule information, not accidental rendering leaks. Partial Korean/English UI remains; themed world labels are bilingual.

The new manor is the default on this entry; older persisted map settings are not silently migrated to a new schema. Existing map choices remain available in the menu, including their compact/full setting. Practice remains the existing untimed weapon lab, not a full scripted new-mechanics tutorial.

## Architecture

- `scripts/hideplay/manor.gd`: new geometry, conservative collision, public hiding ports, fixed single-way passages, floor-specific surfaces and connected 3D graph.
- `scripts/hideplay/services.gd`: authoritative hide/search choices, event snapshots, clue lifetime, bounded decoys/traces/peek markers, inspection/transit state.
- `scripts/hideplay/game.gd`: explicit new controller adapter composing previous gameplay and the new services; historical entry scenes keep the original controller.
- `scripts/hideplay/interface.gd`, `map_board.gd`: readable contextual controls and public-only two-floor plan.

The older controller's hearing bookkeeping was flat-floor; this adapter preserves swing/audio bookkeeping but uses the new sound snapshots with original floor height for AI routing. Hiding and passage entry clear pending dash motion. Presentation never drives damage, weapon scale, timers or score. New scene keeps the exact cute-paw/viewmodel/contact alignment and ToyStudio nodes.

Bots use the actual graph and stairs, old combat, genuine sound snapshots and inspection. Hidden bots can peek and, after a nearby seeker sound, spend one decoy and relocate once. They do not yet strategically plan private-passage/chute use or select all three human investigation tools. Fixed-seed match completion is regression evidence, not proof of entertaining human tactics.

## Passage / concealment limitations

Hiding is a contextual concealed state with authored camera/exit ports, not a physically playable cabinet interior. A chosen exit is capsule-tested at release. Peek uses a constrained camera and local slit mask rather than moving cloth simulation. The private passage and chute are short scripted motion through authored points; they can cross the designated partition/slab, with ordinary endpoints checked. They are not an arbitrary teleport ability, physics tunnel or extra invulnerability. Outside these explicit transitions both stairs are traversed with real CharacterBody3D motion.

New room furniture retains the matte toy palette, rounded edges, room signs, lamps and world-only fill. It is prototype-quality art. No baked GI, moving trains, ladders, full hand/body IK, network multiplayer, Steam integration or release EXE was added.

## Run and verify

`project.godot` → F5 → Hideaway Manor → choose seeker or hider.
`GODOT_BIN=/path/to/godot python tools/test_hideplay.py --matches`
Use a real display or Xvfb with `--capture --video` for staged rendered evidence. Read `PHASE11_TEST_STATUS.md` for actual observed outcomes.

Previous project design basis: the Production Audit §7–8 (choices rather than checking every box, loops and event density), and project docs `PHASE7_MAP_RESEARCH.md` (reference principles, not copied layouts). New graph implementation uses Godot4.4 `AStar3D`; floor following uses `CharacterBody3D.floor_snap_length` and floor-constant speed.
- https://docs.godotengine.org/en/4.4/classes/class_astar3d.html
- https://docs.godotengine.org/en/4.4/classes/class_characterbody3d.html

No competitor assets, external paid services, engine binaries, fonts, private save data or secrets are bundled. LICENSE is preserved; no automatic main merge or force-push.
