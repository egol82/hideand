extends "res://scripts/canyon21/game.gd"
## One extension of the existing round lifecycle, not a competing random-map generator.
const Layout21=preload("res://scripts/seed21/round_layout.gd")
var round_layout
var layout_reset_serial:=0
var layout_reset_pending:=false
var accept_after_layout:=false
func _ready() -> void:
	super._ready()
	round_layout=Layout21.new();add_child(round_layout);round_layout.setup(self)
	# Optional reproducible match seed. Default still uses the original seed/randomization.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--match-seed="):
			var value:=arg.trim_prefix("--match-seed=")
			if value.is_valid_int():rng.seed=int(value)
func _prepare_round() -> void:
	_cancel_layout_reset()
	if is_instance_valid(round_layout):round_layout.park()
	super._prepare_round()
	if is_instance_valid(round_layout) and arena.map_id in round_layout.Plans.IDS and not practice_mode:
		layout_reset_pending=true
		_finish_layout_reset(layout_reset_serial,int(rng.seed),rules.round_index)
func _finish_layout_reset(serial: int,match_seed: int,round_index: int) -> void:
	# Kinematic bodies can retain their previous server transform until a physics step,
	# even after force_update_transform. Keep DRAW until that reset really reaches physics.
	for fighter in fighters: fighter.force_update_transform()
	while not _reset_bodies_synced():
		await get_tree().physics_frame
		if serial!=layout_reset_serial or rules.phase!=Rules.Phase.DRAW:return
	if serial!=layout_reset_serial or rules.phase!=Rules.Phase.DRAW:return
	round_layout.apply_round(match_seed,round_index)
	layout_reset_pending=false
	if accept_after_layout:
		accept_after_layout=false
		accept_drawing()
func _reset_bodies_synced() -> bool:
	for fighter in fighters:
		var physical: Transform3D=PhysicsServer3D.body_get_state(fighter.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		if not physical.is_equal_approx(fighter.global_transform):return false
	return true
func accept_drawing() -> void:
	if layout_reset_pending:
		accept_after_layout=true
		return
	super.accept_drawing()
func _cancel_layout_reset() -> void:
	layout_reset_serial+=1;layout_reset_pending=false;accept_after_layout=false
func select_map(id: String) -> void:
	if rules.phase!=Rules.Phase.MENU:return
	_cancel_layout_reset()
	if is_instance_valid(round_layout):round_layout.park()
	super.select_map(id)
func return_to_menu() -> void:
	_cancel_layout_reset()
	if is_instance_valid(round_layout):round_layout.park()
	super.return_to_menu()
