extends Control
## Original quiet HUD: reads local/public presentation data; never changes simulation.
const S=preload("res://scripts/premium/skin.gd")
var info: Dictionary={}
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if info.is_empty(): return
	var font:=get_theme_default_font()
	var pad:=36.0
	# Small stable backing only where text needs it; the central scene stays uncovered.
	draw_style_box(S.box(Color(0.05,0.11,0.10,0.55),11,0),Rect2(pad-12,22,248,91))
	draw_string(font,Vector2(pad,47),info.role,HORIZONTAL_ALIGNMENT_LEFT,-1,17,S.PAPER)
	for i in range(3):
		var c: Color=S.GOLD if i<int(info.hp) else Color("4c5d50")
		draw_style_box(S.box(c,4,0),Rect2(pad+i*22,59,15,8))
	draw_string(font,Vector2(pad,94),info.map,HORIZONTAL_ALIGNMENT_LEFT,-1,13,S.MUTE)
	var center:=size.x*0.5
	var timer: String=info.time
	draw_style_box(S.box(Color(0.05,0.11,0.10,0.55),10,0),Rect2(center-95,22,190,82))
	draw_string(font,Vector2(center-82,53),timer,HORIZONTAL_ALIGNMENT_CENTER,164,26,S.PAPER)
	draw_string(font,Vector2(center-84,77),info.phase,HORIZONTAL_ALIGNMENT_CENTER,168,12,S.MUTE)
	for i in range(4): draw_circle(Vector2(center-21+i*14,89),2.5,S.GOLD if i<=int(info.round) else Color("4c5d50"))
	var right:=size.x-pad
	draw_style_box(S.box(Color(0.05,0.11,0.10,0.55),9,0),Rect2(right-142,22,154,58))
	draw_string(font,Vector2(right-130,46),info.status,HORIZONTAL_ALIGNMENT_RIGHT,130,14,S.PAPER)
	draw_string(font,Vector2(right-130,66),info.score,HORIZONTAL_ALIGNMENT_RIGHT,130,12,S.MUTE)
	# Ability/quest panel deliberately does not extend into the lowered weapon quadrant.
	var y:=size.y-116
	draw_style_box(S.box(Color(0.05,0.11,0.10,0.86),10,0),Rect2(pad-12,y,350,92))
	draw_arc(Vector2(pad+15,y+29),17,-PI/2,-PI/2+TAU*maxf(0.02,float(info.ready)),36,S.MINT,2,true)
	draw_string(font,Vector2(pad-1,y+34),info.key,HORIZONTAL_ALIGNMENT_CENTER,32,13,S.PAPER)
	draw_string(font,Vector2(pad+45,y+28),info.tool,HORIZONTAL_ALIGNMENT_LEFT,280,15,S.PAPER)
	draw_string(font,Vector2(pad+45,y+49),fit_text(info.tool_note,font,12,270),HORIZONTAL_ALIGNMENT_LEFT,280,12,S.MUTE)
	draw_line(Vector2(pad,y+61),Vector2(pad+320,y+61),Color(0.6,0.7,0.6,0.17),1,true)
	draw_string(font,Vector2(pad,y+80),info.footer,HORIZONTAL_ALIGNMENT_LEFT,325,12,S.MUTE)

func fit_text(value: String,font: Font,pixels: int,limit: float) -> String:
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x<=limit: return value
	while value.length()>1 and font.get_string_size(value+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>limit: value=value.left(-1)
	return value+"…"
