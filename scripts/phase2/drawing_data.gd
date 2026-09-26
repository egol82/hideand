extends "res://scripts/weapon_data.gd"
## Version 1 drawings remain readable. A missing fill flag preserves their old appearance.
var fill_closed := true

func clone():
	var copy = super.clone()
	copy.fill_closed = fill_closed
	return copy

func to_dictionary() -> Dictionary:
	var result := super.to_dictionary()
	result["fill_closed"] = fill_closed
	return result

func load_dictionary(raw: Dictionary) -> bool:
	if not raw.get("fill_closed", false) is bool:
		return false
	if not super.load_dictionary(raw):
		return false
	fill_closed = raw.get("fill_closed", false)
	return true
