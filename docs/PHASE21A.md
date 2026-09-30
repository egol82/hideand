# Phase21 first increment — Pine Hollow leaves and limited thickets

Base: phase20/nature-playgrounds at559167838db71a28c4c0259c7b08573ede665924.
Target: existing phase21/living-nature. Stacked draft PR; no merge/deployment.
This is new, scoped implementation from actual Phase20 source, not recovered Phase21 code.

## Actual changes

Two existing noisy Pine trail strips become dry-leaf carpets. They use the SAME footstep sampler,
sound bank voices, source-coordinate snapshots,32-clue/24-trace pools and tracker skill. Walking
hearing radius14.4m; quiet5.4m. Quiet movement is quieter, not silent on leaves. Leaf traces live4s
and expire for both rendering and investigation; normal tracks retain their old8s. Three small
cached project-generated rustles play through the existing terrain footstep sound path. No fake
position radar or extra step-emission loop. Effect/mute options cannot change clue rules.

Pine's existing hideouts2/7 receive opaque toy hedge art within their previous cover envelope.
Their original collider,entry,two exits,search/peek/fake-site and ambush rules are retained. This is
contextual thicket hiding, NOT freeform foliage/physical cupboard interiors. A public4s plaque and
remaining-time hint make the limit readable. Four seconds per hider per round are SHARED across
both bushes; re-entry does not refill the budget. Countdown starts in active search, pauses with
the game and with CLASSIC's suspended search; initial finite preparation does not consume it.
FIELD search continues during another pair's encounter. After expiry the existing leave handler
tries both exits. If blocked, visibility/collision are restored at the existing position without a
teleport, so blocked exits never grant indefinite concealment. Ordinary timed/loud inspection
still discovers the occupant before expiry and feeds the original reveal/duel/capture rules.
Bots denied an exhausted bush select another original hideout. Normal hideouts are unchanged.

## Preserved scope

All10 maps/catalog9+Manor,spawn/cover/collision/navigation/hide-entry geometry,round rules,
original drawing/0.40 scaled lower-view paws,combat/contact predicates,models/skin/materials/GI,
animation,scenery,World19 batching and detail-culling remain. Only Pine changes sound terrain
and two contextual hiding budgets. No new route blocking,weapon values or map generation.
Wetland/canyon interactions and new seed-based variation are intentionally NOT in this commit.
Existing round seed/fake-home behavior remains; no previous227-test claim is used.

## Reproduction

GODOT_BIN=/path/to/Godot4.4.1 python tools/test_pine21.py --matches
For four staged real-engine views, add --capture under a display/Xvfb.
Affected regressions: test_hideplay.py, test_maps.py --skip-matches, test_outdoor20.py.
Exact local/remote results are in the PR and downloadable evidence, not inferred from upload.

Initial local test issues were an inferred boolean type, a typed hit-array fixture and fixture
actors parked on an existing entry. These were fixed without weakening the corresponding
assertions or moving original map geometry. Old shader UID fallback warnings remain.

Human fun/balance/visibility/accessibility and user hardware performance are unverified. The
same-position forced exposure prevents infinite hiding but is not a new character-depenetration
solver. No paid/downloaded game art,fonts,engine binaries,secrets,caches or player saves delivered.
