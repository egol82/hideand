extends RefCounted
## Pure round state. Presentation, AI and physics cannot advance the round independently.
signal changed
signal duel_resolved(hider: int, captured: bool)
signal round_resolved

enum Phase { MENU, DRAW, HIDE, SEEK, REVEAL, DUEL, RESULT, COMPLETE }
const PLAYERS := 4
const ROUNDS := 4
const DRAW_SECONDS := 25.0
const HIDE_SECONDS := 10.0
const SEEK_SECONDS := 65.0
const REVEAL_SECONDS := 1.2
const DUEL_SECONDS := 5.0
const GRACE_SECONDS := 5.0

var phase: int = Phase.MENU
var round_index := 0
var first_seeker := 0
var seeker := 0
var opponent := -1
var time_left := 0.0
var search_left := SEEK_SECONDS
var alive: Array[bool] = [true, true, true, true]
var scores: Array[int] = [0, 0, 0, 0]
var hp: Array[int] = [3, 3, 3, 3]
var grace: Array[float] = [0.0, 0.0, 0.0, 0.0]
var result_text := ""
var captured_last := false

func start(start_with_seeker: bool = true) -> void:
	first_seeker = 0 if start_with_seeker else 1
	round_index = 0
	scores.assign([0, 0, 0, 0])
	_prepare_round()

func _prepare_round() -> void:
	seeker = (first_seeker + round_index) % PLAYERS
	opponent = -1
	alive.assign([true, true, true, true])
	hp.assign([3, 3, 3, 3])
	grace.assign([0.0, 0.0, 0.0, 0.0])
	search_left = SEEK_SECONDS
	result_text = ""
	_enter(Phase.DRAW, DRAW_SECONDS)

func ready() -> bool:
	if phase != Phase.DRAW:
		return false
	_enter(Phase.HIDE, HIDE_SECONDS)
	return true

func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	if phase in [Phase.MENU, Phase.RESULT, Phase.COMPLETE]:
		return
	# Search grace is paused during reveals/duels, exactly like the search timer.
	if phase == Phase.SEEK:
		for i in range(PLAYERS):
			grace[i] = maxf(0.0, grace[i] - delta)
	time_left = maxf(0.0, time_left - delta)
	if phase == Phase.SEEK:
		search_left = time_left
	if time_left > 0.0:
		return
	match phase:
		Phase.DRAW:
			ready()
		Phase.HIDE:
			_enter(Phase.SEEK, search_left)
		Phase.SEEK:
			_finish_round()
		Phase.REVEAL:
			_enter(Phase.DUEL, DUEL_SECONDS)
		Phase.DUEL:
			_resolve_duel(false) # Staying alive for five seconds earns escape.

func discover(hider: int) -> bool:
	if phase != Phase.SEEK or not _valid_hider(hider) or grace[hider] > 0.0:
		return false
	opponent = hider
	hp[seeker] = 3
	hp[hider] = 3
	_enter(Phase.REVEAL, REVEAL_SECONDS)
	return true

func register_hits(attackers: Array[int]) -> void:
	if phase != Phase.DUEL:
		return
	# Resolve both attacks together. A trade KO awards the hider an escape.
	var unique: Dictionary = {}
	for id in attackers:
		if unique.has(id):
			continue
		unique[id] = true
		if id == seeker:
			hp[opponent] = maxi(0, hp[opponent] - 1)
		elif id == opponent:
			hp[seeker] = maxi(0, hp[seeker] - 1)
	if hp[seeker] <= 0:
		_resolve_duel(false)
	elif hp[opponent] <= 0:
		_resolve_duel(true)

func _resolve_duel(captured: bool) -> void:
	var hider := opponent
	captured_last = captured
	if captured:
		alive[hider] = false
		scores[seeker] += 3
	else:
		scores[hider] += 2
		grace[hider] = GRACE_SECONDS
	opponent = -1
	# Establish the next phase BEFORE emitting events, preventing duplicate resolution.
	phase = Phase.SEEK
	time_left = search_left
	duel_resolved.emit(hider, captured)
	if remaining() == 0 or search_left <= 0.0:
		_finish_round()
	else:
		changed.emit()

func _finish_round() -> void:
	if phase in [Phase.RESULT, Phase.COMPLETE]:
		return
	var escaped := remaining()
	if escaped == 0:
		scores[seeker] += 2
		result_text = "ALL FOUND!  Seeker bonus +2"
	else:
		for i in range(PLAYERS):
			if _valid_hider(i):
				scores[i] += 2
		result_text = "%d HIDERS SURVIVED!  Survival bonus +2" % escaped
	_enter(Phase.RESULT, 0.0)
	round_resolved.emit()

func next_round() -> bool:
	if phase != Phase.RESULT:
		return false
	round_index += 1
	if round_index >= ROUNDS:
		_enter(Phase.COMPLETE, 0.0)
	else:
		_prepare_round()
	return true

func remaining() -> int:
	var total := 0
	for i in range(PLAYERS):
		if _valid_hider(i):
			total += 1
	return total

func _valid_hider(id: int) -> bool:
	return id >= 0 and id < PLAYERS and id != seeker and alive[id]

func _enter(value: int, seconds: float) -> void:
	phase = value
	time_left = seconds
	changed.emit()
