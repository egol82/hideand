extends SceneTree
## Staged live engine evidence. Hiding, footsteps and staircase footage run real handlers/physics.
const Scene=preload("res://scenes/phase11.tscn")
var game
var folder:="res://ci-artifacts/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	game=Scene.instantiate(); root.add_child(game); game.automated=true
	game.preferences.language="ko"; game.preferences.reduced_motion=true
	await process_frame; await physics_frame
	game.set_process(false); game.set_physics_process(false)
	game.ui.show_menu(); await shot("hideplay_00_menu")
	game.start_match(false); game.accept_drawing(); game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(1,4): game.fighters[i].reset_fight(Vector3(10,0,-11+i)); game.fighters[i].set_hidden(true,i)
	var actor=game.fighters[0]
	actor.reset_fight(Vector3(-1,0,1)); game.rig.face(Vector3(-0.65,0,-1)); game.rig.pitch=-0.05
	await shot("hideplay_01_living")
	actor.reset_fight(Vector3(1,0,1)); game.rig.face(Vector3(0.45,0,-1)); game.rig.pitch=-0.04
	await shot("hideplay_02_kitchen")
	actor.reset_fight(Vector3(-11,1.7,1)); game.rig.face(Vector3(0,0,-1)); game.rig.pitch=0.18
	await shot("hideplay_03_stairs")
	actor.reset_fight(Vector3(-1,4,1)); game.rig.face(Vector3(-0.65,0,-1)); game.rig.pitch=-0.05
	await shot("hideplay_04_upper")
	var home: Dictionary={}
	for h in game.hiding.homes:
		if game.hiding.usable(h.id) and h.at.y==0: home=h; break
	actor.reset_fight(home.entry); game.hiding.hide_actor(0,home.id); game.rig.face(Vector3.BACK)
	await shot("hideplay_05_hidden")
	Input.action_press("hs_quiet"); game.hiding.tick(0.7)
	await shot("hideplay_06_peek")
	Input.action_release("hs_quiet"); game.hiding.leave(0,true)
	actor.reset_fight(Vector3(0,0,0)); game.rig.face(Vector3.BACK); game.hiding.deploy_decoy(0); game.hiding.tick(0.9)
	game.rig.pitch=-0.45
	await shot("hideplay_07_decoy")
	actor.reset_fight(Vector3(0,4,11)); game.rig.face(Vector3(0,0,-1)); game.rig.pitch=-0.12
	game.toggle_pause(); game.ui.show_map(); await shot("hideplay_08_map"); game.toggle_pause()
	if "--video" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(folder+"hideplay_frames")
		game.return_to_menu(); game.select_map("toy_manor"); game.start_match(false); game.accept_drawing()
		actor.reset_fight(Vector3(-11,0,9)); game.rig.face(Vector3.FORWARD); game.rig.pitch=0.15
		game.automated=false; Input.action_press("hs_forward")
		for frame in range(180):
			for tick in range(2):
				if actor.position.z<-9.0: Input.action_release("hs_forward")
				game._physics_process(1.0/60); await physics_frame
			game._process(1.0/30)
			await process_frame; await RenderingServer.frame_post_draw
			var err:=root.get_texture().get_image().save_png(folder+"hideplay_frames/frame_%04d.png"%frame)
			if err!=OK: printerr("FAIL: staircase frame"); quit(1); return
		Input.action_release("hs_forward")
	game.queue_free(); await process_frame
	print("HIDEPLAY_CAPTURE_PASS"); quit()
func shot(name_value: String) -> void:
	game.ui.message_seconds=0; game.ui.toast.text=""
	for i in range(3): game._process(0); await process_frame
	await RenderingServer.frame_post_draw
	var err:=root.get_texture().get_image().save_png(folder+name_value+".png")
	if err!=OK: printerr("FAIL: capture ",name_value); quit(1)
	print("HIDEPLAY_CAPTURE ",name_value)
