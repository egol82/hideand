extends SceneTree
## Normal player eye; real movement; static comfort clues must change actual pixels.
const Scene=preload("res://scenes/phase21.tscn")
const Ready=preload("res://tests/seed21/round_ready.gd")
const VIEWS=[
	{"id":"south","at":Vector3(5.8,0,-3.7),"pitch":-0.16},
	{"id":"east","at":Vector3(7.5,0,-7.0),"pitch":-0.28},
	{"id":"north","at":Vector3(5.3,0,-10.5),"pitch":-0.22},
]
var game
var checks:=0
var failures:=0
var records:Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func fresh() -> void:
	game.return_to_menu();game.select_map("reedwater_bend");game.set_mode("field")
	await process_frame;await RenderingServer.frame_post_draw
	game.rng.seed=8027;game.start_match(true);await Ready.wait(game)
	game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.4,0,14))
	await Ready.positions(game)
func trace() -> void:
	var actor=game.fighters[1];actor.reset_fight(Vector3(4.9,0,-8.5));await Ready.positions(game)
	for tick in range(100):
		await physics_frame;actor.step(1.0/60,Vector3.BACK*0.6,Vector3.BACK);game._update_actor_events(1)
		if game.hiding.track_cursor>0:break
	check(game.hiding.track_cursor==1 and game.hiding.tracks[0].kind=="reed21","real 60 Hz movement creates one reed clue")
	actor.reset_fight(Vector3(-16,0,14));await Ready.positions(game)
func shot(tag:String) -> Image:
	await process_frame;await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	check(picture.save_png("res://ci-artifacts/reed_clue22_"+tag+".png")==OK,"save "+tag)
	return picture
func pixels(a:Image,b:Image,roi:Rect2i) -> Dictionary:
	var changed:=0;var contrast:=0.0
	for y in range(roi.position.y,roi.end.y):
		for x in range(roi.position.x,roi.end.x):
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
			var d:=maxf(absf(p.r-q.r),maxf(absf(p.g-q.g),absf(p.b-q.b)))*255.0
			if d>3.0:changed+=1
			contrast=maxf(contrast,d)
	return {"changed_pixels":changed,"max_contrast_255":contrast}
func run() -> void:
	root.size=Vector2i(1280,720);game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame
	game.set_process(false);game.get_node("ToyStudio").set_process(false)
	game.preferences.language="en";game.preferences.reduced_motion=true
	for view in VIEWS:
		await fresh();await trace()
		game.fighters[0].reset_fight(view.at);await Ready.positions(game)
		game.camera.transform=Transform3D.IDENTITY;game.rig.face(Vector3(4.9,0,-7.0)-view.at);game.rig.pitch=view.pitch
		game._process(0);game.get_node("ToyStudio")._process(0)
		check(game.camera.global_position.distance_to(view.at+Vector3.UP*1.48)<0.0001 and is_equal_approx(game.camera.fov,72.0) and game.hiding.free_point(view.at,0),view.id+" original standing eye, FOV and capsule-clear position")
		var h=game.hiding;h.tick(0.15)
		check(h.tufts[0].rotation==Vector3.ZERO and h.tracks[0].node.visible,view.id+" comfort has no sway but a live finite clue")
		var projected:Vector2=game.camera.unproject_position(h.tracks[0].at+Vector3.UP*0.14)
		var roi:=Rect2i(Vector2i(projected)-Vector2i(110,85),Vector2i(220,170)).intersection(Rect2i(0,0,1280,720))
		var live:=await shot(view.id+"_live")
		# Clue-only hidden control establishes that terrain/UI changes cannot pass.
		h.reed_visuals[0].visible=false
		var hidden:=await shot(view.id+"_hidden_control")
		h.reed_visuals[0].visible=true;h.tick(1.36)
		check(not h.tracks[0].node.visible and h.tracks[0].time<0 and h.sounds.is_empty(),view.id+" original 1.5-second visual/hearing expiry")
		var expired:=await shot(view.id+"_expired")
		var change:=pixels(live,expired,roi);var control:=pixels(hidden,expired,roi)
		check(change.changed_pixels>=25 and change.max_contrast_255>=32,view.id+" static clue visibly changes at least 25 pixels on expiry")
		check(control.changed_pixels<=2,view.id+" hidden-clue control cannot pass visibility threshold")
		records.append({"view":view.id,"eye":str(game.camera.global_position),"fov":game.camera.fov,"roi":str(roi),"event":str(h.tracks[0].at),"layout":game.round_layout.descriptor,"expiry":change,"hidden_control":control})
	var file:=FileAccess.open("res://ci-artifacts/wetland22-reed-pixels.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"viewport":[1280,720],"views":records},"  "));file.close()
	game.queue_free();await process_frame
	print("REED_CLUE22_CAPTURE_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
