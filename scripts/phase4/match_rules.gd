extends "res://scripts/phase3/match_rules.gd"
## Presentation preferences never enter this authority-only rules object.
const MODES := ["field", "classic"]
var mode := "field"
var round_start_scores: Array[int] = [0,0,0,0]
var discoveries: Array[int] = [0,0,0,0]
var escapes: Array[int] = [0,0,0,0]

func _prepare_round() -> void:
	round_start_scores.assign(scores)
	discoveries.assign([0,0,0,0])
	escapes.assign([0,0,0,0])
	super._prepare_round()

func reveal_seconds() -> float:
	return 0.55 if mode == "field" else 1.2

func duel_seconds() -> float:
	return 8.0 if mode == "field" else 5.0

func discover(hider: int) -> bool:
	if phase != Phase.SEEK or not _valid_hider(hider) or grace[hider] > 0:
		return false
	opponent = hider
	discoveries[hider] += 1
	hp[seeker] = 3
	hp[hider] = 3
	_enter(Phase.REVEAL,reveal_seconds())
	return true

func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0 or phase in [Phase.MENU,Phase.RESULT,Phase.COMPLETE]:
		return
	if phase == Phase.SEEK or (mode == "field" and phase in [Phase.REVEAL,Phase.DUEL]):
		for i in range(PLAYERS):
			grace[i] = maxf(0,grace[i]-delta)
		if phase != Phase.SEEK:
			search_left = maxf(0,search_left-delta)
	time_left = maxf(0,time_left-delta)
	if phase == Phase.SEEK:
		search_left = time_left
	if mode == "field" and phase in [Phase.REVEAL,Phase.DUEL] and search_left <= 0:
		_resolve_duel(false)
		return
	if time_left > 0:
		return
	match phase:
		Phase.DRAW: ready()
		Phase.HIDE: _enter(Phase.SEEK,search_left)
		Phase.SEEK: _finish_round()
		Phase.REVEAL: _enter(Phase.DUEL,duel_seconds())
		Phase.DUEL: _resolve_duel(false)

func _resolve_duel(captured: bool) -> void:
	if phase not in [Phase.REVEAL,Phase.DUEL] or not _valid_hider(opponent):
		return
	var hider := opponent
	captured_last = captured
	if captured:
		alive[hider] = false
		scores[seeker] += 3
	else:
		if escapes[hider] == 0:
			scores[hider] += 1 # Capped at one escape point per player per round.
		escapes[hider] += 1
		grace[hider] = GRACE_SECONDS
	opponent = -1
	phase = Phase.SEEK
	time_left = search_left
	duel_resolved.emit(hider,captured)
	if remaining() == 0 or search_left <= 0:
		_finish_round()
	else:
		changed.emit()

func _finish_round() -> void:
	if phase in [Phase.RESULT,Phase.COMPLETE]:
		return
	if remaining() == 0:
		scores[seeker] += 2
		result_text = "ALL CAUGHT! Seeker sweep +2"
	else:
		for i in range(PLAYERS):
			if _valid_hider(i):
				scores[i] += 3 + (2 if discoveries[i] == 0 else 0)
		result_text = "SURVIVAL +3 / NEVER FOUND +2 / FIRST ESCAPE +1"
	_enter(Phase.RESULT,0)
	round_resolved.emit()
