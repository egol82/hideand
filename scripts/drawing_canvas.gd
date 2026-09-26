extends Control
## Resolution-independent, bounded vector drawing canvas.
signal drawing_changed
const Data = preload("res://scripts/weapon_data.gd")

var data = Data.new()
var drawing := false
var grip_mode := false
var active_stroke := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(420,420)
	queue_redraw()

func paper_rect() -> Rect2:
	var side := maxf(1.0, minf(size.x,size.y) - 32.0)
	return Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side)

func _draw() -> void:
	var paper := paper_rect()
	draw_style_box(_paper_style(), paper.grow(10))
	for i in range(1,10):
		var t := float(i) / 10.0
		draw_line(paper.position + Vector2(t*paper.size.x,0),paper.position + Vector2(t*paper.size.x,paper.size.y),Color(0.77,0.75,0.69,0.25),1)
		draw_line(paper.position + Vector2(0,t*paper.size.y),paper.position + Vector2(paper.size.x,t*paper.size.y),Color(0.77,0.75,0.69,0.25),1)
	var width: float = 2.0 * Data.TUBE_RADIUS / data.world_scale() * paper.size.x
	for stroke in data.strokes:
		if stroke.is_empty():
			continue
		var transformed := PackedVector2Array()
		for point in stroke:
			transformed.append(paper.position + point * paper.size)
		if transformed.size() > 1:
			draw_polyline(transformed, data.weapon_color(), width, true)
		for point in transformed:
			draw_circle(point, width*0.5, data.weapon_color())
	var hold: Vector2 = paper.position + data.grip * paper.size
	draw_circle(hold, 12, Color(0.12,0.18,0.22,0.12))
	draw_arc(hold, 10, 0, TAU, 24, Color("354c59"),2,true)
	draw_line(hold - Vector2(15,0),hold + Vector2(15,0),Color("354c59"),1.5,true)
	draw_line(hold - Vector2(0,15),hold + Vector2(0,15),Color("354c59"),1.5,true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var paper := paper_rect()
			if not paper.has_point(event.position):
				return
			var p: Vector2 = (event.position-paper.position)/paper.size
			if grip_mode:
				data.snap_grip(p)
				grip_mode = false
				_changed()
				accept_event()
				return
			if data.strokes.size() >= Data.MAX_STROKES or data.point_count() >= Data.MAX_POINTS or data.ink_used() >= Data.MAX_INK:
				return
			if data.strokes.is_empty():
				data.grip = p
			data.strokes.append(PackedVector2Array([p]))
			active_stroke = data.strokes.size()-1
			drawing = true
			queue_redraw()
		else:
			finish_stroke()
		accept_event()
	elif event is InputEventMouseMotion and drawing:
		var paper := paper_rect()
		var p: Vector2 = ((event.position-paper.position)/paper.size).clamp(Vector2.ZERO,Vector2.ONE)
		_append_point(p)
		accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and drawing:
		finish_stroke()

func _append_point(point: Vector2) -> void:
	if active_stroke < 0 or active_stroke >= data.strokes.size():
		return
	var stroke: PackedVector2Array = data.strokes[active_stroke]
	var distance: float = stroke[-1].distance_to(point)
	if distance < Data.MIN_POINT_DISTANCE or data.point_count() >= Data.MAX_POINTS:
		return
	var remaining: float = Data.MAX_INK-data.ink_used()
	if remaining <= 0.0:
		return
	if distance > remaining:
		point = stroke[-1].lerp(point, remaining/distance)
	stroke.append(point)
	data.strokes[active_stroke] = stroke
	queue_redraw()

func finish_stroke() -> void:
	if not drawing:
		return
	drawing = false
	if active_stroke >= 0 and active_stroke < data.strokes.size() and data.strokes[active_stroke].size() < 2:
		data.strokes.remove_at(active_stroke)
	active_stroke = -1
	_changed()

func clear_drawing() -> void:
	drawing = false
	active_stroke = -1
	data.strokes.clear()
	_changed()

func undo() -> void:
	finish_stroke()
	if not data.strokes.is_empty():
		data.strokes.pop_back()
	_changed()

func set_preset(kind: String) -> void:
	drawing = false
	active_stroke = -1
	data.set_preset(kind)
	_changed()

func set_data(value) -> void:
	drawing = false
	active_stroke = -1
	data = value.clone()
	_changed()

func set_color_index(index: int) -> void:
	data.color_index = index
	_changed()

func _changed() -> void:
	queue_redraw()
	drawing_changed.emit()

func _paper_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("faf4e5")
	box.border_color = Color("cdbf9e")
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	return box
