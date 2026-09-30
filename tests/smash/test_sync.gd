extends SceneTree
const Scene = preload("res://scenes/phase9_followup.tscn")
const Attack = preload("res://scripts/phase4/attack_spec.gd")
var checks := 0
var failures := 0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ")+label)
func fresh(style: String) -> void:
	game.return_to_menu(); game.start_practice(); game.accept_drawing()
	game.fighters[0].reset_fight(Vector3(0,0,1))
	game.fighters[1].reset_fight(Vector3(0,0,2.3))
	game.fighters[0].handling = style
	game.rig.face(Vector3.BACK)
	game.preferences.reduced_motion = false
	game.preferences.feedback_strength = 1.0
	game._process(0)
func run() -> void:
	root.size = Vector2i(1280,720)
	var selected: PackedScene = load("res://scenes/phase10.tscn") if "--studio" in OS.get_cmdline_user_args() else Scene
	if "--hideplay" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase11.tscn")
	if "--premium" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase12.tscn")
	if "--character13" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase13.tscn")
	if "--material14" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase14.tscn")
	if "--lighting15" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase15.tscn")
	if "--animation16" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase16.tscn")
	if "--environment17" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase17.tscn")
	if "--feel18" in OS.get_cmdline_user_args(): selected=load("res://scenes/phase18.tscn")
	game = selected.instantiate(); root.add_child(game); game.automated = true
	await process_frame; await process_frame
	game.set_process(false)
	var fx = game.get_node("SmashDirector")
	fresh("balanced")
	check(game.rig.cute_sync,"new default opts into round paws and synchronized view")
	var paw = game.rig.grip_rig.right_hand
	check(paw.has_node("RoundPaw") and paw.has_node("ThumbPad"),"round paw and small thumb exist")
	check(not paw.has_node("Finger0") and not paw.has_node("Finger3"),"anatomical finger loops are absent")
	var new_reach: float = game.fighters[0].weapon_data.reach()*game.rig.view_weapon.scale.x
	check(new_reach > 0.55,"resting hero weapon is larger than old 0.44m display cap")
	for style in Attack.IDS:
		for rate in [30,60,120]:
			fresh(style)
			await physics_frame
			var actor = game.fighters[0]
			var drawing: Dictionary = actor.weapon_data.to_dictionary()
			var samples: PackedVector3Array = actor.hit_samples.duplicate()
			var before: int = fx.handled
			var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
			game._unhandled_input(click)
			var found := false
			for i in range(rate):
				game._physics_practice(1.0/rate)
				if fx.handled > before:
					var e: Dictionary = game.event_history.back()
					if e.outcome == "hit":
						found = true
						check(e.has("weapon_local_point") and e.has("weapon_transform"),style+str(rate)+" real swept contact has visual metadata")
						check(fx.reactions[1].age == 0 and fx.reactions[1].scale.y < 1,style+str(rate)+" body is visibly compressed on contact before render")
						var primed := false
						for p in fx.effects.particles:
							if p.life > 0 and p.age == 0: primed = true
						check(primed,style+str(rate)+" particles share zero-age onset")
						var word = fx.effects.words[(fx.effects.word_cursor+fx.effects.LABEL_CAPACITY-1)%fx.effects.LABEL_CAPACITY]
						check(word.node.position.is_equal_approx(word.at),style+str(rate)+" pooled label is positioned immediately, not at stale location")
						game._process(1.0/rate)
						var projected: Vector2 = game.camera.unproject_position(game.rig.view_weapon.to_global(e.weapon_local_point))
						var expected: Vector2 = game.camera.unproject_position(e.world_point)
						var error: float = projected.distance_to(expected)
						print("SYNC_PIXEL_ERROR ",style," ",rate," ",error)
						check(error < 0.1 and game.rig.contact_rendered,style+str(rate)+" first displayed contact aligns within 0.1px")
						check(game.rules.hp[1] == 2,style+str(rate)+" exactly original one-hit damage")
						check(drawing == actor.weapon_data.to_dictionary() and samples == actor.hit_samples,style+str(rate)+" original drawing and authority samples unchanged")
						var hp: Array = game.rules.hp.duplicate(); var scores: Array = game.rules.scores.duplicate(); var clock: float = game.rules.time_left
						var transform: Transform3D = actor.weapon.global_transform
						for f in range(10): game._process(1.0/rate)
						check(game.rules.hp == hp and game.rules.scores == scores and game.rules.time_left == clock and actor.weapon.global_transform.is_equal_approx(transform),style+str(rate)+" presentation changes no authority state")
						break
				game._process(1.0/rate)
			check(found,style+str(rate)+" actual input and physics produced hit")
			game._clear_feedback()
			check(not game.rig.contact_fresh and game.rig.contact_age >= game.rig.CONTACT_LIFE,style+str(rate)+" reset clears contact latch")
	game.queue_free(); await process_frame
	print("SYNC_UNIT_RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures == 0 else 1)
