extends SceneTree
const Scene=preload("res://scenes/phase21.tscn")
const Wet=preload("res://scripts/wetland21/services.gd")
const Pine=preload("res://scripts/pine21/services.gd")
const PineTests=preload("res://tests/pine21/test_pine.gd")
const OutdoorTests=preload("res://tests/outdoor20/test_outdoors.gd")
const Catalog=preload("res://scripts/maps/catalog.gd")
var game
var checks:=0
var failures:=0
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
	var data: Array=[game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rules.phase,game.rules.time_left,game.camera.transform,game.rig.yaw,game.rig.pitch]
	for a in game.fighters:data.append([a.transform,a.velocity,a.weapon.transform,a.hit_samples.duplicate(),a.weapon_data.to_dictionary(),a.collision_layer,a.collision_mask])
	return data
func fresh(mode: String="field",seeker: bool=true) -> void:
	game.return_to_menu();game.select_map("reedwater_bend");game.set_mode(mode);game.start_match(seeker);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.4,0,14))
	game.preferences.reduced_motion=false;game.preferences.feedback_strength=1;game.preferences.volume=0.5
	game._process(0)
func move(id: int,start: Vector3,dir: Vector3,quiet: bool=false) -> void:
	var a=game.fighters[id];a.reset_fight(start)
	if quiet:Input.action_press("hs_quiet")
	for i in range(90):
		a.step(1.0/60,dir*(0.42 if quiet else 0.6),dir);game._update_actor_events(id)
		if game.hiding.track_cursor>0:break
		if i%15==0:await physics_frame
	Input.action_release("hs_quiet")
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame;game.set_process(false)
	var h=game.hiding
	check(h is Wet and h is Pine,"wet service extends, rather than replaces, tested Pine behavior")
	check(Catalog.IDS.size()==9 and Catalog.IDS.has("reedwater_bend"),"catalog9+Manor remains ten distinct maps")
	fresh();await physics_frame;await physics_frame
	var helpers=PineTests.new();var conn=OutdoorTests.new()
	var original=preload("res://scenes/phase20.tscn").instantiate();root.add_child(original);original.automated=true
	await process_frame;await process_frame;original.set_process(false)
	original.select_map("reedwater_bend");await physics_frame
	# Seed21 is an explicitly authorized ADDITIVE layout. Preserve the full original geometry
	# and require precisely the two selected numeric boxes/rectangles, not an arbitrary filter.
	var expected: Array=helpers.geometry(original.arena)
	var plan: Dictionary=preload("res://scripts/seed21/layouts.gd").plan("reedwater_bend",int(game.rng.seed),game.rules.round_index)
	for center in plan.positions:
		expected[2].append(Rect2(center-Vector2(plan.size.x,plan.size.z)*0.5,Vector2(plan.size.x,plan.size.z)).grow(0.46))
		expected[4].append([Transform3D(Basis.IDENTITY,Vector3(center.x,plan.size.y*0.5,center.y)),"BoxShape3D",plan.size])
	check(helpers.geometry(game.arena)==expected,"all original wetland geometry plus exactly the two selected Seed21 cover boxes")
	var original_zones: Array=game.arena.surface_zones.filter(func(z):return not str(z.id).begins_with("wetland21_"))
	check(original_zones==original.arena.surface_zones,"all existing boardwalk and quiet-bank terrain remains")
	var free:=0
	for x in range(game.arena.grid_size.x):
		for y in range(game.arena.grid_size.y):
			if not game.arena.navigation.is_point_solid(Vector2i(x,y)):free+=1
	check(conn.reachable(game.arena)==free,"all original free navigation cells remain connected")
	for home in h.homes:
		check(h.free_point(home.entry,-1),"original hide entry %d is capsule/floor clear"%home.id)
		check(h.free_point(home.exits[1],-1),"original alternate exit %d remains accessible"%home.id)
	for r in Wet.WATER_RECTS+Wet.REED_RECTS:
		var c: Vector2=r.get_center();var p:=Vector3(c.x,0,c.y)
		check(h.free_point(p,-1),"mechanism centre remains traversable "+str(c))
	check(game.arena.get_node("Wetland21Art").find_children("*","CollisionObject3D",true,false).is_empty(),"new art contains no physics bodies or hidden walls")
	check(h.tufts.size()==4 and h.tracks.size()==24 and h.wet_visuals.size()==24,"four fixed tufts and existing24 trace slots bound allocation")
	original.queue_free();helpers.free();conn.free();await process_frame
	# Both teams and quiet player use the same real movement sampler, not direct injected clues.
	for quiet in [false,true]:
		fresh("field",false);await physics_frame;await physics_frame
		await move(0,Vector3(-2.8,0,-2.9),Vector3.RIGHT,quiet)
		check(h.track_cursor==1 and h.sounds.size()==1,"one sampled wet step, no duplicate trace or sound; quiet="+str(quiet))
		check(h.tracks[0].kind=="water21" and h.wet_visuals[0].visible,"actual water step selects pooled water glyph")
		check(h.sounds[0].kind=="water21","same sound queue carries water clue")
		check(is_equal_approx(h.sounds[0].radius,3.75 if quiet else 10.0),"quiet water is quieter without becoming clue-free")
		var at: Vector3=h.tracks[0].at;var sound: Vector3=h.sounds[0].at
		game.fighters[0].reset_fight(Vector3(15,0,6));h.tick(0.1)
		check(h.tracks[0].at==at and h.sounds[0].at==sound,"wet clue stores prior movement coordinates, never follows the actor")
		game.paused=true;var clock: float=h.elapsed;h.tick(9)
		check(h.elapsed==clock and h.tracks[0].node.visible,"pause freezes the same visual/investigation lifetime")
		game.paused=false;h.tick(2.91)
		check(not h.tracks[0].node.visible and h.tracks[0].time<0 and h.sounds.is_empty(),"three-second expiry clears visual, tracker eligibility and water sound memory together")
	# Water on boots persists briefly on dry land, but no new emission timer follows a character.
	fresh();await physics_frame;await move(1,Vector3(-2.8,0,-2.9),Vector3.RIGHT)
	var initial: int=h.track_cursor
	for i in range(70):
		game.fighters[1].step(1.0/60,Vector3.BACK*0.6,Vector3.BACK);game._update_actor_events(1)
		if h.track_cursor>initial and h.zone_index(game.fighters[1].position,Wet.WATER_RECTS)<0:break
		if i%15==0:await physics_frame
	check(h.track_cursor>initial and h.tracks[posmod(h.track_cursor-1,24)].kind=="water21","sampled steps just outside water leave brief wet prints")
	h.tick(2.6);var cursor: int=h.track_cursor
	for i in range(60):
		game.fighters[1].step(1.0/60,Vector3.BACK*0.6,Vector3.BACK);game._update_actor_events(1)
		if h.track_cursor!=cursor:break
		if i%15==0:await physics_frame
	check(h.tracks[posmod(h.track_cursor-1,24)].kind=="step","drying ends the wet-boot effect without changing normal footprints")
	# Existing investigator can find a fresh movement trace, but cannot find its expired slot.
	fresh();await physics_frame;await move(1,Vector3(-2.8,0,-2.9),Vector3.RIGHT)
	var track_at: Vector3=h.tracks[0].at;game.fighters[0].reset_fight(track_at+Vector3.BACK*1.6);h.skill_index=1
	check(h.investigate() and game.heard_point==track_at,"original tracker tool finds real fresh wet print through its LOS contract")
	h.tick(3.01);h.skill_cooldown=0;game.heard_point=Vector3(99,99,99)
	check(h.investigate() and game.heard_point==Vector3(99,99,99),"expired wet slot is no longer returned by real investigation")
	# Reed stems remain at a fixed world location; their short bend uses a past motion direction.
	for quiet in [false,true]:
		fresh("field",false);await physics_frame;await move(0,Vector3(4.9,0,-8.5),Vector3.BACK,quiet)
		check(h.sounds.size()==1 and h.sounds[0].kind=="reed21" and h.track_cursor==1,"one inherited step drives reed clue; quiet="+str(quiet))
		check(h.tracks[0].kind=="reed21" and h.reed_visuals[0].visible,"reed movement has a bounded ground trace even in comfort mode")
		var at: Vector3=h.tufts[0].position;var before:=authority();h.tick(0.1)
		check(h.tufts[0].rotation.length()>0.001,"actual movement causes a small finite reed bend")
		check(authority()==before,"reed response never modifies camera, capsule, hit samples, HP or clocks")
		var event: Dictionary=h.reed_events[0].duplicate(true)
		game.fighters[0].reset_fight(Vector3(-13,0,0));h.tick(0.15)
		check(h.tufts[0].position==at and h.reed_events[0]==event,"reed reaction stays at recorded patch with no continuing target lookup")
		game.paused=true;var pose: Vector3=h.tufts[0].rotation;h.tick(8)
		check(h.tufts[0].rotation==pose,"paused reed pose does not advance")
		game.paused=false;h.tick(1.26)
		check(h.tufts[0].rotation==Vector3.ZERO and h.tracks[0].time<0 and not h.tracks[0].node.visible and h.sounds.is_empty(),"reed sway, visual trace, sound and investigation end at1.5s")
	fresh();await physics_frame;await move(1,Vector3(4.9,0,-8.5),Vector3.BACK)
	track_at=h.tracks[0].at;game.fighters[0].reset_fight(track_at+Vector3.RIGHT*1.7);h.skill_index=1
	check(h.investigate() and game.heard_point==track_at,"same tracker can inspect fresh bent-reed evidence")
	h.tick(1.51);h.skill_cooldown=0;game.heard_point=Vector3(99,99,99)
	check(h.investigate() and game.heard_point==Vector3(99,99,99),"expired reed cannot become a stale investigation result")
	# Settings and guards do not leak hidden/current actor positions.
	fresh();await physics_frame;game.preferences.reduced_motion=true;game.preferences.feedback_strength=0;game.preferences.volume=0
	await move(1,Vector3(4.9,0,-8.5),Vector3.BACK);h.tick(0.1)
	check(h.tufts[0].rotation==Vector3.ZERO and h.reed_visuals[0].visible and h.sounds.size()==1,"comfort removes sway but keeps the same finite visible/audible-information clue")
	var actor=game.fighters[1];var emitted: int=h.track_cursor
	actor.set_hidden(true,0);h.step_record(1)
	check(h.track_cursor==emitted and h.wet_until[1]<0,"hidden actor has no new traces or retained wetness")
	actor.set_hidden(false);actor.old_position=actor.position-Vector3.RIGHT*5;h.step_record(1)
	check(h.track_cursor==emitted,"teleport is not a movement clue")
	actor.position.y=2;actor.step(1.0/60,Vector3.ZERO,Vector3.BACK);h.step_record(1)
	check(h.track_cursor==emitted,"airborne actor does not disturb water/reeds")
	fresh();await physics_frame
	actor.reset_fight(Vector3(4.9,0,-7));for i in range(12):actor.step(1.0/60,Vector3.ZERO,Vector3.BACK)
	for i in range(20):actor.old_position=actor.position;h.step_record(1);h.tick(0.02)
	check(h.sounds.is_empty() and h.track_cursor==0,"stationary occupant never continuously triggers a patch")
	for mode in ["field","classic"]:
		fresh(mode);await physics_frame;await move(1,Vector3(-2.8,0,-2.9),Vector3.RIGHT)
		var spot:=-1
		for home in h.homes:
			if h.usable(home.id):spot=home.id;break
		actor.reset_fight(h.homes[spot].entry)
		check(h.hide_actor(1,spot),mode+" existing context hide remains available after water")
		check(h.leave(1,true),mode+" real alternate exit remains capsule-clear")
		actor.reset_fight(h.homes[spot].entry);h.hide_actor(1,spot)
		game.fighters[game.rules.seeker].reset_fight(h.homes[spot].entry+Vector3.BACK*1.7)
		game._inspect(game.rules.seeker,spot);h.tick(0.7)
		check(game.rules.phase==game.Rules.Phase.REVEAL,mode+" original timed search reveals wetland hider")
		game.rules.tick(game.rules.time_left+0.01)
		check(game.rules.phase==game.Rules.Phase.DUEL and not actor.hidden_in_box,mode+" original duel exposes a hittable target")
		var hits: Array[int]=[game.rules.seeker]
		for i in range(3):game.rules.register_hits(hits)
		check(not game.rules.alive[1],mode+" original three-hit capture, not an environmental shortcut")
	# Lifecycle: configure twice, reset, return to forest, then wetlands; no new randomization.
	fresh();await physics_frame;var nodes:=count(game.arena);var geom:=PineTests.new()
	var snapshot:=geom.geometry(game.arena)
	for seed_value in [7,7,91,0]:
		h.configure(seed_value)
		check(count(game.arena)==nodes and h.tufts.size()==4,"round configure reuses fixed art seed="+str(seed_value))
		check(game.arena.surface_zones.size()==10 and h.wet_until==[-1.0,-1.0,-1.0,-1.0],"reset restores no wet state, exactly six new zones")
		check(geom.geometry(game.arena)==snapshot,"round seed leaves authoritative geometry unchanged")
	geom.free();nodes=count(game);var before:=authority()
	for i in range(120):h.make_track(Vector3(4.9,0,-7),1,"water21" if i%2 else "reed21");h.sound_at(Vector3(4.9,0,-7),1,8,"reed21")
	check(count(game)==nodes and h.tracks.size()==24 and h.sounds.size()==32,"stress reuses24 trace slots and32 sound records without scene allocation")
	check(authority()==before,"stress contains no new authority writes")
	h.tick(3.1);var active:=0
	for t in h.tracks:if t.node.visible or h.elapsed-t.time<8:active+=1
	check(active==0 and h.sounds.is_empty(),"all stressed wetland clues expire including investigation eligibility")
	h.reset();check(h.wet_until==[-1.0,-1.0,-1.0,-1.0] and h.sounds.is_empty(),"explicit reset clears all transient clue state")
	game.return_to_menu();game.select_map("pine_hollow");await process_frame
	check(h.pine_active and not h.wetland_active and h.remaining==[4.0,4.0,4.0,4.0],"return to Pine keeps four-second shared allowance")
	h.make_track(Vector3(0,0,0),1,"leaves")
	check(h.leaf_visuals[0].visible and not h.wet_visuals[0].visible and not h.reed_visuals[0].visible,"reused slot shows only original Pine leaf visual")
	game.return_to_menu();game.select_map("reedwater_bend");await process_frame
	check(h.wetland_active and not h.pine_active and h.reed_events.size()==4 and h.track_cursor==0,"map switch clears event history and safely reconnects four reed visuals")
	game.queue_free();await process_frame
	print("WETLAND21_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
