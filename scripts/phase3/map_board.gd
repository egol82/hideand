extends Control
## Public level layout only: never displays other players or hidden occupancy.
var arena
var player_position := Vector3.ZERO
var facing := Vector3.FORWARD

func _draw() -> void:
	if arena == null or not is_instance_valid(arena):
		return
	var scale2: float = minf((size.x-24)/arena.dimensions.x,(size.y-24)/arena.dimensions.y)
	var map_size: Vector2 = arena.dimensions*scale2
	var top := (size-map_size)*0.5
	draw_rect(Rect2(top,map_size),Color("283f48"))
	for obstacle in arena.obstacles:
		var position2: Vector2 = top+(obstacle.position+arena.dimensions*0.5)*scale2
		draw_rect(Rect2(position2,obstacle.size*scale2),Color("759493"))
	for spot in arena.spots:
		var point: Vector2 = top+(Vector2(spot.x,spot.z)+arena.dimensions*0.5)*scale2
		draw_circle(point,3,Color("eed698"))
	var you: Vector2 = top+(Vector2(player_position.x,player_position.z)+arena.dimensions*0.5)*scale2
	draw_circle(you,5,Color("94e5cb"))
	draw_line(you,you+Vector2(facing.x,facing.z)*16,Color("94e5cb"),3,true)
	draw_rect(Rect2(top,map_size),Color("adc7bc"),false,2)
