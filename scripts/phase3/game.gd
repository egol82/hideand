extends "res://scripts/phase2/game.gd"
## First-person extension: legacy scenes remain unchanged and independently testable.
const Rules3 = preload("res://scripts/phase3/match_rules.gd")
const Fighter3 = preload("res://scripts/phase3/fighter.gd")
const Arena3 = preload("res://scripts/phase3/arena.gd")
const Interface3 = preload("res://scripts/phase3/interface.gd")
const Rig3 = preload("res://scripts/phase3/first_person.gd")
const Prefs3 = preload("res://scripts/phase3/preferences.gd")
const Catalog3 = preload("res://scripts/phase3/map_catalog.gd")
var rig
var map_id := "toy_home"
var focus_spot := -1
var hit_feedback := 0.0
var current_subject := -1
var pre_duel_angles := Vector2.ZERO
var environment_node: WorldEnvironment
var synthetic_run := false

func _ready() -> void:
	rules = Rules3.new()
	preferences = Prefs3.new()
	preferences.load_local()
	rng.seed = 8027
	var args := OS.get_cmdline_user_args()
	automated = "--phase3-smoke" in args or "--capture-phase3" in args
	autoplay = "--phase3-autoplay" in args
	synthetic_run = automated or autoplay or "--phase3-test" in args
	map_id = preferences.map_id
	for arg in args:
		if arg.begins_with("--map="):
			map_id = str(Catalog3.spec(arg.trim_prefix("--map=")).id)
	if not synthetic_run:
		rng.randomize()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_min_size(Vector2i(1120,680))
	_setup_world()
	arena = Arena3.new()
	arena.map_id = map_id
	add_child(arena)
	rules.configure(arena.config)
	environment_node.environment.background_color = arena.config.sky
	for i in range(4):
		var actor = Fighter3.new()
		actor.player_id = i
		actor.tint = COLORS[i]
		actor.position = arena.spawn_points[i]
		actor.use_view_aim = i == 0 and not autoplay
		add_child(actor)
		var data = Data.new()
		data.set_preset(["fish","hammer","pan","fish"][i])
		data.color_index = i
		actor.equip(data)
		actor.show_weapon(false)
		fighters.append(actor)
		routes.append(PackedVector2Array())
		before_duel.append(actor.position)
	draft = fighters[0].weapon_data.clone()
	audio = SoundBank.new()
	add_child(audio)
	audio.volume = 0.0 if DisplayServer.get_name() == "headless" else preferences.volume
	ui = Interface3.new()
	ui.game = self
	add_child(ui)
	rules.changed.connect(_phase_changed)
	rules.duel_resolved.connect(_duel_resolved)
	ui.show_menu()
	if automated:
		call_deferred("_automation3")
	elif autoplay:
		call_deferred("start_match",true)

func _setup_world() -> void:
	environment_node = WorldEnvironment.new()
	environment_node.environment = make_environment()
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_energy = 0.57
	sun.light_color = Color("ffe8c3")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	add_child(sun)
	rig = Rig3.new()
	add_child(rig)
	camera = rig.view
	camera.fov = preferences.vertical_fov
	rig.sensitivity = preferences.mouse_sensitivity
	rig.invert_y = preferences.invert_y

func select_map(id: String) -> void:
	if rules.phase != Rules.Phase.MENU or id not in Catalog3.IDS:
		return
	map_id = id
	preferences.map_id = id
	if not synthetic_run:
		preferences.save_local()
	remove_child(arena)
	arena.queue_free()
	arena = Arena3.new()
	arena.map_id = id
	add_child(arena)
	rules.configure(arena.config)
	environment_node.environment.background_color = arena.config.sky
	for i in range(fighters.size()):
		fighters[i].original_spawn = arena.spawn_points[i]
		fighters[i].reset_fight(arena.spawn_points[i])
		fighters[i].show_weapon(false)
	focus_spot = -1
	rig.face(Vector3.FORWARD)

func start_match(seek_first: bool = true) -> void:
	qa_stats = {"duels":0,"captures":0,"escapes":0,"hits":0,"rounds":0}
	super.start_match(seek_first)

func _prepare_round() -> void:
	freeze = 0
	shake = 0
	clue_spot = -1
	clue_time = 0
	inspect_cooldown = 0
	taunt_cooldown = 0
	focus_spot = -1
	var available: Array[int] = []
	for i in range(arena.spots.size()):
		available.append(i)
	_shuffle(available)
	# A public-geometry tour, never a route ordered by hidden occupancy.
	search_route = _search_tour(arena.spawn_points[rules.seeker])
	search_cursor = 0
	for i in range(4):
		fighters[i].reset_fight(arena.spawn_points[i])
		fighters[i].show_weapon(false)
		hide_assignments[i] = available.pop_back() if i != rules.seeker else -1
		routes[i] = PackedVector2Array()
		repath[i] = 0
		fighters[i].nameplate.text = Interface.NAMES[i]
	draft = fighters[0].weapon_data.clone()
	rig.face(Vector3.FORWARD)

func _search_tour(start: Vector3) -> Array[int]:
	var remaining: Array[int] = []
	var tour: Array[int] = []
	for i in range(arena.spots.size()):
		remaining.append(i)
	var at := start
	while not remaining.is_empty():
		var best: int = remaining[0]
		for i in remaining:
			if at.distance_squared_to(arena.spots[i]) < at.distance_squared_to(arena.spots[best]):
				best = i
		tour.append(best)
		remaining.erase(best)
		at = arena.spots[best]
	return tour

func _free_spot(id: int) -> int:
	var candidates: Array[int] = []
	for i in range(arena.spots.size()):
		if not _occupied(i,id):
			candidates.append(i)
	_shuffle(candidates)
	return -1 if candidates.is_empty() else candidates[0]

func _phase_changed() -> void:
	var finished: bool = rules.phase == Rules.Phase.COMPLETE and autoplay
	if finished:
		autoplay = false # The inherited report is explicitly Phase 2 only.
	super._phase_changed()
	if finished:
		autoplay = true
		qa_stats["map"] = map_id
		print("PHASE3_AUTOPLAY_RESULT: "+JSON.stringify(qa_stats))
		get_tree().quit(0 if qa_stats.rounds == 4 and qa_stats.duels > 0 and qa_stats.hits > 0 else 1)
	_sync_mouse()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not automated and not paused and rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.DUEL]:
		for actor in fighters:
			if not arena.inside(actor.position) or actor.position.y < -1:
				actor.reset_fight(arena.spawn_points[actor.player_id])

func _process(delta: float) -> void:
	# Headless autoplay exercises the real physics/AI, not an invisible view model.
	if autoplay and DisplayServer.get_name() == "headless":
		return
	if not is_instance_valid(ui):
		return
	var id := view_target()
	if current_subject != id:
		for actor in fighters:
			actor.set_view_subject(false)
		current_subject = id
	fighters[id].set_view_subject(true)
	rig.reduced_motion = preferences.reduced_motion
	var show_hands: bool = world_view_active() and not fighters[id].hidden_in_box and (id == 0 or rules.phase in [Rules.Phase.REVEAL,Rules.Phase.DUEL])
	rig.follow(fighters[id],0.0 if paused else delta,id != 0 or autoplay,show_hands)
	focus_spot = _focused_spot() if world_view_active() and not paused and not is_spectating() else -1
	arena.mark_target(focus_spot)
	hit_feedback = maxf(0,hit_feedback-delta)
	ui.refresh(rules)
	_sync_mouse()

func world_view_active() -> bool:
	return rules.phase in [Rules.Phase.SEEK,Rules.Phase.REVEAL,Rules.Phase.DUEL] or (rules.phase == Rules.Phase.HIDE and rules.seeker != 0)

func view_target() -> int:
	if rules.phase in [Rules.Phase.REVEAL,Rules.Phase.DUEL] and 0 not in [rules.seeker,rules.opponent]:
		return rules.seeker
	if not rules.alive[0]:
		return rules.seeker
	return 0

func is_spectating() -> bool:
	return view_target() != 0

func wants_capture() -> bool:
	return world_view_active() and not paused and not ui.modal.visible

func _sync_mouse() -> void:
	if DisplayServer.get_name() == "headless" or synthetic_run:
		return
	var desired := Input.MOUSE_MODE_CAPTURED if wants_capture() else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != desired:
		Input.mouse_mode = desired

func _move_input() -> Vector3:
	var input := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	return rig.move_vector(input)

func _aim_input() -> Vector3:
	fighters[0].view_pitch = rig.pitch
	return rig.forward()

func _focused_spot() -> int:
	if rules.phase not in [Rules.Phase.HIDE,Rules.Phase.SEEK] or not rules.alive[0] or fighters[0].hidden_in_box:
		return -1
	var best := -1
	var best_dot := 0.42
	var eye: Vector3 = fighters[0].position+Vector3.UP*Rig3.EYE_HEIGHT
	var centers: Array[Vector2] = Catalog3.prop_centers(map_id)
	for i in range(arena.spots.size()):
		var at: Vector3 = arena.spots[i]
		if fighters[0].position.distance_to(at) > 2.0:
			continue
		var into := Vector3(centers[i].x,0,centers[i].y)-at
		var focus: Vector3 = at+into.normalized()*0.4+Vector3.UP
		var direction := (focus-eye).normalized()
		var dot: float = (-camera.global_basis.z).dot(direction)
		if dot > best_dot and arena.clear_ray(eye,focus):
			best_dot = dot
			best = i
	return best

func _interact() -> void:
	if paused or is_spectating() or not rules.alive[0] or rules.phase not in [Rules.Phase.HIDE,Rules.Phase.SEEK]:
		return
	if fighters[0].hidden_in_box and rules.seeker != 0:
		fighters[0].set_hidden(false)
		ui.notify("OUT IN THE OPEN!",0.8)
		return
	var near := _focused_spot()
	if near < 0:
		ui.notify("LOOK AT A NEARBY HIDEOUT, THEN PRESS E",1.2)
		return
	if rules.seeker == 0:
		if rules.phase == Rules.Phase.SEEK and inspect_cooldown <= 0:
			inspect_cooldown = 0.45
			_inspect(0,near)
	elif not _occupied(near,0):
		fighters[0].position = arena.spots[near]
		fighters[0].set_hidden(true,near)
		ui.notify("HIDDEN — E TO LEAVE",1.2)
	else:
		ui.notify("THIS HIDEOUT IS TAKEN",1.0)

func _scan_visible_hiders() -> void:
	var hunter = fighters[rules.seeker]
	for id in range(4):
		if id == rules.seeker or not rules.alive[id] or fighters[id].hidden_in_box or rules.grace[id] > 0:
			continue
		var eye: Vector3 = hunter.position+Vector3.UP*Rig3.EYE_HEIGHT
		var target: Vector3 = fighters[id].position+Vector3.UP*1.1
		var direction := target-eye
		if direction.length() > 6.0:
			continue
		var forward: Vector3 = -camera.global_basis.z if rules.seeker == 0 and not autoplay else hunter.visual.global_basis.z
		# Human discovery is restricted to a cone within the actual camera frustum.
		var threshold := cos(deg_to_rad(minf(32,camera.fov*0.45))) if rules.seeker == 0 and not autoplay else 0.45
		if forward.dot(direction.normalized()) < threshold:
			continue
		if arena.clear_ray(eye,target) and rules.discover(id):
			return

func _inspect(id: int, spot: int) -> void:
	if spot < 0 or spot >= arena.spots.size():
		return
	super._inspect(id,spot)

func _begin_duel() -> void:
	pre_duel_angles = Vector2(rig.yaw,rig.pitch)
	super._begin_duel()
	fighters[rules.seeker].position = Vector3(-1.65,0,0)
	fighters[rules.opponent].position = Vector3(1.65,0,0)
	if 0 in [rules.seeker,rules.opponent]:
		var other: int = rules.opponent if rules.seeker == 0 else rules.seeker
		rig.face(fighters[other].position-fighters[0].position)

func _duel_contacts() -> void:
	var old_hits: int = qa_stats.hits
	super._duel_contacts()
	if qa_stats.hits > old_hits:
		hit_feedback = 0.16

func _duel_resolved(hider: int, captured: bool) -> void:
	super._duel_resolved(hider,captured)
	if not captured:
		var away: Vector3 = before_duel[hider]-before_duel[rules.seeker]
		away.y = 0
		if away.length_squared() < 0.01:
			away = Vector3.RIGHT
		var cell: Vector2i = arena.nearest_id(before_duel[hider]+away.normalized()*3)
		var p: Vector2 = arena.navigation.get_point_position(cell)
		fighters[hider].reset_fight(Vector3(p.x,0,p.y))
		fighters[hider].show_weapon(false)
	rig.yaw = pre_duel_angles.x
	rig.pitch = pre_duel_angles.y

func toggle_pause() -> void:
	super.toggle_pause()
	_sync_mouse()

func return_to_menu() -> void:
	super.return_to_menu()
	_sync_mouse()

func set_sensitivity(value: float) -> void:
	preferences.mouse_sensitivity = clampf(value,0.0005,0.008)
	rig.sensitivity = preferences.mouse_sensitivity
	preferences.save_local()

func set_fov(value: float) -> void:
	preferences.vertical_fov = clampf(value,55,90)
	camera.fov = preferences.vertical_fov
	preferences.save_local()

func set_invert_y(value: bool) -> void:
	preferences.invert_y = value
	rig.invert_y = value
	preferences.save_local()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and wants_capture() and not is_spectating():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or synthetic_run:
			rig.look(event.screen_relative)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		if rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.REVEAL,Rules.Phase.DUEL]:
			toggle_pause()
			if paused:
				ui.show_map()
			get_viewport().set_input_as_handled()
		return
	super._input(event)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not synthetic_run:
		super._notification(what)

func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _automation3() -> void:
	await get_tree().process_frame
	var capture := "--capture-phase3" in OS.get_cmdline_user_args()
	if capture:
		await _capture("phase3_00_map_menu")
	for id in Catalog3.IDS:
		return_to_menu()
		select_map(id)
		await get_tree().physics_frame
		start_match(true)
		if capture and id == "toy_home":
			await _capture("phase3_01_drawing")
		accept_drawing()
		for i in range(1,4):
			fighters[i].position = arena.spots[hide_assignments[i]]
			fighters[i].set_hidden(true,hide_assignments[i])
		rules.tick(rules.hiding_seconds+0.1)
		fighters[0].position = Vector3(0,0,5)
		rig.face(Vector3(-0.45,0,-1))
		await get_tree().physics_frame
		if capture:
			await _capture("phase3_"+id+"_fps")
		if id == "toy_home":
			rules.discover(1)
			await get_tree().process_frame
			if capture:
				await _capture("phase3_02_reveal")
			rules.tick(Rules.REVEAL_SECONDS+0.1)
			fighters[0].begin_swing()
			for n in range(10):
				fighters[0].step(1.0/60,Vector3.ZERO,rig.forward())
				await get_tree().physics_frame
			if capture:
				await _capture("phase3_03_swing")
			rules.tick(Rules.DUEL_SECONDS+0.1)
		if rules.phase != Rules.Phase.SEEK:
			printerr("FAIL: Phase 3 search state lost")
			get_tree().quit(1)
			return
	print("PHASE3_SMOKE_READY: first-person, custom weapon, three maps, reveal and escape initialized")
	get_tree().quit(0)

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: render capture requires a windowed renderer")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ci-artifacts"))
	var error := get_viewport().get_texture().get_image().save_png("res://ci-artifacts/"+name+".png")
	if error != OK:
		printerr("FAIL: capture "+name+" "+error_string(error))
		get_tree().quit(1)
		return
	print("PHASE3_CAPTURE: "+name)
