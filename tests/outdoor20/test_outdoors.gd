extends SceneTree
const Scene=preload("res://scenes/phase20.tscn")
const Baseline=preload("res://scenes/phase19.tscn")
const Plans=preload("res://scripts/outdoor20/plans.gd")
const Catalog=preload("res://scripts/maps/catalog.gd")
var game
var checks:=0
var failures:=0
var metrics: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
func nodes(n: Node) -> int:
	var c:=1
	for child in n.get_children():c+=nodes(child)
	return c
func geometry(a) -> Array:
	var cells: Array=[]
	for x in range(a.grid_size.x):
		for z in range(a.grid_size.y):
			if a.navigation.is_point_solid(Vector2i(x,z)):cells.append(Vector2i(x,z))
	return [a.dimensions,a.active_rect,a.obstacles.duplicate(),a.spots.duplicate(),a.active_spots.duplicate(),cells]
func reachable(a) -> int:
	var queue: Array[Vector2i]=[a.nearest_id(a.spawn_points[0])];var seen: Dictionary={queue[0]:true};var k:=0
	while k<queue.size():
		var at:=queue[k];k+=1
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var n: Vector2i=at+d
			if not a.navigation.region.has_point(n) or seen.has(n) or a.navigation.is_point_solid(n):continue
			seen[n]=true;queue.append(n)
	return seen.size()
func state() -> Array:
	var s: Array=[game.rules.time_left,game.rules.hp.duplicate(),game.rules.scores.duplicate(),geometry(game.arena)]
	for a in game.fighters:s.append([a.transform,a.weapon.global_transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate()])
	return s
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame;game.set_process(false)
	var fx=game.get_node("SmashDirector");var studio=game.get_node("ToyStudio");var world=game.get_node("World19")
	check(Catalog.IDS.size()==9,"nine catalog maps plus dedicated manor equals ten selectable maps")
	var fingerprints: Array=[]
	for id in Plans.IDS:
		game.return_to_menu();game.select_map(id);game.start_match(true);game.accept_drawing()
		await process_frame;await physics_frame;await physics_frame;game._process(0);studio._process(0)
		var a=game.arena
		check(a.map_id==id and a.get_meta("outdoor20",false),id+" actual game loaded the new plan")
		check(a.spots.size()==10 and a.active_spots.size()==10,id+" ten authored hiding locations")
		var solid:=0
		for x in range(a.grid_size.x):
			for z in range(a.grid_size.y):
				if a.navigation.is_point_solid(Vector2i(x,z)):solid+=1
		var free: int=a.grid_size.x*a.grid_size.y-solid
		check(reachable(a)==free,id+" EVERY free navigation cell is connected to spawn")
		fingerprints.append(str(geometry(a)).sha256_text())
		for i in range(a.spawn_points.size()):check(game.hiding.free_point(a.spawn_points[i],i),id+" capsule-clear spawn with actor self excluded")
		for i in range(a.spots.size()):
			var h: Dictionary=game.hiding.homes[i]
			check(game.hiding.free_point(h.entry,-1),id+" capsule-clear floor at entry "+str(i))
			check(h.exits[0].distance_to(h.exits[1])>0.8,id+" genuinely different second exit "+str(i))
			check(game.hiding.free_point(h.exits[1],-1),id+" capsule-clear second exit "+str(i))
			check(a.path_to(a.spawn_points[0],h.entry).size()>1,id+" approach has a connected route "+str(i))
		# Disjoint routes around each authored island/mesa; removing one corridor cell still leaves a detour.
		for loop in a.map_plan.loops:
			var start:=Vector3(loop[0].x,0,loop[0].y);var end:=Vector3(loop[2].x,0,loop[2].y)
			var path: PackedVector2Array=a.path_to(start,end)
			check(path.size()>5,id+" long enough loop approach")
			if path.size()>5:
				var mid: Vector2i=a.nearest_id(Vector3(path[path.size()/2].x,0,path[path.size()/2].y))
				a.navigation.set_point_solid(mid,true)
				check(a.path_to(start,end).size()>5,id+" blocked inner lane still has an alternate route")
				a.navigation.set_point_solid(mid,false)
		var c: Dictionary=a.map_plan.props[0];var at:=Vector3(c.at.x,1.0,c.at.y)
		check(not a.clear_ray(at-Vector3.RIGHT*(c.size.x*0.5+1),at+Vector3.RIGHT*(c.size.x*0.5+1)),id+" landmark really blocks physical line of sight")
		check(a.surface_profile(Vector3(a.surface_zones[0].rect.get_center().x,0,a.surface_zones[0].rect.get_center().y)).noise!=1.0,id+" routes affect inherited step-hearing multiplier")
		# Use real contextual hide/alternate exit, not just a graph assertion.
		var hider: int=1 if game.rules.seeker!=1 else 2
		var home_index:=0
		while not game.hiding.usable(home_index):home_index+=1
		game.fighters[hider].reset_fight(game.hiding.homes[home_index].entry)
		check(game.hiding.hide_actor(hider,home_index),id+" actual hide handler succeeds")
		check(not game.fighters[hider].body_art.body.is_visible_in_tree(),id+" concealment hides connected avatar")
		check(game.hiding.leave(hider,true),id+" actual alternate-exit handler succeeds")
		# Walk a real actor along its AStar route: no teleporting between waypoints.
		var actor=game.fighters[hider];actor.reset_fight(Vector3(-4,0,2));var target: Vector3=a.spots[0]
		var route: PackedVector2Array=a.path_to(actor.position,target);var index:=0
		for step in range(1300):
			if index>=route.size():break
			var goal:=Vector3(route[index].x,0,route[index].y);var delta: Vector3=goal-actor.position;delta.y=0
			if delta.length()<0.23:index+=1;continue
			actor.step(1.0/60,delta.normalized(),delta)
			if step%60==0:await physics_frame
		check(actor.position.distance_to(target)<1.0,id+" real CharacterBody physically follows route to a hideout")
		var layer=a.get_node("OutdoorAccents");var before:=state();var count_before:=nodes(game)
		for distance in [0,18,28]:
			world.set_distance(distance);studio._process(0)
			var good:=true
			for n in layer.get_children():
				if n.visibility_range_end!=(float(distance) if n.get_meta("small19") else 0.0):good=false
			check(good,id+" only small non-cover decoration culled at "+str(distance))
			check(state()==before,id+" distance option never changes cover/hide/weapon authority")
		for i in range(30):studio._process(1.0/60)
		check(nodes(game)==count_before,id+" no steady-frame scene-node growth")
		check(layer.get_meta("batch_count")<layer.get_meta("piece_count"),id+" repeated accents actually grouped into fewer submissions")
		check(nodes(a)<650,id+" bounded arena node count below 650")
		metrics.append({"map":id,"free_cells":free,"arena_nodes":nodes(a),"decor_instances":layer.get_meta("piece_count"),"decor_batches":layer.get_meta("batch_count")})
		# Real input and original practice contact physics in the new arena, not a cosmetic injected event.
		# This isolated contact fixture switches practice mode without calling start_practice (which selects ToyHouse).
		game.practice_mode=true;game.rules.phase=game.Rules.Phase.DUEL;game.rules.opponent=1;game.rules.seeker=0;game.rules.hp[1]=3;game.practice_respawn=0;game.practice.equipped=true;game.last_phase=game.Rules.Phase.DUEL;game.ui.hide_modal()
		for i in [2,3]:game.fighters[i].set_hidden(true,i)
		game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3));game.rig.face(Vector3.BACK);game._process(0)
		var prev: int=fx.handled
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;game._unhandled_input(click)
		for step in range(70):
			game._physics_practice(1.0/60);game._process(1.0/60)
			if fx.handled>prev:break
		check(fx.handled>prev and game.rules.hp[1]==2,id+" real attack still deals one original hit")
		check(game.rig.view_weapon.scale.is_equal_approx(Vector3.ONE*0.40),id+" original drawing-proportional view retained")
		game.practice_mode=false
	check(fingerprints[0]!=fingerprints[1] and fingerprints[1]!=fingerprints[2] and fingerprints[0]!=fingerprints[2],"three distinct physical layouts, not pigment variants")
	# Compare prior seven maps in two scene entries, with no new physics/geometry in the old maps.
	for id in ["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu();game.select_map(id);await process_frame;await physics_frame
		var original=Baseline.instantiate();root.add_child(original);original.automated=true
		await process_frame;await process_frame;original.set_process(false);original.return_to_menu();original.select_map(id)
		await process_frame;await physics_frame
		check(geometry(game.arena)==geometry(original.arena),id+" full obstacle/grid/entry state matches preserved Phase19")
		original.queue_free();await process_frame
	var file:=FileAccess.open("res://ci-artifacts/outdoor20-budget.json",FileAccess.WRITE);file.store_string(JSON.stringify(metrics,"  "));file.close()
	game.queue_free();await process_frame
	print("OUTDOOR20_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
