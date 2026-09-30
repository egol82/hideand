extends SceneTree
## Same camera/state/light comparisons in the real playable manor; no image generation or repainting.
const Scene=preload("res://scenes/phase17.tscn")
var game
var env
var studio
var camera: Camera3D
var shots:=0
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.save_png("res://ci-artifacts/environment17_"+tag+".png")!=OK:push_error("image save failed");quit(1);return
	shots+=1;print("ENVIRONMENT17_CAPTURE ",tag)
func view(at: Vector3,target: Vector3) -> void:
	camera.global_position=at;camera.look_at(target)
func run() -> void:
	root.size=Vector2i(1280,720)
	print("ENV17_STAGE: instantiate")
	game=Scene.instantiate();root.add_child(game);game.automated=true
	print("ENV17_STAGE: first frames")
	await process_frame;await process_frame;await physics_frame
	print("ENV17_STAGE: initialize controls")
	game.set_process(false);env=game.get_node("Environment17");env.set_process(false);studio=game.get_node("ToyStudio");studio.set_process(false)
	game.preferences.language="ko";game.preferences.reduced_motion=true
	print("ENV17_STAGE: start match")
	game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
	game.fighters[0].reset_fight(Vector3(-1.5,0,0.5));game.fighters[1].reset_fight(Vector3(-3,0,-3.2))
	for i in [2,3]:game.fighters[i].set_hidden(true,i)
	game.rig.face(Vector3(-0.36,0,-1));game._process(0);studio._process(0);env.refresh()
	game.ui.toast.text="";game.local_notice="";game.local_notice_time=0;game.ui.message_seconds=0
	camera=game.camera
	for flag in [false,true]:env.set_enabled(flag);await shot("fps_"+("after" if flag else "before"))
	game.ui.visible=false;studio.ui_layer.visible=false;game.rig.hand_root.visible=false
	for a in game.fighters:a.visible=false
	var setups:={
		"living":[Vector3(-1.0,2.45,-0.5),Vector3(-4.4,1.38,-6.7)],
		"sofa":[Vector3(-1.0,2.24,-3.70),Vector3(-4.0,1.30,-6.0)],
		"window":[Vector3(-6.5,2.75,-8.25),Vector3(-5.0,2.0,-12.4)],
		"cupboard":[Vector3(-4.1,1.9,0.0),Vector3(-6.2,1.12,-2.0)],
		"kitchen":[Vector3(6.8,2.52,-2.8),Vector3(4.0,1.0,-6.0)],
		"bedroom":[Vector3(-1.0,6.45,-2.1),Vector3(-4.0,5.35,-6.0)]}
	for tag in setups:
		view(setups[tag][0],setups[tag][1])
		for flag in [false,true]:env.set_enabled(flag);await shot(tag+"_"+("after" if flag else "before"))
	# Restore normal menu; the crafting switch remains a native control next to GI/material choices.
	game.return_to_menu();game.select_map("toy_manor");await process_frame;await process_frame;studio._process(0);env.refresh()
	game.ui.visible=true;studio.ui_layer.visible=true;studio.panel.popup_centered();await shot("options");studio.panel.hide()
	game.queue_free();await process_frame
	print("ENVIRONMENT17_CAPTURE_PASS: ",shots);quit()
