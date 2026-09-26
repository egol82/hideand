extends Node3D
## Offline Phase 2: one human, three bots, four rotating-seeker rounds.
const Rules = preload("res://scripts/phase2/match_rules.gd")
const Fighter = preload("res://scripts/phase2/fighter.gd")
const Arena = preload("res://scripts/phase2/arena.gd")
const Data = preload("res://scripts/phase2/drawing_data.gd")
const Interface = preload("res://scripts/phase2/interface.gd")
const Combat = preload("res://scripts/phase2/combat.gd")
const Preferences = preload("res://scripts/phase2/preferences.gd")
const SoundBank = preload("res://scripts/phase2/sound_bank.gd")
const Toy = preload("res://scripts/toy_factory.gd")
const HOME := Vector3(9.5,12.5,15.5)
const COLORS := [Color("88d6b0"),Color("df92b2"),Color("edcd75"),Color("8fbbe4")]
var rules = Rules.new()
var preferences = Preferences.new()
var arena
var ui
var audio
var fighters: Array = []
var camera: Camera3D
var rng := RandomNumberGenerator.new()
var paused := false
var automated := false
var autoplay := false
var qa_stats := {"duels":0,"captures":0,"escapes":0,"hits":0,"rounds":0}
var draft = Data.new()
var last_phase := Rules.Phase.MENU
var hide_assignments: Array[int] = [-1,-1,-1,-1]
var routes: Array[PackedVector2Array] = []
var repath: Array[float] = [0.0,0.0,0.0,0.0]
var search_route: Array[int] = []
var search_cursor := 0
var inspect_cooldown := 0.0
var taunt_cooldown := 0.0
var clue_spot := -1
var clue_time := 0.0
var scan_elapsed := 0.0
var freeze := 0.0
var shake := 0.0
var clock := 0.0
var before_duel: Array[Vector3] = []

func _ready() -> void:
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			rng.seed = arg.trim_prefix("--seed=").to_int()
	automated = "--phase2-smoke" in OS.get_cmdline_user_args() or "--capture-phase2" in OS.get_cmdline_user_args()
	autoplay = "--autoplay-test" in OS.get_cmdline_user_args()
	preferences.load_local()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_min_size(Vector2i(1120,680))
	_setup_world()
	arena = Arena.new()
	add_child(arena)
	for i in range(4):
		var actor = Fighter.new()
		actor.player_id = i
		actor.tint = COLORS[i]
		actor.position = Vector3(-1.5+i,0,0.7)
		add_child(actor)
		var data = Data.new()
		data.set_preset(["hammer","fish","pan","hammer"][i])
		data.color_index = i
		actor.equip(data)
		actor.show_weapon(false)
		fighters.append(actor)
		routes.append(PackedVector2Array())
		before_duel.append(actor.position)
	draft = fighters[0].weapon_data.clone()
	audio = SoundBank.new()
	add_child(audio)
	audio.volume = preferences.volume
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	rules.changed.connect(_phase_changed)
	rules.duel_resolved.connect(_duel_resolved)
	ui.show_menu()
	if automated:
		call_deferred("_automation")
	elif autoplay:
		rng.seed = 8027
		call_deferred("start_match",true)

func _setup_world() -> void:
	var world := WorldEnvironment.new()
	world.environment = make_environment()
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-35,0)
	sun.light_color = Color("ffe3b6")
	sun.light_energy = 0.58
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(4,4,3)
	fill.omni_range = 15
	fill.light_energy = 0.12
	fill.light_color = Color("b8d8e6")
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.5
	camera.position = HOME
	add_child(camera)
	camera.look_at(Vector3(0,0.6,-0.2))
	camera.current = true

func make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("283f46")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e8eedc")
	env.ambient_light_energy = 0.23
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	return env

func start_match(seek_first: bool = true) -> void:
	paused = false
	rules.start(seek_first)

func return_to_menu() -> void:
	paused = false
	rules.phase = Rules.Phase.MENU
	last_phase = Rules.Phase.MENU
	for actor in fighters:
		actor.reset_fight(actor.original_spawn)
		actor.show_weapon(false)
	arena.mark_near(Vector3.ZERO,false)
	ui.show_menu()

func accept_drawing() -> void:
	if rules.phase != Rules.Phase.DRAW:
		return
	if is_instance_valid(ui.canvas) and not ui.canvas.data.is_valid():
		return
	_commit_draft()
	rules.ready()

func _commit_draft() -> void:
	if is_instance_valid(ui.canvas):
		ui.canvas.finish_stroke()
		draft = ui.canvas.data.clone()
	if draft.is_valid():
		fighters[0].equip(draft)

func next_round() -> void:
	rules.next_round()

func _phase_changed() -> void:
	var phase: int = rules.phase
	if last_phase == Rules.Phase.DRAW and phase != Rules.Phase.DRAW:
		_commit_draft() # Timeout keeps the previous valid toy instead of inventing one.
	var previous_phase := last_phase
	var entering := phase != last_phase
	last_phase = phase
	match phase:
		Rules.Phase.DRAW:
			_prepare_round()
			ui.show_drawing(draft)
			if autoplay:
				call_deferred("accept_drawing")
		Rules.Phase.HIDE:
			for actor in fighters:
				actor.show_weapon(false)
			fighters[rules.seeker].visible = false
			if rules.seeker == 0:
				ui.show_wait()
			else:
				ui.hide_modal()
				ui.notify("HIDE! Find a prop and press E.")
			audio.play("ready")
		Rules.Phase.SEEK:
			ui.hide_modal()
			fighters[rules.seeker].visible = true
			for actor in fighters:
				actor.show_weapon(false)
			if entering and previous_phase == Rules.Phase.HIDE:
				ui.notify("SEEK! Inspect a prop with E.")
		Rules.Phase.REVEAL:
			_begin_duel()
			ui.hide_modal()
			ui.notify("FOUND!  SHOW YOUR TOY",1.2)
			audio.play("found")
		Rules.Phase.DUEL:
			ui.notify("SMASH!",0.7)
		Rules.Phase.RESULT:
			qa_stats["rounds"] += 1
			ui.show_result(rules,false)
			if autoplay:
				call_deferred("next_round")
		Rules.Phase.COMPLETE:
			preferences.best_score = maxi(preferences.best_score,rules.scores[0])
			preferences.save_local()
			ui.show_result(rules,true)
			if autoplay:
				print("PHASE2_AUTOPLAY_RESULT: "+JSON.stringify(qa_stats))
				get_tree().quit(0 if qa_stats["duels"] > 0 and qa_stats["hits"] > 0 and qa_stats["rounds"] == 4 else 1)

func _prepare_round() -> void:
	freeze = 0.0
	shake = 0.0
	clue_spot = -1
	clue_time = 0.0
	inspect_cooldown = 0.0
	taunt_cooldown = 0.0
	var available: Array[int] = [0,1,2,3,4,5]
	_shuffle(available)
	search_route.assign([0,1,2,3,4,5])
	_shuffle(search_route)
	search_cursor = 0
	for i in range(4):
		fighters[i].reset_fight(Vector3(-1.5+i,0,0.7))
		fighters[i].show_weapon(false)
		hide_assignments[i] = available.pop_back() if i != rules.seeker else -1
		routes[i] = PackedVector2Array()
		repath[i] = 0.0
		fighters[i].nameplate.text = Interface.NAMES[i] + ("  [SEEKER]" if i == rules.seeker else "")
	# Every round keeps the human's last valid weapon, ready for editing.
	draft = fighters[0].weapon_data.clone()

func _shuffle(values: Array[int]) -> void:
	for i in range(values.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var temp := values[i]
		values[i] = values[j]
		values[j] = temp

func _physics_process(delta: float) -> void:
	if automated or paused:
		return
	clock += delta
	if freeze > 0.0:
		freeze -= delta
		return
	rules.tick(delta)
	inspect_cooldown = maxf(0,inspect_cooldown-delta)
	taunt_cooldown = maxf(0,taunt_cooldown-delta)
	clue_time = maxf(0,clue_time-delta)
	if rules.phase not in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.DUEL]:
		return
	var simulation_phase: int = rules.phase
	for i in range(4):
		if rules.phase != simulation_phase:
			break
		if not rules.alive[i]:
			continue
		if rules.phase == Rules.Phase.HIDE and i == rules.seeker:
			continue
		if rules.phase == Rules.Phase.DUEL and i != rules.seeker and i != rules.opponent:
			continue
		var wish := _move_input() if i == 0 and not autoplay else _bot_move(i,delta)
		if rules.phase != simulation_phase:
			break
		var aim := _aim_input() if i == 0 and not autoplay else _bot_aim(i,wish)
		fighters[i].step(delta,wish,aim)
		# Recovery guard: never leave a participant underneath or outside the room.
		if fighters[i].position.y < -2.0:
			fighters[i].reset_fight(Vector3.ZERO)
	if rules.phase == Rules.Phase.DUEL:
		_duel_contacts()
	elif rules.phase == Rules.Phase.SEEK:
		scan_elapsed += delta
		if scan_elapsed >= 0.15:
			scan_elapsed = 0.0
			_scan_visible_hiders()

func _process(delta: float) -> void:
	if not is_instance_valid(ui):
		return
	ui.refresh(rules)
	var fight: bool = rules.phase in [Rules.Phase.REVEAL,Rules.Phase.DUEL]
	var target_size := 10.8 if fight and not preferences.reduced_motion else 14.5
	camera.size = lerpf(camera.size,target_size,minf(1,delta*5))
	shake = move_toward(shake,0.0,delta*0.8)
	camera.position = HOME
	if not preferences.reduced_motion:
		camera.position += Vector3(sin(clock*111)*shake,sin(clock*79)*shake,0)
	arena.mark_near(fighters[0].position,not paused and rules.alive[0] and rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK])

func _move_input() -> Vector3:
	var x := float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	var z := float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var right := camera.global_basis.x
	var down := camera.global_basis.z
	right.y = 0
	down.y = 0
	return (right.normalized()*x+down.normalized()*z).limit_length()

func _aim_input() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var plane := Plane(Vector3.UP,1.0)
	var point: Variant = plane.intersects_ray(camera.project_ray_origin(mouse),camera.project_ray_normal(mouse))
	if point is Vector3:
		var direction: Vector3 = point-fighters[0].position
		direction.y = 0
		return direction.normalized()
	return Vector3.FORWARD

func _bot_move(id: int, delta: float) -> Vector3:
	var actor = fighters[id]
	if actor.hidden_in_box:
		return Vector3.ZERO
	if rules.phase == Rules.Phase.DUEL:
		var other: int = rules.opponent if id == rules.seeker else rules.seeker
		var direction: Vector3 = fighters[other].position-actor.position
		direction.y = 0
		var distance := direction.length()
		if distance < maxf(0.85,actor.weapon_data.reach()*0.9):
			actor.begin_swing()
		if fighters[other].attack_active() and rng.randf() < 0.008:
			actor.begin_dash(-direction)
		if distance > 1.2:
			return direction.normalized()*0.75
		if distance < 0.75:
			return -direction.normalized()*0.6
		return Vector3.ZERO
	var destination: Vector3
	if id == rules.seeker:
		var target_spot: int = search_route[search_cursor]
		if clue_time > 0.0 and clue_spot >= 0:
			target_spot = clue_spot
		destination = arena.spots[target_spot]
		if actor.position.distance_to(destination) < 0.9:
			if inspect_cooldown <= 0.0:
				inspect_cooldown = 0.55
				_inspect(id,target_spot)
				search_cursor = (search_cursor+1)%search_route.size()
				clue_spot = -1
			return Vector3.ZERO
	else:
		var spot: int = hide_assignments[id]
		if spot < 0 or _occupied(spot,id):
			spot = _free_spot(id)
			hide_assignments[id] = spot
		if spot < 0:
			return Vector3.ZERO
		destination = arena.spots[spot]
		if actor.position.distance_to(destination) < 0.6:
			actor.position = destination
			actor.set_hidden(true,spot)
			return Vector3.ZERO
	repath[id] -= delta
	if repath[id] <= 0.0 or routes[id].is_empty():
		routes[id] = arena.path_to(actor.position,destination)
		repath[id] = 0.4
	while not routes[id].is_empty():
		var point := Vector3(routes[id][0].x,0,routes[id][0].y)
		var direction: Vector3 = point-actor.position
		direction.y = 0
		if direction.length() < 0.22:
			routes[id].remove_at(0)
		else:
			return direction.normalized()*0.8
	var direct: Vector3 = destination-actor.position
	direct.y = 0
	return direct.limit_length()*0.8

func _bot_aim(id: int, wish: Vector3) -> Vector3:
	if rules.phase == Rules.Phase.DUEL:
		var other: int = rules.opponent if id == rules.seeker else rules.seeker
		return fighters[other].position-fighters[id].position
	return wish

func _occupied(spot: int, except: int) -> bool:
	for i in range(4):
		if i != except and rules.alive[i] and fighters[i].hidden_in_box and fighters[i].spot == spot:
			return true
	return false

func _free_spot(id: int) -> int:
	var order: Array[int] = [0,1,2,3,4,5]
	_shuffle(order)
	for spot in order:
		if not _occupied(spot,id):
			return spot
	return -1

func _scan_visible_hiders() -> void:
	var hunter = fighters[rules.seeker]
	for id in range(4):
		if id == rules.seeker or not rules.alive[id] or fighters[id].hidden_in_box or rules.grace[id] > 0.0:
			continue
		var direction: Vector3 = fighters[id].position-hunter.position
		direction.y = 0
		if direction.length() > 3.5:
			continue
		if direction.length() > 1.0 and hunter.visual.global_basis.z.dot(direction.normalized()) < 0.15:
			continue
		if arena.has_sight(hunter.position,fighters[id].position):
			if rules.discover(id):
				return

func _inspect(id: int, spot: int) -> void:
	if rules.phase != Rules.Phase.SEEK or id != rules.seeker:
		return
	if not arena.has_sight(fighters[id].position,arena.spots[spot]):
		return
	for other in range(4):
		if fighters[other].hidden_in_box and fighters[other].spot == spot:
			if rules.discover(other):
				return
	if id == 0:
		ui.notify("EMPTY... TRY ANOTHER SPOT",0.9)

func _interact() -> void:
	if rules.phase not in [Rules.Phase.HIDE,Rules.Phase.SEEK] or not rules.alive[0]:
		return
	if rules.seeker == 0:
		if rules.phase == Rules.Phase.HIDE or inspect_cooldown > 0.0:
			return
		var near: int = arena.nearest_spot(fighters[0].position)
		if near >= 0:
			inspect_cooldown = 0.45
			_inspect(0,near)
		else:
			ui.notify("MOVE CLOSER TO A HIDING SPOT",1.0)
	elif fighters[0].hidden_in_box:
		fighters[0].set_hidden(false)
		ui.notify("OUT IN THE OPEN!",0.8)
	else:
		var near: int = arena.nearest_spot(fighters[0].position)
		if near >= 0 and not _occupied(near,0) and arena.has_sight(fighters[0].position,arena.spots[near]):
			fighters[0].position = arena.spots[near]
			fighters[0].set_hidden(true,near)
			ui.notify("HIDDEN — E TO LEAVE",1.6)
		else:
			ui.notify("FIND AN EMPTY HIDING SPOT",1.0)

func _begin_duel() -> void:
	qa_stats["duels"] += 1
	for i in range(4):
		before_duel[i] = fighters[i].position
	var hunter = fighters[rules.seeker]
	var hider = fighters[rules.opponent]
	hunter.reset_fight(Vector3(-1.0,0,0))
	hider.reset_fight(Vector3(1.0,0,0))
	hunter.visual.rotation.y = PI*0.5
	hider.visual.rotation.y = -PI*0.5
	hunter.show_weapon(true)
	hider.show_weapon(true)

func _duel_contacts() -> void:
	var first: int = rules.seeker
	var second: int = rules.opponent
	var attacks: Array[int] = []
	for id in [first,second]:
		var other: int = second if id == first else first
		if Combat.contact(fighters[id],fighters[other],get_world_3d().direct_space_state):
			attacks.append(id)
			qa_stats["hits"] += 1
			var direction: Vector3 = fighters[other].position-fighters[id].position
			direction.y = 0
			fighters[other].take_hit(direction)
			_spawn_impact(fighters[other].position+Vector3.UP)
	if not attacks.is_empty():
		freeze = 0.04 if not preferences.reduced_motion else 0.0
		shake = 0.1
		audio.play("hit")
		rules.register_hits(attacks)

func _duel_resolved(hider: int, captured: bool) -> void:
	qa_stats["captures" if captured else "escapes"] += 1
	fighters[rules.seeker].reset_fight(before_duel[rules.seeker])
	fighters[rules.seeker].show_weapon(false)
	if captured:
		fighters[hider].set_hidden(true)
		fighters[hider].visible = false
		audio.play("capture")
		ui.notify("CAPTURED!",1.1)
	else:
		fighters[hider].reset_fight(Vector3(2.0,0,1.8))
		fighters[hider].show_weapon(false)
		hide_assignments[hider] = _free_spot(hider)
		routes[hider] = PackedVector2Array()
		repath[hider] = 0.0
		audio.play("escape")
		ui.notify("ESCAPED!  5 SECOND HEAD START",1.3)

func _taunt() -> void:
	if rules.phase != Rules.Phase.SEEK or rules.seeker == 0 or not rules.alive[0] or taunt_cooldown > 0.0:
		return
	taunt_cooldown = 6.0
	clue_spot = fighters[0].spot if fighters[0].hidden_in_box else arena.nearest_spot(fighters[0].position,100.0)
	clue_time = 4.0
	audio.play("taunt")
	_spawn_impact(fighters[0].position+Vector3.UP*1.5)
	ui.notify("HEY, OVER HERE!  Your location is exposed.",1.4)

func _spawn_impact(at: Vector3) -> void:
	for i in range(8):
		var angle := TAU*i/8.0
		var spark := Toy.ellipsoid(self,at,Vector3.ONE*0.06,Color("fff0b0"))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(spark,"position",at+Vector3(cos(angle),0.5,sin(angle))*0.8,0.3)
		tween.tween_property(spark,"scale",Vector3.ONE*0.004,0.3)
		tween.chain().tween_callback(spark.queue_free)

func toggle_pause() -> void:
	if rules.phase in [Rules.Phase.MENU,Rules.Phase.RESULT,Rules.Phase.COMPLETE]:
		return
	paused = not paused
	if paused:
		if is_instance_valid(ui.canvas):
			ui.canvas.finish_stroke()
			draft = ui.canvas.data.clone()
		ui.show_pause()
	elif rules.phase == Rules.Phase.DRAW:
		ui.show_drawing(draft)
	elif rules.phase == Rules.Phase.HIDE and rules.seeker == 0:
		ui.show_wait()
	else:
		ui.hide_modal()

func set_reduced_motion(value: bool) -> void:
	preferences.reduced_motion = value
	preferences.save_local()

func set_volume(value: float) -> void:
	preferences.volume = value
	audio.volume = value
	preferences.save_local()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ui) and not paused and not automated and not autoplay:
		toggle_pause()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif event.physical_keycode == KEY_F12:
			_save_screenshot()
		elif event.physical_keycode == KEY_ENTER and rules.phase == Rules.Phase.RESULT:
			next_round()

func _unhandled_input(event: InputEvent) -> void:
	if paused or not rules.alive[0]:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				_interact()
			KEY_C:
				_taunt()
			KEY_SHIFT:
				if rules.phase == Rules.Phase.HIDE and rules.seeker == 0:
					return
				if rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.DUEL]:
					if rules.phase != Rules.Phase.DUEL or 0 in [rules.seeker,rules.opponent]:
						fighters[0].begin_dash(_move_input())
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if rules.phase == Rules.Phase.DUEL and 0 in [rules.seeker,rules.opponent]:
			fighters[0].begin_swing()

func _save_screenshot() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "user://phase2_%d.png" % Time.get_ticks_msec()
	var error := get_viewport().get_texture().get_image().save_png(path)
	ui.notify("Screenshot saved to user data" if error == OK else "Screenshot failed",1.3)

func _automation() -> void:
	# Scripted initialization/captures, NOT a claim of human playtesting.
	await get_tree().process_frame
	var capture := "--capture-phase2" in OS.get_cmdline_user_args()
	start_match(true)
	await get_tree().process_frame
	if capture:
		await _capture("01_drawing")
	accept_drawing()
	for id in range(1,4):
		fighters[id].position = arena.spots[hide_assignments[id]]
		fighters[id].set_hidden(true,hide_assignments[id])
	rules.tick(Rules.HIDE_SECONDS+0.01)
	await get_tree().physics_frame
	if capture:
		await _capture("02_seeking")
	if not rules.discover(1):
		printerr("PHASE2_SMOKE_FAILED: discovery rejected")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if capture:
		await _capture("03_reveal")
	rules.tick(Rules.REVEAL_SECONDS+0.01)
	fighters[0].begin_swing()
	for i in range(8):
		fighters[0].step(1.0/60.0,Vector3.ZERO,Vector3.RIGHT)
		await get_tree().physics_frame
	if capture:
		await _capture("04_duel")
	rules.tick(Rules.DUEL_SECONDS+0.01)
	if rules.phase != Rules.Phase.SEEK or rules.grace[1] <= 0:
		printerr("PHASE2_SMOKE_FAILED: escape did not return to search")
		get_tree().quit(1)
		return
	rules.tick(Rules.SEEK_SECONDS+0.01)
	if rules.phase != Rules.Phase.RESULT:
		get_tree().quit(1)
		return
	if capture:
		await _capture("05_result")
	print("PHASE2_SMOKE_READY: draw/hide/seek/reveal/duel/escape/result initialized")
	get_tree().quit(0)

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Capture requires a windowed renderer")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ci-artifacts"))
	var error := get_viewport().get_texture().get_image().save_png("res://ci-artifacts/"+name+".png")
	if error != OK:
		printerr("Capture failed: "+error_string(error))
	print("PHASE2_CAPTURE: "+name)
