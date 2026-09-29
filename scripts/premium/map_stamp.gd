extends Control
## Public layout only. No fighter/hidden-occupant references or secret camera.
const S=preload("res://scripts/premium/skin.gd")
var arena
var player_position:=Vector3.ZERO
var show_player:=false
var show_both:=true
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE; resized.connect(queue_redraw)
func _draw() -> void:
	if not is_instance_valid(arena): return
	var manor: bool=arena.map_id=="toy_manor"
	var floors:=2 if manor and show_both else 1
	for f in range(floors):
		var slot_width:=size.x/floors
		var dimensions: Vector2=arena.dimensions
		var k:=minf((slot_width-28)/dimensions.x,(size.y-48)/dimensions.y)
		var extent:=dimensions*k; var origin:=Vector2(slot_width*f+(slot_width-extent.x)*0.5,(size.y-extent.y)*0.5+8)
		draw_style_box(S.box(Color("2a4038"),9,0),Rect2(origin-Vector2.ONE*3,extent+Vector2.ONE*6))
		for i in range(1,6):
			draw_line(origin+Vector2(extent.x*i/6,0),origin+Vector2(extent.x*i/6,extent.y),Color(0.65,0.76,0.65,0.07),1)
			draw_line(origin+Vector2(0,extent.y*i/6),origin+Vector2(extent.x,extent.y*i/6),Color(0.65,0.76,0.65,0.07),1)
		var blocks: Array=arena.floor_blocks[f] if manor else arena.obstacles
		for obstacle in blocks:
			var r: Rect2=obstacle
			draw_style_box(S.box(Color("71806a"),2,0),Rect2(origin+(r.position+dimensions*0.5)*k,r.size*k))
		if manor:
			for home in arena.homes:
				if absf(home.at.y-f*4.0)<0.5: draw_circle(origin+(Vector2(home.at.x,home.at.z)+dimensions*0.5)*k,3.1,S.MINT)
			for x in [-11.0,11.0]: draw_line(origin+(Vector2(x,-9)+dimensions*0.5)*k,origin+(Vector2(x,9)+dimensions*0.5)*k,S.GOLD,3,true)
		else:
			for at in arena.spots: draw_circle(origin+(Vector2(at.x,at.z)+dimensions*0.5)*k,2.8,S.MINT)
		if show_player and (not manor or (1 if player_position.y>2.5 else 0)==f):
			var at:=origin+(Vector2(player_position.x,player_position.z)+dimensions*0.5)*k
			draw_circle(at,7,Color("20362f")); draw_circle(at,4,Color("f1d09b"))
		var font:=get_theme_default_font()
		draw_string(font,origin+Vector2(0,-12),"%02d  /  FLOOR"%(f+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,S.MUTE)
