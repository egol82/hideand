extends SceneTree
const Scene=preload("res://scenes/phase21.tscn")
const Service=preload("res://scripts/canyon21/services.gd")
const PineTests=preload("res://tests/pine21/test_pine.gd")
const OutdoorTests=preload("res://tests/outdoor20/test_outdoors.gd")
const MAPS: Array=["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station","pine_hollow","reedwater_bend","amber_canyon"]
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func fresh(mode: String="field",seeker: bool=true) -> void:
	game.return_to_menu();game.select_map("amber_canyon");game.set_mode(mode);game.start_match(seeker);game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.5,0,15))
	game.preferences.reduced_motion=false;game.preferences.volume=0.5;game.preferences.feedback_strength=1
	game._process(0)
func settle(id: int,p: Vector3) -> void:
	var a=game.fighters[id];a.reset_fight(p)
	for i in range(12):a.step(1.0/60,Vector3.ZERO,Vector3.BACK)
func authority() -> Array:
	var result: Array=[game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rules.time_left,game.rules.phase,game.camera.transform,game.rig.yaw,game.rig.pitch]
	for a in game.fighters:result.append([a.transform,a.velocity,a.weapon.transform,a.hit_samples.duplicate(),a.weapon_data.to_dictionary(),a.collision_layer,a.collision_mask])
	return result
func count(n: Node) -> int:
	var result:=1
	for c in n.get_children():result+=count(c)
	return result
func toy_poses() -> Array:
	var result: Array=[]
	for i in range(2):
		for j in range(4):result.append(game.hiding.canyon_art.get_node("WindPad%d/WindToy%d"%[i,j]).transform)
	return result
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame;game.set_process(false)
	var h=game.hiding
	check(h is Service,"live scene uses Canyon over preserved Wet/Pine services")
	# Numeric original footprints, not permissive count-only map checks.
	var old=preload("res://scenes/phase20.tscn").instantiate();root.add_child(old);old.automated=true
	await process_frame;await process_frame;old.set_process(false)
	var helpers=PineTests.new()
	for mid in MAPS:
		game.return_to_menu();game.select_map(mid);old.return_to_menu();old.select_map(mid)
		await process_frame;await physics_frame
		check(game.arena.map_id==mid and old.arena.map_id==mid,mid+" identity retained")
		check(helpers.geometry(game.arena)==helpers.geometry(old.arena),mid+" original colliders/spawns/cover/entries unchanged")
		check(h.canyon_active==(mid=="amber_canyon"),mid+" canyon service is opt-in")
	old.queue_free();helpers.free();await process_frame
	fresh();await physics_frame;await physics_frame
	check(h.canyon_art.find_children("*","CollisionObject3D",true,false).is_empty(),"new lane and eight wind toys add no physical barriers")
	check(h.canyon_art.find_children("WindToy*","Node3D",true,false).size()==8,"wind toys are a fixed pool of eight")
	var conn=OutdoorTests.new();var free:=0
	for x in range(game.arena.grid_size.x):
		for y in range(game.arena.grid_size.y):
			if not game.arena.navigation.is_point_solid(Vector2i(x,y)):free+=1
	check(conn.reachable(game.arena)==free,"all original free navigation cells remain connected")
	conn.free()
	for home in h.homes:
		check(h.free_point(home.entry,-1),"home%d entry capsule and floor clear"%home.id)
		for endpoint in home.exits:check(h.free_point(endpoint,-1),"home%d exit capsule and floor clear"%home.id)
	for p in game.arena.spawn_points:check(h.free_point(p,-1),"original spawn remains free")
	for i in range(2):
		check(h.lane(i).has("label") and h.lane(i).has("id"),"canonical lane includes the original passage UI contract")
		check(h.free_point(Service.LANE_ENDS[i],-1),"lane%d access is on reachable open floor"%i)
		for side in [-1,1]:check(h.free_point(Service.LANE_ENDS[i]+Vector3(side*1.7,0,0),-1),"lane endpoint has a walkable side escape")
	# Interact prioritizes passages. Keep its trigger out of every hideout inspection radius.
	for home in h.homes:
		for endpoint in Service.LANE_ENDS:
			check(endpoint.distance_to(home.entry)>3.2,"home%d interaction and lane prompt never overlap"%home.id)
	settle(0,h.homes[9].entry+Vector3.BACK*1.5)
	game.rig.face(Vector3.FORWARD);game._process(0)
	check(h.passage(0).is_empty(),"nearby original hideout has no competing lane prompt")
	check(game._focused_spot()==9,"original front-facing hideout selection remains available")
	game._interact()
	check(h.inspecting.has(0) and not h.transit.has(0),"original Interact inspects hideout rather than hijacking it for travel")
	h.inspecting.clear()
	settle(0,Service.LANE_ENDS[0])
	for language in ["ko","en"]:
		game.preferences.language=language;game.ui.refresh(game.rules)
		check(h.lane(0).label in game.ui.action_hint.text,language+" native inherited HUD reads the real passage without missing keys")
	game.preferences.language="ko"
	check(h.clear_sweep(Service.LANE_ENDS[0],Service.LANE_ENDS[1],0),"full fast corridor has capsule clearance")
	check(game.arena.clear_ray(Service.LANE_ENDS[0]+Vector3.UP,Service.LANE_ENDS[1]+Vector3.UP),"rider takes an actually exposed straight corridor")
	# Actual old walking vs fixed-duration traversal, not a renamed existing route.
	var walking:=0.0
	for i in range(360):
		game.fighters[0].step(1.0/60,Vector3.BACK,Vector3.BACK);walking+=1.0/60
		if game.fighters[0].position.z>=Service.LANE_ENDS[1].z-0.1:break
	check(walking>Service.LANE_SECONDS*1.35 and walking<6,"original real walking is slower than the new1.35s lane")
	print("CANYON21_WALK_SECONDS: ",walking)
	for mode in ["field","classic"]:
		for seeker in [true,false]:
			fresh(mode,seeker);await physics_frame;settle(0,Service.LANE_ENDS[0])
			var original_hp=game.rules.hp.duplicate();var original_grace=game.rules.grace.duplicate()
			# Invoke the original E interaction handler rather than inserting a transit job.
			game._interact()
			check(h.transit.has(0),mode+str(seeker)+" original interaction starts the exposed passage")
			if not h.transit.has(0):continue
			game._process(0)
			check(game.ui.action_hint.visible and "EXPOSED CROSSING" in game.ui.action_hint.text,"live passage HUD remains visibly informative while crossing")
			check(h.sounds.size()==1 and h.sounds[0].kind=="lane21" and h.sounds[0].radius==18,mode+str(seeker)+" one public loud launch event")
			check(not game.fighters[0].hidden_in_box and game.fighters[0].collision_layer==2 and game.rules.grace==original_grace,"rider stays hittable, no concealment or grace grant")
			var at=game.fighters[0].position;h.tick(0.3)
			check(game.fighters[0].position.z>at.z and h.transit.has(0),"existing transit actually moves rider on route")
			game.paused=true;at=game.fighters[0].position;var clock: float=h.elapsed;h.tick(7)
			check(game.fighters[0].position==at and h.elapsed==clock,"pause freezes travel, wind and cooldown clock")
			game.paused=false;h.tick(1.06)
			check(not h.transit.has(0) and game.fighters[0].position.distance_to(Service.LANE_ENDS[1])<0.001,"passage reaches its exact clear exit")
			check(not h.travel(0,h.lane(1)) and h.lane_ready[0]>h.elapsed,"round-trip spam is limited by shared per-actor8s cooldown")
			check(game.rules.hp==original_hp and game.rules.grace==original_grace,"travel adds no damage, healing or invulnerability")
			h.tick(2.01)
			check(h.tracks[0].time<0 and not h.tracks[0].node.visible,"launch clue expires visually and for investigation")
			check(h.sounds.filter(func(s):return s.kind=="lane21").is_empty(),"lane launch/landing sounds expire without tracking the rider")
		# Original hide -> timed inspect -> duel/capture still works in canyon.
		fresh(mode);await physics_frame
		var spot:=-1
		for home in h.homes:
			if h.usable(home.id):spot=home.id;break
		settle(1,h.homes[spot].entry)
		check(h.hide_actor(1,spot),mode+" original hide handler remains available")
		check(h.leave(1,true),mode+" alternate hideout exit remains accessible")
		settle(1,h.homes[spot].entry);h.hide_actor(1,spot)
		settle(game.rules.seeker,h.homes[spot].entry+Vector3.BACK*1.7)
		game._inspect(game.rules.seeker,spot);h.tick(0.7)
		check(game.rules.phase==game.Rules.Phase.REVEAL,mode+" original timed inspection reveals hider")
		game.rules.tick(game.rules.time_left+0.01)
		check(game.rules.phase==game.Rules.Phase.DUEL and not game.fighters[1].hidden_in_box,mode+" original duel restores target")
		var hits: Array[int]=[game.rules.seeker]
		for i in range(3):game.rules.register_hits(hits)
		check(not game.rules.alive[1],mode+" unchanged three-hit capture rule")
	# Blocked start/late occupancy. There is no gate that can close on anybody.
	fresh();await physics_frame;settle(0,Service.LANE_ENDS[0]);settle(1,Vector3(0,0,4));await physics_frame
	check(not h.travel(0,h.lane(0)) and h.lane_uses==0,"occupied swept corridor refuses launch without spending a use")
	settle(1,Vector3(15,0,14));await physics_frame;check(h.travel(0,h.lane(0)),"cleared corridor allows retry")
	h.tick(0.15);settle(1,Vector3(0,0,1.4));await physics_frame;var stop=game.fighters[0].position;h.tick(0.55)
	check(not h.transit.has(0) and game.fighters[0].position==stop and h.lane_aborts==1,"late occupancy cancels at current safe point instead of pushing into a player")
	check(h.free_point(game.fighters[0].position,0),"aborted rider is still capsule-clear")
	game.fighters[0].step(1.0/60,Vector3.LEFT,Vector3.LEFT)
	check(game.fighters[0].position.x<stop.x,"aborted rider can move out sideways immediately")
	fresh();await physics_frame;settle(0,Service.LANE_ENDS[0]);h.travel(0,h.lane(0));h.tick(0.2)
	game.fighters[0].take_hit(Vector3.RIGHT);stop=game.fighters[0].position;h.tick(0.1)
	check(not h.transit.has(0) and game.fighters[0].position==stop and game.fighters[0].knock_velocity.length()>0,"damage cancels propulsion and preserves original knockback")
	# Actual swept melee against a launched target in the unmodified DUEL contact path.
	fresh();await physics_frame;game.rules.discover(1);game.rules.tick(game.rules.time_left+0.01)
	settle(1,Service.LANE_ENDS[0]);settle(0,Service.LANE_ENDS[0]+Vector3.FORWARD*1.3)
	check(h.travel(1,h.lane(0)),"duel target may choose exposed route without immunity")
	game.fighters[0].handling="quick";game.fighters[0].begin_swing()
	for i in range(35):
		game.fighters[0].step(1.0/60,Vector3.BACK*0.7,Vector3.BACK)
		game.fighters[1].step(1.0/60,Vector3.ZERO,Vector3.FORWARD)
		game._duel_contacts()
		if game.rules.hp[1]<3:break
	check(game.rules.hp[1]==2,"original swept duel attack damages a rider with exactly one ordinary hit")
	h.tick(0.016);check(not h.transit.has(1),"actual contact releases transit instead of ignoring hit")
	fresh();await physics_frame;settle(0,Service.LANE_ENDS[0]);var fake=h.lane(0);fake.to=Vector3(18,0,15)
	check(not h.travel(0,fake),"caller cannot substitute arbitrary teleport endpoint")
	# Public periodic wind is bounded, stateless with respect to occupants, and truly moves props.
	var nodes:=count(game);var stable:=toy_poses();var before:=authority()
	h.tick(4.25)
	check(h.wind_emissions==0 and h.canyon_art.get_node("WindPad0/WindFlag").rotation.z>0,"visible warning precedes wind sound and movement")
	h.tick(0.75)
	check(toy_poses()!=stable and h.wind_emissions==1,"active gust physically changes toy transforms once per cycle")
	check(h.sounds.size()==1 and h.sounds[0].source==-1 and h.sounds[0].kind=="wind21","wind stores a public environmental source, not a player coordinate")
	check(authority()==before,"gust never moves actors/camera, changes damage, weapons or rule clocks")
	var positions:=toy_poses();var event=h.sounds[0].duplicate(true)
	game.paused=true;h.tick(6);check(toy_poses()==positions and h.sounds[0]==event,"paused wind freezes its same finite clock")
	game.paused=false;game.preferences.reduced_motion=true;h.tick(0.05)
	check(toy_poses()==stable and h.sounds.size()==1,"comfort keeps the public clue but removes moving prop flourish")
	game.preferences.reduced_motion=false;h.tick(2.3)
	check(toy_poses()==stable and h.sounds.is_empty(),"wind toys return exactly home and event expires; no accumulation")
	for cycle in range(12):
		h.tick(14.9);h.tick(0.4)
		check(count(game)==nodes and h.sounds.size()<=32,"repeated gust%d uses fixed nodes and bounded event queue"%cycle)
		for i in range(2):
			for j in range(4):
				var toy=h.canyon_art.get_node("WindPad%d/WindToy%d"%[i,j])
				check(toy.position.distance_to(toy.get_meta("rest"))<0.75,"toy stays inside its nonblocking1m sweep")
	for seed_value in [17,17,90]:
		h.configure(seed_value);await process_frame
		check(h.lane_ready==[0.0,0.0,0.0,0.0] and h.wind_emissions==0 and h.transit.is_empty(),"round resets corridor and wind lifecycle, seed="+str(seed_value))
		check(count(game)==nodes and toy_poses()==stable,"round reset reuses rather than respawns eight wind toys")
	game.queue_free();await process_frame
	print("CANYON21_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
