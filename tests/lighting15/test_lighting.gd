extends SceneTree
const Scene=preload("res://scenes/phase15.tscn")
const Build=preload("res://scripts/lighting15/build_room.gd")
const OldTests=preload("res://tests/material14/test_materials.gd")
const Data=preload("res://scripts/phase4/drawing_data.gd")
const Maps:=["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func physics(n: Node) -> Array:
	var data: Array=[]
	if n is CollisionObject3D:data.append([n.get_path(),n.global_transform,n.collision_layer,n.collision_mask])
	if n is CollisionShape3D:data.append([n.get_path(),n.global_transform,n.shape,n.disabled])
	for child in n.get_children():data.append_array(physics(child))
	return data
func authority(g) -> Array:
	var data: Array=[g.rules.time_left,g.rules.scores.duplicate(),g.rules.hp.duplicate(),g.rules.phase,physics(g.arena),g.arena.spots.duplicate(),g.rig.transform]
	for actor in g.fighters:data.append([actor.transform,actor.weapon.global_transform,actor.weapon_data.to_dictionary(),actor.hit_samples.duplicate(),actor.body_art.body.mesh,actor.body_art.body.skin])
	return data
func light_state(g,s) -> Array:
	var out: Array=[g.environment_node.environment.ambient_light_energy,g.environment_node.environment.ambient_light_color]
	for n in s.bundle.get_node("AuthoredLights").get_children():out.append([n.transform,n.light_color,n.light_energy,n.shadow_enabled])
	return out
func meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D]=[]
	if n is MeshInstance3D:out.append(n)
	for c in n.get_children():out.append_array(meshes(c))
	return out
func run() -> void:
	var game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	var studio=game.get_node("ToyStudio")
	var allow: bool="--allow-unbaked" in OS.get_cmdline_user_args()
	check(studio.active and studio.lighting_mode==2,"new entry selects live manor GI mode")
	check(game.arena.map_id=="toy_manor","representative playable manor is loaded")
	check(studio.bundle.get_parent()==game.arena,"baked scene is inside live gameplay, not a review-only scene")
	check(studio.bundle.get_meta("excludes_round_furniture",false),"baked scene excludes seeded movable hiding furniture")
	check(studio.gi!=null,"actual LightmapGI node loaded")
	if not allow:
		check(studio.baked_data!=null,"actual baked LightmapGIData exists")
		if studio.baked_data==null:quit(1);return
		check(studio.baked_data.get_user_count()==Build.fixed_meshes(game.arena).size(),"every fixed source has a populated baked user")
		check(studio.baked_data.get_lightmap_textures().size()>0,"baked lightmap texture array exists")
		var valid:=true
		for i in range(studio.baked_data.get_user_count()):
			var n=studio.bundle.get_node_or_null(studio.baked_data.get_user_path(i))
			if not n is MeshInstance3D:valid=false
		check(valid,"all baked user paths resolve inside the instantiated gameplay scene")
		var probes=studio.baked_data.get("probe_data")
		check(probes is Dictionary and not probes.is_empty(),"engine-generated probe data is populated")
		var file:=FileAccess.open("res://ci-artifacts/lighting15-probe-keys.txt",FileAccess.WRITE);file.store_string(str(probes.keys()));file.close()
	var source:=Build.fixed_meshes(game.arena)
	check(source.size()==326,"326 fixed meshes; no randomized cabinet or actor in static bake")
	check(studio.bundle.get_meta("fixed_signature")==Build.signature(source),"geometry and original pigments match baked snapshot")
	var uv_ok:=true
	for n in studio.bundle.get_children():
		if not n is MeshInstance3D:continue
		for surface in range(n.mesh.get_surface_count()):
			var a=n.mesh.surface_get_arrays(surface)
			if a[Mesh.ARRAY_TEX_UV2]==null or a[Mesh.ARRAY_TEX_UV2].size()!=a[Mesh.ARRAY_VERTEX].size():uv_ok=false;continue
			for uv in a[Mesh.ARRAY_TEX_UV2]:
				if not uv.is_finite() or uv.x<0 or uv.y<0 or uv.x>1.00001 or uv.y>1.00001:uv_ok=false
	check(uv_ok,"all static vertices retain valid finite in-range UV2")
	check(physics(studio.bundle).is_empty(),"lighting scene has no physics authority")
	var old_ambient: float=0.0
	for mode in [0,1,2,0,2,1,2]:
		var before:=authority(game)
		studio.set_lighting(mode);studio._process(0)
		check(authority(game)==before,"mode %d preserves physics, drawings, timing, camera and skeleton"%mode)
		check(studio.bundle.visible==(mode>0),"mode %d toggles only new visual bundle"%mode)
		check(source[0].visible==(mode==0),"mode %d prevents duplicate floor geometry"%mode)
		check(studio.gi.light_data==(studio.baked_data if mode==2 else null),"mode %d really switches lightmap/probe resource"%mode)
	studio.set_lighting(1);var lights:=light_state(game,studio)
	studio.set_lighting(2)
	check(light_state(game,studio)==lights,"GI off/on use identical direct lights and environment")
	for gen in [1,2]:
		studio.set_material_generation(gen)
		check(light_state(game,studio)==lights,"material generation %d does not accumulate lighting"%gen)
	studio.set_profile(0);check(studio.lighting_mode==2,"material and lighting selections are independent")
	studio.set_profile(2)
	for actor in game.fighters:
		check(actor.body_art.body.gi_mode==GeometryInstance3D.GI_MODE_DYNAMIC,"skinned actor %d receives probes"%actor.player_id)
		check(actor.weapon.gi_mode==GeometryInstance3D.GI_MODE_DYNAMIC,"world weapon %d receives probes"%actor.player_id)
		check(actor.body_art.skeleton.get_bone_count()==18,"eighteen-bone avatar %d preserved"%actor.player_id)
		actor.set_hidden(true,0);studio.update_contacts()
		check(not actor.body_art.body.is_visible_in_tree() and not actor.visual.get_node("Grounding15L").is_visible_in_tree(),"hidden actor %d has no body or contact-shadow leak"%actor.player_id)
		actor.set_hidden(false)
	for seed in [123,8027,419]:
		var old_bundle: int=studio.bundle.get_instance_id()
		game.arena.set_layout(seed);studio._process(0)
		check(studio.bundle.get_instance_id()==old_bundle,"seed %d reuses fixed bake rather than stale cabinet shadows"%seed)
		check(Build.signature(Build.fixed_meshes(game.arena))==studio.bundle.get_meta("fixed_signature"),"seed %d leaves baked geometry fixed"%seed)
		var dynamic_ok:=true
		for mesh in meshes(game.arena.furnishings):
			if not mesh.name.begins_with("Grounding15") and mesh.gi_mode!=GeometryInstance3D.GI_MODE_DYNAMIC:dynamic_ok=false
		check(dynamic_ok,"seed %d movable furniture receives probes"%seed)
	game.return_to_menu();game.start_match(true);game.accept_drawing();game._process(0);studio._process(0)
	var actor=game.fighters[0]
	for kind in ["fish","pan","hammer"]:
		var drawing=Data.new();drawing.set_preset(kind);actor.equip(drawing);game._process(0);studio._process(0)
		check(game.rig.view_weapon.gi_mode==GeometryInstance3D.GI_MODE_DYNAMIC,kind+" re-equipped camera weapon receives probes")
		check(actor.weapon.gi_mode==GeometryInstance3D.GI_MODE_DYNAMIC,kind+" new world weapon receives probes")
		check(game.rig.view_weapon.scale.is_equal_approx(Vector3.ONE*0.40),kind+" retains proportional display scale")
		check(actor.weapon_data.to_dictionary()==drawing.to_dictionary(),kind+" preserves original drawn data")
	var before:=authority(game);var builds: int=game.rig.rebuild_count
	for i in range(30):studio._process(1.0/60)
	check(authority(game)==before and game.rig.rebuild_count==builds,"lighting frames do not rebuild hands or change game state")
	studio.contact_support=false;studio.update_contacts()
	check(not game.fighters[1].visual.get_node("Grounding15R").visible,"contact supplement can be disabled independently")
	studio.contact_support=true;studio.update_contacts()
	for id in Maps:
		game.return_to_menu();game.select_map(id);await process_frame;await process_frame;studio._process(0)
		var original:=authority(game);studio.set_lighting(1);studio.set_lighting(2)
		check(authority(game)==original,id+" keeps gameplay through lighting selection")
		check((studio.bundle!=null)==(id=="toy_manor"),id+" only manor gets the new lighting bundle")
		if id!="toy_manor":check(studio.lighting_choice.disabled,id+" honestly disables manor-only comparison")
	game.queue_free();await process_frame
	print("LIGHTING15_UNIT_RESULT: %d checks, %d failures"%[checks,failures])
	if allow:print("LIGHTING15_UNBAKED_CANDIDATE_ONLY")
	quit(0 if failures==0 else 1)
