extends SceneTree
const ResetReady=preload("res://tests/seed21/round_ready.gd")
## Actual passage and timed wind state rendered with Godot; camera placement is diagnostic.
const Scene=preload("res://scenes/phase21.tscn")
const C=preload("res://scripts/canyon21/services.gd")
var game
var readings: Dictionary={}
func _initialize() -> void:call_deferred("run")
func require(ok: bool,label: String) -> void:
	if not ok:push_error(label);quit(1)
func shot(tag: String) -> Image:
	# Settle deferred lighting/preview work before identical-pose pixel comparisons.
	for i in range(4):
		await process_frame;await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	require(image.save_png("res://ci-artifacts/canyon21_"+tag+".png")==OK,"Cannot save "+tag)
	print("CANYON21_CAPTURE ",tag);return image
func difference(a: Image,b: Image) -> float:
	var value:=0.0;var n:=0
	for y in range(90,620,4):
		for x in range(100,1180,4):
			var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y);value+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b);n+=3
	return value/maxi(1,n)
func fresh() -> void:
	game.return_to_menu();game.select_map("amber_canyon")
	# Flush staged map/preview setup before beginning the captured round.
	await process_frame;await RenderingServer.frame_post_draw
	game.start_match(true);await ResetReady.wait(game);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.5,0,15))
	game._process(0);game.get_node("ToyStudio")._process(0)
	await physics_frame;await physics_frame
func run() -> void:
	root.size=Vector2i(1280,720);game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	game.get_node("ToyStudio").set_process(false);game.preferences.reduced_motion=false;game.preferences.language="ko"
	await fresh()
	game.fighters[0].reset_fight(C.LANE_ENDS[0]);game.rig.face(Vector3.BACK);game.rig.pitch=-0.08
	for i in range(12):game.fighters[0].step(1.0/60,Vector3.ZERO,Vector3.BACK)
	game._process(0);await shot("lane_ready")
	game._interact();require(game.hiding.transit.has(0),"Real interaction must launch lane")
	game.hiding.tick(0.675);game._process(0)
	require(not game.fighters[0].hidden_in_box,"Rider is exposed, not concealed")
	await shot("lane_riding")
	game.hiding.tick(0.68);game._process(0)
	require(not game.hiding.transit.has(0),"Real passage must finish")
	await shot("lane_exit")
	await fresh();game.ui.visible=false;game.rig.hand_root.visible=false
	# Isolate environmental reaction for identical-view pairs; only fixture actors are hidden.
	for a in game.fighters:a.visible=false
	game.camera.global_position=Vector3(-8.7,2.1,5.6);game.camera.look_at(Vector3(-12,0.55,2))
	var rest:=await shot("gust_rest")
	game.hiding.tick(4.3);await shot("gust_warning")
	game.hiding.tick(1.0);var moving:=await shot("gust_active")
	readings.wind_movement=difference(rest,moving)
	require(readings.wind_movement>0.0001,"Actual moved toys change rendered pixels")
	game.hiding.tick(2.01);var settled:=await shot("gust_settled")
	readings.wind_return=difference(rest,settled)
	require(readings.wind_return<0.00002,"All bounded toys and flag return to the identical rendered rest pose")
	var f:=FileAccess.open("res://ci-artifacts/canyon21-pixels.json",FileAccess.WRITE);f.store_string(JSON.stringify(readings,"  "));f.close()
	game.queue_free();await process_frame
	print("CANYON21_CAPTURE_PASS: seven actual views ",JSON.stringify(readings));quit()
