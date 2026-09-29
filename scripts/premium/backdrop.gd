extends Control
## Light-weight opaque edge gradient: world remains visible without full-screen blur cost.
var journal := false
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	for i in range(48):
		var t:=float(i)/47.0
		var alpha:=lerpf(0.96,0.62,t) if journal else lerpf(0.94,0.32,t)
		draw_rect(Rect2(i*size.x/48,0,size.x/48+1,size.y),Color(0.041,0.085,0.077,alpha))
	# Original broken-line border; no copied glyphs or franchise ornament.
	var margin:=Vector2(28,25)
	for corner in [margin,Vector2(size.x-margin.x,margin.y),Vector2(margin.x,size.y-margin.y),size-margin]:
		var sx:=1.0 if corner.x<size.x/2 else -1.0
		var sy:=1.0 if corner.y<size.y/2 else -1.0
		draw_line(corner,corner+Vector2(30*sx,0),Color(0.81,0.72,0.49,0.36),1,true)
		draw_line(corner,corner+Vector2(0,22*sy),Color(0.81,0.72,0.49,0.36),1,true)
