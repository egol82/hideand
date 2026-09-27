extends "res://scripts/phase2/drawing_data.gd"
const Spec4 = preload("res://scripts/phase4/attack_spec.gd")
var handling := "balanced"
var _cached_strokes: Array = []
var _cached_grip := Vector2(-10,-10)
var _cached_fill := false
var _cached_scale := 1.0

func clone():
	var copy = super.clone()
	copy.handling = handling
	return copy

func to_dictionary() -> Dictionary:
	var raw := super.to_dictionary()
	raw["handling"] = handling
	return raw

func load_dictionary(raw: Dictionary) -> bool:
	var style: Variant = raw.get("handling","balanced")
	if not style is String or style not in Spec4.IDS:
		return false
	if not super.load_dictionary(raw):
		return false
	handling = style
	return true

func world_scale() -> float:
	if strokes == _cached_strokes and grip == _cached_grip and fill_closed == _cached_fill:
		return _cached_scale
	var scale_value := super.world_scale()
	# Conservative filled-area budget; normalized shape and grip are never rewritten.
	if not fill_closed: return _cache_scale(scale_value)
	var area := 0.0
	var source = preload("res://scripts/phase2/weapon_form.gd")
	for poly in source.contours(self):
		var signed := 0.0
		for i in range(poly.size()): signed += poly[i].cross(poly[(i+1)%poly.size()])
		area += absf(signed)*0.5
	if area > 0.0001: scale_value = minf(scale_value,sqrt(2.6/area))
	return _cache_scale(scale_value)

func _cache_scale(value: float) -> float:
	_cached_strokes = strokes.duplicate(true)
	_cached_grip = grip
	_cached_fill = fill_closed
	_cached_scale = value
	return value
