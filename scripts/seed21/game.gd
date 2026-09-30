extends "res://scripts/canyon21/game.gd"
## One extension of the existing round lifecycle, not a competing random-map generator.
const Layout21=preload("res://scripts/seed21/round_layout.gd")
var round_layout
func _ready() -> void:
	super._ready()
	round_layout=Layout21.new();add_child(round_layout);round_layout.setup(self)
	# Optional reproducible match seed. Default still uses the original seed/randomization.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--match-seed="):
			var value:=arg.trim_prefix("--match-seed=")
			if value.is_valid_int():rng.seed=int(value)
func _prepare_round() -> void:
	if is_instance_valid(round_layout):round_layout.park()
	super._prepare_round()
	if is_instance_valid(round_layout):round_layout.apply_round(int(rng.seed),rules.round_index)
func select_map(id: String) -> void:
	if rules.phase!=Rules.Phase.MENU:return
	if is_instance_valid(round_layout):round_layout.park()
	super.select_map(id)
func return_to_menu() -> void:
	if is_instance_valid(round_layout):round_layout.park()
	super.return_to_menu()
