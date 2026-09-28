extends SceneTree
const Scene = preload("res://scenes/phase10.tscn")
const Base = preload("res://scenes/phase9_followup.tscn")
const Surface = preload("res://scripts/graphics/surfaces.gd")
const Materials = preload("res://scripts/renderlab/materials.gd")
const Island = preload("res://scenes/art/sugar_island.scn")
const Maps := ["toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures+=1
	print(("PASS: " if value else "FAIL: ")+label)
func nodes(n: Node) -> int:
	var count:=1
	for c in n.get_children(): count+=nodes(c)
	return count
func physics(n: Node) -> int:
	var count:=1 if n is CollisionObject3D else 0
	for c in n.get_children(): count+=physics(c)
	return count
func fingerprint(arena) -> Dictionary:
	var cells: Array=[]
	for x in range(arena.grid_size.x):
		for y in range(arena.grid_size.y): cells.append(arena.navigation.is_point_solid(Vector2i(x,y)))
	return {"size":arena.dimensions,"active":arena.active_rect,"spots":arena.spots.duplicate(),"ids":arena.active_spots.duplicate(),"obstacles":arena.obstacles.duplicate(),"cells":cells,"physics":physics(arena)}
func lighting(g) -> Dictionary:
	var out: Dictionary={"ambient":g.environment_node.environment.ambient_light_energy,"color":g.environment_node.environment.ambient_light_color}
	for key in ["WarmKey","CoolSoftFill"]:
		var n=g.get_node(key)
		out[key]=[n.transform,n.light_color,n.light_energy,n.shadow_bias,n.shadow_normal_bias,n.shadow_blur,n.directional_shadow_max_distance]
	return out
func state(g) -> Dictionary:
	var out: Dictionary={"hp":g.rules.hp.duplicate(),"score":g.rules.scores.duplicate(),"time":g.rules.time_left,"camera":g.rig.transform,"navigation":fingerprint(g.arena)}
	for i in range(4):
		var a=g.fighters[i]
		out[i]=[a.global_transform,a.weapon.global_transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.elapsed,a.health,a.collision_layer,a.hidden_in_box]
	return out
func finite_meshes(n: Node) -> bool:
	if n is MeshInstance3D and n.mesh!=null:
		for i in range(n.mesh.get_surface_count()):
			var a: Array=n.mesh.surface_get_arrays(i)
			for v in a[Mesh.ARRAY_VERTEX]:
				if not v.is_finite(): return false
	for child in n.get_children():
		if not finite_meshes(child): return false
	return true
func run() -> void:
	var original=Base.instantiate(); root.add_child(original); original.automated=true
	await process_frame; await process_frame
	original.set_process(false)
	var expected: Dictionary={}; var lights: Dictionary={}
	for id in Maps:
		original.select_map(id); await process_frame; await process_frame
		expected[id]=fingerprint(original.arena); lights[id]=lighting(original)
	original.queue_free(); await process_frame; await process_frame
	var materials=Materials.new()
	for kind in ["foam","vinyl","wood","fabric","plaster","ceramic"]:
		var source:=Surface.make(Color("c6d4c1"),kind)
		var snapshot: Array=[source.albedo_color,source.roughness,source.disable_receive_shadows]
		var world:=materials.convert(source,true,false) as ShaderMaterial
		var view:=materials.convert(source,true,true) as ShaderMaterial
		check(world!=null and world.get_shader_parameter("family")==Materials.FAMILIES.find(kind),kind+" custom shader family")
		check(world!=view and not world.get_shader_parameter("view_only") and view.get_shader_parameter("view_only"),kind+" view/world isolation")
		check(materials.convert(source,true,false)==world,kind+" converted resources cached")
		check(snapshot==[source.albedo_color,source.roughness,source.disable_receive_shadows],kind+" original material untouched")
	var ink:=Surface.make(Color("26333d"),"ink")
	check(materials.convert(ink,true,false)==ink,"face ink keeps exact source")
	var shader_text:=FileAccess.get_file_as_string("res://shaders/renderlab/toy_surface.gdshader")
	check("ATTENUATION" in shader_text and not "depth_test_disabled" in shader_text and not "unshaded" in shader_text,"world shader preserves shadow attenuation and depth")
	check(not "VERTEX +=" in shader_text and not "EMISSION =" in shader_text,"no geometry displacement or glowing enemy silhouette")
	var model=Island.instantiate(); root.add_child(model)
	check(physics(model)==0 and finite_meshes(model),"saved editable art has finite meshes and no colliders")
	check(model.get_child_count()>10,"saved scene contains editable separate authored parts")
	model.queue_free(); await process_frame
	var game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await process_frame
	game.set_process(false)
	var studio=game.get_node("ToyStudio")
	check(studio.active and studio.profile==2,"actual entry enables custom studio")
	check(studio.canonical_environment!=null and not studio.canonical_lights.is_empty(),"baseline captured once before studio changes")
	for id in Maps:
		game.select_map(id); await process_frame; await process_frame
		var before:=state(game)
		for mode in [0,1,2,0,2]:
			studio.set_profile(mode)
			check(state(game)==before,id+" mode "+str(mode)+" preserves authority/camera/nav")
		check(fingerprint(game.arena)==expected[id],id+" physics/nav/hideouts unchanged from old scene")
		studio.set_profile(0)
		check(lighting(game)==lights[id],id+" original lighting restored after repeated switches")
		if id=="sugar_market":
			check(is_instance_valid(studio.new_island) and studio.old_island.visible and not studio.extras.visible,"mode A restores original island and hides new dressing")
			studio.set_profile(2)
			check(not studio.old_island.visible and studio.new_island.is_visible_in_tree(),"mode C replaces only visible island art")
			check(physics(studio.extras)==0,"new bakery decoration has no authority collision")
		studio.set_profile(2)
		var n_before:=nodes(game); var revision: int=game.rig.rebuild_count
		for frame in range(30): studio._process(1.0/60)
		check(nodes(game)==n_before and game.rig.rebuild_count==revision,id+" no per-frame mesh/node rebuild")
		game.fighters[1].set_hidden(true,0)
		studio.set_profile(1); studio.set_profile(2)
		check(not game.fighters[1].body_art.is_visible_in_tree() and not game.fighters[1].visual.get_node("ArtContactShadow").is_visible_in_tree(),id+" modes cannot reveal hidden body or shadow")
		game.fighters[1].set_hidden(false)
	# Repeated switching between themed maps must not accumulate key/fill/ambient changes.
	for id in ["sugar_market","starlight_arcade","sugar_market","pocket_station","sugar_market"]:
		game.select_map(id); await process_frame; await process_frame
		studio.set_profile(0)
		check(lighting(game)==lights[id],id+" revisit baseline is idempotent")
		studio.set_profile(2)
	game.start_practice(); game.accept_drawing(); game._process(0)
	await process_frame; await process_frame
	studio._process(0)
	var actor=game.fighters[0]
	var shape: Dictionary=actor.weapon_data.to_dictionary(); var samples: PackedVector3Array=actor.hit_samples.duplicate()
	var grip: Node3D=game.rig.grip_rig.right_hand
	var grip_transform: Transform3D=grip.transform
	var view_mesh: Mesh=game.rig.view_weapon.mesh
	var view_scale: Vector3=game.rig.view_weapon.scale
	for mode in [0,1,2]:
		studio.set_profile(mode)
		check(actor.weapon_data.to_dictionary()==shape and actor.hit_samples==samples,"drawing and samples preserved in mode"+str(mode))
		check(grip.transform.is_equal_approx(grip_transform) and game.rig.view_weapon.mesh==view_mesh and game.rig.view_weapon.scale==view_scale,"round paw and enlarged weapon unchanged in mode"+str(mode))
		check(grip.has_node("RoundPaw") and not grip.has_node("Finger0"),"user-requested simple paw retained mode"+str(mode))
		if mode==2:
			check(game.rig.view_weapon.material_override is ShaderMaterial and actor.weapon.material_override is ShaderMaterial,"both drawn weapon representations use custom material")
			check(game.rig.view_weapon.material_override!=actor.weapon.material_override,"world weapon and camera weapon materials independent")
			check(not actor.weapon.material_override.get_shader_parameter("view_only"),"world weapon retains real light attenuation")
	game.paused=true; studio._process(0)
	check(studio.button.visible,"graphics UI available during explicit pause")
	game.paused=false; studio._process(0)
	check(not studio.button.visible,"graphics UI does not block live combat input")
	check(studio.records.size()<5000 and studio.converter.cache.size()<2048,"bounded typical material/cache population")
	game.queue_free(); await process_frame; await process_frame
	print("STUDIO_UNIT_RESULT: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
