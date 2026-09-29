extends SceneTree
const Scene=preload("res://scenes/phase11.tscn")
var game
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func key(code: int) -> void:
	var e:=InputEventKey.new(); e.physical_keycode=code; e.pressed=true; game._unhandled_input(e)
func click() -> void:
	var e:=InputEventMouseButton.new(); e.button_index=MOUSE_BUTTON_LEFT; e.pressed=true; game._unhandled_input(e)
func fresh(hider: bool=true) -> void:
	game.return_to_menu(); game.select_map("toy_manor"); game.start_match(not hider); game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4): game.fighters[i].reset_fight(Vector3(-8+i*3,0,11))
	game.set_process(false)
func free_home() -> int:
	for h in game.hiding.homes:
		if game.hiding.usable(h.id): return h.id
	return -1
func enter(index: int) -> bool:
	game.fighters[0].reset_fight(game.hiding.homes[index].entry)
	return game.hiding.hide_actor(0,index)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await physics_frame
	game.set_process(false)
	check(game.map_id=="toy_manor","new default has playable two-floor manor")
	check(game.rig.cute_sync,"rounded paws and selected-contact sync remain enabled")
	check(game.has_node("ToyStudio"),"prior graphics comparison remains attached")
	var geometry_count:=0
	for seed_value in [0,991,1982]:
		game.hiding.configure(seed_value); await physics_frame
		check(game.arena.homes.size()==12,"twelve furniture records seed "+str(seed_value))
		var usable:=0
		for h in game.hiding.homes:
			if game.hiding.usable(h.id): usable+=1
			check(game.hiding.free_point(h.entry,-1),"entry capsule + floor "+str(seed_value)+" / "+str(h.id))
			for side in range(2):
				check(game.hiding.free_point(h.exits[side],-1),"exit capsule + floor "+str(seed_value)+" / "+str(h.id)+" / "+str(side))
			check(h.exits[0].distance_to(h.exits[1])>2,"two distinct exit directions "+str(h.id))
			check(game.arena.route_available(Vector3(0,0,0),h.entry),"spawn reaches hiding site on correct floor "+str(h.id))
		check(usable==10,"two filled decoys never remove the three hiders' capacity")
		var ids: PackedInt64Array=game.arena.graph.get_point_ids(); var visited: Dictionary={}; var todo: Array[int]=[ids[0]]
		while not todo.is_empty():
			var id: int=todo.pop_back()
			if visited.has(id): continue
			visited[id]=true
			for n in game.arena.graph.get_point_connections(id): todo.append(n)
		check(visited.size()==ids.size(),"all multi-floor graph nodes connected seed "+str(seed_value))
		geometry_count+=ids.size()
	var first: Array=[]
	for h in game.hiding.homes: first.append([h.entry,h.fake])
	game.hiding.configure(1982); var second: Array=[]
	for h in game.hiding.homes: second.append([h.entry,h.fake])
	check(first==second,"same round seed reproduces placements and filled lockers")
	# Real CharacterBody movement, not assigning target position, across both stair directions.
	var actor=game.fighters[0]
	for side in [-1,1]:
		for upwards in [true,false]:
			var start:=Vector3(side*11,0,9 if side==-1 else -9); var end:=Vector3(side*11,4,-9 if side==-1 else 9)
			if not upwards: var swap:=start; start=end; end=swap
			actor.reset_fight(start)
			for step in range(480):
				var d: Vector3=end-actor.position; d.y=0; actor.step(1.0/60,d.normalized(),d)
				await physics_frame
				if actor.position.distance_to(end)<0.45: break
			check(actor.position.distance_to(end)<0.5,"actual stair traversal "+str(side)+" up="+str(upwards))
	fresh(); await physics_frame
	var index:=free_home(); var h: Dictionary=game.hiding.homes[index]
	check(enter(index),"human enters a real available home")
	check(actor.hidden_in_box and not actor.visual.visible and actor.collision_layer==0,"hidden body is not still a visible/colliding target")
	var hunter=game.fighters[game.rules.seeker]
	hunter.reset_fight(Vector3(8,0,11))
	Input.action_press("hs_quiet")
	game.hiding.tick(0.6)
	check(game.hiding.peek_active[0] and not game.hiding.peek_eyes[0].visible,"short peek shows local slit without exposed eyes yet")
	game.hiding.tick(0.6)
	check(game.hiding.peek_eyes[0].visible,"long peek creates visible eyes at public slit")
	Input.action_release("hs_quiet"); game.hiding.tick(0.01)
	check(not game.hiding.peek_eyes[0].visible,"releasing peek immediately hides exposed eyes")
	key(KEY_SHIFT)
	check(not actor.hidden_in_box and actor.position.is_equal_approx(h.exits[1]),"actual dash binding selects second exit while hidden")
	check(enter(index),"can re-enter after leaving")
	key(KEY_E)
	check(not actor.hidden_in_box and actor.position.is_equal_approx(h.exits[0]),"actual interaction binding selects first exit")
	# A physical wall between the exposed slit and hunter blocks peek discovery.
	fresh(); await physics_frame; index=free_home(); h=game.hiding.homes[index]; enter(index)
	hunter=game.fighters[game.rules.seeker]; hunter.reset_fight(h.peek+Vector3(0,-h.peek.y,2.3))
	hunter.visual.rotation.y=PI
	var blocker: StaticBody3D=game.arena.Toy.collider(game,Vector3(h.peek.x,1.5,h.peek.z+1.15),Vector3(3.5,3,0.15))
	await physics_frame; Input.action_press("hs_quiet"); game.hiding.tick(1.2)
	check(game.rules.phase==game.Rules.Phase.SEEK,"peek exposure does not reveal through solid walls")
	blocker.queue_free(); await physics_frame; await physics_frame; game.hiding.tick(0.05)
	check(game.rules.phase==game.Rules.Phase.REVEAL,"seeker can actually discover exposed eyes with clear sight")
	Input.action_release("hs_quiet")
	fresh(); await physics_frame; index=free_home(); h=game.hiding.homes[index]
	var filled:=-1
	for home in game.hiding.homes: if home.fake: filled=home.id
	actor.reset_fight(game.hiding.homes[filled].entry)
	check(not game.hiding.hide_actor(0,filled),"filled false hiding place rejects hiding without losing player")
	# Block a chosen exit by another actual actor: no overlap/forced teleport.
	enter(index); hunter.reset_fight(h.exits[0]); await physics_frame
	check(not game.hiding.leave(0,false) and actor.hidden_in_box,"occupied exit cannot push a player through another actor")
	hunter.reset_fight(Vector3(8,0,11)); check(game.hiding.leave(0,true),"other exit remains usable")
	fresh(); await physics_frame; index=free_home(); enter(index)
	h=game.hiding.homes[index]
	actor.visual.rotation.y=0; game.rig.face(Vector3.BACK)
	var hp: Array=game.rules.hp.duplicate(); var score: Array=game.rules.scores.duplicate()
	check(game.hiding.deploy_decoy(0),"hider can put a real wind-up toy in clear nearby space")
	var planted: Vector3=game.hiding.decoys[0].at
	var count: int=game.hiding.sounds.size(); game.hiding.tick(0.4)
	check(game.hiding.sounds.size()==count,"wind-up toy does not sound before its delay")
	actor.position=Vector3(0,0,10)
	game.hiding.tick(0.5)
	check(game.hiding.sounds.back().kind=="decoy" and game.hiding.sounds.back().at.distance_to(planted)<1.5,"decoy sounds at stored toy, not owner's new hidden position")
	check(not game.hiding.deploy_decoy(0),"one decoy charge per round prevents infinite sound spam")
	check(game.rules.hp==hp and game.rules.scores==score,"decoy never deals damage or farms points")
	game.paused=true; var age: float=game.hiding.elapsed; game.hiding.tick(3)
	check(game.hiding.elapsed==age,"pause freezes clue/peek/transit clocks")
	game.paused=false
	# A real public sound, rather than any stored hidden-player list, drives listen.
	fresh(false); await physics_frame
	actor.reset_fight(Vector3(0,0,0)); game.hiding.sound_at(Vector3(3,0,0),1,12,"step")
	game.hiding.skill_index=0
	check(game.hiding.investigate(),"listen ability begins on seeker key action")
	game.hiding.tick(3.1)
	check(not game.hiding.listening and game.heard_time>0,"stationary listening resolves a recorded nearby sound")
	check(not game.hiding.investigate(),"shared investigation cooldown enforced")
	game.hiding.skill_cooldown=0; game.hiding.sounds.clear(); game.hiding.investigate(); game.hiding.tick(3.1)
	check("No recent" in game.local_notice or "없습니다" in game.local_notice,"no event means no x-ray location fabricated")
	game.hiding.skill_cooldown=0; game.hiding.investigate(); Input.action_press("hs_forward"); game.hiding.tick(0.1); Input.action_release("hs_forward")
	check(not game.hiding.listening,"movement interrupts listening")
	game.hiding.make_track(Vector3(2,0,0),1,"step"); game.hiding.skill_index=1; game.hiding.skill_cooldown=0
	check(game.hiding.investigate() and game.heard_point.is_equal_approx(Vector3(2,0,0)),"investigation follows a visible recorded footprint")
	game.hiding.tick(8.2)
	check(not game.hiding.tracks[0].node.visible,"footprints expire instead of tracking their owner")
	# Normal cabinet inspection takes a beat; loud tool bypasses that wait, never walls.
	fresh(false); await physics_frame; index=free_home(); h=game.hiding.homes[index]
	actor.reset_fight(h.entry+Vector3(0,0,1.1)); game.rig.face(Vector3.FORWARD)
	game.fighters[1].reset_fight(h.entry); game.hiding.hide_actor(1,index)
	game._inspect(0,index)
	check(game.hiding.inspecting.has(0) and game.rules.phase==game.Rules.Phase.SEEK,"ordinary inspection queues a 0.65-second check")
	game.hiding.tick(0.3)
	check(game.rules.phase==game.Rules.Phase.SEEK,"inspection does not discover before completion")
	actor.position.x+=0.3; game.hiding.tick(0.01)
	check(not game.hiding.inspecting.has(0),"moving away cancels ordinary inspection")
	actor.reset_fight(h.entry+Vector3(0,0,1.1)); game._inspect(0,index); game.hiding.tick(0.7)
	check(game.rules.phase==game.Rules.Phase.REVEAL,"completed ordinary inspection finds actual occupant")
	fresh(false); await physics_frame; index=free_home(); h=game.hiding.homes[index]
	actor.reset_fight(h.entry+Vector3(0,0,1.1)); game.rig.face(Vector3.FORWARD); game.rig.follow(actor,0,false,true)
	game.fighters[1].reset_fight(h.entry); game.hiding.hide_actor(1,index)
	game.hiding.skill_index=2
	check(game.hiding.investigate() and game.rules.phase==game.Rules.Phase.REVEAL,"loud quick tool inspects instantly rather than duplicate normal delay")
	var loud:=false
	for packet in game.hiding.sounds: if packet.source==0 and packet.radius==18: loud=true
	check(loud,"quick inspection broadcasts the seeker's location as a sound event")
	# Upstairs clues preserve vertical location instead of routing the seeker to the ground floor.
	fresh(false); actor.reset_fight(Vector3.ZERO); game.hiding.sound_at(Vector3(0,4,0),1,12)
	check(game.heard_point.y==4,"recorded hearing target preserves floor height")

	# Contextual traversal has bounded time, charges and a clear destination, never extra damage.
	fresh(); await physics_frame
	var port: Dictionary=game.arena.passages[1]; actor.reset_fight(port.from)
	check(game.hiding.travel(0,port),"hider-only passage starts for hider")
	game.hiding.tick(port.duration+0.01)
	check(actor.position.is_equal_approx(port.to) and not game.hiding.transit.has(0),"passage ends at authored exit")
	actor.reset_fight(port.from)
	check(not game.hiding.travel(0,port),"private passage is limited to once per round")
	var hs=game.rules.seeker; game.fighters[hs].reset_fight(port.from)
	check(not game.hiding.travel(hs,port),"seeker must use ordinary route around private passage")
	var chute: Dictionary=game.arena.passages[0]; actor.reset_fight(chute.from)
	check(game.hiding.travel(0,chute),"upstairs laundry chute starts")
	game.hiding.tick(chute.duration+0.01)
	check(actor.position.is_equal_approx(chute.to) and game.hiding.sounds.back().radius==18,"chute reaches lower floor and leaves loud landing clue")
	# Ambush input leaves hiding and queues ONE normal swing; no free hidden attack damage.
	fresh(); await physics_frame; index=free_home(); h=game.hiding.homes[index]
	enter(index); hunter=game.fighters[game.rules.seeker]; hunter.reset_fight(h.exits[0]+Vector3(0,0,1.3))
	game.rig.face(Vector3.BACK); await physics_frame
	click()
	check(game.rules.phase==game.Rules.Phase.REVEAL and not actor.hidden_in_box,"real attack input initiates an in-place ambush reveal")
	check(game.rules.hp[game.rules.seeker]==3,"ambush produces no synthetic/free damage")
	game.rules.tick(game.rules.reveal_seconds()+0.01)
	check(actor.elapsed==0 and game.hiding.ambush_player==-1,"reveal completion consumes one queued normal attack")
	var hit:=false
	for step in range(60):
		actor.step(1.0/60,Vector3.ZERO,Vector3.BACK); game._duel_contacts()
		if game.rules.hp[game.rules.seeker]<3: hit=true; break
		await physics_frame
	check(hit,"queued ambush swing uses real swept contact to land a hit")
	# Public endgame clue is a room/quadrant name, not a target position or occupied locker ID.
	fresh(); game.rules.search_left=29; game.hiding.tick(0.01)
	check(game.hiding.pressure_stage==1 and not game.hiding.pressure_zone.is_empty(),"first late-search pulse names a broad public zone")
	game.rules.search_left=11; game.hiding.tick(0.01)
	check(game.hiding.pressure_stage==2,"second late pulse remains bounded to two stages")
	check(game.hiding.sounds.size()<=32 and game.hiding.tracks.size()==24,"clue visuals/history have fixed budgets")
	game.controls.rebind("taunt",KEY_Q); game.choose_extra_keys()
	check(game.skill_key!=KEY_Q and game.skill_key not in game.controls.bindings.values(),"extra skill key avoids saved binding conflicts")
	game.controls.reset()
	for map_id in ["toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu(); game.select_map(map_id); await physics_frame
		check(game.hiding.homes.size()==game.arena.spots.size(),map_id+" has hide/search feature records")
		var dual:=0
		for home in game.hiding.homes:
			if home.exits[0].distance_to(home.exits[1])>1.0: dual+=1
		print("LEGACY_DUAL_EXITS ",map_id," ",dual," / ",game.arena.active_spots.size()," active")
		check(dual>=game.arena.active_spots.size(),map_id+" active hiding spaces have geometry-supported alternate exits")
	game.return_to_menu()
	check(game.hiding.sounds.is_empty() and game.hiding.transit.is_empty(),"menu reset removes all live clues and traversal")
	game.queue_free(); await process_frame
	print("HIDEPLAY_UNIT_RESULT: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
