# Phase 9 — smash / reaction references

Research date: 2026-09-28. These are publicly documented reference principles, not reverse-engineered source code, copied art, or proof of why a game sold. No competitor effect timing was measured. Exact timing/amplitude values in this project are test hypotheses.

| Primary source | What it supports | Our adaptation | What we deliberately do not copy |
|---|---|---|---|
| Party Animals, official Steam page [1] | Cute animals fight and interact using physics; the store has substantial positive player reception. | The struck toy visibly compresses, flails, wobbles and changes expression. | No lifted models, textures, audio or rigidbody camera; no claim that our cosmetic reaction is their ragdoll system. |
| Boomerang Fu, developer site [2] | Fast rounds, cute physics combat, one stick/three buttons; lists Australian Game Developers Awards 2020 Best Gameplay. | A compact readable hit accent, distinct blocked contact, playful shapes rather than realistic blood/explosion effects. | No dismemberment, borrowed food characters or power-up system. |
| Stick Fight, Landfall press kit [3] | Physics-based multiplayer fighting; procedural physical animation derived from their TABS system. | Visible cause-and-effect on the target, including a brief comedic exit echo after a confirmed finishing hit. | No physics/animation source or added gameplay stun/impulse. |
| Fatshark, Animating the Grail Knight [4] | First-person animation research and iterative chaining; avoiding unwanted loss of player control. | Keep the shared attack timeline and viewmodel grip; no global pause or forced camera tumble to fake impact. | No claim our toy animation matches their production pipeline or measured frame timings. |
| GDC, Don't Juice It or Lose It [5] | Decorative polish can harm context when disconnected from the event. | Contact-only stars, rubber squeak for vinyl/foam, separate woody block sound, no random fake hits. | No always-on dust or effects that expose hidden actors. |
| Microsoft XAG117 [6] | Allow control over camera/visual movement. | Existing reduced-motion and strength settings suppress the new moving effects without changing damage/clock. | No claim that our implementation is an accessibility certification. |

The user's Production Audit sections 6 and 10 also prescribe stable camera input, exaggerated target art, separate incoming/outgoing/miss/block events, and authority-independent comfort settings. The new implementation follows those constraints rather than reviving historical hit-stop clock bugs.

## References

[1] https://store.steampowered.com/app/1260320/Party_Animals/
[2] https://www.boomerangfu.com/
[3] https://landfall.se/stick-fight-press-kit
[4] https://www.vermintide.com/news/dev-blog-animating-the-grail-knight
[5] https://www.gdcvault.com/play/1020861/
[6] https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117

Implementation API references:
- https://docs.godotengine.org/en/stable/classes/class_multimesh.html
- https://docs.godotengine.org/en/stable/classes/class_label3d.html

MultiMesh is used to bound repeated geometry submissions, not as evidence of a measured frame rate. Comic labels retain depth tests so they cannot be seen through walls. Existing Korean system-font requirements remain; no fonts are shipped.
