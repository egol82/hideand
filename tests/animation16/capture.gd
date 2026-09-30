extends SceneTree
## Actual skinned-pose inspection and actual collision/movement footage. No image generation.
const Scene=preload("res://scenes/phase16.tscn")
const Buddy=preload("res://scripts/character13/avatar.gd")
const Driver=preload("res://scripts/animation16/animator.gd")
const Art=preload("res://scripts/phase4/art.gd")
const Light=preload("res://scripts/graphics/studio.gd")
const Mat=preload("res://scripts/material14/materials.gd")
var game
var counter:=0
var video:=false
func _initialize() -> void:call_deferred("run")
func shot(name_value: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://ci-artifacts/animation16_"+name_value+".png")!=OK:
		push_error("Capture save failed");quit(1);return
	print("ANIMATION16_CAPTURE ",name_value)
func frame() -> void:
	await process_frame;await RenderingServer.frame_post_draw
	if video:
		if root.get_texture().get_image().save_png("res://ci-artifacts/animation16_frames/frame_%04d.png"%counter)!=OK:
			push_error("Frame save failed");quit(1);return
	counter+=1
func run() -> void:
	video="--video" in OS.get_cmdline_user_args()
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts/animation16_frames")
	# Neutral studio clips expose the actual body; hidden states below are labelled inspection views.
	var stage:=Node3D.new();root.add_child(stage)
	var e:=WorldEnvironment.new();e.environment=Light.environment();stage.add_child(e);Light.key_lights(stage,true)
	Art.box(stage,Vector3(0,-0.06,0),Vector3(30,0.1,30),Color("647c74"),"wood",0.025)
	var cam:=Camera3D.new();stage.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=3.5;cam.position=Vector3(2.3,1.6,6.0);cam.look_at(Vector3(0,0.94,0));cam.current=true
	var buddy:=Buddy.new();buddy.configure(Color("88d6b0"));stage.add_child(buddy)
	var materials=Mat.new();materials.generation=2
	buddy.body.material_override=materials.convert_role(buddy.body.material_override,true,false,"body")
	var d:=Driver.new();buddy.add_child(d);d.setup(buddy)
	for state in ["idle","walk","run","hide","peek","windup","attack","hit","recover","ko"]:
		d.reset();d.evaluate(state,0.24,1.0/30,false);await shot("pose_"+state)
	stage.queue_free();await process_frame
	# Live game, same materials and GI. No pose-only stage substitutes for gameplay captures.
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	var studio=game.get_node("ToyStudio");studio.set_process(false)
	game.preferences.language="ko";game.preferences.reduced_motion=false
	game.return_to_menu();game.select_map("toy_manor");game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1);game._process(0);studio._process(0)
	game.fighters[0].reset_fight(Vector3(-1.5,0,0.5));game.fighters[1].reset_fight(Vector3(-3,0,-3.2));game.fighters[1].visual.rotation.y=0.12
	for i in [2,3]:game.fighters[i].set_hidden(true,i)
	game.rig.face(Vector3(-0.36,0,-1));game._process(0);studio._process(0)
	await shot("live_manor")
	# Physical walk and run on ordinary floor. Fixed camera follows for inspection only.
	game.return_to_menu();game.select_map("toy_home");game.start_practice();game.accept_drawing();game.ui.visible=false
	var actor=game.fighters[1]
	for a in game.fighters:
		a.set_hidden(false);a.set_view_subject(false)
		if a!=actor:a.visible=false
	# A separate clearly documented open test pad avoids a camera passing through map signs.
	# Movement still uses the unmodified CharacterBody.step and real floor collision.
	var pad:=StaticBody3D.new();game.add_child(pad);pad.position=Vector3(0,30,0);pad.collision_layer=1
	var cs:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(30,0.2,30);cs.shape=shape;pad.add_child(cs)
	Art.box(pad,Vector3.ZERO,shape.size,Color("647c74"),"wood",0.02)
	# Let the physics server register the newly created inspection floor before settling.
	await physics_frame;await physics_frame
	actor.reset_fight(Vector3(-3,30.1,0));actor.show_weapon(false)
	for i in range(12):actor.step(1.0/60,Vector3.ZERO,Vector3.BACK)
	if not actor.is_on_floor():push_error("Inspection actor did not settle on the real test floor");quit(1);return
	studio._process(0)
	for i in range(45):
		actor.step(1.0/30,Vector3.RIGHT*0.55,Vector3.BACK)
		game._sync_characters(1.0/30);studio.update_contacts()
		game.camera.global_position=actor.position+Vector3(1.3,1.2,3.2);game.camera.look_at(actor.position+Vector3.UP*0.9)
		game.rig.hand_root.visible=false
		if i==25:await shot("live_walk")
		await frame()
	actor.reset_fight(Vector3(-3,30.1,0))
	for i in range(30):
		if i%27==0:actor.begin_dash(Vector3.RIGHT)
		actor.step(1.0/30,Vector3.RIGHT,Vector3.BACK);game._sync_characters(1.0/30);studio.update_contacts()
		game.camera.global_position=actor.position+Vector3(1.3,1.2,3.2);game.camera.look_at(actor.position+Vector3.UP*0.9);game.rig.hand_root.visible=false
		if i==2:await shot("live_run")
		await frame()
	pad.queue_free();await process_frame
	# Shared physics input creates the attack, contact, reaction and recovery.
	game.return_to_menu();game.select_map("toy_home");game.start_practice();game.accept_drawing()
	var fx=game.get_node("SmashDirector");var count: int=fx.handled
	for i in range(3):
		fx.reset()
		game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3))
		game.fighters[0].handling=["quick","balanced","heavy"][i]
		game.rig.face(Vector3.BACK);game._process(0);studio._process(0)
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;game._unhandled_input(event)
		var recorded:=false
		for j in range(30):
			game._physics_practice(1.0/30);game._process(1.0/30);studio._process(0)
			if fx.handled>count and not recorded:
				recorded=true;count=fx.handled;await shot("contact_"+str(i))
			await frame()
		if not recorded:push_error("Real attack failed to make contact");quit(1);return
	game.queue_free();await process_frame
	print("ANIMATION16_CAPTURE_PASS: frames=",counter);quit()
