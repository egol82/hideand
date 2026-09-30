extends SceneTree
## Actual maps and contact fixtures. Aerial images are inspection views, not a new gameplay camera.
const Scene=preload("res://scenes/phase20.tscn")
const Plans=preload("res://scripts/outdoor20/plans.gd")
var game
var metrics: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> void:
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.save_png("res://ci-artifacts/outdoor20_"+tag+".png")!=OK:push_error("Capture failed");quit(1);return
	metrics.append({"view":tag,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)})
	print("OUTDOOR20_CAPTURE ",tag)
func run() -> void:
	root.size=Vector2i(1280,720);game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	var studio=game.get_node("ToyStudio");studio.set_process(false);var world=game.get_node("World19");world.set_process(false)
	game.preferences.language="ko";game.preferences.reduced_motion=true
	for id in Plans.IDS:
		game.return_to_menu();game.select_map(id);game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
		await process_frame;await physics_frame;await physics_frame
		game.camera.transform=Transform3D.IDENTITY;game.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		# Use walkable map-specific observation points; never stage a camera inside a reed island.
		var eye := Vector3(-8,0,8) if id=="reedwater_bend" else Vector3(0,0,7)
		var target := Vector3(-6,0,5) if id=="reedwater_bend" else Vector3(-2,0,3)
		game.fighters[0].reset_fight(eye);game.fighters[1].reset_fight(target)
		game.rig.face(Vector3(0.70,0,-1) if id=="reedwater_bend" else Vector3.FORWARD);game.rig.pitch=-0.025
		for i in [2,3]:game.fighters[i].set_hidden(true,i)
		if not game.hiding.free_point(eye,0) or not game.hiding.free_point(target,1):
			push_error("Inspection position is not capsule-clear on "+id);quit(1);return
		game._process(0);studio._process(0);world.refresh();game.ui.toast.text="";game.ui.message_seconds=0;game.local_notice="";game.local_notice_time=0
		world.set_distance(0);studio._process(0);await shot(id+"_game")
		world.set_distance(18);studio._process(0);await shot(id+"_near")
		game.ui.visible=false;game.rig.hand_root.visible=false
		game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;game.camera.size=46
		game.camera.global_position=Vector3(22,40,30);game.camera.look_at(Vector3.ZERO)
		await shot(id+"_plan")
		# Deterministic real original practice collision on the new arena (no start_practice map switch).
		game.camera.transform=Transform3D.IDENTITY;game.camera.projection=Camera3D.PROJECTION_PERSPECTIVE;game.ui.visible=true
		game.practice_mode=true;game.practice.equipped=true;game.practice_respawn=0
		game.rules.phase=game.Rules.Phase.DUEL;game.last_phase=game.rules.phase;game.rules.opponent=1;game.rules.seeker=0;game.rules.hp[1]=3;game.ui.hide_modal()
		game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3));game.rig.face(Vector3.BACK)
		game.preferences.reduced_motion=false;game.preferences.feedback_strength=0.7;game._process(0);studio._process(0)
		var fx=game.get_node("SmashDirector");var before: int=fx.handled
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;game._unhandled_input(click)
		var hit:=false
		for i in range(60):
			game._physics_practice(1.0/60);game._process(1.0/60);studio._process(0)
			if fx.handled>before:hit=true;break
		if not hit:push_error("Actual input did not hit on "+id);quit(1);return
		await shot(id+"_contact");game.practice_mode=false;game.preferences.reduced_motion=true
	var f:=FileAccess.open("res://ci-artifacts/outdoor20-render-metrics.json",FileAccess.WRITE);f.store_string(JSON.stringify({"backend":"software OpenGL, not hardware FPS","views":metrics},"  "));f.close()
	game.queue_free();await process_frame;print("OUTDOOR20_CAPTURE_PASS: 12 real images");quit()
