extends "res://scripts/phase2/fighter.gd"
## Layer 19 excludes only the currently observed body, never other participants.
const SELF_LAYER := 1 << 18

func _ready() -> void:
	super._ready()
	nameplate.pixel_size = 0.0035
	nameplate.font_size = 28

func set_view_subject(value: bool) -> void:
	_set_layers(visual,SELF_LAYER if value else 1)
	nameplate.layers = SELF_LAYER if value else 1

func _set_layers(node: Node, mask: int) -> void:
	if node is VisualInstance3D:
		node.layers = mask
	for child in node.get_children():
		_set_layers(child,mask)

var use_view_aim := false
var view_pitch := 0.0

func step(delta: float, desired: Vector3, aim: Vector3) -> void:
	var previous := global_hit_samples()
	super.step(delta,desired,aim)
	if use_view_aim and not hidden_in_box and aim.length_squared() > 0.001:
		visual.rotation.y = atan2(aim.x,aim.z)
		weapon_pivot.rotation.x -= clampf(view_pitch,-0.9,0.9)
		previous_samples = previous
