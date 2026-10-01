extends SceneTree
const ResetReady=preload("res://tests/seed21/round_ready.gd")
const Scene=preload("res://scenes/phase21.tscn")
const Old=preload("res://scenes/phase20.tscn")
const OutdoorTests=preload("res://tests/outdoor20/test_outdoors.gd")
const Plans=preload("res://scripts/pine21/services.gd")
const Catalog=preload("res://scripts/maps/catalog.gd")
const MAPS: Array=["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station","pine_hollow","reedwater_bend","amber_canyon"]
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func node_count(n: Node) -> int:
	var total:=1
	for child in n.get_children():total+=node_count(child)
	return total
func normalized_vertices(points: PackedVector3Array) -> Array:
	# Convex resource IDs and point order are not geometry. Pin numeric coordinates
	# at 10 micrometres so independently built resources compare deterministically.
	var vertices: Array=[]
	for p in points:vertices.append([roundi(p.x*100000.0),roundi(p.y*100000.0),roundi(p.z*100000.0)])
	vertices.sort_custom(func(left: Array,right: Array) -> bool:
		for axis in range(3):
			if left[axis]!=right[axis]:return left[axis]<right[axis]
		return false)
	return vertices
func shape_geometry(sh: Shape3D):
	if sh is BoxShape3D:return sh.size
	if sh is ConvexPolygonShape3D:return normalized_vertices(sh.points)
	if sh is CylinderShape3D or sh is CapsuleShape3D:return [sh.radius,sh.height]
	if sh is SphereShape3D:return sh.radius
	push_error("No numeric geometry serializer for "+sh.get_class())
	return null
func geometry(a) -> Array:
	# Compare all authoritative transforms and numeric shape data, never resource IDs.
	var collision: Array=[]
	for n in a.find_children("*","CollisionShape3D",true,false):
		var sh=n.shape
		collision.append([n.global_transform,sh.get_class(),shape_geometry(sh)])
	return [a.spots.duplicate(),a.active_spots.duplicate(),a.obstacles.duplicate(),a.spawn_points.duplicate(),collision]
func fresh(mode: String="field",hider: bool=true) -> void:
	game.return_to_menu();game.select_map("pine_hollow");game.set_mode(mode);game.start_match(not hider);await ResetReady.wait(game);game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-4+i*2,0,3))
	game._process(0)
	await ResetReady.positions(game)
func select_bush() -> int:
	for id in Plans.BUSH_IDS:
		if game.hiding.usable(id):return id
	# Pick another genuine round seed rather than clearing a fake-site rule.
	for seed_value in range(1,10):
		game.hiding.configure(seed_value)
		for id in Plans.BUSH_IDS:
			if game.hiding.usable(id):return id
	return -1
func enter(id: int,spot: int) -> bool:
	game.fighters[id].reset_fight(game.hiding.homes[spot].entry)
	return game.hiding.hide_actor(id,spot)
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame;game.set_process(false)
	var h=game.hiding
	check(h is Plans,"new scene uses the existing hide-service subclass")
	check(Catalog.IDS.size()==9 and (["toy_manor"]+Catalog.IDS).size()==10,"catalog9 plus Manor remains10")
	# All ten arenas retain exactly the same authoritative footprints.
	var baseline=Old.instantiate();root.add_child(baseline);baseline.automated=true
	await process_frame;await process_frame;baseline.set_process(false)
	for id in MAPS:
		game.return_to_menu();game.select_map(id);baseline.return_to_menu();baseline.select_map(id)
		await process_frame;await physics_frame
		check(game.arena.map_id==id,id+" resolves to itself")
		check(geometry(game.arena)==geometry(baseline.arena),id+" same collision,spawn,cover and hide entries as Phase20")
		check(h.pine_active==(id=="pine_hollow"),id+" forest mechanism gate")
		if id!="pine_hollow":
			var original_zones: Array=game.arena.surface_zones.filter(func(z):return not str(z.id).begins_with("wetland21_"))
			check(original_zones==baseline.arena.surface_zones,id+" pre-existing sound zones unchanged; Wetland21 additions checked separately")
	baseline.queue_free();await process_frame
	await fresh();await physics_frame;await physics_frame
	check(game.arena.spots.size()==10 and h.homes.size()==10,"Pine still has ten original hide sites")
	var connected=OutdoorTests.new();var free:=0
	for x in range(game.arena.grid_size.x):
		for y in range(game.arena.grid_size.y):
			if not game.arena.navigation.is_point_solid(Vector2i(x,y)):free+=1
	check(connected.reachable(game.arena)==free,"all free navigation cells remain connected")
	connected.free()
	for i in range(10):
		check(h.free_point(h.homes[i].entry,-1),"entry %d retains clear capsule and floor"%i)
		check(h.free_point(h.homes[i].exits[1],-1),"exit2 %d remains reachable"%i)
	for rect in Plans.LEAF_RECTS:
		var c: Vector2=rect.get_center();var p:=Vector3(c.x,0,c.y)
		check(h.free_point(p,-1),"leaf trail is walkable, not new collision")
		check(game.arena.surface_profile(p).sound=="leaves21","existing audible step path selects rustle")
		check(is_equal_approx(game.footstep_radius(p,false),14.4) and is_equal_approx(game.footstep_radius(p,true),5.4),"walk14.4m vs quiet5.4m through original radius function")
		check(h.free_point(p+Vector3.FORWARD*2,-1),"dry-leaf strip has a walkable bypass")
	var actor=game.fighters[0]
	for quiet in [false,true]:
		await fresh();await physics_frame
		actor.reset_fight(Vector3(-2.8,0,0));h.quiet_distance[0]=0
		if quiet:Input.action_press("hs_quiet")
		for i in range(90):
			actor.step(1.0/60,Vector3.RIGHT*(0.42 if quiet else 0.6),Vector3.RIGHT)
			game._update_actor_events(0)
			if h.track_cursor>0:break
			if i%20==0:await physics_frame
		Input.action_release("hs_quiet")
		check(h.track_cursor==1,"one trace for one genuine step, including quiet="+str(quiet))
		check(h.sounds.size()==1 and h.sounds[0].kind=="leaves","same existing sound queue, not duplicated footstep")
		check(h.tracks[0].get("kind","")=="leaves" and h.leaf_visuals[0].visible,"existing trace pool renders leaf marks")
		var at: Vector3=h.tracks[0].at;var clue: Vector3=h.sounds[0].at
		actor.reset_fight(Vector3(9,0,9));h.tick(0.1)
		check(h.tracks[0].at==at and h.sounds[0].at==clue,"clues snapshot the old step, never follow a player")
		game.paused=true;var clock: float=h.elapsed;h.tick(5)
		check(h.elapsed==clock and h.tracks[0].node.visible,"pause freezes trace lifetime")
		game.paused=false;h.tick(4)
		check(not h.tracks[0].node.visible and h.tracks[0].time<0,"leaf lifetime expires both pixels and investigation")
	# Real tracker tool consumes that existing trace; it does not know current target location.
	await fresh("field",false);await physics_frame
	h.make_track(Vector3(0,0,0),1,"leaves");actor.reset_fight(Vector3(0,0,2));h.skill_index=1
	check(h.investigate() and game.heard_point==Vector3.ZERO,"original tracker skill can inspect a leaf trace")
	# Cosmetic settings cannot remove gameplay clues; hidden/air/teleport do not emit footsteps.
	await fresh();await physics_frame;actor.reset_fight(Vector3(0,0,0))
	for i in range(12):actor.step(1.0/60,Vector3.ZERO,Vector3.FORWARD)
	game.preferences.volume=0;game.preferences.reduced_motion=true;game.preferences.feedback_strength=0
	h.quiet_distance[0]=1.39;actor.old_position=actor.position-Vector3.RIGHT*0.03;h.step_record(0)
	check(h.sounds.size()==1 and h.track_cursor==1,"mute/comfort/effect0 keep the same audible-information rule and visual track")
	var count_before: int=h.track_cursor;actor.set_hidden(true,2);h.step_record(0)
	check(h.track_cursor==count_before,"hidden player emits no step clue")
	actor.set_hidden(false);actor.old_position=actor.position-Vector3.RIGHT*5;h.step_record(0)
	check(h.track_cursor==count_before,"teleport emits no step clue")
	for mode in ["field","classic"]:
		await fresh(mode);await physics_frame;var bush:=select_bush();var entry: Vector3=h.homes[bush].entry
		check(bush>=0 and enter(0,bush),mode+" ordinary hide handler enters a valid bush")
		check(not actor.body_art.body.is_visible_in_tree(),mode+" full body hidden, not emissive/outlining")
		check(not h.hide_actor(game.rules.seeker,bush),mode+" seeker cannot use hider-only concealment")
		h.tick(1.0);var left: float=h.remaining[0]
		game.paused=true;h.tick(8);game.paused=false
		check(is_equal_approx(left,h.remaining[0]),mode+" pause freezes bush budget")
		check(h.leave(0,true),mode+" inherited second exit works")
		check(enter(0,bush) and is_equal_approx(left,h.remaining[0]),mode+" re-entry cannot refresh shared time budget")
		h.tick(3.2)
		check(not actor.hidden_in_box and h.remaining[0]==0 and actor.collision_layer==2,mode+" expiry restores target/collider within four active seconds")
		check(not enter(0,bush),mode+" exhausted bush rejects re-entry")
		var normal:=-1
		for home in h.homes:
			if home.id not in Plans.BUSH_IDS and h.usable(home.id):normal=home.id;break
		check(enter(0,normal),mode+" ordinary cover unaffected by shrub budget")
		h.leave(0)
		# Direct search uses same existing 0.65s action and REVEAL/DUEL pipeline.
		await fresh(mode);await physics_frame;bush=select_bush();check(enter(0,bush),mode+" reconfigured round resets four-second allowance")
		var hunter=game.fighters[game.rules.seeker];hunter.reset_fight(h.homes[bush].entry+Vector3.BACK*1.7)
		game._inspect(game.rules.seeker,bush);check(h.inspecting.has(game.rules.seeker),mode+" existing timed inspection starts")
		h.tick(0.7);check(game.rules.phase==game.Rules.Phase.REVEAL and game.rules.opponent==0,mode+" inspection defeats concealment via original discover")
		game.rules.tick(game.rules.time_left+0.01)
		check(game.rules.phase==game.Rules.Phase.DUEL and not actor.hidden_in_box,mode+" discovered bush occupant is normally hittable in duel")
		# Resolve using unchanged round hit API, not a new capture shortcut.
		var hits: Array[int]=[game.rules.seeker]
		for i in range(3):game.rules.register_hits(hits)
		check(not game.rules.alive[0],mode+" original three-hit capture rule still resolves")
	# Block both exits: time limit still exposes at its present position; no clipping teleport.
	await fresh();await physics_frame;var bush:=select_bush();check(enter(0,bush),"blocked-exit setup enters")
	var before: Vector3=actor.position
	var blockers: Array=[]
	for exit_at in h.homes[bush].exits:
		var b:=StaticBody3D.new();b.collision_layer=2;game.add_child(b)
		var c:=CollisionShape3D.new();var sh:=BoxShape3D.new();sh.size=Vector3(0.4,1.2,0.4);c.shape=sh;b.add_child(c);b.position=exit_at+Vector3.UP*0.8;blockers.append(b)
	await physics_frame;await physics_frame;h.tick(4.1)
	check(not actor.hidden_in_box and actor.position==before and h.remaining[0]==0,"blocked exits cannot extend hiding or teleport actor into another point")
	for b in blockers:b.queue_free()
	await physics_frame;await process_frame
	# Repeated seeds reset budgets but never duplicate geometry or zones. No new seed variation yet.
	await fresh();await physics_frame;var nodes_before:=node_count(game.arena)
	for seed_value in [7,7,91]:
		h.configure(seed_value)
		check(node_count(game.arena)==nodes_before,"round reset reuses forest art, seed="+str(seed_value))
		check(game.arena.surface_zones.size()==5 and h.remaining==[4.0,4.0,4.0,4.0],"round reset restores budget and exactly two leaf zones")
	check(h.tracks.size()==24 and h.sounds.size()<=32,"trace/sound pools remain bounded")
	var original_nodes:=node_count(game)
	for i in range(100):h.make_track(Vector3(0,0,0),0,"leaves")
	check(node_count(game)==original_nodes and h.tracks.size()==24,"many leaf steps reuse original pool, no per-step scene allocation")
	h.remaining[1]=0;game.hide_assignments[1]=Plans.BUSH_IDS[0];game._hide_bot(1,0.016)
	check(game.hide_assignments[1] not in Plans.BUSH_IDS,"bot chooses existing other cover when shrub budget exhausted")
	game.queue_free();await process_frame
	print("PINE21_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
