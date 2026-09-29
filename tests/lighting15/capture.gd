extends SceneTree
## Actual live-map snapshots. No image overlays; direct lights stay identical between B and C.
const Scene=preload("res://scenes/phase15.tscn")
var game
var studio
var readings: Dictionary={}
func _initialize() -> void:call_deferred("run")
func picture() -> Image:
	for i in range(2):await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func shot(tag: String) -> Image:
	var image:=await picture()
	if image.save_png("res://ci-artifacts/lighting15_"+tag+".png")!=OK:push_error("image save failed "+tag);quit(1)
	print("LIGHTING15_CAPTURE ",tag);return image
func mean(image: Image) -> float:
	var total:=0.0;var count:=0
	for y in range(130,image.get_height()-140,5):
		for x in range(80,image.get_width()-80,5):
			var c:=image.get_pixel(x,y);total+=(c.r+c.g+c.b)/3.0;count+=1
	return total/maxi(1,count)
func difference(a: Image,b: Image) -> float:
	var total:=0.0;var count:=0
	for y in range(80,a.get_height()-80,5):
		for x in range(80,a.get_width()-80,5):
			var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y);total+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b);count+=3
	return total/maxi(1,count)
func require(ok: bool,message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:quit(1)
func hide_meshes(n: Node) -> void:
	if n is MeshInstance3D or n is Label3D:n.visible=false
	for c in n.get_children():hide_meshes(c)
func reveal_meshes(n: Node) -> void:
	if n is MeshInstance3D:n.visible=true
	for c in n.get_children():reveal_meshes(c)
func silence(n: Node) -> void:
	if n is Light3D:n.light_energy=0.0
	for c in n.get_children():silence(c)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	studio=game.get_node("ToyStudio");studio.set_process(false)
	require(studio.baked_data!=null,"real baked data is required for final captures")
	if studio.baked_data==null:return
	var probe_data: Dictionary=studio.baked_data.get("probe_data")
	readings["baked_probe_points"]=probe_data.get("points",PackedVector3Array()).size()
	readings["baked_probe_sh"]=probe_data.get("sh",PackedColorArray()).size()
	require(readings.baked_probe_points>0 and readings.baked_probe_sh>0,"real rendering backend contains populated probe positions and SH data")
	game.preferences.language="ko";game.preferences.reduced_motion=true
	game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
	game.fighters[0].reset_fight(Vector3(-1.5,0,0.5));game.fighters[1].reset_fight(Vector3(-3.0,0,-3.2))
	game.fighters[1].visual.rotation.y=0.12
	for i in [2,3]:game.fighters[i].set_hidden(true,i)
	game.rig.face(Vector3(-0.36,0,-1));game.rig.pitch=-0.025
	game._process(0);studio._process(0)
	game.ui.toast.text="";game.local_notice="";game.local_notice_time=0;game.ui.message_seconds=0
	studio.set_lighting(0);await shot("old_room")
	studio.set_lighting(1);var direct:=await shot("direct_room")
	studio.set_lighting(2);var indirect:=await shot("gi_room")
	readings["live_room_mean_pixel_difference"]=difference(direct,indirect)
	require(readings.live_room_mean_pixel_difference>0.002,"GI changes actual live-map pixels with the same direct lights")
	game.ui.visible=false;studio.ui_layer.visible=false;game.rig.hand_root.visible=false
	# Hide the whole participant (including sibling name labels), not only its body mesh.
	var old_visibility: Array[bool]=[]
	for a in game.fighters:old_visibility.append(a.visible);a.visible=false
	await shot("gi_empty")
	for i in range(game.fighters.size()):game.fighters[i].visible=old_visibility[i]
	game.fighters[1].visual.visible=true;game.camera.global_position=Vector3(-2.5,0.60,-1.8);game.camera.look_at(Vector3(-3.0,0.12,-3.2))
	studio.update_contacts();await shot("gi_feet")
	game.camera.global_position=Vector3(-7,5.55,1.0);game.camera.look_at(Vector3(-3.2,4.9,-7))
	await shot("gi_upper")
	# Isolate true dynamic probe transport in the existing LIVE bundle: remove all direct and ambient light.
	# Keep only one real mesh target per pair so environment textures cannot fake the result.
	hide_meshes(game.arena)
	for a in game.fighters:hide_meshes(a.visual)
	game.rig.hand_root.visible=false
	silence(game)
	var env: Environment=game.environment_node.environment
	env.background_mode=Environment.BG_COLOR;env.background_color=Color.BLACK
	env.ambient_light_source=Environment.AMBIENT_SOURCE_DISABLED;env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	var body: MeshInstance3D=game.fighters[1].body_art.body
	body.visible=true;game.fighters[1].visual.visible=true
	game.fighters[1].reset_fight(Vector3(-5.0,0,-8.5));game.fighters[1].visual.rotation.y=0
	# reset_fight changes actor art visibility, so isolate the connected body again.
	hide_meshes(game.fighters[1].visual);body.visible=true
	game.camera.global_position=Vector3(-5,1.15,-5.0);game.camera.look_at(Vector3(-5,1.0,-8.5))
	studio.gi.light_data=studio.baked_data;var on:=await shot("probe_body_on")
	studio.gi.light_data=null;var off:=await shot("probe_body_off")
	readings["body_probe_on"]=mean(on);readings["body_probe_off"]=mean(off)
	require(difference(on,off)>0.001,"isolated skinned body visibly receives baked probes, with every direct light off")
	body.visible=false
	var weapon: MeshInstance3D=game.fighters[1].weapon
	weapon.visible=true;reveal_meshes(weapon)
	# Choose a stable ordinary weapon pose; changes belong to this render fixture only.
	game.fighters[1].weapon_pivot.rotation=Vector3(-0.25,-0.4,0)
	studio.gi.light_data=studio.baked_data;on=await shot("probe_weapon_on")
	studio.gi.light_data=null;off=await shot("probe_weapon_off")
	readings["weapon_probe_on"]=mean(on);readings["weapon_probe_off"]=mean(off)
	require(difference(on,off)>0.0002,"isolated world weapon receives real probe illumination")
	weapon.visible=false
	# Actual camera-held drawn weapon, not a second fake demonstration mesh.
	game.camera.transform=Transform3D.IDENTITY
	game.fighters[0].reset_fight(Vector3(-5,0,-8.5));game.rig.face(Vector3.FORWARD)
	game.rig.follow(game.fighters[0],0,false,true);studio.refresh_dynamic(true)
	hide_meshes(game.rig.hand_root);game.rig.view_weapon.visible=true;reveal_meshes(game.rig.view_weapon)
	studio.gi.light_data=studio.baked_data;on=await shot("probe_hand_on")
	studio.gi.light_data=null;off=await shot("probe_hand_off")
	readings["camera_weapon_probe_on"]=mean(on);readings["camera_weapon_probe_off"]=mean(off)
	require(difference(on,off)>0.0002,"actual camera-held weapon receives real probe illumination")
	var file:=FileAccess.open("res://ci-artifacts/lighting15-pixels.json",FileAccess.WRITE);file.store_string(JSON.stringify(readings,"  "));file.close()
	print("LIGHTING15_RENDER_PASS: ",JSON.stringify(readings))
	# New map rebuild restores fixtures and demonstrates the actual player comparison menu.
	game.return_to_menu();game.select_map("toy_manor");await process_frame;await process_frame
	game.ui.visible=true;studio.ui_layer.visible=true;studio._process(0);studio.set_lighting(2)
	studio.panel.popup_centered();await shot("gi_menu");studio.panel.hide()
	game.queue_free();await process_frame
	print("LIGHTING15_CAPTURE_PASS");quit()
