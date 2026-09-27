# Phase 7 — map references and original design decisions

Research checked 2026-09-27. We inspected official product/developer descriptions and patch notes, not proprietary source or extracted map geometry. No competitor models, textures, level layouts or licensed assets are bundled. The transfer column is our design hypothesis, not a proven causal explanation of sales.

| Primary source | What the source supports | Decision used in this project |
|---|---|---|
| Boomerang Fu official site [1] | Small-input party combat; corner-curving attacks; more than 30 arenas with different tools and traps. | A map should change decisions, not merely wall colour. Short/noisy paths and longer/quiet loops share the same input scheme. |
| Boomerang Fu developer news [2] | The June 11, 2024 announcement reports over one million copies sold and introduces rotating-seeker hide-and-seek. | An established adjacent success, not proof that our specific layout will be fun. |
| Boomerang Fu developer fixes [2] | June 2024 removed a rotating hide-and-seek level because inconsistent prop rotation exposed players; March 2025 removed an exploitable moving circle maze. | Do NOT add moving trains/floors merely for spectacle. Static cover, matched colliders, and actual hiding-state tests come first. |
| Witch It developer Steam page [3] | Villages, islands and forests; varied prop arrangements; tools for detection/trapping; escape/distraction; an editor/workshop. The inspected listing has positive user reception. | Distinct themes and landmarks, alternate routes around cover, public clues instead of hidden-position knowledge. No sale estimate or exact layout copying. |
| Party Animals official FAQ [4] | Different map objectives: collecting gummies, basketball-like Buzz Ball, and Trebuchet attack/defend/disrupt. | Give maps identifiable interactions. Here, terrain changes sound risk, not score rules or an entirely new minigame. |

## Our three original layouts

**Sugar Market, 30 × 26:** a cake display blocks central sight; berry/mint display islands form side loops. Stripe tiles on the direct route emit louder footsteps; outer mint runners are quieter. Ten themed hiding cabinets/parcels. Warm cream, berry and mint palette.

**Starlight Arcade, 40 × 32:** four cabinet banks and a planet display interrupt long sightlines. A chime-tile crossing is direct but noisy; carpet lanes provide a lower-noise bypass. Fourteen prize/token hiding sites. Teal, plum and brass accents; a static star ceiling, not flashing lights.

**Pocket Station, 52 × 40:** three parked toy carriages form multiple gaps and a ring route. The noisy crossing competes with blue carpet paths; kiosk/planter islands break long side views. Eighteen luggage/mail hideouts. Colour-coded carriages and a clock landmark. Trains do not move and cannot be boarded.

These are one-level four-player layouts compatible with the existing controller. There are no jumps, lifts, damaging hazards, procedurally changing blockers or occupied-site indicators. Existing 24×20 / 48×36 / 80×56 maps remain available. New maps use their complete authored layout in both compact/full selections; the toggle does not cut a loop in half.

## Testable design hypotheses

- Landmarks make directions easier to communicate than a field of identical crates.
- Choosing noisy direct terrain versus a quiet bypass creates decisions during local counterattack/chase.
- Each hiding approach has at least two neighbouring free nav cells, and every free grid cell connects to the spawn component. These are engineering checks, NOT proof that every spot has two independent safe escape routes against a human opponent.
- Opposite sides of the central landmark have a blocked line of sight and navigable routes around both sides.
- Public map previews display static geometry and terrain, never opponents or occupied hideouts.

## Sources

[1] https://www.boomerangfu.com/
[2] https://steamcommunity.com/app/965680/allnews/ (dated developer announcements cited above)
[3] https://store.steampowered.com/app/559650/Witch_It/
[4] https://steamcommunity.com/app/1260320/discussions/0/3800524658157273943/

The user's production audit, section 8, also motivates landmarks, loops, multiple exits and event density. The current map dimensions/noise multipliers are project-authored initial values, not extracted industry standards. Human group testing, actual audio audition and target-PC GPU profiling remain necessary.
