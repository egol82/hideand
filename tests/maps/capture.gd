extends SceneTree
const Scene = preload("res://scenes/phase7.tscn")
const Catalog = preload("res://scripts/maps/catalog.gd")
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	game = Scene.instantiate(); root.add_child(game)
	game.automated = true
	game.preferences.language = "ko"
	game.preferences.reduced_motion = true
	await frames()
	for id in Catalog.NEW_IDS:
		game.return_to_menu()
		game.select_map(id)
		game.ui.show_menu()
		await frames(); await shot(id+"_menu")
		game.start_match(true); game.accept_drawing()
		game.rules.tick(game.rules.hiding_seconds+0.1)
		var eye := Vector3(1,0,4.5)
		var toward := Vector3(-0.08,0,-1)
		if id=="starlight_arcade": eye = Vector3(1.8,0,4.3)
		if id=="pocket_station": eye = Vector3(1.8,0,3.8)
		game.local_notice_time = 0
		game.local_notice = ""
		game.ui.message_seconds = 0; game.ui.toast.text = ""
		game.fighters[0].reset_fight(eye)
		game.fighters[0].show_weapon(true)
		game.fighters[1].reset_fight(Vector3(-1.8,0,1.3))
		game.fighters[1].visual.rotation.y = 0.4
		for i in [2,3]: game.fighters[i].set_hidden(true,i)
		game.rig.face(toward); game.rig.pitch = -0.03
		await frames(); await shot(id+"_fps")
		if id=="sugar_market":
			game.fighters[0].reset_fight(Vector3(-8.7,0,6.4)); game.rig.face(Vector3(5.6,0,-8))
		elif id=="starlight_arcade":
			game.fighters[0].reset_fight(Vector3(12,0,6.5)); game.rig.face(Vector3(-9,0,-10))
		else:
			game.fighters[0].reset_fight(Vector3(-11,0,6.5)); game.rig.face(Vector3(8,0,-12))
		game.rig.pitch = -0.03
		await frames(); await shot(id+"_route")
		# A separate overview uses the real same scene; restore FPS before next map.
		for part in game.arena.get_children():
			if part is MeshInstance3D and part.has_meta("cutaway_roof"): part.visible = false
		var camera := Camera3D.new(); camera.position = Vector3(0,52,0.1); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = game.arena.dimensions.y+5
		game.add_child(camera); camera.look_at(Vector3.ZERO); camera.current = true
		game.ui.root.visible = false
		await process_frame; await shot(id+"_overview")
		camera.queue_free(); game.camera.current = true; game.ui.root.visible = true
		for part in game.arena.get_children():
			if part is MeshInstance3D and part.has_meta("cutaway_roof"): part.visible = true
	game.queue_free()
	await process_frame
	game = null
	preload("res://scripts/graphics/surfaces.gd").cache.clear()
	preload("res://scripts/graphics/surfaces.gd").tiles.clear()
	preload("res://scripts/phase4/art.gd").meshes.clear()
	preload("res://scripts/maps/props.gd").cylinders.clear()
	for i in range(12):
		await process_frame
		await RenderingServer.frame_post_draw
	print("MAP_PACK_CAPTURE_PASS"); quit()
func frames() -> void:
	for i in range(5):
		game._process(1.0/60); await process_frame
func shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png("res://ci-artifacts/phase7_"+tag+".png") != OK:
		printerr("FAIL: capture "+tag); quit(1)
	print("CAPTURE: "+tag)
