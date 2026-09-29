extends SceneTree
## Same geometry/camera/light snapshots. Real engine pixels, not painted-over images.
const Buddy=preload("res://scripts/character13/avatar.gd")
const Art=preload("res://scripts/phase4/art.gd")
const Studio=preload("res://scripts/graphics/studio.gd")
const Mat=preload("res://scripts/material14/materials.gd")
const Data=preload("res://scripts/phase4/drawing_data.gd")
const Form=preload("res://scripts/phase4/weapon_form.gd")
const Scene=preload("res://scenes/phase14.tscn")
var materials=Mat.new()
var stage: Node3D
var camera: Camera3D
var gallery: Node3D
var game
func _initialize() -> void:call_deferred("run")
func shade(node: Node) -> void:
	if node is MeshInstance3D:
		if not node.has_meta("original14"):node.set_meta("original14",node.material_override)
		var source=node.get_meta("original14")
		if source is StandardMaterial3D:
			var role:="body" if node.name=="ConnectedBody" else ("cutout" if node.name=="SafeFoamFill" else "surface")
			node.material_override=materials.convert_role(source,true,false,role)
	for child in node.get_children():shade(child)
func shot(tag: String) -> void:
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://ci-artifacts/material14_"+tag+".png")!=OK:
		push_error("capture failed "+tag);quit(1)
	print("MATERIAL_CAPTURE ",tag)
func label(at: Vector3,text: String) -> void:
	var n:=Label3D.new();n.text=text;n.font_size=36;n.pixel_size=0.009;n.modulate=Color("f3eedf");n.outline_size=3
	n.position=at;gallery.add_child(n)
func run() -> void:
	root.size=Vector2i(1280,720)
	stage=Node3D.new();root.add_child(stage)
	var e:=WorldEnvironment.new();e.environment=Studio.environment();stage.add_child(e)
	Studio.key_lights(stage,true)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.3
	camera.position=Vector3(2.6,2.2,7);stage.add_child(camera);camera.look_at(Vector3(0,1.0,0));camera.current=true
	Art.box(stage,Vector3(0,-0.085,0),Vector3(40,0.1,40),Color("586e68"),"wood",0.05)
	gallery=Node3D.new();stage.add_child(gallery)
	var avatar=Buddy.new();avatar.configure(Color("88d6b0"));gallery.add_child(avatar)
	avatar.pose_mode="weapon_ready";avatar.sync_pose(0,true)
	var data=Data.new();data.set_preset("fish")
	var pivot:=Node3D.new();gallery.add_child(pivot);pivot.position=Vector3(0.48,1,0.14);pivot.rotation=Vector3(-0.28,-0.9,0);pivot.add_child(Form.build(data))
	for gen in [1,2]:
		materials.generation=gen;shade(gallery);await shot("character_v"+str(gen))
	# Same shape, same pigment, same light. Only the material recipe changes.
	gallery.queue_free();await process_frame;gallery=Node3D.new();stage.add_child(gallery)
	camera.size=6.5;camera.position=Vector3(0,4.0,11.5);camera.look_at(Vector3(0,0.62,0))
	var kinds:=["vinyl","foam","fabric","wood","plaster","ceramic"]
	for i in range(6):
		var x: float=(i-2.5)*1.62
		Art.ball(gallery,Vector3(x,0.69,0),Vector3.ONE*0.56,Color("cd7362"),kinds[i])
		Art.box(gallery,Vector3(x,0.02,0),Vector3(1.32,0.16,1.32),Color("3d514b"),"wood",0.035)
		label(Vector3(x,0.19,0.95),kinds[i].to_upper())
	for gen in [1,2]:
		materials.generation=gen;shade(gallery);await shot("same_color_v"+str(gen))
	var key=stage.get_node("WarmKey")
	var start: Vector3=key.rotation
	var frames:="res://ci-artifacts/material14_frames"
	DirAccess.make_dir_recursive_absolute(frames)
	for i in range(120):
		key.rotation.y=start.y+sin(float(i)/120.0*TAU)*0.65
		await process_frame;await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(frames+"/frame_%04d.png"%i)!=OK:push_error("frame capture failed");quit(1);return
	key.rotation=start
	materials.detail=false;shade(gallery);await shot("microdetail_off")
	gallery.queue_free();await process_frame;gallery=Node3D.new();stage.add_child(gallery)
	materials.detail=true;materials.generation=2
	camera.size=2.15;camera.position=Vector3(0,1.2,6);camera.look_at(Vector3(0,0.64,0))
	for i in range(2):
		var x: float=-0.95 if i==0 else 0.95
		Art.box(gallery,Vector3(x,0.60,0),Vector3(1.48,1.12,0.75),Color("ceb297"),"foam" if i==0 else "fabric",0.16)
		label(Vector3(x,-0.13,0.42),"FOAM" if i==0 else "FABRIC")
	shade(gallery);await shot("foam_fabric_detail")
	stage.queue_free();await process_frame;materials.cache.clear()
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	game.preferences.language="ko";game.preferences.reduced_motion=true
	var studio=game.get_node("ToyStudio")
	for id in ["toy_manor","sugar_market","starlight_arcade"]:
		game.return_to_menu();game.select_map(id)
		game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
		await process_frame;await process_frame
		game.fighters[0].reset_fight(Vector3(1.0,0,4.5));game.fighters[1].reset_fight(Vector3(-0.3,0,1.8));game.fighters[1].visual.rotation.y=0.2
		for i in [2,3]:game.fighters[i].set_hidden(true,i)
		game.rig.face(Vector3(-0.2,0,-1));game._process(0)
		game.ui.message_seconds=0;game.ui.toast.text="";game.local_notice="";game.local_notice_time=0
		for gen in [1,2]:
			studio.set_profile(2);studio.set_material_generation(gen);game._process(0);studio._process(0)
			await shot(id+"_v"+str(gen))
	game.return_to_menu();game.start_practice();game._process(0)
	await process_frame;await process_frame;game._process(0);studio._process(0)
	await shot("workshop")
	game.return_to_menu();studio.panel.popup_centered();await shot("comparison_menu")
	studio.panel.hide()
	# In-engine attack + contact + skinned reaction, with the upgraded materials.
	game.select_map("toy_home");game.start_practice();game.accept_drawing()
	game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3))
	game.fighters[0].handling="heavy";game.rig.face(Vector3.BACK);game.preferences.reduced_motion=false;game._process(0);studio._process(0)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	var fx=game.get_node("SmashDirector");var before: int=fx.handled;var hit:=false
	game._unhandled_input(click)
	for step in range(60):
		game._physics_practice(1.0/60);game._process(0);studio._process(0)
		if fx.handled>before:hit=true;await shot("real_contact");break
		await physics_frame
	if not hit:push_error("real collision not reached");quit(1);return
	game.queue_free();await process_frame
	print("MATERIAL_CAPTURE_PASS");quit()
