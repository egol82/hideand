# Phase21B — Reedwater movement clues (second increment only)

Base: verified Pine HEAD3739c805d11e9591b83bd0891cd6e2344d7645ba.
Same branch phase21/living-nature, same stacked DRAFT PR21, base phase20/nature-playgrounds.
The actual source ZIP tree was checked as7deb9442350d3eee23c458c594ae3e910cd692af before edits.
This is not a recovery of the earlier missing broad Phase21 implementation.

## Actual gameplay

Two shallow,passable wet strips extend the visible water at the existing reed islands. They add
no colliders or swimming/death/slowdown. The original boardwalk and quiet bank are still available.
Water contact stores a bounded2.5-second wet-foot allowance,refreshed only by actual grounded
movement in water,not standing. The ORIGINAL1.4m sampled footstep produces a water trace in the
shared24-slot track pool. Quiet movement also leaves a short wet trace; actual audible terrain
uses the old footstep voice route. Normal water hearing10m,quiet3.75m via the original formula.
Wet traces persist3s,at their recorded world coordinates. The allowance makes subsequent real
steps just outside water wet until drying; there is no timer that manufactures new footprints or
moves an old one to the actor. Hide,death,airborne,transit and teleport samples release wetness.

Four sparse,low reed tufts beside the original two opaque reed islands respond to the SAME step
sampler. A real step within a patch stores its timestamp and movement direction; the fixed tuft
briefly bends and returns to rest over1.5s. A short ground reed-mark and sound snapshot use the
same existing investigation and32-record sound queues. Hearing8m normal/3m quiet. Stillness does
not continuously retrigger reeds. Either team can disturb them,and the existing listening/search
mechanics can respond. No enemy marker,live coordinate lookup,outline or through-wall visual.
The solid reed-island occluders never move or disappear. Sparse tufts are not new cover/colliders.

Water3s and reed1.5s expiration clears BOTH the visible track and the timestamp used by the
inherited investigator. Matching sound records are also removed then. A prior heard direction
can linger for its existing bounded UI/memory interval; it is always the historical position.
Pause freezes the shared service clock. Comfort removes reed sway but retains the same short
static clue/hearing contract; muting does not change AI clue rules. Ordinary tracks retain8s,
Pine leaves retain4s,and the two Pine thickets still share4s per hider per round.

## Structure and preservation

WetServices extends PineServices. The new game adapter only installs this more specific service;
Pine game/service/art code is unchanged. No separate polling loop duplicates footsteps. Water
sound uses three small cached,project-authored PCM streams; reeds reuse the existing Pine rustle.
24 wet glyphs and24 reed glyphs are allocated under the existing track slots once. The torus mesh
is shared. Four tufts and two water surfaces are built once per arena and reset in place. No new
per-step scene creation,quality-based clue hiding,unbounded event lists or gameplay RNG use.

Original collision/navigation/spawn/hide entries,all10maps,catalog9+Manor,body/skin/material/GI,
viewmodel,combat samples/timing,animation,search/capture/round APIs and save/input paths stay.
The one original-zone equality in Pine tests now filters separately tested wetland21_* additions;
it STILL requires every original zone to equal Phase20. New tests verify the exact six added
zones,collision identity,free-cell connectivity and existing entry/exit access. Tests were not
deleted or made unconditional. The first real Pine regression exposed step->leaves canonicalization
inside the parent override: wet visual selection now reads the parent's final track kind instead
of the pre-call argument,so quiet and ordinary Pine leaves retain their original visuals.

## Reproduction and evidence

GODOT_BIN=/path/to/Godot4.4.1 python tools/test_wetland21.py --matches
Add --capture under Xvfb/display for six actual renderer states: water,expired water,bent reeds,
settled reeds,comfort and first-person gameplay. The pairs use the same camera/environment and
real CharacterBody motion; diagnostic pairs hide actors/name labels to isolate the historical
clue,not to add a new hiding feature. Pixel differences check actual visible expiry/return.
The final GUI view requires a capsule-clear player position. No image generation or retouching.

Focused tests verify actual emission/quiet movement,one sampled clue,coordinates after the actor
moves away,drying,investigation before/after expiry,settings,pause,stationary/hidden/air/teleport,
original hide/search/reveal/duel/three-hit capture in BOTH modes,round configure,finite pools and
Pine return. Dedicated existing94 sweep/contact tests cover actual hits; three-hit rule tests
use the existing hit API and are not described as three physics attacks. Repeated seeds only test
lifecycle stability; no new seed-based route generation is introduced.

CI extends the existing Pine21 Windows/Linux workflow,keeping original Pine126 and sync94 tests,
20 complete matches,and affected hide/map/outdoor regressions. Exact observed results and final
commit are reported in PR21 and downloadable evidence. Prior227 tests are never used here.
No claim is inferred solely from source creation or a running CI job.

## Limits

This is a scoped wetland interaction increment,not full Phase21. Canyon interactions/broad seed
variation remain pending. Ground water is a toy surface,not fluid simulation; tufts do not simulate
physical contact/deformation of all original reeds. Reactivity follows existing sampled footsteps,
not every millimetre. Small ornaments may visually overlap; no new depenetration solver is added.
Human fun/balance/hiding readability,hearing comfort and user hardware FPS/VRAM remain unverified.
No merge,deployment,payment,new Cloud Codex,local laptop or credentials are used/requested.
Pinned API reference: https://docs.godotengine.org/en/4.4/classes/class_torusmesh.html
