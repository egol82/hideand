extends SceneTree
const Scene = preload("res://scenes/phase6.tscn")
var game
var prefix := "phase6"
var one := ""
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="): prefix = arg.trim_prefix("--prefix=")
		if arg.begins_with("--one="): one = arg.trim_prefix("--one=")
	root.size = Vector2i(1280,720)
	game = Scene.instantiate(); root.add_child(game)
	game.automated = true
	game.preferences.language = "en"
	game.preferences.reduced_motion = true
	game.ui.show_menu()
	await frames(); await shot("menu")
	game.start_practice()
	game.ui.canvas.set_preset("fish")
	await frames(); await shot("workshop")
	game.accept_drawing()
	game.fighters[0].reset_fight(Vector3(0.9,0,3.8))
	game.fighters[1].reset_fight(Vector3(0.0,0,0.9))
	game.fighters[1].visual.rotation.y = 0.12
	game.rig.face(Vector3(-0.15,0,-1)); game.rig.pitch = -0.07
	await frames(); await shot("hero")
	if one == "hero": await finish(); return
	game.fighters[0].reset_fight(Vector3(-3.8,0,2.8))
	game.rig.face(Vector3(2.8,0,-5.4)); game.rig.pitch = -0.07
	await frames(); await shot("lounge")
	if one == "lounge": await finish(); return
	game.return_to_menu(); game.preferences.language = "ko"
	game.ui.show_menu(); await frames(); await shot("menu_ko")
	game.start_practice(); await frames(); await shot("workshop_ko")
	game.return_to_menu(); game.preferences.language = "en"
	game.select_map("garden"); game.start_match(true); game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.1)
	game.rig.face(Vector3(-0.45,0,-1))
	await frames(); await shot("garden")
	await finish()
func finish() -> void:
	game.queue_free(); await process_frame
	print("GRAPHICS_CAPTURE_PASS"); quit()
func frames() -> void:
	for i in range(3):
		game._process(1.0/60)
		await process_frame
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://ci-artifacts/"+prefix+"_"+label+".png")
	if error != OK:
		printerr("FAIL: image save ",label); quit(1)
	print("CAPTURE ",label," ",image.get_size())
