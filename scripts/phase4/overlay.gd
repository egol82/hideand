extends Control
var game
func _draw() -> void:
	if game == null or not game.world_view_active() or game.paused: return
	var center := size*0.5
	if not game.is_spectating():
		var color := Color("e9efda") if game.focus_spot < 0 else Color("ffe09a")
		draw_circle(center,3,Color(0.08,0.18,0.20,0.8))
		draw_circle(center,1.5,color)
		if game.hit_feedback > 0:
			for direction in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]: draw_line(center+direction*7,center+direction*12,Color("fff0a8"),2,true)
		if game.hurt_feedback > 0:
			var a: float = game.hurt_angle
			draw_arc(center,55,a-0.36,a+0.36,20,Color(0.88,0.39,0.36,0.85),4,true)
		if game.block_feedback > 0: draw_arc(center,12,0,TAU,24,Color("edb55f"),2,true)
