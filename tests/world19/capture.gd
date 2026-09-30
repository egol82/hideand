extends SceneTree
const Scene=preload("res://scenes/phase19.tscn")
const Maps:=["sugar_market","starlight_arcade","pocket_station","toy_home","warehouse","garden"]
var game
var report: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.save_png("res://ci-artifacts/world19_"+tag+".png")!=OK:push_error("capture failed");quit(1);return
	report.append({"view":tag,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	print("WORLD19_CAPTURE ",tag)
func run() -> void:
	root.size=Vector2i(1280,720);game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await process_frame;game.set_process(false)
	var studio=game.get_node("ToyStudio");studio.set_process(false)
	var world=game.get_node("World19");world.set_process(false)
	game.preferences.language="ko";game.preferences.reduced_motion=true
	for id in Maps:
		game.return_to_menu();game.select_map(id);game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
		await process_frame;await process_frame
		game.fighters[0].reset_fight(Vector3(1,0,4.0));game.fighters[1].reset_fight(Vector3(-2.0,0,1.0))
		for i in [2,3]:game.fighters[i].set_hidden(true,i)
		game.rig.face(Vector3(-0.06,0,-1));game._process(0);studio._process(0);world.refresh()
		world.set_enabled(false);studio.world_lighting=false;studio.set_profile(2,false);await shot(id+"_before")
		world.set_enabled(true);studio.world_lighting=true;studio.set_profile(2,false);world.refresh();await shot(id+"_after")
		# Make the explicit small-detail range pair on the same physical game scene.
		world.set_distance(0);await shot(id+"_full")
		world.set_distance(18);await shot(id+"_near")
	game.return_to_menu();game.select_map("toy_manor");game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
	await process_frame;await process_frame
	game.fighters[0].reset_fight(Vector3(-1.5,0,0.5));game.rig.face(Vector3(-0.36,0,-1));game._process(0);studio._process(0);world.refresh();await shot("manor_preserved")
	game.return_to_menu();world.panel.popup_centered();await shot("options")
	var file:=FileAccess.open("res://ci-artifacts/world19-render-metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify({"renderer":"software GL, not hardware FPS","views":report},"  "));file.close()
	game.queue_free();await process_frame;print("WORLD19_CAPTURE_PASS: 26 images");quit()
