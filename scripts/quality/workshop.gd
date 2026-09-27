extends RefCounted
## Only a queued NEXT-round copy. No current authority actor is mutated here.
const Data = preload("res://scripts/phase4/drawing_data.gd")
var opened := false
var queued
var generation := 0

func allowed(alive: bool, round_index: int, phase: int) -> bool:
	return not alive and round_index < 3 and phase in [3,4,5]

func keep(data) -> bool:
	if data == null or not data.is_valid(): return false
	var validated = Data.new()
	if not validated.load_dictionary(data.to_dictionary()): return false
	queued = validated
	generation += 1
	return true

func take():
	var result = queued.clone() if queued != null else null
	queued = null
	opened = false
	return result
