extends SceneTree
const Scene=preload("res://scenes/phase21.tscn")
const Old=preload("res://scenes/phase20.tscn")
const Plans=preload("res://scripts/seed21/layouts.gd")
const Layout=preload("res://scripts/seed21/round_layout.gd")
const Helpers=preload("res://tests/pine21/test_pine.gd")
const Maps: Array=["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station","pine_hollow","reedwater_bend","amber_canyon"]
var game
var checks:=0
var failures:=0
var evidence: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func count(n: Node) -> int:
	var result:=1
	for c in n.get_children():result+=count(c)
	return result
func authority() -> Array:
	var a: Array=[game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rules.time_left,game.rules.phase,game.rules.alive.duplicate(),game.rng.state,game.camera.transform,game.hiding.seed_value]
	for f in game.fighters:a.append([f.transform,f.velocity,f.weapon.transform,f.weapon_data.to_dictionary(),f.hit_samples.duplicate(),f.body_art.body.mesh,f.body_art.body.skin])
	return a
func empty_spawns() -> void:
	for i in range(4):game.fighters[i].reset_fight(Vector3(-game.arena.dimensions.x*0.5+1.2+i*1.25,0,game.arena.dimensions.y*0.5-1.2))
func plain(arena) -> Array:
	var h:=Helpers.new();var p:=h.geometry(arena);h.free();return p
func witness(p: Dictionary,base_grid: AStarGrid2D) -> Dictionary:
	var a=game.arena
	for center in p.positions:
		for axis in [Vector2.RIGHT,Vector2.DOWN]:
			for shift in [-1.0,0.0,1.0]:
				for distance in [2.0,3.0,4.0]:
					var origin: Vector2=center+Vector2(axis.y,axis.x)*shift
					var start: Vector2=origin-axis*distance;var end: Vector2=origin+axis*distance
					var si:=Vector2i((start-a.origin).round());var ei:=Vector2i((end-a.origin).round())
					if not base_grid.region.has_point(si) or not base_grid.region.has_point(ei):continue
					if base_grid.is_point_solid(si) or base_grid.is_point_solid(ei) or a.navigation.is_point_solid(si) or a.navigation.is_point_solid(ei):continue
					var old_path:=base_grid.get_point_path(si,ei);var new_path: PackedVector2Array=a.navigation.get_point_path(si,ei)
					if old_path.size()>0 and new_path.size()>old_path.size():
						return {"from":Vector3(old_path[0].x,0,old_path[0].y),"to":Vector3(old_path[-1].x,0,old_path[-1].y),"before_edges":old_path.size()-1,"after_edges":new_path.size()-1,"path":new_path}
	return {}
func walk_path(path: PackedVector2Array) -> bool:
	var actor=game.fighters[0];actor.reset_fight(Vector3(path[0].x,0,path[0].y))
	var destination:=1
	for step in range(600):
		if destination>=path.size():return true
		var target:=Vector3(path[destination].x,0,path[destination].y);var move: Vector3=target-actor.position;move.y=0
		if move.length()<0.20:destination+=1;continue
		actor.step(1.0/60,move.normalized(),move)
		if step%80==0:await physics_frame
	return false
func run() -> void:
	# Pure, versioned selection: even interleaved unrelated random calls cannot move the sockets.
	for mid in Plans.IDS:
		var all: Dictionary={}
		for seed_value in [0,1,17,8027,-2147483648,9223372036854775807]:
			var seen: Dictionary={};var same:=true
			for r in range(9):
				var p:=Plans.plan(mid,seed_value,r);var rng:=RandomNumberGenerator.new();rng.seed=seed_value
				for j in range(20):rng.randi()
				same=same and p==Plans.plan(mid,seed_value,r)
				seen[str(p.positions)]=true;all[p.index]=true
			check(same,mid+" same input independent of random calls seed="+str(seed_value))
			check(seen.size()==9,mid+" nine real positions over nine rounds seed="+str(seed_value))
		var seed_variants: Dictionary={}
		for s in range(20):seed_variants[Plans.plan(mid,s,0).index]=true
		check(seed_variants.size()==9 and all.size()==9,mid+" different seeds reach all nine combinations")
	check(Plans.plan("toy_home",123,0).is_empty() and Plans.plan("pine_hollow",1,-1).is_empty(),"unsupported map/negative round rejected")
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await physics_frame;game.set_process(false)
	var baseline=Old.instantiate();root.add_child(baseline);baseline.automated=true
	await process_frame;await process_frame;baseline.set_process(false)
	for mid in Maps:
		game.return_to_menu();game.select_map(mid);baseline.return_to_menu();baseline.select_map(mid)
		await process_frame;await physics_frame
		check(plain(game.arena)==plain(baseline.arena),mid+" entire original numeric geometry retained in staging")
		check(not game.round_layout.applied,mid+" no new blockers appear in the menu")
		if mid not in Plans.IDS:
			baseline.rng.seed=game.rng.seed;game.start_match(true);baseline.start_match(true);await process_frame
			check(not game.round_layout.applied and plain(game.arena)==plain(baseline.arena),mid+" original map unchanged in a real round")
	baseline.queue_free();await process_frame
	var layout=game.round_layout
	for mid in Plans.IDS:
		game.return_to_menu();game.select_map(mid);game.rng.seed=8027;game.start_match(true)
		await process_frame;await physics_frame
		check(layout.applied and layout.descriptor.seed==8027 and layout.descriptor.round==0,mid+" inherited round callback applies actual seed")
		empty_spawns();await physics_frame
		layout.park();var original_geometry:=plain(game.arena);var original_grid:=Layout.grid_for(game.arena,[])
		var stable_count:=count(game);var found: Dictionary={}
		for r in range(9):
			game.rules.round_index=r
			game.hiding.configure(8027+r*991)
			var before:=authority();var p:=Plans.plan(mid,8027,r)
			check(layout.apply_round(8027,r),mid+" validated real placement "+p.id)
			await physics_frame
			check(authority()==before,p.id+" layout writes no random state/actor/weapon/rule state")
			check(Layout.fully_connected(game.arena.navigation),p.id+" all walkable grid cells connected")
			var ports:=true
			for home in game.hiding.homes:
				ports=ports and game.hiding.free_point(home.entry,-1)
				for exit_point in home.exits:ports=ports and game.hiding.free_point(exit_point,-1)
			for spawn in game.arena.spawn_points:ports=ports and game.hiding.free_point(spawn,-1)
			check(ports,p.id+" all original spawns/entries/both exits capsule-clear")
			var hit:=false
			for at in p.positions:
				var a:=Vector3(at.x-1.5,1.0,at.y);var b:=Vector3(at.x+1.5,1.0,at.y)
				hit=hit or not game.arena.clear_ray(a,b)
			check(hit,p.id+" real cover changes line of sight, not just color")
			var choice:=witness(p,original_grid)
			check(not choice.is_empty(),p.id+" safe alternate route actually differs in path length")
			if not choice.is_empty():
				evidence.append({"map":mid,"layout":p.id,"before_edges":choice.before_edges,"after_edges":choice.after_edges})
				if r==0:
					check(await walk_path(choice.path),mid+" unmodified CharacterBody walks the new detour")
					empty_spawns();await physics_frame
			var stamp: Dictionary=layout.descriptor.duplicate(true)
			check(layout.apply_round(8027,r) and layout.descriptor==stamp,p.id+" repeated input restores identical transforms/fingerprint")
			check(count(game)==stable_count and layout.root.find_children("*","CollisionObject3D",true,false).size()==2,p.id+" exactly two pooled bodies, no accumulation")
			check(game.arena.obstacles.size()==original_geometry[2].size()+2,p.id+" exactly two conservative navigation additions")
			found[str(layout.descriptor.positions)]=true
			layout.park()
		check(found.size()==9,mid+" all nine collision-safe choices really applied")
		# Mid-round calls cannot close a route on an active player.
		game.rules.round_index=0;layout.apply_round(8027,0);game.accept_drawing();await physics_frame
		var snapshot: Dictionary=layout.descriptor.duplicate(true);var before:=authority()
		check(not layout.apply_round(9000,2) and layout.descriptor==snapshot and authority()==before,mid+" active-play layout mutation refused atomically")
		game.paused=true;check(not layout.apply_round(8,2) and layout.descriptor==snapshot,mid+" pause never swaps props");game.paused=false
		# A new match restores budgets/traces and uses the original fake-home seed rule.
		game.return_to_menu();game.select_map(mid);game.rng.seed=17;game.start_match(false);await physics_frame
		check(layout.applied and layout.descriptor.seed==17 and game.hiding.seed_value==17,mid+" new match resets reproducible round seed")
		check(game.hiding.sounds.is_empty() and game.hiding.transit.is_empty() and game.hiding.remaining==[4.0,4.0,4.0,4.0],mid+" old clue/transit/Pine allowance reset intact")
		check(game.hiding.wet_until==[-1.0,-1.0,-1.0,-1.0] and game.hiding.lane_ready==[0.0,0.0,0.0,0.0],mid+" wet allowance and canyon cooldown reset intact")
		# Deterministic safe failure for an unexpected occupied candidate (never move an occupant).
		layout.park();var p:=Plans.plan(mid,17,0);var at: Vector2=p.positions[0]
		var blocker:=StaticBody3D.new();blocker.collision_layer=2;game.add_child(blocker)
		var cs:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3.ONE;cs.shape=shape;blocker.add_child(cs);blocker.position=Vector3(at.x,0.7,at.y)
		await physics_frame;await physics_frame
		check(not layout.apply_round(17,0) and not layout.applied and layout.last_rejection=="occupied socket",mid+" occupied socket refuses placement without moving anything")
		blocker.queue_free();await physics_frame;await process_frame
		check(layout.apply_round(17,0) and layout.descriptor.id==p.id,mid+" clear retry keeps the exact selected template")
	# No additional leaf/water/reed/gust timing or damage API was introduced here.
	var f:=FileAccess.open("res://ci-artifacts/seed21-route-evidence.json",FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"  "));f.close()
	game.queue_free();await process_frame
	print("SEED21_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
