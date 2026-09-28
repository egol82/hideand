extends SceneTree
const Scene=preload("res://scenes/phase9.tscn")
const Contact=preload("res://scripts/phase4/combat.gd")
const Attack=preload("res://scripts/phase4/attack_spec.gd")
const Audio=preload("res://scripts/smash/audio.gd")
var game
var director
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, title: String) -> void:
	checks+=1
	if not value: failures+=1
	print(("PASS: " if value else "FAIL: ")+title)
func count_nodes(n: Node) -> int:
	var size_value:=1
	for child in n.get_children(): size_value+=count_nodes(child)
	return size_value
func physics_count(n: Node) -> int:
	var size_value:=1 if n is CollisionObject3D else 0
	for child in n.get_children(): size_value+=physics_count(child)
	return size_value
func next_hit(handling: String="balanced", target: int=1, finish: bool=false) -> void:
	var attacker: int=0 if target!=0 else 1
	game.fighters[attacker].attack_sequence+=1
	game.fighters[attacker].handling=handling
	game.rules.hp[target]=1 if finish else 3
	game._consume_event(Contact.event(game.fighters[attacker],game.fighters[target],game.fighters[target].position+Vector3.UP,Vector3.BACK,"hit"))
func advance(t: float) -> void:
	game._process(t)
func run() -> void:
	game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await process_frame
	director=game.get_node("SmashDirector")
	game.start_practice(); game.accept_drawing()
	game.preferences.feedback_strength=1.0; game.preferences.reduced_motion=false
	var actor=game.fighters[1]
	check(director.active and game.smash_presentation,"default scene installs actual event-driven director")
	check(director.reactions.size()==4 and director.ghosts.size()==4,"reaction and exit pools have fixed four actors")
	check(physics_count(director.effects)==0 and physics_count(director.reactions[1])==0,"new visuals never add physics bodies")
	var original: Dictionary=actor.weapon_data.to_dictionary()
	var samples: PackedVector3Array=actor.hit_samples.duplicate()
	var world: Transform3D=actor.weapon.global_transform
	var hp: Array=game.rules.hp.duplicate(); var scores: Array=game.rules.scores.duplicate(); var clock: float=game.rules.time_left
	for style in Attack.IDS:
		director.reset(); next_hit(style)
		check(director.last_kind=="hit",style+" confirmed contact selects hit, not fake finish")
		check(director.effects.active_count()>0,style+" visible contact burst exists")
		for rate in [30,60,120]:
			director.reactions[1].start(Vector3.BACK,style,1)
			for i in range(rate*2): director.advance(1.0/rate)
			check(actor.weapon.global_transform.is_equal_approx(world),style+" reaction preserves weapon transform at "+str(rate))
			check(actor.body_art.get_parent().transform.is_equal_approx(Transform3D.IDENTITY),style+" bounded spring returns to rest at "+str(rate))
			check(actor.body_art.get_node("LeftEye").visible,style+" restores default face at "+str(rate))
	check(actor.weapon_data.to_dictionary()==original and actor.hit_samples==samples,"all cartoon reactions preserve canonical drawing and contact samples")
	check(game.rules.hp==hp and game.rules.scores==scores and game.rules.time_left==clock,"presentation update does not damage, score or advance match")
	# Compare exactly sampled closed-form reactions, not integrated unstable springs.
	var poses: Array[Transform3D]=[]
	for rate in [30,60,120]:
		director.reactions[1].start(Vector3.RIGHT,"heavy",2)
		for i in range(rate/5): director.advance(1.0/rate)
		poses.append(director.reactions[1].transform)
	check(poses[0].is_equal_approx(poses[1]) and poses[1].is_equal_approx(poses[2]),"reaction is frame-step independent at common elapsed time")
	director.reset(); next_hit("heavy")
	var event: Dictionary=game.event_history.back().duplicate(true)
	event.handling="heavy"; event.finisher=false
	var n: int=director.handled; var used: int=director.effects.active_count()
	for i in range(20): director.contact(event)
	check(director.handled==n and director.effects.active_count()==used,"one authoritative contact cannot spawn duplicate bursts")
	game._consume_event(Contact.event(game.fighters[0],null,Vector3.UP,Vector3.UP,"miss","air"))
	check(director.handled==n,"miss never becomes a hit, star burst or victim reaction")
	game.fighters[0].attack_sequence+=1
	game.hit_feedback=0
	game._consume_event(Contact.event(game.fighters[0],null,Vector3.UP,Vector3.UP,"blocked","wood"))
	check(director.last_kind=="blocked" and game.hit_feedback==0 and game.block_feedback>0,"blocked contact is blue clonk without outgoing hit confirmation")
	game.hit_feedback=0; next_hit("quick",0)
	check(game.hit_feedback==0 and game.hurt_feedback>0,"incoming hit does not impersonate outgoing confirmation")
	game.fighters[1].set_hidden(true,0); director.reset()
	next_hit("balanced",1)
	check(director.effects.active_count()==0,"hidden target cannot emit fresh smash or reaction")
	game.fighters[1].reset_fight(Vector3.ZERO)
	next_hit("heavy",1); director.advance(0.08)
	check(director.reactions[1].face.visible and director.reactions[1].stars.visible,"real visible target shows comic face and orbiting stars")
	game.fighters[1].set_hidden(true,0); director.advance(0.016)
	check(not director.reactions[1].face.visible and director.reactions[1].life==0,"hiding immediately cancels following face/stars")
	game.fighters[1].reset_fight(Vector3.ZERO)
	for reduced in [false,true]:
		director.reset(); game.preferences.reduced_motion=reduced; next_hit("heavy")
		var current_world: Transform3D=actor.weapon.global_transform
		var before: float=game.rules.time_left
		director.advance(0.12)
		check(game.rules.time_left==before,"comfort setting never changes authority time "+str(reduced))
		check(actor.weapon.global_transform.is_equal_approx(current_world),"comfort never transforms world weapon "+str(reduced))
		if reduced: check(director.effects.active_count()==0 and director.reactions[1].life==0,"reduced motion removes moving burst and body recoil")
	game.preferences.reduced_motion=false
	next_hit("heavy"); game.preferences.feedback_strength=0; director.advance(0.01)
	check(director.effects.active_count()==0 and director.reactions[1].life==0,"zero effect strength clears existing effects immediately")
	game.preferences.feedback_strength=1
	next_hit("balanced"); game.paused=true
	var age: float=director.reactions[1].age
	advance(0.4)
	check(director.reactions[1].age==age,"explicit pause freezes visual lifetime")
	game.paused=false
	# The third real hit can vanish an actor immediately. Echo remains only at last public contact.
	director.reset(); actor.reset_fight(Vector3(0,0,0.3)); next_hit("heavy",1,true)
	var at: Vector3=actor.global_position
	actor.visible=false; director.advance(0.09)
	check(director.last_kind=="finish" and director.ghosts[1].root.visible,"finisher has distinct exit echo after authoritative disappearance")
	actor.position=Vector3(13,0,13); director.advance(0.03)
	check(director.ghosts[1].root.position.is_equal_approx(at),"exit echo never follows current hidden or respawn position")
	check(physics_count(director.ghosts[1].root)==0,"exit echo cannot block navigation or become a damage target")
	director.advance(0.7)
	check(not director.ghosts[1].root.visible,"exit echo retires within its bounded lifetime")
	actor.reset_fight(Vector3.ZERO)
	var node_count:=count_nodes(game)
	for i in range(220): next_hit("heavy",1,i%3==0); director.advance(0.01)
	check(count_nodes(game)==node_count,"repeated impacts reuse fixed nodes without per-hit scene growth")
	check(director.effects.active_count()<=director.effects.CAPACITY and director.recent.size()<=128,"particle and dedup history budgets stay bounded")
	game._clear_feedback()
	check(director.effects.active_count()==0 and director.recent.is_empty(),"restart clears effect pool and dedup state")
	for w in director.effects.words: check(not w.node.visible and not w.node.no_depth_test,"comic text resets and remains depth-tested, not wallhack labels")
	var handled_before: int=director.handled
	for invalid in [{},{"world_point":Vector3(NAN,0,0)},{"world_point":Vector3.ZERO,"attacker_id":19,"target_id":0,"outcome":"hit"}]: director.contact(invalid)
	check(director.handled==handled_before,"invalid visual packets fail safely")
	for kind in ["bop","bonk","smash","blocked","squeak"]:
		for v in range(3):
			var wav:=Audio.make_tone(kind,v)
			check(wav.data.size()>1000 and wav.data.size()<=22050,"bounded original audio sample "+kind+str(v))
			var peak:=0
			for i in range(0,wav.data.size(),2):
				var value:=int(wav.data[i])|(int(wav.data[i+1])<<8)
				if value>32767: value-=65536
				peak=maxi(peak,absi(value))
			check(peak>100 and peak<30000,"audio has headroom and non-silent energy "+kind+str(v))
	await actual_contact()
	game.queue_free(); await process_frame; await process_frame
	print("SMASH_UNIT_RESULT: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)

func actual_contact() -> void:
	game.return_to_menu(); game.start_practice(); game.accept_drawing(); game.preferences.reduced_motion=false
	game.fighters[0].reset_fight(Vector3(0,0,1)); game.fighters[1].reset_fight(Vector3(0,0,2.3))
	game.rig.face(Vector3.BACK)
	await physics_frame
	var before: int=director.handled
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
	game._unhandled_input(event)
	for i in range(30):
		game._physics_practice(1.0/60); game._process(1.0/60); await physics_frame
	check(game.practice.hits>0 and director.handled>before,"real mouse-handler swing and swept geometry drive new presentation")
	check(game.rules.hp[1]<3,"authoritative real contact still subtracts original damage")
	check(game.rules.scores==[0,0,0,0],"actual practice contact still awards no match points")
