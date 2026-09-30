extends SceneTree
const Scene=preload("res://scenes/phase17.tscn")
const Kit=preload("res://scripts/environment17/kit.gd")
const Geo=preload("res://scripts/environment17/geometry.gd")
const Bake=preload("res://scripts/lighting15/build_room.gd")
var checks:=0
var failures:=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
func meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D]=[]
	if n is MeshInstance3D:out.append(n)
	for c in n.get_children():out.append_array(meshes(c))
	return out
func physics(n: Node) -> Array:
	var out: Array=[]
	if n is CollisionObject3D:out.append([n.get_path(),n.transform,n.collision_layer,n.collision_mask])
	if n is CollisionShape3D:out.append([n.get_path(),n.transform,n.shape,n.disabled])
	for c in n.get_children():out.append_array(physics(c))
	return out
func authority() -> Array:
	var out: Array=[physics(game.arena),game.rules.phase,game.rules.time_left,game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rng.state,game.arena.spots.duplicate(),game.arena.active_spots.duplicate(),game.rig.transform]
	for a in game.fighters:out.append([a.transform,a.weapon.global_transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.body_art.body.mesh,a.body_art.body.skin])
	for h in game.hiding.homes:out.append([h.at,h.entry,h.exits.duplicate(),h.peek,h.fake])
	return out
func validate_mesh(n: MeshInstance3D) -> bool:
	for i in range(n.mesh.get_surface_count()):
		var a: Array=n.mesh.surface_get_arrays(i)
		var vs: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var ns: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
		if vs.size()!=ns.size() or vs.is_empty():return false
		for j in range(vs.size()):
			if not vs[j].is_finite() or not ns[j].is_finite() or ns[j].length()<0.90 or ns[j].length()>1.1:return false
		if a[Mesh.ARRAY_INDEX]!=null:
			for j in a[Mesh.ARRAY_INDEX]:
				if j<0 or j>=vs.size():return false
	return true
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame
	game.set_process(false)
	var env=game.get_node("Environment17");var studio=game.get_node("ToyStudio")
	env.refresh()
	check(game.arena.map_id=="toy_manor" and env.detail_root!=null,"real manor entry contains crafted room")
	check(env.home_records.size()==12,"all twelve original hiding furniture sites receive crafted art")
	check(studio.baked_data!=null and studio.baked_data.get_user_count()==326,"original populated live lightmap remains attached")
	var signature:=Bake.signature(Bake.fixed_meshes(game.arena))
	check(signature==studio.bundle.get_meta("fixed_signature"),"unchanged baked source signature, no stale fixed-geometry rebake")
	check(physics(env.detail_root).is_empty(),"room decoration adds no new physics")
	var recipes:=["sofa","bed","kitchen","wardrobe","play","bath","home_0","home_1","home_2","home_3","home_4","home_5","window","lamp","wall_art","architecture"]
	var total_triangles:=0;var recipe_metrics: Dictionary={}
	for key in recipes:
		var n:=Kit.make(key);root.add_child(n)
		var list:=meshes(n);var triangles:=0;var valid:=true;var bounds:=AABB();var first:=true
		for m in list:
			if not validate_mesh(m):valid=false
			if first:bounds=m.mesh.get_aabb();first=false
			else:bounds=bounds.merge(m.mesh.get_aabb())
			if m.layers!=1 or m.gi_mode!=GeometryInstance3D.GI_MODE_DYNAMIC:valid=false
			for surface in range(m.mesh.get_surface_count()):
				var a: Array=m.mesh.surface_get_arrays(surface)
				triangles+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size())/3
		check(valid,key+" finite geometry/normals and world-only probe receiving")
		check(list.size()<=12,key+" material-batched draw objects bounded at twelve")
		check(physics(n).is_empty(),key+" has no collision or gameplay object")
		if key.begins_with("home_"):
			check(bounds.position.x>=-0.911 and bounds.end.x<=0.911 and bounds.position.z>=-0.701 and bounds.end.z<=0.801,key+" remains inside authored hide-site visual footprint")
			check(list[0].cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,key+" replacement still casts real direct-light shadows")
			n.set_meta("bound17",bounds)
		recipe_metrics[key]={"mesh_nodes":list.size(),"triangles":triangles,"bounds":str(bounds)};total_triangles+=triangles
		n.queue_free();await process_frame
	var old:=authority();var before_builds: int=Kit.builds;var before_surfaces: int=Geo.built
	for flag in [false,true,false,true]:
		env.set_enabled(flag);env.refresh()
		check(authority()==old,"art toggle preserves rules, colliders, drawing, GI source and RNG "+str(flag))
		check(env.detail_root.visible==flag,"art toggle changes room visuals "+str(flag))
		for record in env.home_records:
			var correct: bool=record.root.get_ref().visible==flag
			for child in record.originals:correct=correct and child.ref.get_ref().visible==(not flag)
			if not correct:push_error("home visibility restoration failed")
		check(game.arena.homes[0].root.get_node("RoundParcel").visible,"original shuffled parcel is never suppressed")
	for i in range(30):env.refresh()
	check(Kit.builds==before_builds and Geo.built==before_surfaces,"steady-frame and toggle loops do not rebuild geometry")
	# Separate material and lighting switches may reapply materials, but cannot lose the art toggle.
	env.set_enabled(false)
	for mode in [0,1,2]:
		studio.set_lighting(mode);env.refresh()
		check(not env.detail_root.visible,"lighting "+str(mode)+" does not override scenery OFF")
	env.set_enabled(true)
	for profile in [0,1,2]:
		studio.set_profile(profile);env.refresh()
		check(env.detail_root.visible,"material "+str(profile)+" retains independently enabled scenery")
		check(Bake.signature(Bake.fixed_meshes(game.arena))==signature,"material switch preserves fixed bake input")
	# All authored sites, exits and fixed paths remain unchanged across randomized rounds.
	for seed in [123,8027,419]:
		game.hiding.configure(seed);var prior:=authority();env.refresh();studio._process(0)
		check(authority()==prior,"seeded rebuilding only replaces nested art "+str(seed))
		check(env.home_records.size()==12,"no accumulated old home decorations "+str(seed))
		var clear:=true
		for h in game.hiding.homes:
			for pos in [h.entry,h.exits[0],h.exits[1]]:
				if not game.hiding.free_point(pos,-1):clear=false
		check(clear,"all 36 entry/exit points remain capsule/floor clear "+str(seed))
		check(Bake.signature(Bake.fixed_meshes(game.arena))==signature,"round shift leaves baked source intact "+str(seed))
	# Hiding does not change the recipe, pigments or visibility; no occupied-box tell.
	var home_meshes:=meshes(game.arena.homes[0].root.get_node("CraftedHome17"));var picture: Array=[]
	for m in home_meshes:picture.append([m.mesh,m.material_override,m.transform,m.visible])
	game.rules.seeker=1;game.rules.alive[0]=true
	game.hiding.homes[0].fake=false;game.fighters[0].position=game.hiding.homes[0].entry
	check(game.hiding.hide_actor(0,0),"actual concealment handler still accepts a free site")
	env.refresh()
	var now: Array=[]
	for m in home_meshes:now.append([m.mesh,m.material_override,m.transform,m.visible])
	check(now==picture and not game.fighters[0].body_art.is_visible_in_tree(),"no art change leaks hidden occupant")
	check(game.hiding.leave(0,true),"second-exit handler remains usable with new art")
	# Every historical map remains available, with no manor details leaking into other maps.
	for id in ["toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station","toy_manor"]:
		game.return_to_menu();game.select_map(id);await process_frame;await process_frame;env.refresh()
		check((env.detail_root!=null)==(id=="toy_manor"),id+" has exactly the intended art scope")
		check(game.arena.map_id==id,id+" selected map not reset to practice")
	var report:={"recipes":recipe_metrics,"total_recipe_triangles":total_triangles,"fixed_signature":signature,"kit_builds":Kit.builds,"surface_builds":Geo.built}
	var f:=FileAccess.open("res://ci-artifacts/environment17-metrics.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	game.queue_free();await process_frame
	print("ENVIRONMENT17_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
