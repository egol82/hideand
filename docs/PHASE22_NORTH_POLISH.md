# Phase22 — north island visual polish

Base: published `25380d021818c2b0516a7591f4d8b4de5a588c67`, tree
`d7071ea093e40870e8758fd7944ca406e7b88d32`. This is a decorative north-only
follow-on, not another terrain or collision revision.

## Visual changes

- The same 24 reeds form four loose authored patches with staggered depth,
  varied heights and lean, and open front/centre gaps. Each head and each of
  the 12 curved, rooted blades shares its own stalk frame.
- Five shallow, unequal moss cushions sit embedded along the actual bank.
  Six tapered roots have distinct lengths and follow the sampled bank slope.
- Both existing terrain material slots share `north_bank.gdshader`. Its local
  position colour field gives moss an irregular, gently feathered edge and
  restrained material mottling. There is no vertex displacement, extra mesh,
  alpha, time input, actor input, or floating decal. It is used by north only.

`north_reed_profile.gd` is byte-identical to the base, including the 64 points
and 108 triangles. The one Convex body, layer/mask, navigation, water skirt,
all south-island code, other maps, seed selection and clue services are
unchanged. Decorations stay within the original 7x6m north footprint and add
no collision. No external art or new dependency is introduced.

## Verification

The unchanged North58 suite still pins the approved collider, hull triangle
congruence, planting and counts, open corners and occlusion. The additive
`test_polish.gd` has 16 checks for repeatable transforms/colours across seeds,
no RNG consumption, one continuous material, shallow moss, height/depth/gap
variation, connected stalk/head/rooted leaves, varied root lengths, bank
contact and original-footprint containment. `test_wetland21.py` now runs this
suite in addition to every existing check.

Actual local Godot4.6.3 runs retain logs outside the source tree. They include
editor import, Wet105/North58/Polish16/Pine126/Sync94 and the entry smoke test.
The existing seed/match/regression and round-reset commands are run as well;
the delivery verification report records their exact terminal results.

The unchanged capture harness renders before/after close, mid and real-eye
views with seed8027, round0, RW-v1-2, 1280x720 and identical camera/actor
manifests. The local base closely matches the published images, with small measured
pixel differences retained in the comparison report. Captures use Godot's actual compatibility renderer on Mesa llvmpipe
through the existing cloud display. The first overly blurred transition was
rejected; final images use the finer edge. This is neither a human playtest
nor hardware performance certification.

Only the pre-existing manor shader UID fallback and software-display V-Sync
warning are accepted. Editor-generated UIDs, caches, import default changes,
logs and image dumps are excluded from source delivery. No push, merge or
deployment is part of this local polish delivery.
