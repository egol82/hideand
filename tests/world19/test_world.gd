extends SceneTree
const Scene=preload("res://scenes/phase19.tscn")
const Old=preload("res://scenes/phase18.tscn")
const Recipes=preload("res://scripts/world19/recipes.gd")
const Maps:=["toy_manor","sugar_market","starlight_arcade","pocket_station","toy_home","warehouse","garden"]
var checks:=0
var failures:=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func colliders(n: Node) -> Array:
	var data: Array=[]
	if n is CollisionShape3D:
		var s=n.shape
		data.append([n.global_transform,str(s.get_class()),s.get("size"),s.get("radius"),s.get("height"),n.disabled])
	for c in n.get_children():data.append_array(colliders(c))
	return data
func map_state(a) -> Array:
	var bits:=PackedByteArray()
	for x in range(a.grid_size.x):
		for y in range(a.grid_size.y):bits.append(int(a.navigation.is_point_solid(Vector2i(x,y))))
	return [a.dimensions,a.active_rect,a.spots.duplicate(),a.active_spots.duplicate(),a.obstacles.duplicate(),colliders(a),bits]
func state() -> Array:
	var s: Array=[game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rules.time_left,game.rig.transform,map_state(game.arena)]
	for a in game.fighters:s.append([a.transform,a.weapon.transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.body_art.body.mesh,a.body_art.body.skin])
	return s
func light_state() -> Array:
	var s: Array=[game.environment_node.environment.ambient_light_energy,game.environment_node.environment.tonemap_mode]
	for k in ["WarmKey","CoolSoftFill"]:
		var n=game.get_node(k);s.append([n.transform,n.light_color,n.light_energy])
	return s
func run() -> void:
	var original: Dictionary={}
	game=Old.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await process_frame;game.set_process(false)
	for id in Maps:
		game.return_to_menu();game.select_map(id);await process_frame;await process_frame
		original[id]=map_state(game.arena)
	game.queue_free();await process_frame;await process_frame
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await process_frame;game.set_process(false)
	var world=game.get_node("World19");var studio=game.get_node("ToyStudio")
	var reports: Array=[]
	check(world.installed,"real new options and component initialized")
	for id in Maps:
		game.return_to_menu();game.select_map(id);await process_frame;await process_frame;world.refresh()
		check(game.arena.map_id==id,id+" actual selection")
		check(original[id]==map_state(game.arena),id+" collision, nav, active bounds and hideouts equal Phase18")
		var before:=state()
		for distance in [0.0,18.0,28.0]:
			world.set_distance(distance);world.set_enabled(false);world.set_enabled(true)
			check(before==state(),id+" detail/range toggles preserve authority "+str(distance))
		if id=="toy_manor":
			check(not is_instance_valid(world.finish_root),"manor retains existing crafted scenery without duplicate batch layer")
			check(studio.baked_data!=null and studio.baked_data.get_user_count()==326,"all existing manor baked users retained")
		else:
			check(world.stats.pieces>40 and world.stats.batches<world.stats.pieces,id+" repeated props really grouped")
			check(colliders(world.finish_root).is_empty(),id+" detail layer adds no collision")
			var finite:=true;var ranges:=true;var total:=0
			for n in world.finish_root.get_children():
				total+=n.multimesh.instance_count
				for i in range(n.multimesh.instance_count):
					if not n.multimesh.get_instance_transform(i).is_finite():finite=false
				if not n.get_meta("small19") and n.visibility_range_end!=0:ranges=false
				if n.get_meta("small19") and n.visibility_range_end!=28:ranges=false
			check(finite and total==world.stats.pieces,id+" finite instance transforms preserve every submitted piece")
			check(ranges,id+" only tagged small detail has a distance cutoff")
			check(Recipes.new().make(id)==Recipes.new().make(id),id+" deterministic recipes independent of occupancy")
			studio.world_lighting=true;studio.set_profile(2,false);var lights:=light_state()
			for i in range(3):studio.set_profile(0,false);studio.set_profile(2,false)
			check(lights==light_state(),id+" light profile restores without accumulating")
			reports.append(world.stats.duplicate())
		var rebuilds: int=world.rebuilds
		for i in range(120):world.refresh()
		check(world.rebuilds==rebuilds,id+" steady frames do not regenerate batches")
		game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1);game._process(0)
		check(game.fighters[1].body_art.skeleton.get_bone_count()==18,id+" original skinned character")
		check(game.rig.view_weapon.scale.is_equal_approx(Vector3.ONE*0.4),id+" proportional lowered weapon retained")
		game.fighters[1].set_hidden(true,0)
		check(not game.fighters[1].body_art.body.is_visible_in_tree(),id+" hidden player stays invisible")
	var file:=FileAccess.open("res://ci-artifacts/world19-batches.json",FileAccess.WRITE);file.store_string(JSON.stringify(reports,"  "));file.close()
	game.queue_free();await process_frame
	print("WORLD19_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
