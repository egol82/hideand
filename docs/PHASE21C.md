# Phase21C — Amber Canyon increment (not complete Phase21)

Base runtime: `90dbfbb78320e2465fbba2406278db6f5d811e79` on `phase21/living-nature`.
Same draft PR #21, stacked on `phase20/nature-playgrounds`. No new map or full seed variation.

## Fast, exposed crossing

A new opt-in 9m straight passage connects (0,0,-1.0) and (0,0,8.0). Use the existing Interact
binding at either painted endpoint. It takes1.35s vs2.1667s measured ordinary walking on the same9m lane.
Its price is one loud18m launch/landing cue, a predictable unsteerable route, and an8s individual
cooldown. It does not grant concealment, hit immunity, grace, health or an extra attack. Original
passage travel cancels the rider's swing and temporarily locks movement. The existing DUEL contact
handler still hits a rider normally. No automatic-discovery/damage timer is introduced.

There is NO closing gate. All old floor/colliders/nav/side routes remain. Before launching, a capsule
sweep checks the full route and destination; each transit tick checks the next swept segment. A new
occupant, damage/knockback or disallowed phase cancels propulsion at the current location without
pushing the occupant away or snapping to the destination. The rider can immediately move sideways.
Only one rider can use this lane at a time. Both prompts stay outside every original hideout's
interaction radius; a regression invokes the actual nearby cabinet inspection to catch priority conflicts. These are conservative floor/capsule checks, not new
character physics. Rare outside teleports into an occupied body are not repaired by this component.

The previous hidden-passage vignette is not used for this exposed corridor. HUD uses the user's
existing Interact binding. Bots retain their existing pathing/search behavior; this increment does
not teach them a new optimal shortcut policy. Either player-selected role can use the lane.

## Short public gusts

Two marked pads, centered(-12,0,2)/(12,0,7), contain four toy seed spools each. A flag warns0.8s,
toys move for2s and settle for0.5s. Pads alternate on a17s cycle with8.5s offset. The eight nodes
are reused and return exactly to their authored starting transforms. Motions stay within0.75m
of their rest positions. They have no collision bodies, cannot block spawns/hiding ports, and are
not pushed into ever-growing physical piles. No camera shake or new light is used.

The active gust emits one14m public environmental sound (source=-1, fixed pad position). It can
distract through the existing hearing system; it does NOT suppress footsteps or follow a hidden
player. Nearby players see the flag and toys and can wait, move, or use cover. A three-variant
cached noise waveform is generated with a separate seeded RNG. Reduced motion removes toy rolling
but retains the short flag state and unchanged public sound information. Pause freezes the shared
service clock. Lane and gust sound records expire2s after their own event time.

## Wetland boundary fix — reproduced, not inferred

On base90dbfbb, WetServices.tick called its parent before pruning3s water/1.5s reed clues. If the
parent finished a3s listen at that instant, it could read an expired sound and assign a NEW3s HUD
memory. The regression failed4/39 predicates at exact or just-after expiry. Still-live samples,
track visibility and ordinary investigation were separately exercised.

The minimal fix prunes short-lived clues using elapsed+delta BEFORE parent tick resolves listening,
only if that tick will actually advance. The investigator also prunes against the current clock.
The identical39-predicate regression now passes. Existing already-heard memories keep their old
short duration; the fix prevents renewed exposure from an expired sound, not retroactive forgetting.
Canyon's two-second clues extend this same lifetime method instead of adding another tracker.

## Preservation and execution

CanyonServices extends WetServices extends PineServices; only the entry scene selects the new game
adapter. Original Pine4s shared bush allowance, leaves, Wet water3s/reeds1.5s,24-track/32-sound pools,
10 map identities and numeric physical footprints, character/GI manifests, drawing size/round paws,
attack sync, storage, inputs, and FIELD/CLASSIC rule handlers are retained. No existing predicate was
deleted or loosened. Actual map checks compare numeric geometry, not only map counts.

`python tools/test_canyon21.py --matches --regressions` runs the focused suite, expiry regression,
Wet/Pine/sync and affected old hide/map/outdoor runners. `--skip-import --capture-only` on an X display
produces real passage/gust screenshots and identical-view rest/active/settled pixel checks.
The updated existing pine21.yml workflow runs Windows/Linux and inherited PR regression remains.

Evidence records in the delivered package distinguish executed web Linux tests from remote CI.
No historical227 check result is used. Check counts include repeated bounds/cases, not human play
or quality ratings. Source and full-index patch are preserved BEFORE trying remote writes.

## Limits

Scheduled toy transforms are not physically simulated wind. The lane is contextual traversal,
not free steering or a jump mechanic. No overall seed variation yet. No human fun/balance/accessibility/
listening acceptance or user-GPU performance result is claimed. No merged PR, deployment, payment,
new Cloud Codex environment, notebook access or credential request.

Implementation reference: Godot4.4 PhysicsDirectSpaceState3D cast_motion + intersect_shape
(the former ignores initial overlaps, so the latter is used as well), and PhysicsShapeQueryParameters3D.
https://docs.godotengine.org/en/4.4/classes/class_physicsdirectspacestate3d.html
https://docs.godotengine.org/en/4.4/classes/class_physicsshapequeryparameters3d.html
