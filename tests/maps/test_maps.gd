extends SceneTree
const Scene = preload("res://scenes/phase7.tscn")
const Catalog = preload("res://scripts/maps/catalog.gd")
const Plans = preload("res://scripts/maps/plans.gd")
const Prefs = preload("res://scripts/phase4/preferences.gd")
const LegacyCatalog = preload("res://scripts/phase3/map_catalog.gd")
const Board = preload("res://scripts/maps/board.gd")
var game
var count := 0
var failures := 0
var metrics: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	count += 1
	if ok: print("PASS: "+label)
	else: failures += 1; printerr("FAIL: "+label)
func run() -> void:
	check(Catalog.IDS.size()==6 and Catalog.NEW_IDS.size()==3,"three original and three new map IDs")
	check(Catalog.spec("invalid").id=="toy_home","unknown ID safely falls back")
	for old in LegacyCatalog.IDS:
		check(Catalog.spec(old)==LegacyCatalog.spec(old),old+" unchanged old metadata")
		check(Catalog.prop_centers(old)==LegacyCatalog.prop_centers(old),old+" unchanged public prop centres")
	game = Scene.instantiate(); root.add_child(game)
	game.automated = true; game.set_physics_process(false); game.set_process(false)
	await physics_frame; await process_frame
	for id in Catalog.NEW_IDS:
		await test_map(id)
	await sound_rules()
	game.return_to_menu(); game.select_map("toy_home")
	await process_frame
	check(game.arena.surface_profile(Vector3.ZERO).noise==1.0,"old maps keep original footstep radius")
	check(game.map_id=="toy_home" and not game.arena.has_meta("map_pack"),"switch back to historical map")
	game.queue_free(); await process_frame; await process_frame
	var file := FileAccess.open("res://ci-artifacts/map-pack-metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"maps":metrics,"note":"Navigation metrics, not human fun/FPS evidence"},"\t")); file.close()
	print("MAP_PACK_UNIT_RESULT: %d checks, %d failures" % [count,failures])
	quit(0 if failures==0 else 1)
func test_map(id: String) -> void:
	game.return_to_menu(); game.select_map(id)
	await physics_frame; await process_frame
	var a = game.arena
	var plan: Dictionary = a.map_plan
	check(game.map_id==id and a.config.id==id,id+" selected via actual menu handler")
	check(a.dimensions==Catalog.spec(id).size,id+" dimensions")
	check(is_equal_approx(game.rules.seeking_seconds,Catalog.spec(id).seek),id+" tailored search time not legacy clamp")
	check(a.spots.size()=={"sugar_market":10,"starlight_arcade":14,"pocket_station":18}[id],id+" intended hideout count")
	check(a.active_spots.size()==a.spots.size(),id+" four-player authored zone uses every hideout")
	var keys: Dictionary = {}
	for item in plan.props+plan.hideouts:
		check(not keys.has(item.id),id+" unique solid "+item.id); keys[item.id] = true
		var body: Node = a.get_node_or_null("Solid_"+item.id)
		check(body is StaticBody3D and body.get_meta("map_prop_id","")==item.id,id+" matching collision "+item.id)
		var footprint := Rect2(item.at-item.size*0.5,item.size)
		check(a.active_rect.encloses(footprint),id+" solid remains inside map "+item.id)
	for spawn in a.spawn_points:
		check(clear_capsule(spawn),id+" spawn capsule clear")
	for pos in [Vector3(-1.65,0,0),Vector3(1.65,0,0),a.escape_point]:
		check(clear_capsule(pos),id+" classic encounter/recovery origin clear")
	var reached := flood(a,a.nearest_id(a.spawn_points[0]))
	var free := 0
	for x in range(a.grid_size.x):
		for y in range(a.grid_size.y):
			if not a.navigation.is_point_solid(Vector2i(x,y)): free+=1
	check(reached.size()==free,id+" all free navigation cells form one component")
	var lengths: Array[float] = []
	for i in range(a.spots.size()):
		var spot: Vector3 = a.spots[i]
		check(a.inside(spot) and clear_capsule(spot),id+" hiding approach %02d has capsule clearance"%i)
		var route: PackedVector2Array = a.path_to(a.spawn_points[0],spot)
		check(not route.is_empty(),id+" hideout %02d reachable"%i)
		check(Vector2(spot.x,spot.z).distance_to(a.origin+Vector2(a.nearest_id(spot)))<0.75,id+" no distant nav snap at %02d"%i)
		var neighbours := 0
		var cell: Vector2i = a.nearest_id(spot)
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q: Vector2i = cell+d
			if a.navigation.region.has_point(q) and not a.navigation.is_point_solid(q): neighbours+=1
		check(neighbours>=2,id+" hideout %02d has multiple adjacent escape cells"%i)
		var dist := 0.0
		for n in range(1,route.size()): dist+=route[n].distance_to(route[n-1])
		lengths.append(dist)
		# Test actual first-person E target and hiding handler at EVERY new hideout.
		game.start_match(false); game.accept_drawing()
		game.fighters[0].reset_fight(spot)
		game.rig.face(Vector3(plan.hideouts[i].at.x,0,plan.hideouts[i].at.y)-spot)
		game.rig.follow(game.fighters[0],0.016,false,false)
		await physics_frame
		check(game._focused_spot()==i,id+" focused E reaches hideout %02d"%i)
		for bot in [1,2,3]: game.fighters[bot].set_hidden(false)
		game._interact()
		check(game.fighters[0].hidden_in_box,id+" E hides player at %02d"%i)
		check(not game.fighters[0].visual.visible,id+" hidden body and attached grounding hidden %02d"%i)
		game._interact()
		check(not game.fighters[0].hidden_in_box,id+" E exits hideout %02d"%i)
	# Seeker uses the same real E action, including hidden-to-reveal transition.
	game.start_match(true); game.accept_drawing(); game.rules.tick(game.rules.hiding_seconds+0.01)
	game.fighters[0].reset_fight(a.spots[0])
	game.fighters[1].reset_fight(a.spots[0]); game.fighters[1].set_hidden(true,0)
	game.rig.face(Vector3(plan.hideouts[0].at.x,0,plan.hideouts[0].at.y)-a.spots[0])
	game.rig.follow(game.fighters[0],0.016,false,false)
	await physics_frame
	game._interact()
	check(game.rules.opponent==1 and game.rules.phase==game.Rules.Phase.REVEAL,id+" seeker E discovers an occupied hideout")
	check(game.fighters[0].position.distance_to(a.spots[0])<0.1,id+" field reveal preserves discovery location")
	# Both sides of the landmark are valid routes, but sight across it is blocked.
	var loop: Array = plan.loop
	for i in range(loop.size()):
		var p: Vector3 = Vector3(loop[i].x,0,loop[i].y)
		var q: Vector3 = Vector3(loop[(i+1)%4].x,0,loop[(i+1)%4].y)
		check(clear_capsule(p) and not a.path_to(p,q).is_empty(),id+" landmark loop leg %d"%i)
	check(not a.has_sight(Vector3(loop[0].x,0,loop[0].y),Vector3(loop[2].x,0,loop[2].y)),id+" landmark breaks direct sight")
	var dims: Vector2 = a.dimensions
	game.return_to_menu(); var fingerprint := str(a.obstacles)+str(a.spots)
	game.set_compact(false); await physics_frame
	check(fingerprint==str(game.arena.obstacles)+str(game.arena.spots),id+" compact toggle does not cut a hand-authored loop")
	game.set_compact(true); await physics_frame
	check(fingerprint==str(game.arena.obstacles)+str(game.arena.spots),id+" map rebuild stable")
	metrics.append({"map":id,"dimensions":[dims.x,dims.y],"hideouts":lengths.size(),"path_lengths_m":lengths,"connected_free_cells":free})
func flood(a, start: Vector2i) -> Dictionary:
	var seen := {start:true}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	while cursor<queue.size():
		var cell := queue[cursor]; cursor+=1
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q: Vector2i = cell+d
			if a.navigation.region.has_point(q) and not a.navigation.is_point_solid(q) and not seen.has(q):
				seen[q]=true; queue.append(q)
	return seen
func clear_capsule(pos: Vector3) -> bool:
	var shape := CapsuleShape3D.new(); shape.radius=0.36; shape.height=1.45
	var query := PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.transform.origin=pos+Vector3.UP*0.75; query.collision_mask=1; query.margin=0.005
	return game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func sound_rules() -> void:
	game.return_to_menu(); game.select_map("sugar_market"); await physics_frame
	game.start_match(false); game.accept_drawing()
	var a = game.fighters[0]
	var z: Dictionary = game.arena.map_plan.zones[0]
	var center: Vector2 = z.rect.get_center()
	var loud := Vector3(center.x,0,center.y)
	var quiet2: Vector2 = game.arena.map_plan.zones[1].rect.get_center()
	var quiet := Vector3(quiet2.x,0,quiet2.y)
	check(is_equal_approx(game.footstep_radius(loud,false),13.2),"noisy lane has defined 13.2m clue radius")
	check(is_equal_approx(game.footstep_radius(quiet,false),4.0),"quiet runner has defined 4m clue radius")
	check(game.footstep_radius(loud,true)<game.footstep_radius(loud,false),"quiet movement reduces terrain noise")
	var baseline: float = game.footstep_radius(loud,false)
	game.audio.volume=0; game.preferences.reduced_motion=true
	check(is_equal_approx(game.footstep_radius(loud,false),baseline),"audio/comfort preferences do not change clue rules")
	check(game.audio.streams.has("chime_step") and game.audio.streams.has("soft_step"),"surface sounds exist")
	check(game.audio.voices.size()==12,"surface sounds retain bounded voice pool")
	a.reset_fight(loud)
	for i in range(8): a.step(0.016,Vector3.ZERO,Vector3.FORWARD); await physics_frame
	check(a.is_on_floor(),"real floor contact for step clue scenario")
	game.fighters[game.rules.seeker].reset_fight(loud+Vector3(9,0,0))
	a.old_position=a.position-Vector3(0.1,0,0); game.foot_distance[0]=1.5; game.heard_time=0
	game._update_actor_events(0)
	check(game.heard_time>0,"real footstep handler emits clue on loud terrain even muted")
	game.heard_time=0; a.set_hidden(true,0); game.foot_distance[0]=1.6
	game._update_actor_events(0)
	check(game.heard_time==0,"hidden actors do not emit phantom footsteps")
	# The public board's exposed input has no actor list or opponent coordinates.
	var board := Board.new(); board.arena=game.arena; board.player_position=Vector3.ZERO
	check(board.get_script().get_base_script().get_path().ends_with("map_board.gd"),"terrain map extends own-position-only board")
	board.free()
