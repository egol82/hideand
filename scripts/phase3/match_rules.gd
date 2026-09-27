extends "res://scripts/phase2/match_rules.gd"
var hiding_seconds := 14.0
var seeking_seconds := 80.0

func configure(config: Dictionary) -> void:
	hiding_seconds = clampf(float(config.get("hide",14.0)),10.0,60.0)
	seeking_seconds = clampf(float(config.get("seek",80.0)),30.0,300.0)

func _prepare_round() -> void:
	super._prepare_round()
	search_left = seeking_seconds

func ready() -> bool:
	if phase != Phase.DRAW:
		return false
	_enter(Phase.HIDE,hiding_seconds)
	return true
