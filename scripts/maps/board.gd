extends "res://scripts/phase3/map_board.gd"
## Extra information is public terrain only. Inherited board never receives opponents.
func _draw() -> void:
	super._draw()
	if arena == null or not is_instance_valid(arena) or not arena.has_meta("map_pack"): return
	var scale2: float = minf((size.x-24)/arena.dimensions.x,(size.y-24)/arena.dimensions.y)
	var top: Vector2 = (size-arena.dimensions*scale2)*0.5
	for zone in arena.surface_zones:
		var rect: Rect2 = zone.rect
		draw_rect(Rect2(top+(rect.position+arena.dimensions*0.5)*scale2,rect.size*scale2),Color(0.93,0.69,0.35,0.55) if zone.loud else Color(0.39,0.77,0.69,0.55))
