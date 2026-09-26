extends "res://scripts/drawing_canvas.gd"
const PhaseData = preload("res://scripts/phase2/drawing_data.gd")
const Form = preload("res://scripts/phase2/weapon_form.gd")
var preview_elapsed := 0.0

func _init() -> void:
	data = PhaseData.new()

func _process(delta: float) -> void:
	preview_elapsed += delta
	if drawing and preview_elapsed >= 0.15:
		preview_elapsed = 0.0
		drawing_changed.emit()

func _draw() -> void:
	super._draw()
	var paper := paper_rect()
	for poly in Form.contours(data):
		var points := PackedVector2Array()
		for p in poly:
			points.append(paper.position + p * paper.size)
		var color: Color = data.weapon_color()
		color.a = 0.55
		draw_colored_polygon(points, color)
	var hold: Vector2 = paper.position + data.grip * paper.size
	draw_arc(hold, 10, 0, TAU, 24, Color("354c59"), 2, true)
