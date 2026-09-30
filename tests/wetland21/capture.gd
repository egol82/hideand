extends SceneTree
const ResetReady=preload("res://tests/seed21/round_ready.gd")
## Actual movement creates these bounded clues. The camera is staged for visual inspection only.
const Scene=preload("res://scenes/phase21.tscn")
var game
var readings: Dictionary={}
func _initialize() -> void:call_deferred("run")
func require(ok: bool,label: String) -> void:
	if not ok:push_error(label);quit(1)
func shot(tag: String) -> Image:
	await process_frame;await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	require(image.save_png("res://ci-artifacts/wetland21_"+tag+".png")==OK,"Cannot save "+tag)
	print("WETLAND21_CAPTURE ",tag);return image
func difference(a: Image,b: Image) -> float:
	var total:=0.0;var samples:=0
	for y in range(90,620,3):
		for x in range(100,1180,3):
			var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y)
			total+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b);samples+=3
	return total/maxi(samples,1)
func fresh() -> void:
	game.return_to_menu();game.select_map("reedwater_bend")
	# Flush staged map/preview setup before beginning the captured round.
	await process_frame;await RenderingServer.frame_post_draw
	game.start_match(true);await ResetReady.wait(game);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.4,0,14))
	game._process(0);game.get_node("ToyStudio")._process(0)
	await physics_frame;await physics_frame
func move_until_trace(start: Vector3,dir: Vector3) -> void:
	var actor=game.fighters[1];actor.reset_fight(start)
	for i in range(80):
		actor.step(1.0/60,dir*0.6,dir);game._update_actor_events(1)
		if game.hiding.track_cursor>0:break
		if i%15==0:await physics_frame
	require(game.hiding.track_cursor>0,"Real movement must create a trace")
	# Diagnostic pairs remove actor/name labels, not the recorded clue or terrain.
	for a in game.fighters:a.visible=false
func run() -> void:
	root.size=Vector2i(1280,720);game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	game.get_node("ToyStudio").set_process(false)
	game.preferences.language="ko";game.preferences.reduced_motion=false
	await fresh();await move_until_trace(Vector3(-2.8,0,-2.9),Vector3.RIGHT)
	game.ui.visible=false;game.rig.hand_root.visible=false
	game.camera.global_position=Vector3(-1.2,2.6,0.6);game.camera.look_at(Vector3(-1.1,0.1,-2.9))
	var wet:=await shot("water")
	game.hiding.tick(3.01)
	require(not game.hiding.tracks[0].node.visible and game.hiding.tracks[0].time<0,"Expired water trace must be hidden and unsearchable")
	var dry:=await shot("water_expired")
	readings.water_expiry_difference=difference(wet,dry)
	require(readings.water_expiry_difference>0.00001,"Actual water expiry must change rendered pixels")
	await fresh();await move_until_trace(Vector3(4.9,0,-8.5),Vector3.BACK)
	game.ui.visible=false;game.rig.hand_root.visible=false
	game.camera.global_position=Vector3(7.7,1.8,-3.9);game.camera.look_at(Vector3(4.9,0.55,-7))
	game.hiding.tick(0.14);var bent:=await shot("reeds")
	require(game.hiding.tufts[0].rotation.length()>0.001,"Real step must bend the tuft")
	game.preferences.reduced_motion=true;game.hiding.tick(0.01);await shot("comfort")
	require(game.hiding.tufts[0].rotation==Vector3.ZERO and game.hiding.tracks[0].node.visible,"Comfort keeps a finite visible clue without animation")
	game.preferences.reduced_motion=false;game.hiding.tick(1.36);var rest:=await shot("reeds_settled")
	readings.reed_settle_difference=difference(bent,rest)
	require(readings.reed_settle_difference>0.00001,"Actual reed return must change rendered pixels")
	await fresh()
	game.ui.visible=true;game.camera.transform=Transform3D.IDENTITY
	game.fighters[0].reset_fight(Vector3(5.8,0,-2.4));game.rig.face(Vector3(-0.2,0,-1));game.rig.pitch=-0.10
	game.fighters[1].reset_fight(Vector3(5.1,0,-6.3))
	game._process(0);game.get_node("ToyStudio")._process(0)
	require(game.hiding.free_point(game.fighters[0].position,0),"Gameplay capture must use a real capsule-clear position")
	await shot("gameplay")
	var f:=FileAccess.open("res://ci-artifacts/wetland21-pixels.json",FileAccess.WRITE);f.store_string(JSON.stringify(readings,"  "));f.close()
	game.queue_free();await process_frame
	print("WETLAND21_CAPTURE_PASS: six actual views ",JSON.stringify(readings));quit()
