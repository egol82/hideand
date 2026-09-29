# Astra — Phase 15 handoff

Start from phase15/manor-lighting-gi. Read AGENTS.md, PHASE15.md and PHASE15_TEST_STATUS.md.
Do not rebuild the prior game. Default entry scenes/phase15.tscn uses the same character/game
controller and a lighting-only ToyStudio extension.

The baked native map must match the fixed geometry signature. Never include seeded furniture in
static GI. Use saved real LightmapGI data; no hand-generated imitation and no fallback labelled success.
Retain the original collision and hidden-state rules, material generations and original weapon contact.
Run test_lighting15.py --matches, actual --capture and all historical runners. Report exact code/bake
SHA and real evidence. Human art/fairness, hardware/audio performance and later animations remain separate.
