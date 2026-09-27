extends SceneTree
const Game = preload("res://scripts/phase4/game.gd")
const Rules = preload("res://scripts/phase4/match_rules.gd")
const Data = preload("res://scripts/phase4/drawing_data.gd")
const Attack = preload("res://scripts/phase4/attack_spec.gd")
const Contact = preload("res://scripts/phase4/combat.gd")
const Form = preload("res://scripts/phase4/weapon_form.gd")
const Art = preload("res://scripts/phase4/art.gd")
const Metrics = preload("res://scripts/phase4/telemetry.gd")
var checks := 0
var failures := 0
var game

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	_rules()
	_data()
	game = Game.new()
	root.add_child(game)
	game.automated = true
	game.set_physics_process(false)
	game.set_process(false)
	await physics_frame
	await process_frame
	var a = game.fighters[0]
	for hz in [30,60,120]:
		a.reset_fight(Vector3.ZERO)
		a.use_view_aim = true
		a.view_pitch = 0.6
		var stable := true
		for i in range(hz*2):
			a.step(1.0/hz,Vector3.ZERO,Vector3.FORWARD)
			stable = stable and is_equal_approx(a.weapon_pivot.rotation.x,-0.82)
		check(stable,"P0 aim absolute and stable at %d Hz step" % hz)
	a.use_view_aim = false
	a.view_pitch = 0
	for style in Attack.IDS:
		a.handling = style
		a.reset_fight(Vector3.ZERO)
		var seq: int = a.attack_sequence
		check(a.begin_swing(),style+" accepts idle attack")
		a.elapsed = Attack.duration(style)-0.06
		a.cooldown = 0.06
		check(not a.begin_swing() and a.buffered > 0,style+" buffers recovery input")
		for i in range(4): a.step(1.0/60,Vector3.ZERO,Vector3.FORWARD)
		check(a.attack_sequence == seq+2,style+" buffered press starts exactly once")
		a.reset_fight(Vector3.ZERO)
		a.begin_swing()
		a.begin_swing()
		seq = a.attack_sequence
		for i in range(80): a.step(1.0/60,Vector3.ZERO,Vector3.FORWARD)
		check(a.attack_sequence == seq,style+" stale early buffer expires")
	a.handling = "balanced"
	a.reset_fight(Vector3.ZERO)
	game.hit_feedback = 0
	game.hurt_feedback = 0
	game._consume_event(Contact.event(game.fighters[1],a,Vector3.ZERO,Vector3.FORWARD,"hit"))
	check(game.hit_feedback == 0 and game.hurt_feedback > 0,"P0 opponent hit only lights incoming damage")
	game.hit_feedback = 0
	game.hurt_feedback = 0
	game._consume_event(Contact.event(game.fighters[1],game.fighters[2],Vector3.ZERO,Vector3.UP,"hit"))
	check(game.hit_feedback == 0 and game.hurt_feedback == 0,"bot trade does not impersonate player hit")
	game._consume_event(Contact.event(a,game.fighters[1],Vector3.ZERO,Vector3.UP,"hit"))
	check(game.hit_feedback > 0,"player hit confirms outgoing impact")
	game.hit_feedback = 0
	game._consume_event(Contact.event(a,null,Vector3.ZERO,Vector3.UP,"blocked","wood"))
	check(game.block_feedback > 0 and game.hit_feedback == 0,"blocked impact is separate")
	var times: Array[float] = []
	for reduced in [false,true]:
		game.start_match(true)
		game.accept_drawing()
		game.rules.tick(game.rules.hiding_seconds+0.01)
		game.rules.discover(1)
		game.rules.tick(game.rules.reveal_seconds()+0.01)
		game.preferences.reduced_motion = reduced
		game._consume_event(Contact.event(game.fighters[1],a,Vector3.ZERO,Vector3.UP,"hit"))
		game.automated = false
		game._physics_process(1.0/60)
		game.automated = true
		times.append(game.rules.time_left)
	check(is_equal_approx(times[0],times[1]),"P0 reduced motion cannot change game clock")
	check(game.freeze == 0,"contact presentation never freezes authority")
	_camera_cache(a)
	await _navigation()
	await _field_flow()
	await _collision()
	_metrics()
	game.queue_free()
	await process_frame
	await process_frame
	print("PHASE4_UNIT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _rules() -> void:
	for mode in Rules.MODES:
		var r = Rules.new()
		r.mode = mode
		r.start()
		r.ready()
		r.tick(30)
		for n in range(3):
			check(r.discover(1),mode+" valid discovery")
			r.tick(r.reveal_seconds()+0.01)
			r.tick(r.duel_seconds()+0.01)
			r.tick(5.1)
		check(r.scores[1] == 1,mode+" escape score capped after repeated discoveries")
		r.tick(999)
		check(r.scores[1] == 4 and r.scores[2] == 5,mode+" never found beats escape farming")
		var score: Array = r.scores.duplicate()
		r._finish_round()
		check(score == r.scores,mode+" round finalization idempotent")
		r.start()
		r.ready()
		r.tick(30)
		var before: float = r.search_left
		r.discover(1)
		r.tick(0.1)
		check(is_equal_approx(r.search_left,before-0.1 if mode == "field" else before),mode+" search-clock contract")
		check(not r.discover(2),mode+" one encounter at a time")
		r.tick(r.reveal_seconds())
		r.hp[0] = 1
		r.hp[1] = 1
		r.register_hits([0,1])
		check(r.alive[1] and r.escapes[1] == 1,mode+" simultaneous KO escapes by defined rule")
		check(not r.discover(-1) and not r.discover(8),mode+" invalid actors rejected")

func _data() -> void:
	for style in Attack.IDS:
		var d = Data.new()
		d.set_preset("fish")
		d.handling = style
		var clone = d.clone()
		check(clone.handling == style and clone.strokes == d.strokes,style+" copy preserves style and original path")
		var loaded = Data.new()
		check(loaded.load_dictionary(d.to_dictionary()) and loaded.handling == style,style+" handling roundtrip")
		check(Attack.duration(style)>0.3 and not Attack.overlaps_active(style,0,0.02),style+" no windup hit")
		check(not loaded.load_dictionary({"handling":"infinite","strokes":[]}),"unknown handling rejected")
	var d = Data.new()
	d.strokes.assign([PackedVector2Array([Vector2(0.1,0.1),Vector2(0.9,0.1),Vector2(0.9,0.9),Vector2(0.1,0.9),Vector2(0.1,0.1)]),PackedVector2Array([Vector2(0.4,0.4),Vector2(0.6,0.4),Vector2(0.6,0.6),Vector2(0.4,0.6),Vector2(0.4,0.4)])])
	check(Form.contours(d).is_empty(),"nested loops remain hollow; no silently filled hole")
	d.strokes.pop_back()
	check(Form.contours(d).size() == 1,"simple large square may fill")
	check(0.64*d.world_scale()*d.world_scale() <= 2.6001,"filled area budget bounds free giant plane advantage")
	check(d.reach() <= 2.2,"area budget never overrides reach limit")
	var original := d.to_dictionary()
	var mesh := Form.build(d)
	check(d.to_dictionary() == original,"meshing never changes canonical drawing")
	check(Form.samples(d).size() <= 1400,"bounded solid hit sampling")
	mesh.free()
	var figure := Art.avatar(Color.WHITE)
	var arrays: Array = figure.get_child(0).mesh.surface_get_arrays(0)
	var dot := 0.0
	for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
		var v: Vector3 = arrays[Mesh.ARRAY_VERTEX][i]
		dot += Vector3(v.x,0,v.z).dot(arrays[Mesh.ARRAY_NORMAL][i])
	check(dot > 0,"authored body normals face outward")
	figure.free()

func _camera_cache(actor) -> void:
	actor.reset_fight(Vector3.ZERO)
	game.rig.follow(actor,0,false,true)
	var count: int = game.rig.rebuild_count
	for i in range(25): game.rig.follow(actor,1.0/60,false,true)
	check(game.rig.rebuild_count == count,"stable drawing does not serialize/rebuild each frame")
	actor.equip(actor.weapon_data)
	game.rig.follow(actor,0,false,true)
	check(game.rig.rebuild_count == count+1,"equip revision invalidates view once")
	var before: float = actor.weapon_data.reach()
	game.rig.view_weapon.scale *= 0.5
	check(is_equal_approx(actor.weapon_data.reach(),before),"cosmetic scale cannot change authority reach")
	actor.begin_swing()
	for n in range(15):
		actor.step(1.0/60,Vector3.ZERO,Vector3.FORWARD)
		game.rig.follow(actor,1.0/60,false,true)
		check(is_equal_approx(game.rig.display_progress,0.0 if actor.elapsed < 0 else Attack.progress(actor.handling,actor.elapsed)),"world/view consume same attack clock")

func _navigation() -> void:
	for compact in [true,false]:
		for map in ["toy_home","warehouse","garden"]:
			game.return_to_menu()
			game.preferences.compact = compact
			game.select_map(map)
			await physics_frame
			check(game.arena.active_spots.size() >= 4,map+" enough active hideouts")
			for id in game.arena.active_spots:
				var p: Vector3 = game.arena.spots[id]
				check(not game.arena.path_to(Vector3.ZERO,p).is_empty(),"reachable active hideout %s/%d" % [map,id])
				var query := PhysicsShapeQueryParameters3D.new()
				var capsule := CapsuleShape3D.new()
				capsule.radius = 0.36
				capsule.height = 1.45
				query.shape = capsule
				query.collision_mask = 1
				query.transform.origin = p+Vector3.UP*0.75
				check(game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"hideout capsule fits %s/%d" % [map,id])

func _field_flow() -> void:
	game.return_to_menu()
	game.preferences.compact = true
	game.select_map("toy_home")
	await physics_frame
	game.rules.mode = "field"
	game.start_match(false)
	game.accept_drawing()
	game.rules.tick(30)
	game.fighters[1].reset_fight(Vector3(-1,0,1))
	game.fighters[2].reset_fight(Vector3(1,0,1))
	var saved: Vector3 = game.fighters[1].position
	var look_before: float = game.rig.yaw
	game.rules.discover(2)
	check(game.fighters[1].position == saved,"field discovery does not teleport to centre")
	check(game.view_target() == 0,"uninvolved player retains own camera")
	check(is_equal_approx(game.rig.yaw,look_before),"field discovery never steals human look")
	game.fighters[0].set_hidden(true,game.arena.active_spots[0])
	game._interact()
	check(not game.fighters[0].hidden_in_box,"uninvolved hider can leave cover during encounter")
	game.rules.tick(0.56)
	var at: Vector3 = game.fighters[3].position
	game.automated = false
	game._physics_process(0.05)
	game.automated = true
	check(game.fighters[3].position.distance_to(at)>0.01,"uninvolved bot continues moving during encounter")
	var clock: float = game.rules.time_left
	game.toggle_pause()
	game._physics_process(0.1)
	check(is_equal_approx(game.rules.time_left,clock),"explicit pause still pauses match")
	game.toggle_pause()
	game.ui.show_map()
	check(game.ui.modal.visible,"map UI builds with public map data")
	game.ui.hide_modal()

func _collision() -> void:
	var a = game.fighters[0]
	var b = game.fighters[1]
	a.reset_fight(Vector3(0,0,1))
	b.reset_fight(Vector3(0,0,2.5))
	a.use_view_aim = false
	a.visual.rotation.y = 0
	b.old_center = b.position+Vector3.UP*0.75
	a.begin_swing()
	var hit := false
	var duplicate_rejected := false
	for n in range(30):
		a.step(1.0/60,Vector3.ZERO,Vector3.BACK)
		var e := Contact.contact(a,b,game.get_world_3d().direct_space_state)
		if not e.is_empty() and e.outcome == "hit":
			hit = true
			duplicate_rejected = Contact.contact(a,b,game.get_world_3d().direct_space_state).is_empty()
	check(hit,"actual swept drawn-weapon contact hits nearby capsule")
	check(duplicate_rejected,"same active swing cannot register target twice")
	a.reset_fight(Vector3.ZERO)
	b.reset_fight(Vector3(0,0,20))
	a.begin_swing()
	a.step(0.14,Vector3.ZERO,Vector3.BACK)
	check(Contact.contact(a,b,game.get_world_3d().direct_space_state).is_empty(),"out-of-range target is rejected")

func _metrics() -> void:
	var t = Metrics.new()
	t.record("hello")
	check(t.events.is_empty(),"local metrics opt-in by default")
	t.enabled = true
	for i in range(4200): t.record("sample",{"actor":0,"drawing":"private","ip":"private"})
	check(t.events.size() == Metrics.LIMIT and t.dropped > 0,"event memory bounded")
	check(not t.events[0].has("ip") and not t.events[0].has("drawing"),"event allowlist excludes drawings and addresses")
