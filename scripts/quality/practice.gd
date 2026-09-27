extends RefCounted
## Practice progression is separate from match scoring and never awards points.
var equipped := false
var walked := 0.0
var dodged := false
var hits := 0
var blocked := 0
var misses := 0
var completed := false

func record_move(distance: float) -> void:
	if is_finite(distance) and distance > 0 and distance < 0.8: walked += distance
	_update()

func record_hit(outcome: String) -> void:
	match outcome:
		"hit": hits += 1
		"blocked": blocked += 1
		"miss": misses += 1
	_update()

func _update() -> void:
	completed = equipped and walked >= 2.0 and dodged and hits >= 3

func states() -> Array[bool]:
	_update()
	return [equipped,walked >= 2.0,dodged,hits >= 3]
