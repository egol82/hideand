extends SceneTree
## Reproducible real mesh/skin renders and actual collision reaction, not concept artwork.
const Buddy=preload("res://scripts/character13/avatar.gd")
const Art=preload("res://scripts/phase4/art.gd")
const Studio=preload("res://scripts/graphics/studio.gd")
const Scene=preload("res://scenes/phase13.tscn")
const Form=preload("res://scripts/phase4/weapon_form.gd")
const Data=preload("res://scripts/phase4/drawing_data.gd")
var stage: Node3D
var camera: Camera3D
var avatar
var old
var game
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> void:
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://ci-artifacts/character13_"+tag+".png")!=OK:
		push_error("capture failed "+tag);quit(1)
	print("CHARACTER_CAPTURE ",tag)
func run() -> void:
	root.size=Vector2i(1280,720)
	stage=Node3D.new();root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Studio.environment();stage.add_child(env)
	Studio.key_lights(stage,true)
	Art.box(stage,Vector3(0,-0.055,0),Vector3(8,0.1,7),Color("b6c9be"),"wood",0.05)
	old=Art.avatar(Color("88d6b0"));stage.add_child(old);old.position.x=-1.05
	avatar=Buddy.new();avatar.configure(Color("88d6b0"));stage.add_child(avatar);avatar.position.x=1.05
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.7
	camera.position=Vector3(1.8,2.18,6.8);stage.add_child(camera);camera.look_at(Vector3(0,1.0,0));camera.current=true
	await shot("comparison")
	old.hide();avatar.position=Vector3.ZERO
	camera.size=3.1;camera.position=Vector3(0,1.2,6.0);camera.look_at(Vector3(0,1,0))
	await shot("front")
	avatar.rotation.y=PI;await shot("back");avatar.rotation.y=0
	avatar.pose_mode="a_pose";avatar.sync_pose(0,true);await shot("a_pose")
	avatar.pose_mode="weapon_ready";avatar.sync_pose(0,true)
	var data=Data.new();data.set_preset("fish")
	var pivot:=Node3D.new();avatar.add_child(pivot);pivot.position=Vector3(0.48,1,0.14);pivot.rotation=Vector3(-0.28,-0.9,0)
	pivot.add_child(Form.build(data));camera.size=4.2;camera.position=Vector3(3.0,2.0,6.0);camera.look_at(Vector3(0,1.0,0))
	await shot("ready")
	pivot.hide();avatar.pose_mode="idle"
	var frames:="res://ci-artifacts/character13_frames"
	DirAccess.make_dir_recursive_absolute(frames)
	for i in range(120):
		avatar.rotation.y=float(i)/120.0*TAU
		avatar.sync_pose(1.0/30,false)
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(frames+"/frame_%04d.png"%i)
	stage.queue_free();await process_frame
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	game.preferences.language="ko";game.return_to_menu();game.select_map("sugar_market")
	game.start_practice();game._process(0);await shot("workshop")
	game.accept_drawing();game.fighters[0].reset_fight(Vector3(1.0,0,4.5))
	game.fighters[1].reset_fight(Vector3(-0.3,0,1.8));game.fighters[1].visual.rotation.y=0.2
	for i in [2,3]:game.fighters[i].set_hidden(true,i)
	game.rig.face(Vector3(-0.2,0,-1));game._process(0)
	await shot("game")
	# Real attack -> original swept collision -> original effect + new skin reaction.
	game.return_to_menu();game.select_map("toy_home");game.start_practice();game.accept_drawing()
	game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3))
	game.fighters[0].handling="heavy";game.rig.face(Vector3.BACK);game.preferences.reduced_motion=false;game._process(0)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	var fx=game.get_node("SmashDirector");var before: int=fx.handled
	game._unhandled_input(click)
	var hit:=false
	for step in range(60):
		game._physics_practice(1.0/60);game._process(0)
		if fx.handled>before:
			hit=true;await shot("reaction");break
		await physics_frame
	if not hit:push_error("real collision not reached");quit(1);return
	game.queue_free();await process_frame;print("CHARACTER_CAPTURE_PASS");quit()
