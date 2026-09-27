extends SceneTree
## Engine integration assertions, not a claim of manual OS-input or fun testing.
const Catalog = preload("res://scripts/phase3/map_catalog.gd")
const Map = preload("res://scripts/phase3/arena.gd")
const Rig = preload("res://scripts/phase3/first_person.gd")
const State = preload("res://scripts/phase3/match_rules.gd")
const Scene = preload("res://scenes/phase3.tscn")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: "+description)
	else:
		failures += 1
		printerr("FAIL: "+description)

func run() -> void:
	var expected_sizes := [Vector2(24,20),Vector2(48,36),Vector2(80,56)]
	var expected_spots := [8,14,24]
	for index in range(3):
		var map = Map.new()
		map.map_id = Catalog.IDS[index]
		root.add_child(map)
		await physics_frame
		check(map.dimensions == expected_sizes[index],map.map_id+": exact world dimensions")
		check(map.spots.size() == expected_spots[index],map.map_id+": hiding place count")
		check(map.navigation.region.size == Vector2i(map.dimensions)-Vector2i.ONE,map.map_id+": navigation covers full size")
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.36
		capsule.height = 1.45
		for i in range(map.spots.size()):
			var spot: Vector3 = map.spots[i]
			check(map.inside(spot),map.map_id+": hideout %d in bounds" % i)
			var path: PackedVector2Array = map.path_to(Vector3.ZERO,spot)
			check(not path.is_empty(),map.map_id+": hideout %d reachable" % i)
			check(not map.navigation.is_point_solid(map.nearest_id(spot)),map.map_id+": hideout %d free nav cell" % i)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.collision_mask = 1
			query.transform.origin = spot+Vector3.UP*0.8
			check(map.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),map.map_id+": hideout %d capsule clearance" % i)
		for at in map.spawn_points:
			check(not map.path_to(at,map.spots[0]).is_empty(),map.map_id+": spawn reaches map")
		check(not map.clear_ray(Vector3(0,1,0),Vector3(map.dimensions.x,1,0)),map.map_id+": physical boundary stops rays")
		var rules := State.new()
		rules.configure(map.config)
		rules.start()
		rules.ready()
		check(is_equal_approx(rules.time_left,float(map.config.hide)),map.map_id+": map hiding budget")
		rules.tick(rules.hiding_seconds+0.1)
		check(is_equal_approx(rules.time_left,float(map.config.seek)),map.map_id+": map search budget")
		map.queue_free()
		await process_frame
	var rig = Rig.new()
	root.add_child(rig)
	check(rig.view.projection == Camera3D.PROJECTION_PERSPECTIVE,"camera is perspective, not top down")
	check(rig.view.near <= 0.05,"near plane supports visible hand-held geometry")
	check((rig.view.cull_mask & Rig.SELF_LAYER) == 0,"camera excludes own head/body layer")
	check((rig.view.cull_mask & Rig.VIEW_LAYER) != 0,"camera includes first-person weapon layer")
	check(rig.move_vector(Vector2(0,-1)).is_equal_approx(Vector3.FORWARD),"W follows view at zero yaw")
	rig.yaw = -PI*0.5
	check(rig.move_vector(Vector2(0,-1)).is_equal_approx(Vector3.RIGHT),"W follows view after 90 degree turn")
	check(rig.move_vector(Vector2(1,-1)).length() <= 1.0001,"diagonal movement is normalized")
	rig.pitch = 0
	rig.look(Vector2(0,100000))
	check(rig.pitch >= deg_to_rad(-80),"mouse pitch lower clamp")
	rig.look(Vector2(0,-200000))
	check(rig.pitch <= deg_to_rad(80),"mouse pitch upper clamp")
	rig.pitch = 0
	rig.invert_y = true
	rig.look(Vector2(0,100))
	check(rig.pitch > 0,"invert Y reverses vertical look")
	var yaw: float = rig.yaw
	rig.look(Vector2(NAN,0))
	check(rig.yaw == yaw,"nonfinite mouse input rejected")
	rig.queue_free()
	await process_frame
	var game = Scene.instantiate()
	root.add_child(game)
	game.automated = true
	game.synthetic_run = true
	game.select_map("toy_home")
	await physics_frame
	await process_frame
	check(game.rules.phase == State.Phase.MENU,"Phase 3 starts on map-select menu")
	check(not game.wants_capture(),"menu releases mouse")
	game.start_match(false)
	check(not game.wants_capture(),"drawing canvas releases mouse")
	game.accept_drawing()
	await process_frame
	check(game.wants_capture(),"hider gameplay requests captured mouse")
	game._process(0.1)
	check(game.rig.hand_root.visible,"own custom weapon and hands visible during exploration")
	check(game.rig.view_weapon.mesh != null,"first-person weapon is generated 3D geometry")
	check(game.rig.view_weapon.layers == Rig.VIEW_LAYER,"view weapon uses camera layer")
	game.fighters[0].view_pitch = 0.0
	game.fighters[0].step(1.0/60,Vector3.ZERO,game.rig.forward())
	var neutral_pitch: float = game.fighters[0].weapon_pivot.rotation.x
	game.fighters[0].view_pitch = 0.6
	game.fighters[0].step(1.0/60,Vector3.ZERO,game.rig.forward())
	check(game.fighters[0].weapon_pivot.rotation.x < neutral_pitch-0.4,"world-space weapon responds to vertical view aim")
	game.fighters[0].view_pitch = 0.0
	game.rig.pitch = 0.3
	game._aim_input()
	check(is_equal_approx(game.fighters[0].view_pitch,0.3),"camera pitch is delivered to authoritative weapon pose")
	game.rig.pitch = 0.0
	var source := JSON.stringify(game.fighters[0].weapon_data.to_dictionary())
	game.rig.follow(game.fighters[0],0.1,false,true)
	check(JSON.stringify(game.fighters[0].weapon_data.to_dictionary()) == source,"cosmetic view scale never changes canonical weapon")
	var original_yaw: float = game.rig.yaw
	var motion := InputEventMouseMotion.new()
	motion.screen_relative = Vector2(120,20)
	game._input(motion)
	check(game.rig.yaw != original_yaw,"real mouse handler changes first-person aim")
	var time: float = game.rules.time_left
	game.toggle_pause()
	check(not game.wants_capture() and game.paused,"pause releases mouse")
	var paused_yaw: float = game.rig.yaw
	game._input(motion)
	check(game.rig.yaw == paused_yaw,"UI mouse movement cannot rotate player")
	game.automated = false
	game._physics_process(0.5)
	game.automated = true
	check(game.rules.time_left == time,"pause freezes map timers")
	game.toggle_pause()
	var center: Vector2 = Catalog.prop_centers("toy_home")[0]
	var spot: Vector3 = game.arena.spots[0]
	game.fighters[0].position = spot
	game.rig.face(Vector3(center.x,0,center.y)-spot)
	game._process(0.01)
	await physics_frame
	check(game._focused_spot() == 0,"reticle selects nearby in-view hideout")
	game.rig.face(spot-Vector3(center.x,0,center.y))
	game._process(0.01)
	check(game._focused_spot() == -1,"cannot inspect a hideout behind the camera")
	game.rig.face(Vector3(center.x,0,center.y)-spot)
	game._process(0.01)
	game._interact()
	check(game.fighters[0].hidden_in_box,"first-person E hides at focused prop")
	game._process(0.01)
	check(not game.rig.hand_root.visible,"hiding removes first-person weapon from view")
	check(game.fighters[0].collision_layer == 0,"hidden player does not block other players")
	game._interact()
	check(not game.fighters[0].hidden_in_box,"E exits hiding without a focused prop")
	game.return_to_menu()
	game.start_match(true)
	game.accept_drawing()
	check(not game.wants_capture() and game.ui.modal.visible,"seeker wait prevents peeking")
	game.rules.tick(game.rules.hiding_seconds+0.1)
	for id in [2,3]:
		game.fighters[id].set_hidden(true,id)
	game.fighters[0].position = Vector3(0,0,2)
	game.fighters[1].position = Vector3(0,0,4)
	game.rig.face(Vector3.FORWARD)
	game._process(0.01)
	await physics_frame
	game._scan_visible_hiders()
	check(game.rules.phase == State.Phase.SEEK,"no automatic discovery behind first-person camera")
	game.fighters[0].position = Vector3(-7.8,0,-1.8)
	game.fighters[1].position = Vector3(-7.8,0,-4.4)
	game._process(0.01)
	await physics_frame
	game._scan_visible_hiders()
	check(game.rules.phase == State.Phase.SEEK,"partition wall prevents first-person discovery")
	game.fighters[0].position = Vector3(0,0,2)
	game.fighters[1].position = Vector3(0,0,-2)
	game._process(0.01)
	await physics_frame
	game._scan_visible_hiders()
	check(game.rules.phase == State.Phase.REVEAL,"visible front target is discovered")
	game._process(0.01)
	check(game.view_target() == 0 and game.rig.hand_root.visible,"own duel stays first person with visible weapon")
	check(game.rig.forward().dot((game.fighters[1].position-game.fighters[0].position).normalized()) > 0.99,"duel starts facing opponent")
	game.rules.tick(State.REVEAL_SECONDS+0.1)
	game.rules.tick(State.DUEL_SECONDS+0.1)
	check(game.rules.phase == State.Phase.SEEK,"first-person duel returns to search")
	game.select_map("garden")
	check(game.map_id == "toy_home","map cannot switch mid-match")
	game.fighters[0].position = Vector3(0,0,-9.55)
	game.rig.face(Vector3.FORWARD)
	await physics_frame
	game._process(1.0)
	check(game.rig.wall_retract > 0.5,"weapon retracts near a wall")
	game.return_to_menu()
	game.select_map("garden")
	await physics_frame
	check(game.arena.dimensions == Vector2(80,56),"menu map selector rebuilds large arena")
	game.start_match(true)
	game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.1)
	check(game.hide_assignments.size() == 4 and game.search_route.size() == 24,"large map uses dynamic hideouts, not old six-slot list")
	game.fighters[0].position = Vector3(29,0,19)
	game.fighters[1].position = Vector3(31,0,19)
	game.rules.discover(1)
	game.rules.tick(State.REVEAL_SECONDS+0.1)
	game.rules.tick(State.DUEL_SECONDS+0.1)
	check(game.fighters[1].position.distance_to(Vector3(31,0,19)) < 6,"escaped hider returns near discovery, not across the large map")
	game.rules.alive[0] = false
	game.rules.seeker = 1
	game._process(0.01)
	check(game.is_spectating() and game.view_target() == 1,"captured player spectates a live first-person subject")
	check((game.fighters[1].nameplate.layers & game.camera.cull_mask) == 0,"spectated head and nameplate do not obstruct camera")
	game.queue_free()
	await process_frame
	print("PHASE3_UNIT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
