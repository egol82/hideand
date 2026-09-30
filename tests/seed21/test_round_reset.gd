extends SceneTree
## No frame is inserted between the inherited reset and its placement request.
## Actual autoplay is separately exercised by test_seed21_rounds.py.
const Scene=preload("res://scenes/phase21.tscn")
const Plans=preload("res://scripts/seed21/layouts.gd")
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func physical(actor) -> Transform3D:
	return PhysicsServer3D.body_get_state(actor.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
func settle_reset() -> void:
	for i in range(8):
		if not game.layout_reset_pending:return
		await physics_frame
		await process_frame
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await physics_frame;game.set_process(false)
	for mid in Plans.IDS:
		game.return_to_menu();game.select_map(mid);game.rng.seed=17;game.start_match(true)
		await settle_reset();await physics_frame
		var layout=game.round_layout
		var fighter=game.fighters[3]
		var old_mask: int=fighter.collision_mask
		var old_layer: int=fighter.collision_layer
		for seed_value in [17,8027]:
			for r in range(4):
				layout.park();game.rng.seed=seed_value;game.rules.round_index=r
				var p:=Plans.plan(mid,seed_value,r)
				var at: Vector2=p.positions[1]
				# Previous round really ends inside the future socket, at the server level.
				fighter.reset_fight(Vector3(at.x,0,at.y));fighter.force_update_transform()
				await physics_frame;await process_frame;await physics_frame
				check(physical(fighter).origin.distance_to(fighter.global_position)<0.001,p.id+" old server body actually occupies future socket")
				game._prepare_round()
				# Synchronous: no test-side await/force-update after the reset request.
				check(game.layout_reset_pending and not layout.applied,p.id+" stale kinematic reset defers placement instead of rejecting safe template")
				check(game.rules.phase==game.Rules.Phase.DRAW,p.id+" remains in DRAW while reset settles")
				await settle_reset()
				check(not game.layout_reset_pending and layout.applied and layout.descriptor.id==p.id,p.id+" exact template applied after physics sync")
				var synced:=true
				for a in game.fighters:synced=synced and physical(a).is_equal_approx(a.global_transform)
				check(synced,p.id+" all four reset transforms agree with PhysicsServer")
				check(fighter.collision_mask==old_mask and fighter.collision_layer==old_layer,p.id+" collision masks are never disabled or filtered")
		# A real occupant AFTER reset is still rejected by the unchanged query.
		layout.park();game.rules.round_index=0;game.rng.seed=17
		var p:=Plans.plan(mid,17,0);var at: Vector2=p.positions[0]
		fighter.reset_fight(Vector3(at.x,0,at.y));fighter.force_update_transform()
		await physics_frame;await process_frame;await physics_frame
		var occupied_position: Vector3=fighter.position
		var occupied_hidden: bool=fighter.hidden_in_box
		check(not layout.apply_round(17,0) and layout.last_rejection=="occupied socket",mid+" genuine character occupancy is still rejected")
		check(fighter.position==occupied_position and fighter.hidden_in_box==occupied_hidden and not layout.applied,mid+" rejection neither moves nor hides the occupant")
		# External solid stays put when round reset moves the players to spawns.
		var blocker:=StaticBody3D.new();blocker.collision_layer=2;game.add_child(blocker)
		var cs:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3.ONE;cs.shape=shape;blocker.add_child(cs)
		blocker.position=Vector3(at.x,0.7,at.y);blocker.force_update_transform()
		await physics_frame;await process_frame
		game._prepare_round();await settle_reset()
		check(not layout.applied and layout.last_rejection=="occupied socket",mid+" real solid still refuses placement after synchronized round reset")
		blocker.queue_free();await physics_frame;await process_frame
		game._prepare_round();await settle_reset()
		check(layout.applied and layout.descriptor.id==p.id,mid+" clear retry uses same seed and template")
		# Early DRAW acceptance is queued, then handled once. No chase before placement.
		layout.park();fighter.reset_fight(Vector3(at.x,0,at.y));fighter.force_update_transform()
		await physics_frame;await process_frame;await physics_frame
		game._prepare_round();game.accept_drawing();game.accept_drawing()
		check(game.layout_reset_pending and game.accept_after_layout and game.rules.phase==game.Rules.Phase.DRAW,mid+" early accept waits for physical placement without advancing rules")
		await settle_reset()
		check(not game.layout_reset_pending and not game.accept_after_layout and layout.applied and game.rules.phase==game.Rules.Phase.HIDE,mid+" queued acceptance enters original HIDE only after placement")
		# Returning to MENU invalidates any waiter; it cannot place a stale round later.
		game.return_to_menu();game.start_match(true);await settle_reset()
		layout.park();fighter.reset_fight(Vector3(at.x,0,at.y));fighter.force_update_transform()
		await physics_frame;await process_frame;await physics_frame
		game._prepare_round();game.accept_drawing();game.return_to_menu()
		await physics_frame;await process_frame;await physics_frame
		check(not game.layout_reset_pending and not layout.applied and game.rules.phase==game.Rules.Phase.MENU,mid+" cancelled round cannot resurrect layout or queued accept")
	game.queue_free();await process_frame
	print("SEED21_RESET_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
