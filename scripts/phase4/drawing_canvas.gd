extends "res://scripts/drawing_canvas.gd"
const Data4 = preload("res://scripts/phase4/drawing_data.gd")

func _init() -> void:
	data = Data4.new()

func set_data(value) -> void:
	var incoming = Data4.new()
	if incoming.load_dictionary(value.to_dictionary()): super.set_data(incoming)

var preview_elapsed := 0.0
func _process(delta: float) -> void:
	preview_elapsed += delta
	if drawing and preview_elapsed >= 0.15:
		preview_elapsed = 0
		drawing_changed.emit()

func _draw() -> void:
	super._draw()
	var form = preload("res://scripts/phase4/weapon_form.gd")
	var paper := paper_rect()
	for poly in form.contours(data):
		var points := PackedVector2Array()
		for p in poly: points.append(paper.position+p*paper.size)
		var color: Color = data.weapon_color()
		color.a = 0.5
		draw_colored_polygon(points,color)
	draw_arc(paper.position+data.grip*paper.size,10,0,TAU,24,Color("354c59"),2,true)
