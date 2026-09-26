# Acceptance — Phase 2

CI completion and human approval are different. See TEST_STATUS.md for evidence from actual runs.

## Automated coverage

Original bounded weapon data/mesh regression tests; Phase 2 state transitions, scoring, timers, capture, escape and tie KO; simple fill/fallback and random custom contour meshes; all six navigation routes; scripted mouse drawing, equipped shape, E hide/inspect, pause, restart and timeout; actual phase scene initialization; a full four-round bot match; rendered captures at 1280×720.

## Human checks still required

- [ ] Play four rounds as both starting roles without using debug flags.
- [ ] Inspect/hide at all six props and try corner cases around walls and other players.
- [ ] Draw long, tiny, disconnected, crossed and dense shapes; verify the visible/contact shape and grip.
- [ ] Judge five-second duel timing, recovery, escape grace, cooldown and the payoff of discovery.
- [ ] Save/load all eight slots, overwrite a slot, restart the app and simulate permission/write failures.
- [ ] Verify input at 720p/1080p, window resize, DPI, fullscreen and focus loss while drawing/dueling.
- [ ] Hear effects on an actual audio device; CI capture deliberately uses a dummy driver.
- [ ] Test graphics and performance on the intended Windows GPU/CPU. Headless Windows is not GPU validation.
- [ ] Validate an exported Windows executable and required distribution notices before release.
- [ ] Compare screenshots and motion against the chosen art direction; do not claim concept-level fidelity yet.

Online, Steam lobbies, controller navigation, Korean UI and shipping assets are separate future acceptance scopes.
