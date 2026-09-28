extends Node
## Presentation only. Reserve the lower right for both gripping forearms.
var ui
func _ready() -> void: call_deferred("initialize")
func initialize() -> void:
	ui = get_parent().ui
	if not ui.root.resized.is_connected(layout): ui.root.resized.connect(layout)
	layout()
func layout() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(ui.detail): return
	ui.detail.position = Vector2(maxf(24,ui.root.size.x-446),78)
