extends SceneTree
const ResetReady=preload("res://tests/seed21/round_ready.gd")
## Four actual staged views. No generated art; the first trace is made by real CharacterBody motion.
const Scene=preload("res://scenes/phase21.tscn")
var game
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://ci-artifacts/pine21_"+tag+".png")!=OK:push_error("capture failed");quit(1)
func run() -> void:
	root.size=Vector2i(1280,720);game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	game.return_to_menu();game.select_map("pine_hollow");game.start_match(true);await ResetReady.wait(game);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	game.preferences.language="ko";game.get_node("ToyStudio")._process(0)
	var actor=game.fighters[1]
	game.fighters[0].reset_fight(Vector3(0,0,6));game.rig.face(Vector3.FORWARD)
	for id in [2,3]:game.fighters[id].reset_fight(Vector3(10,0,5+id))
	await physics_frame;await physics_frame
	actor.reset_fight(Vector3(-2.8,0,0))
	for step in range(50):
		actor.step(1.0/60,Vector3.RIGHT*0.55,Vector3.RIGHT);game._update_actor_events(1)
		if step%12==0:await physics_frame
	if game.hiding.track_cursor==0:push_error("No actual movement trace");quit(1);return
	game._process(0);game.camera.global_position=Vector3(0,3.7,5);game.camera.look_at(Vector3(-0.7,0.12,0));game.rig.hand_root.visible=false
	await shot("leaves")
	# Public bush shape does not change when occupied; ordinary interaction is used.
	game.return_to_menu();game.select_map("pine_hollow");game.start_match(false);await ResetReady.wait(game);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	var h=game.hiding;var index:=-1
	for seed_value in range(10):
		h.configure(seed_value)
		for id in h.BUSH_IDS:
			if h.usable(id):index=id;break
		if index>=0:break
	if index<0:push_error("No usable bush");quit(1);return
	for id in range(1,4):game.fighters[id].reset_fight(Vector3(3+id*2,0,2))
	var entry: Vector3=h.homes[index].entry
	game.fighters[0].reset_fight(entry+Vector3.BACK*1.6);game.camera.transform=Transform3D.IDENTITY;game.rig.face(Vector3.FORWARD);game._process(0)
	await shot("bush")
	game.fighters[0].reset_fight(entry)
	if not h.hide_actor(0,index):push_error("Real hiding failed");quit(1);return
	game._process(0);await shot("hidden")
	h.tick(4.1);game._process(0)
	if game.fighters[0].hidden_in_box:push_error("Timeout did not expose actor");quit(1);return
	await shot("expired")
	game.queue_free();await process_frame;print("PINE21_CAPTURE_PASS: 4 real views");quit()
