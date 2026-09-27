extends Control
var target := false
var hit := false

func _draw() -> void:
	var c := size*0.5
	var ink := Color("c6ffdd") if target else Color("f3f4e8")
	draw_circle(c,2,ink)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(c+direction*7,c+direction*13,Color(0.04,0.08,0.09,0.7),4,true)
		draw_line(c+direction*7,c+direction*13,ink,2,true)
	if hit:
		for d in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
			draw_line(c+d*15,c+d*22,Color("ffe3ab"),3,true)
