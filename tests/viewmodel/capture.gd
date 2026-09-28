extends SceneTree
## Reproducible real-engine scenes, not generated art or a manual playthrough.
const Scene = preload("res://scenes/phase8.tscn")
const Data = preload("res://scripts/phase4/drawing_data.gd")
const Attack = preload("res://scripts/phase4/attack_spec.gd")
var game
var prefix := "phase8"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="): prefix = arg.trim_prefix("--prefix=")
	root.size = Vector2i(1280,720)
	game = Scene.instantiate(); root.add_child(game); game.automated = true
	game.preferences.language = "ko"; game.preferences.reduced_motion = true
	await process_frame
	for id in ["sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu(); game.select_map(id); game.start_match(true); game.accept_drawing()
		game.rules.tick(game.rules.hiding_seconds+0.1)
		var eye := Vector3(1,0,4.5)
		if id=="starlight_arcade": eye=Vector3(1.8,0,4.3)
		if id=="pocket_station": eye=Vector3(1.8,0,3.8)
		game.fighters[0].reset_fight(eye); game.fighters[0].show_weapon(true)
		game.fighters[1].reset_fight(Vector3(-1.8,0,1.3)); game.fighters[1].visual.rotation.y = 0.4
		for i in [2,3]: game.fighters[i].set_hidden(true,i)
		game.rig.face(Vector3(-0.08,0,-1)); game.rig.pitch = -0.03
		await shot(id)
	# Reuse the same world to show actual timeline poses, no geometry replacements.
	for style in Attack.IDS:
		game.fighters[0].handling = style
		var s: Dictionary = Attack.spec(style)
		for stage in ["windup","active","recovery"]:
			var elapsed: float = {"windup":s.windup*0.8,"active":s.windup+s.active*0.45,"recovery":s.windup+s.active+s.recovery*0.55}[stage]
			game.fighters[0].elapsed = elapsed
			await shot(style+"_"+stage)
	game.fighters[0].cancel_attack()
	var staff = Data.new(); staff.grip = Vector2(0.5,0.88)
	staff.strokes.append(PackedVector2Array([staff.grip,Vector2(0.5,0.08)]))
	game.fighters[0].equip(staff); await shot("long_staff")
	var sideways = Data.new(); sideways.grip = Vector2(0.1,0.5)
	sideways.strokes.append(PackedVector2Array([sideways.grip,Vector2(0.9,0.5)]))
	game.fighters[0].equip(sideways); await shot("sideways")
	game.queue_free(); await process_frame
	print("GRIP_CAPTURE_PASS"); quit()
func shot(tag: String) -> void:
	game.ui.message_seconds=0; game.ui.toast.text=""; game.local_notice_time=0; game.local_notice=""
	for i in range(4): game._process(1.0/60); await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://ci-artifacts/"+prefix+"_"+tag+".png")
	if result != OK: printerr("FAIL: capture ",tag); quit(1)
	print("GRIP_CAPTURE ",tag)
