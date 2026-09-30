extends RefCounted
## Only test setup waits here. Actual autoplay uses the real pending-DRAW lifecycle.
static func wait(game) -> void:
	for i in range(8):
		if not game.layout_reset_pending:return
		await game.get_tree().physics_frame
		await game.get_tree().process_frame
	if game.layout_reset_pending:
		push_error("Round reset did not synchronize with PhysicsServer within eight test frames")
		game.get_tree().quit(1)

static func positions(game) -> void:
	# Test fixtures also teleport participants to observation/parking positions.
	# Wait for those authored setup positions without changing any collision predicate.
	for actor in game.fighters:actor.force_update_transform()
	for i in range(8):
		var synced:=true
		for actor in game.fighters:
			var physical: Transform3D=PhysicsServer3D.body_get_state(actor.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			synced=synced and physical.is_equal_approx(actor.global_transform)
		if synced:return
		await game.get_tree().physics_frame
		await game.get_tree().process_frame
	push_error("Test parking transforms did not reach PhysicsServer")
	game.get_tree().quit(1)
