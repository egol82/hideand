extends Control
## Receives the static arena and local player only. No opponent or occupancy state is supplied.
var arena
var player_position:=Vector3.ZERO
func _ready() -> void:
	for index in range(2):
		var heading:=Label.new(); heading.text="1F · 거실 / 주방 / 놀이방" if index==0 else "2F · 침실 / 옷방 / 욕실"
		heading.position=Vector2(18+index*385,0); heading.add_theme_font_size_override("font_size",16); heading.add_theme_color_override("font_color",Color("314f4c")); add_child(heading)
func _draw() -> void:
	if not is_instance_valid(arena): return
	var scale_value:=minf((size.x-90)/56.0,(size.y-45)/26.0)
	for level in range(2):
		var origin:=Vector2(18+level*(28*scale_value+45),30)
		draw_rect(Rect2(origin,Vector2(28,26)*scale_value),Color("f0e3cb"))
		for rect in arena.floor_blocks[level]: draw_rect(Rect2(origin+(rect.position+Vector2(14,13))*scale_value,rect.size*scale_value),Color("b99580"))
		for h in arena.homes:
			if absf(h.at.y-level*4.0)<0.5: draw_rect(Rect2(origin+(Vector2(h.at.x,h.at.z)+Vector2(13.1,12.3))*scale_value,Vector2(1.8,1.4)*scale_value),Color("9db7a9"))
		for x in [-11,11]: draw_line(origin+(Vector2(x,-9)+Vector2(14,13))*scale_value,origin+(Vector2(x,9)+Vector2(14,13))*scale_value,Color("cb9853"),4)
		if (1 if player_position.y>2.5 else 0)==level: draw_circle(origin+(Vector2(player_position.x,player_position.z)+Vector2(14,13))*scale_value,5,Color("df775f"))
