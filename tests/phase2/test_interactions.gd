extends SceneTree
## Calls the same input handlers used in play; this is scripted integration, not human QA.
const Scene = preload("res://scenes/phase2.tscn")
const Rules = preload("res://scripts/phase2/match_rules.gd")
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
	var game = Scene.instantiate()
	root.add_child(game)
	game.automated = true
	await physics_frame
	await process_frame
	check(game.rules.phase == Rules.Phase.MENU,"real scene starts on title")
	game.start_match(false)
	await process_frame
	check(game.rules.phase == Rules.Phase.DRAW,"hide-first button route starts drawing")
	var canvas = game.ui.canvas
	canvas.clear_drawing()
	game.accept_drawing()
	check(game.rules.phase == Rules.Phase.DRAW,"UI rejects empty ready submission")
	var paper: Rect2 = canvas.paper_rect()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = paper.position + paper.size*Vector2(0.5,0.85)
	canvas._gui_input(press)
	for point in [Vector2(0.5,0.5),Vector2(0.2,0.3),Vector2(0.7,0.2)]:
		var motion := InputEventMouseMotion.new()
		motion.position = paper.position+paper.size*point
		canvas._gui_input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	canvas._gui_input(release)
	check(canvas.data.is_valid(),"mouse drawing handler produces valid arbitrary weapon")
	check(canvas.data.strokes.size() == 1 and canvas.data.point_count() == 4,"input points retained without preset substitution")
	check(not game.ui.ready_button.disabled,"valid drawing enables ready")
	check(game.ui.preview_weapon.mesh != null,"drawing handler builds 3D preview")
	game.accept_drawing()
	check(game.rules.phase == Rules.Phase.HIDE,"ready enters hide phase")
	check(game.fighters[0].weapon_data.point_count() == 4,"player equips exactly the submitted drawing")
	var time: float = game.rules.time_left
	game.toggle_pause()
	check(game.paused,"pause menu pauses simulation")
	game.automated = false
	game._physics_process(1.0)
	game.automated = true
	check(game.rules.time_left == time,"pause does not consume phase time")
	game.toggle_pause()
	check(not game.paused,"resume restores simulation")
	game.fighters[0].position = game.arena.spots[0]
	game._interact()
	check(game.fighters[0].hidden_in_box,"E hides at an available prop")
	check(not game.fighters[0].visual.visible and not game.fighters[0].nameplate.visible,"hiding removes model and nameplate")
	check(game.fighters[0].collision_layer == 0,"hidden player cannot block another player")
	game._interact()
	check(not game.fighters[0].hidden_in_box and game.fighters[0].collision_layer == 2,"E leaves the prop and restores collision")
	game.return_to_menu()
	game.start_match(true)
	game.accept_drawing()
	var shift := InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	shift.pressed = true
	game._unhandled_input(shift)
	check(game.fighters[0].dash_time == 0.0,"seeker cannot bank a dash while waiting")
	check(game.ui.wait_clock != null,"seeker cannot watch hiding movement")
	game.rules.tick(Rules.HIDE_SECONDS+0.01)
	game.fighters[1].position = game.arena.spots[0]
	game.fighters[1].set_hidden(true,0)
	game.fighters[0].position = game.arena.spots[0]+Vector3(0,0,0.4)
	await physics_frame
	game._interact()
	check(game.rules.phase == Rules.Phase.REVEAL,"E inspection discovers a real hidden occupant")
	check(game.fighters[0].weapon.visible and game.fighters[1].weapon.visible,"discovery reveals both player-made weapons")
	check(not game.fighters[1].hidden_in_box,"found hider becomes a visible duelist")
	game.rules.tick(Rules.REVEAL_SECONDS+0.01)
	check(game.rules.phase == Rules.Phase.DUEL,"real scene enters duel")
	var seeker_attack: Array[int] = [0]
	for hit in range(3):
		game.rules.register_hits(seeker_attack)
	check(not game.rules.alive[1] and not game.fighters[1].visible,"capture removes player for rest of round")
	check(game.rules.phase == Rules.Phase.SEEK,"capture resumes search without a new round")
	game.return_to_menu()
	game.start_match(false)
	check(game.rules.scores == [0,0,0,0] and game.rules.remaining() == 3,"new match resets score and eliminations")
	check(game.fighters[0].weapon_data.point_count() == 4,"restarting preserves the player's custom toy")
	game.ui.canvas.clear_drawing()
	game.rules.tick(Rules.DRAW_SECONDS+0.01)
	check(game.fighters[0].weapon_data.is_valid() and game.rules.phase == Rules.Phase.HIDE,"blank drawing timeout keeps previous valid weapon")
	game.queue_free()
	await process_frame
	print("PHASE2_INTERACTION_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
