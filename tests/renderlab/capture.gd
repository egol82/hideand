extends SceneTree
const Scene=preload("res://scenes/phase10.tscn")
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts")
	root.size=Vector2i(1280,720)
	game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await process_frame
	game.set_process(false)
	var studio=game.get_node("ToyStudio")
	for map_id in ["sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu(); game.select_map(map_id); game.start_match(true); game.accept_drawing()
		game.rules.tick(game.rules.hiding_seconds+0.1)
		game.practice_mode=true
		game.fighters[0].reset_fight(Vector3(0.6,0,4.5))
		game.fighters[1].reset_fight(Vector3(-1.6,0,1.3)); game.fighters[1].visual.rotation.y=0.2
		for i in [2,3]: game.fighters[i].set_hidden(true,i)
		game.rig.face(Vector3(-0.08,0,-1)); game.rig.pitch=-0.015
		game.preferences.language="ko"; game.preferences.reduced_motion=true
		game.preferences.hand_sway=0; game.preferences.head_bob=0
		await process_frame; await process_frame
		for mode in [0,1,2]:
			studio.set_profile(mode)
			await shot("studio_"+map_id+"_"+str(mode))
		if map_id=="sugar_market":
			game.fighters[0].reset_fight(Vector3(3.5,0,-1.0)); game.rig.face(Vector3(-0.50,0,-1)); game.rig.pitch=-0.10
			for mode in [0,2]: studio.set_profile(mode); await shot("studio_detail_"+str(mode))
		game.practice_mode=false
	studio.set_profile(2)
	game.queue_free(); await process_frame; await process_frame
	load("res://scripts/graphics/surfaces.gd").cache.clear()
	load("res://scripts/graphics/surfaces.gd").tiles.clear()
	await process_frame
	print("STUDIO_CAPTURE_PASS"); quit()
func shot(name_value: String) -> void:
	game.ui.message_seconds=0; game.ui.toast.text=""; game.local_notice_time=0; game.local_notice=""
	for i in range(4): game._process(1.0/60); await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://ci-artifacts/"+name_value+".png")!=OK:
		printerr("FAIL: image ",name_value); quit(1)
	print("STUDIO_CAPTURE ",name_value)
