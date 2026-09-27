extends "res://scripts/phase3/game.gd"
## Phase 4 composes independently verified authority, view, audio and rules modules.
const Rules4 = preload("res://scripts/phase4/match_rules.gd")
const Fighter4 = preload("res://scripts/phase4/fighter.gd")
const Arena4 = preload("res://scripts/phase4/arena.gd")
const Interface4 = preload("res://scripts/phase4/interface.gd")
const Rig4 = preload("res://scripts/phase4/first_person.gd")
const Prefs4 = preload("res://scripts/phase4/preferences.gd")
const Data4 = preload("res://scripts/phase4/drawing_data.gd")
const Contact4 = preload("res://scripts/phase4/combat.gd")
const Sound4 = preload("res://scripts/phase4/sound_bank.gd")
const Attack4 = preload("res://scripts/phase4/attack_spec.gd")
const Metrics4 = preload("res://scripts/phase4/telemetry.gd")
var metrics = Metrics4.new()
var hurt_feedback := 0.0
var block_feedback := 0.0
var hurt_angle := 0.0
var local_notice := ""
var local_notice_time := 0.0
var attack_seen: Array[int] = [0,0,0,0]
var foot_distance: Array[float] = [0,0,0,0]
var heard_point := Vector3.ZERO
var heard_time := 0.0
var event_history: Array[Dictionary] = []
var effects
const Controls5 = preload("res://scripts/quality/controls.gd")
const Practice5 = preload("res://scripts/quality/practice.gd")
const Workshop5 = preload("res://scripts/quality/workshop.gd")
var controls = Controls5.new()
var practice = Practice5.new()
var workshop = Workshop5.new()
var practice_mode := false
var practice_respawn := 0.0
var settings_dirty := false
var settings_delay := 0.0
var settings_from_menu := false
var practice_old_map := "toy_home"
var practice_old_mode := "field"

func _ready() -> void:
	rules = Rules4.new()
	preferences = Prefs4.new()
	var args := OS.get_cmdline_user_args()
	automated = "--phase4-smoke" in args or "--capture-phase4" in args
	autoplay = "--phase4-autoplay" in args
	synthetic_run = automated or autoplay or "--phase4-test" in args or "--quality-test" in args
	if not synthetic_run:
		preferences.load_local()
		controls.load_local()
	rules.mode = preferences.mode
	rng.seed = 8027
	map_id = preferences.map_id
	for arg in args:
		if arg.begins_with("--map="): map_id = str(Catalog3.spec(arg.trim_prefix("--map=")).id)
		if arg.begins_with("--mode=") and arg.trim_prefix("--mode=") in Rules4.MODES: rules.mode = arg.trim_prefix("--mode=")
		if arg == "--full-map": preferences.compact = false
	if not synthetic_run: rng.randomize()
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_min_size(Vector2i(1120,680))
	_setup_world()
	arena = Arena4.new()
	arena.map_id = map_id
	arena.compact = preferences.compact
	add_child(arena)
	rules.configure(arena.config)
	if preferences.compact and map_id != "toy_home": rules.seeking_seconds = minf(rules.seeking_seconds,115)
	for i in range(4):
		var actor = Fighter4.new()
		actor.player_id = i
		actor.tint = COLORS[i]
		actor.position = arena.spawn_points[i]
		actor.use_view_aim = i == 0 and not autoplay
		add_child(actor)
		var data = Data4.new()
		data.set_preset(["fish","hammer","pan","fish"][i])
		data.color_index = i
		data.handling = Attack4.IDS[i%3]
		actor.equip(data)
		actor.show_weapon(false)
		fighters.append(actor)
		routes.append(PackedVector2Array())
		before_duel.append(actor.position)
	draft = fighters[0].weapon_data.clone()
	audio = Sound4.new()
	add_child(audio)
	audio.volume = 0 if DisplayServer.get_name() == "headless" else preferences.volume
	effects = preload("res://scripts/phase4/effects.gd").new()
	add_child(effects)
	ui = Interface4.new()
	ui.game = self
	add_child(ui)
	rules.changed.connect(_phase_changed)
	rules.duel_resolved.connect(_duel_resolved)
	metrics.enabled = preferences.recording
	ui.show_menu()
	if automated: call_deferred("_automation4")
	elif autoplay: call_deferred("start_match",true)

func _setup_world() -> void:
	environment_node = WorldEnvironment.new()
	environment_node.environment = make_environment()
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46,-28,0)
	sun.light_color = Color("ffe4bd")
	sun.light_energy = 0.43
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 90
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-28,150,0)
	fill.light_color = Color("c0dce0")
	fill.light_energy = 0.13
	add_child(fill)
	rig = Rig4.new()
	add_child(rig)
	camera = rig.view
	camera.fov = preferences.vertical_fov
	rig.sensitivity = preferences.mouse_sensitivity
	rig.invert_y = preferences.invert_y

func make_environment() -> Environment:
	var e := super.make_environment()
	e.background_color = Color("b7ced2")
	e.ambient_light_color = Color("dbdccc")
	e.ambient_light_energy = 0.22
	return e

func select_map(id: String) -> void:
	if rules.phase != Rules.Phase.MENU or id not in Catalog3.IDS: return
	map_id = id
	preferences.map_id = id
	_save_preferences()
	remove_child(arena)
	arena.queue_free()
	arena = Arena4.new()
	arena.map_id = id
	arena.compact = preferences.compact
	add_child(arena)
	rules.configure(arena.config)
	if preferences.compact and id != "toy_home": rules.seeking_seconds = minf(rules.seeking_seconds,115)
	for i in range(fighters.size()):
		fighters[i].original_spawn = arena.spawn_points[i]
		fighters[i].reset_fight(arena.spawn_points[i])
		fighters[i].show_weapon(false)
	rig.face(Vector3.FORWARD)

func set_mode(value: String) -> void:
	if rules.phase == Rules.Phase.MENU and value in Rules4.MODES:
		rules.mode = value
		preferences.mode = value
		_save_preferences()

func set_compact(value: bool) -> void:
	if rules.phase != Rules.Phase.MENU: return
	preferences.compact = value
	select_map(map_id)

func _prepare_round() -> void:
	_clear_feedback()
	freeze = 0
	shake = 0
	clue_spot = -1
	clue_time = 0
	heard_time = 0
	inspect_cooldown = 0
	taunt_cooldown = 0
	focus_spot = -1
	var available: Array[int] = arena.active_spots.duplicate()
	_shuffle(available)
	search_route = _search_tour(arena.spawn_points[rules.seeker])
	search_cursor = 0
	for i in range(4):
		fighters[i].reset_fight(arena.spawn_points[i])
		fighters[i].show_weapon(false)
		hide_assignments[i] = available.pop_back() if i != rules.seeker else -1
		routes[i] = PackedVector2Array()
		repath[i] = 0
		foot_distance[i] = 0
	draft = fighters[0].weapon_data.clone()
	if not practice_mode:
		var planned = workshop.take()
		if planned != null:
			draft = planned
			fighters[0].equip(draft)
	rig.face(Vector3.FORWARD)

func _search_tour(start: Vector3) -> Array[int]:
	var result: Array[int] = []
	var remaining: Array[int] = arena.active_spots.duplicate()
	var at := start
	while not remaining.is_empty():
		var nearest: int = remaining[0]
		for i in remaining:
			if at.distance_squared_to(arena.spots[i]) < at.distance_squared_to(arena.spots[nearest]): nearest = i
		result.append(nearest)
		remaining.erase(nearest)
		at = arena.spots[nearest]
	return result

func _free_spot(id: int) -> int:
	var candidates: Array[int] = []
	for i in arena.active_spots:
		if not _occupied(i,id): candidates.append(i)
	_shuffle(candidates)
	return -1 if candidates.is_empty() else candidates[0]

func _phase_changed() -> void:
	var phase: int = rules.phase
	var before := last_phase
	if workshop.opened and phase in [Rules.Phase.RESULT,Rules.Phase.COMPLETE,Rules.Phase.DRAW]:
		stash_workshop()
		workshop.opened = false
	if before == Rules.Phase.DRAW and phase != before: _commit_draft()
	last_phase = phase
	metrics.record("phase",{"value":phase,"round":rules.round_index,"mode":rules.mode,"map":map_id})
	match phase:
		Rules.Phase.DRAW:
			_prepare_round()
			ui.show_drawing(draft)
			if autoplay: call_deferred("accept_drawing")
		Rules.Phase.HIDE:
			for a in fighters: a.show_weapon(false)
			fighters[rules.seeker].visible = false
			if rules.seeker == 0: ui.show_wait()
			else: ui.hide_modal(); ui.notify("HIDE! CHOOSE YOUR ESCAPE ROUTE",1)
			audio.play("ready")
		Rules.Phase.SEEK:
			if not workshop.opened: ui.hide_modal()
			fighters[rules.seeker].visible = true
			for a in fighters: a.show_weapon(false)
			if before == Rules.Phase.HIDE: ui.notify("READY OR NOT!",1)
		Rules.Phase.REVEAL:
			_begin_duel()
			if not workshop.opened: ui.hide_modal()
			if 0 in [rules.seeker,rules.opponent]: ui.notify("FOUND! SMASH YOUR WAY OUT",0.65)
			audio.play_at("found",fighters[rules.opponent].position+Vector3.UP)
		Rules.Phase.DUEL:
			if 0 in [rules.seeker,rules.opponent]: ui.notify("SMASH!",0.4)
		Rules.Phase.RESULT:
			qa_stats.rounds += 1
			ui.show_result(rules,false)
			if autoplay: call_deferred("next_round")
		Rules.Phase.COMPLETE:
			ui.show_result(rules,true)
			if metrics.enabled: metrics.export_local()
			if autoplay:
				qa_stats["map"] = map_id
				qa_stats["mode"] = rules.mode
				print("PHASE4_AUTOPLAY_RESULT: "+JSON.stringify(qa_stats))
				get_tree().quit(0 if qa_stats.rounds == 4 and qa_stats.duels > 0 and qa_stats.hits > 0 else 1)
	_sync_mouse()

func _physics_process(delta: float) -> void:
	if automated or paused: return
	if practice_mode:
		if rules.phase != Rules.Phase.DRAW: _physics_practice(delta)
		return
	clock += delta
	metrics.time += delta
	# Presentation freeze is never used by simulation, with either accessibility setting.
	freeze = 0
	rules.tick(delta)
	for key in ["inspect_cooldown","taunt_cooldown","clue_time","heard_time"]: set(key,maxf(0,get(key)-delta))
	if rules.phase not in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.REVEAL,Rules.Phase.DUEL]: return
	var simulation_phase: int = rules.phase
	for i in range(4):
		if rules.phase != simulation_phase: break
		if not rules.alive[i]: continue
		if rules.phase == Rules.Phase.HIDE and i == rules.seeker: continue
		var pair: bool = i in [rules.seeker,rules.opponent]
		if rules.phase == Rules.Phase.REVEAL and (pair or rules.mode == "classic"): continue
		if rules.phase == Rules.Phase.DUEL and not pair and rules.mode == "classic": continue
		var wish := _move_input() if i == 0 and not autoplay else _bot_move(i,delta)
		if rules.phase != simulation_phase: break
		var aim := _aim_input() if i == 0 and not autoplay else _bot_aim(i,wish)
		fighters[i].step(delta,wish,aim)
		if not arena.inside(fighters[i].position) or fighters[i].position.y < -1:
			fighters[i].reset_fight(arena.spawn_points[i])
		_update_actor_events(i)
	if rules.phase == Rules.Phase.DUEL: _duel_contacts()
	elif rules.phase == Rules.Phase.SEEK:
		scan_elapsed += delta
		if scan_elapsed >= 0.15:
			scan_elapsed = 0
			_scan_visible_hiders()

func _process(delta: float) -> void:
	if settings_dirty:
		settings_delay -= delta
		if settings_delay <= 0: _flush_preferences()
	if autoplay and DisplayServer.get_name() == "headless": return
	if not is_instance_valid(ui): return
	var dt := 0.0 if paused else delta
	effects.enabled = not preferences.reduced_motion
	effects.advance(dt)
	var id := view_target()
	if current_subject != id:
		for a in fighters: a.set_view_subject(false)
		current_subject = id
	fighters[id].set_view_subject(true)
	rig.reduced_motion = preferences.reduced_motion
	rig.hand_sway = preferences.hand_sway
	rig.head_bob = preferences.head_bob
	rig.feedback_strength = preferences.feedback_strength
	var show_hands: bool = world_view_active() and not fighters[id].hidden_in_box
	rig.follow(fighters[id],dt,id != 0 or autoplay,show_hands)
	focus_spot = _focused_spot() if world_view_active() and not paused and not is_spectating() and not practice_mode else -1
	arena.mark_target(focus_spot)
	hit_feedback = maxf(0,hit_feedback-dt)
	hurt_feedback = maxf(0,hurt_feedback-dt)
	block_feedback = maxf(0,block_feedback-dt)
	local_notice_time = maxf(0,local_notice_time-dt)
	ui.refresh(rules)
	_sync_mouse()

func view_target() -> int:
	if not rules.alive[0]: return rules.seeker
	if rules.mode == "classic": return super.view_target()
	return 0

func _move_input() -> Vector3:
	var direction: Vector3 = rig.move_vector(controls.vector())
	return direction*0.42 if controls.held("quiet") else direction

func _bot_move(id: int, delta: float) -> Vector3:
	var actor = fighters[id]
	if actor.hidden_in_box: return Vector3.ZERO
	if rules.phase == Rules.Phase.DUEL and id in [rules.seeker,rules.opponent]:
		var other: int = rules.opponent if id == rules.seeker else rules.seeker
		var d: Vector3 = fighters[other].position-actor.position
		d.y = 0
		var length := d.length()
		if length < maxf(1.05,actor.weapon_data.reach()*0.88): actor.begin_swing()
		if fighters[other].attack_active() and rng.randf() < 0.015: actor.begin_dash(-d)
		if length < 0.76: return -d.normalized()*0.6
		if length < 1.18: return Vector3.ZERO
		return _navigate(id,fighters[other].position,delta)*0.9
	if id != rules.seeker: return _hide_bot(id,delta)
	if heard_time > 0 and actor.position.distance_to(heard_point) > 1:
		return _navigate(id,heard_point,delta)
	if search_route.is_empty(): return Vector3.ZERO
	var spot_id: int = search_route[search_cursor%search_route.size()]
	if clue_time > 0 and clue_spot in arena.active_spots: spot_id = clue_spot
	if actor.position.distance_to(arena.spots[spot_id]) < 1:
		if inspect_cooldown <= 0:
			inspect_cooldown = 0.55
			_inspect(id,spot_id)
			search_cursor = (search_cursor+1)%search_route.size()
			clue_spot = -1
		return Vector3.ZERO
	return _navigate(id,arena.spots[spot_id],delta)

func _hide_bot(id: int, delta: float) -> Vector3:
	var target: int = hide_assignments[id]
	if target not in arena.active_spots or _occupied(target,id):
		target = _free_spot(id)
		hide_assignments[id] = target
	if target < 0: return Vector3.ZERO
	if fighters[id].position.distance_to(arena.spots[target]) < 0.6:
		fighters[id].position = arena.spots[target]
		fighters[id].old_position = fighters[id].position
		fighters[id].set_hidden(true,target)
		return Vector3.ZERO
	return _navigate(id,arena.spots[target],delta)

func _navigate(id: int, destination: Vector3, delta: float) -> Vector3:
	repath[id] -= delta
	if repath[id] <= 0 or routes[id].is_empty():
		routes[id] = arena.path_to(fighters[id].position,destination)
		repath[id] = 0.3
	while not routes[id].is_empty():
		var d: Vector3 = Vector3(routes[id][0].x,0,routes[id][0].y)-fighters[id].position
		d.y = 0
		if d.length() < 0.22: routes[id].remove_at(0)
		else: return d.normalized()*0.85
	var d: Vector3 = destination-fighters[id].position
	d.y = 0
	return d.limit_length()*0.7

func _bot_aim(id: int, wish: Vector3) -> Vector3:
	if rules.phase == Rules.Phase.DUEL and id in [rules.seeker,rules.opponent]:
		var other: int = rules.opponent if id == rules.seeker else rules.seeker
		return fighters[other].position-fighters[id].position
	return wish

func _begin_duel() -> void:
	qa_stats.duels += 1
	for i in range(4): before_duel[i] = fighters[i].position
	pre_duel_angles = Vector2(rig.yaw,rig.pitch)
	for id in [rules.seeker,rules.opponent]:
		var at: Vector3 = before_duel[id]
		if rules.mode == "classic": at = Vector3(-1.65 if id == rules.seeker else 1.65,0,0)
		fighters[id].reset_fight(at)
		fighters[id].show_weapon(true)
		metrics.record("discovered",{"actor":id,"round":rules.round_index})
	if rules.mode == "classic" and 0 in [rules.seeker,rules.opponent]:
		var other: int = rules.opponent if rules.seeker == 0 else rules.seeker
		rig.face(fighters[other].position-fighters[0].position)

func _duel_contacts() -> void:
	var attackers: Array[int] = []
	for id in [rules.seeker,rules.opponent]:
		var other: int = rules.opponent if id == rules.seeker else rules.seeker
		var e := Contact4.contact(fighters[id],fighters[other],get_world_3d().direct_space_state)
		if e.is_empty(): e = Contact4.wall_contact(fighters[id],get_world_3d().direct_space_state)
		if e.is_empty(): continue
		_consume_event(e)
		if e.outcome == "hit":
			attackers.append(id)
			qa_stats.hits += 1
			var direction: Vector3 = fighters[other].position-fighters[id].position
			direction.y = 0
			fighters[other].take_hit(direction)
			fighters[other].knock_velocity = direction.normalized()*Attack4.spec(fighters[id].handling).knock
	if not attackers.is_empty(): rules.register_hits(attackers)

func _consume_event(e: Dictionary) -> void:
	if event_history.size() >= 128: event_history.pop_front()
	event_history.append(e.duplicate())
	if practice_mode and e.outcome == "miss" and e.attacker_id == 0: practice.record_hit("miss")
	var feedback := Contact4.viewer_feedback(e,0)
	match feedback:
		"hit": hit_feedback = 0.16
		"hurt":
			hurt_feedback = 0.3
			var toward: Vector3 = fighters[e.attacker_id].position-fighters[0].position
			hurt_angle = Vector2(camera.global_basis.x.dot(toward),camera.global_basis.z.dot(toward)).angle()
		"blocked": block_feedback = 0.18
	if feedback in ["hit","hurt","blocked"]: rig.feedback(feedback)
	if e.outcome in ["hit","blocked"]:
		audio.play_at(e.outcome,e.world_point)
		if not preferences.reduced_motion: effects.burst(e.world_point,e.outcome == "blocked")
	metrics.record("contact",{"actor":e.attacker_id,"target":e.target_id,"outcome":e.outcome})

func _duel_resolved(hider: int, captured: bool) -> void:
	qa_stats["captures" if captured else "escapes"] += 1
	for id in [rules.seeker,hider]:
		var at: Vector3 = before_duel[id] if rules.mode == "classic" else fighters[id].position
		fighters[id].reset_fight(at)
		fighters[id].show_weapon(false)
		routes[id] = PackedVector2Array()
	if captured:
		fighters[hider].visible = false
		fighters[hider].collision_layer = 0
	else:
		hide_assignments[hider] = _free_spot(hider)
	if rules.mode == "classic":
		rig.yaw = pre_duel_angles.x
		rig.pitch = pre_duel_angles.y
	if 0 in [rules.seeker,hider]: ui.notify("CAUGHT!" if captured else "ESCAPED! FIND NEW COVER",0.9)
	audio.play_at("escape",fighters[hider].position)
	metrics.record("duel_end",{"actor":hider,"outcome":"captured" if captured else "escaped"})

func _update_actor_events(id: int) -> void:
	var a = fighters[id]
	if a.attack_sequence != attack_seen[id]:
		attack_seen[id] = a.attack_sequence
		audio.play_at("swing",a.position+Vector3.UP,0.8)
		metrics.record("swing",{"actor":id})
	if a.swing_finished and a.outcome == "pending":
		a.outcome = "miss"
		_consume_event(Contact4.event(a,null,a.weapon_pivot.global_position,Vector3.ZERO,"miss","air"))
	if a.hidden_in_box or not a.visible or not a.is_on_floor(): return
	var moved: float = a.position.distance_to(a.old_position)
	if moved > 0.5: return # No footstep clue from teleports/spawn correction.
	foot_distance[id] += moved
	if foot_distance[id] >= 1.55:
		foot_distance[id] = 0
		var quiet: bool = id == 0 and controls.held("quiet") and not autoplay
		audio.play_at("step",a.position,0.3 if quiet else 0.7)
		# A seeker can pursue a noise that actually occurred, not a hidden model's position.
		if id != rules.seeker and fighters[rules.seeker].position.distance_to(a.position) < (3 if quiet else 8):
			heard_point = Vector3(snappedf(a.position.x,2),0,snappedf(a.position.z,2))
			heard_time = 1.6
			if rules.seeker == 0 and preferences.sound_cues:
				local_notice = "FOOTSTEPS NEARBY"
				local_notice_time = 0.65

func _can_hide_now() -> bool:
	return rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK] or (rules.mode == "field" and rules.phase in [Rules.Phase.REVEAL,Rules.Phase.DUEL] and 0 not in [rules.seeker,rules.opponent])

func _focused_spot() -> int:
	if not _can_hide_now() or not rules.alive[0] or fighters[0].hidden_in_box: return -1
	var eye: Vector3 = fighters[0].position+Vector3.UP*Rig4.EYE_HEIGHT
	var centers: Array[Vector2] = Catalog3.prop_centers(map_id)
	var result := -1
	var best := 0.42
	for i in arena.active_spots:
		var at: Vector3 = arena.spots[i]
		if fighters[0].position.distance_to(at) > 2: continue
		var toward := Vector3(centers[i].x,0,centers[i].y)-at
		var point: Vector3 = at+toward.normalized()*0.4+Vector3.UP
		var dot: float = (-camera.global_basis.z).dot((point-eye).normalized())
		if dot > best and arena.clear_ray(eye,point):
			best = dot
			result = i
	return result

func _interact() -> void:
	if paused or is_spectating() or not rules.alive[0] or not _can_hide_now(): return
	if fighters[0].hidden_in_box and rules.seeker != 0:
		fighters[0].set_hidden(false)
		audio.play_at("hide",fighters[0].position)
		return
	var near := _focused_spot()
	if near < 0: return
	if rules.seeker == 0:
		if rules.phase == Rules.Phase.SEEK and inspect_cooldown <= 0:
			inspect_cooldown = 0.45
			_inspect(0,near)
	elif not _occupied(near,0):
		fighters[0].position = arena.spots[near]
		fighters[0].old_position = fighters[0].position
		fighters[0].set_hidden(true,near)
		audio.play_at("hide",fighters[0].position)

func _input(e: InputEvent) -> void:
	if not is_instance_valid(ui): return
	if ui.capture_binding(e):
		get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseMotion and wants_capture() and not is_spectating():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or synthetic_run:
			rig.look(e.screen_relative)
			get_viewport().set_input_as_handled()
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_ESCAPE:
				if ui.key_page: ui.show_pause()
				elif workshop.opened and not paused: close_workshop()
				elif rules.phase == Rules.Phase.MENU and not paused: open_settings()
				else: toggle_pause()
				get_viewport().set_input_as_handled()
				return
			KEY_F11:
				if DisplayServer.get_name() != "headless":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
				return
			KEY_F12:
				if DisplayServer.get_name() != "headless": _save_screenshot()
				return
			KEY_ENTER:
				if rules.phase == Rules.Phase.RESULT: next_round()
	if controls.pressed(e,"workshop") and not paused:
		if practice_mode and not ui.modal.visible: open_practice_drawing()
		elif workshop.opened: close_workshop()
		elif workshop.allowed(rules.alive[0],rules.round_index,rules.phase): open_workshop()
		else: return
		get_viewport().set_input_as_handled()
	elif controls.pressed(e,"map") and world_view_active() and not workshop.opened:
		toggle_pause()
		if paused: ui.show_map()
		get_viewport().set_input_as_handled()

func _unhandled_input(e: InputEvent) -> void:
	if paused or not rules.alive[0] or ui.modal.visible: return
	if controls.pressed(e,"attack"):
		if practice_mode or (rules.phase == Rules.Phase.DUEL and 0 in [rules.seeker,rules.opponent]): fighters[0].begin_swing()
	elif controls.pressed(e,"interact") and not practice_mode: _interact()
	elif controls.pressed(e,"taunt") and not practice_mode: _taunt()
	elif controls.pressed(e,"dash"):
		if rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.DUEL] and not is_spectating() and not (rules.phase == Rules.Phase.HIDE and rules.seeker == 0):
			fighters[0].begin_dash(_move_input())
			if practice_mode and fighters[0].dash_time > 0: practice.dodged = true

func toggle_pause() -> void:
	if settings_from_menu:
		settings_from_menu = false
		paused = false
		_flush_preferences()
		ui.show_menu()
		return
	if rules.phase in [Rules.Phase.MENU,Rules.Phase.RESULT,Rules.Phase.COMPLETE]: return
	if not paused:
		if workshop.opened: stash_workshop()
		elif rules.phase == Rules.Phase.DRAW: _commit_draft()
	paused = not paused
	controls.release_all()
	for v in audio.voices: v.stream_paused = paused
	if paused: ui.show_pause()
	else:
		_flush_preferences()
		if workshop.opened: ui.show_drawing(workshop.queued if workshop.queued != null else draft)
		elif rules.phase == Rules.Phase.DRAW: ui.show_drawing(draft)
		elif rules.phase == Rules.Phase.HIDE and rules.seeker == 0: ui.show_wait()
		else: ui.hide_modal()
	_sync_mouse()

func open_settings() -> void:
	if rules.phase == Rules.Phase.MENU:
		settings_from_menu = true
		paused = true
		ui.show_pause()
	else: toggle_pause()

func _save_preferences() -> void:
	if synthetic_run: return
	settings_dirty = true
	settings_delay = 0.35

func _flush_preferences() -> void:
	if not settings_dirty or synthetic_run: return
	settings_dirty = false
	var error: Error = preferences.save_local()
	if error != OK and is_instance_valid(ui): ui.notify(ui.s("save_error")+error_string(error),3)

func set_language(value: String) -> void:
	if value not in ["en","ko"]: return
	preferences.language = value
	_save_preferences()
	if paused: ui.show_pause()
	elif rules.phase == Rules.Phase.MENU: ui.show_menu()

func set_sound_cues(value: bool) -> void:
	preferences.sound_cues = value
	_save_preferences()

func save_controls() -> void:
	if not synthetic_run:
		var error: Error = controls.save_local()
		if error != OK: ui.notify(ui.s("save_error")+error_string(error),3)


func set_sensitivity(value: float) -> void:
	if not is_finite(value): return
	preferences.mouse_sensitivity = clampf(value,0.0005,0.008)
	rig.sensitivity = preferences.mouse_sensitivity
	_save_preferences()

func set_fov(value: float) -> void:
	if not is_finite(value): return
	preferences.vertical_fov = clampf(value,55,90)
	camera.fov = preferences.vertical_fov
	_save_preferences()

func set_invert_y(value: bool) -> void:
	preferences.invert_y = value
	rig.invert_y = value
	_save_preferences()

func set_reduced_motion(value: bool) -> void:
	preferences.reduced_motion = value
	_save_preferences()

func set_volume(value: float) -> void:
	if not is_finite(value): return
	preferences.volume = clampf(value,0,1)
	audio.volume = 0 if DisplayServer.get_name() == "headless" else preferences.volume
	_save_preferences()

func set_comfort(value: float, key: String) -> void:
	if key in ["hand_sway","head_bob","feedback_strength"] and is_finite(value):
		preferences.set(key,clampf(value,0,1))
		_save_preferences()

func set_recording(value: bool) -> void:
	preferences.recording = value
	metrics.enabled = value
	_save_preferences()

func _automation4() -> void:
	await get_tree().process_frame
	var capture := "--capture-phase4" in OS.get_cmdline_user_args()
	if capture: await _capture("phase4_00_menu")
	start_match(true)
	if capture: await _capture("phase4_01_draw")
	accept_drawing()
	for i in range(1,4):
		fighters[i].reset_fight(arena.spots[hide_assignments[i]])
		fighters[i].set_hidden(true,hide_assignments[i])
	rules.tick(rules.hiding_seconds+0.01)
	fighters[0].reset_fight(Vector3(0,0,3))
	rig.face(Vector3(0,0,-1))
	await get_tree().physics_frame
	if capture: await _capture("phase4_02_lounge")
	fighters[1].reset_fight(Vector3(-0.6,0,0.3))
	fighters[1].visual.rotation.y = 0
	rules.discover(1)
	if capture: await _capture("phase4_03_reveal")
	rules.tick(rules.reveal_seconds()+0.01)
	fighters[0].begin_swing()
	for i in range(8):
		fighters[0].step(1.0/60,Vector3.ZERO,rig.forward())
		await get_tree().physics_frame
	if capture: await _capture("phase4_04_swing")
	rules.tick(rules.duel_seconds()+0.01)
	if rules.phase != Rules.Phase.SEEK:
		printerr("FAIL: Phase 4 escape did not restore search")
		get_tree().quit(1)
		return
	toggle_pause()
	if capture: await _capture("phase4_05_settings")
	print("PHASE4_SMOKE_READY: drawing, field encounter, escape and pause initialized")
	get_tree().quit(0)

func _taunt() -> void:
	if rules.phase != Rules.Phase.SEEK or rules.seeker == 0 or not rules.alive[0] or taunt_cooldown > 0: return
	taunt_cooldown = 6
	clue_spot = fighters[0].spot if fighters[0].hidden_in_box else arena.nearest_spot(fighters[0].position,100)
	clue_time = 3
	audio.play_at("taunt",fighters[0].position+Vector3.UP,1.0)
	ui.notify("OVER HERE! Your area is now a clue",0.9)
	metrics.record("taunt",{"actor":0})

func _capture(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts")
	var error := image.save_png("res://ci-artifacts/"+name+".png")
	if error != OK:
		printerr("FAIL: capture "+name+" "+error_string(error))
		get_tree().quit(1)
	else: print("PHASE4_CAPTURE: "+name)

# Phase 5 lifecycle: practice and the next-round sketch are not authority match modes.
func start_match(seek_first: bool = true) -> void:
	practice_mode = false
	settings_from_menu = false
	controls.release_all()
	super.start_match(seek_first)

func _commit_draft() -> void:
	if workshop.opened:
		stash_workshop()
		return
	super._commit_draft()

func accept_drawing() -> void:
	if workshop.opened:
		stash_workshop()
		ui.ink.text = ui.s("queued")
		return
	if practice_mode:
		if rules.phase != Rules.Phase.DRAW or not is_instance_valid(ui.canvas) or not ui.canvas.data.is_valid(): return
		_commit_draft()
		practice.equipped = true
		rules.phase = Rules.Phase.DUEL
		last_phase = rules.phase
		rules.opponent = 1
		rules.seeker = 0
		for i in range(4):
			fighters[i].reset_fight(Vector3(0,0,2.8) if i == 0 else Vector3(0,0,0.2))
			fighters[i].visible = i < 2
			fighters[i].collision_layer = 2 if i < 2 else 0
			fighters[i].show_weapon(i == 0)
			rules.hp[i] = 3
		rig.face(Vector3.FORWARD)
		practice_respawn = 0
		fighters[1].visual.rotation.y = PI
		_clear_feedback()
		ui.hide_modal()
		_sync_mouse()
		return
	super.accept_drawing()

func start_practice() -> void:
	if rules.phase != Rules.Phase.MENU: return
	practice_old_map = map_id
	practice_old_mode = rules.mode
	select_map("toy_home")
	preferences.map_id = practice_old_map
	practice_mode = true
	practice = Practice5.new()
	workshop = Workshop5.new()
	paused = false
	rules.start(true)

func open_practice_drawing() -> void:
	if not practice_mode or paused or rules.phase == Rules.Phase.DRAW: return
	draft = fighters[0].weapon_data.clone()
	fighters[0].cancel_attack()
	rules.phase = Rules.Phase.DRAW
	last_phase = rules.phase
	ui.show_drawing(draft)
	controls.release_all()
	_sync_mouse()

func _physics_practice(delta: float) -> void:
	clock += delta
	fighters[0].step(delta,_move_input(),_aim_input())
	practice.record_move(fighters[0].position.distance_to(fighters[0].old_position))
	_update_actor_events(0)
	if not arena.inside(fighters[0].position): fighters[0].reset_fight(Vector3(0,0,2.8))
	if practice_respawn > 0:
		practice_respawn -= delta
		if practice_respawn <= 0:
			fighters[1].reset_fight(Vector3(0,0,0.2))
			fighters[1].show_weapon(false)
			rules.hp[1] = 3
		return
	fighters[1].step(delta,Vector3.ZERO,fighters[0].position-fighters[1].position)
	var e := Contact4.contact(fighters[0],fighters[1],get_world_3d().direct_space_state)
	if e.is_empty(): e = Contact4.wall_contact(fighters[0],get_world_3d().direct_space_state)
	if not e.is_empty():
		_consume_event(e)
		practice.record_hit(e.outcome)
		if e.outcome == "hit":
			fighters[1].take_hit(fighters[1].position-fighters[0].position)
			rules.hp[1] -= 1
			if rules.hp[1] <= 0:
				practice_respawn = 0.65
				fighters[1].visible = false
				fighters[1].collision_layer = 0

func open_workshop() -> void:
	if practice_mode or paused or not workshop.allowed(rules.alive[0],rules.round_index,rules.phase): return
	workshop.opened = true
	var sketch = workshop.queued if workshop.queued != null else fighters[0].weapon_data
	ui.show_drawing(sketch)
	controls.release_all()
	_sync_mouse()

func stash_workshop() -> bool:
	if not workshop.opened or not is_instance_valid(ui.canvas): return false
	ui.canvas.finish_stroke()
	return workshop.keep(ui.canvas.data)

func close_workshop() -> void:
	stash_workshop()
	workshop.opened = false
	ui.hide_modal()
	_sync_mouse()

func return_to_menu() -> void:
	_clear_feedback()
	var restore := practice_mode
	practice_mode = false
	settings_from_menu = false
	workshop = Workshop5.new()
	controls.release_all()
	_flush_preferences()
	super.return_to_menu()
	if restore:
		select_map(practice_old_map)
		set_mode(practice_old_mode)
		ui.show_menu()

func _exit_tree() -> void:
	_flush_preferences()
	controls.release_all()
	super._exit_tree()

func _clear_feedback() -> void:
	hit_feedback = 0
	hurt_feedback = 0
	block_feedback = 0
	local_notice = ""
	local_notice_time = 0
	if is_instance_valid(rig): rig.kick = 0
	if is_instance_valid(ui):
		ui.message_seconds = 0
		ui.toast.text = ""
	if is_instance_valid(effects): effects.reset()
	if is_instance_valid(audio):
		for voice in audio.voices: voice.stop()
