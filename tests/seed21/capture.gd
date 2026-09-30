extends SceneTree
const ResetReady=preload("res://tests/seed21/round_ready.gd")
## Actual renderer; same-camera round layouts and actual capsule-clear first-person views.
const Scene=preload("res://scenes/phase21.tscn")
const Plans=preload("res://scripts/seed21/layouts.gd")
var game
var records: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var im:=root.get_texture().get_image()
	if im.save_png("res://ci-artifacts/seed21_"+tag+".png")!=OK:push_error("Failed to save "+tag);quit(1)
	records.append({"tag":tag,"layout":game.round_layout.descriptor.duplicate(true),"render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	print("SEED21_CAPTURE: ",tag);return im
func difference(a: Image,b: Image) -> float:
	var total:=0.0;var count:=0
	for y in range(0,a.get_height(),4):
		for x in range(0,a.get_width(),4):
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y);total+=absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b);count+=3
	return total/count
func run() -> void:
	root.size=Vector2i(1280,720)
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await physics_frame;game.set_process(false)
	game.round_layout.set_process(false)
	var studio=game.get_node("ToyStudio");studio.set_process(false)
	for mid in Plans.IDS:
		var frames: Array[Image]=[]
		for r in [0,1]:
			game.return_to_menu();game.select_map(mid);game.rng.seed=8027;game.start_match(false)
			if r>0:game.rules.round_index=r;game._prepare_round()
			await ResetReady.wait(game)
			if not game.round_layout.applied:push_error("Renderer has no actual seeded layout");quit(1);return
			game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
			game._process(0);studio._process(0)
			game.ui.visible=false;game.round_layout.diagnostic.visible=false;game.rig.hand_root.visible=false
			for a in game.fighters:a.visible=false
			game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;game.camera.size=game.arena.dimensions.x+3
			game.camera.global_position=Vector3(0,42,2);game.camera.look_at(Vector3(0,0,2),Vector3.FORWARD)
			frames.append(await shot(mid+"_round"+str(r)))
		var delta:=difference(frames[0],frames[1])
		if delta<=0.00001:push_error("Actual layout pixels did not change "+mid);quit(1);return
		print("SEED21_LAYOUT_PIXEL_DELTA: ",mid," ",delta)
		game.ui.visible=true;game.camera.projection=Camera3D.PROJECTION_PERSPECTIVE;game.camera.transform=Transform3D.IDENTITY
		game.camera.fov=76
		var p: Vector2=Plans.plan(mid,8027,1).positions[0]
		var origin:=Vector3(p.x,0,p.y);var chosen:=false
		for offset in [Vector3(0,0,4),Vector3(3,0,3),Vector3(-3,0,3),Vector3(0,0,-4)]:
			var at: Vector3=origin+offset
			if game.hiding.free_point(at,0):
				game.fighters[0].reset_fight(at);game.rig.face(origin-at);game.rig.pitch=-0.10;chosen=true;break
		if not chosen:push_error("No capsule-clear gameplay capture position");quit(1);return
		game._process(0);studio._process(0);game.round_layout._process(0)
		await shot(mid+"_gameplay")
	var file:=FileAccess.open("res://ci-artifacts/seed21-render-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "));file.close()
	game.queue_free();await process_frame
	print("SEED21_CAPTURE_PASS: 9 actual images, 3 same-camera changed-layout pairs");quit()
