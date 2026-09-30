extends SceneTree
const Scene=preload("res://scenes/phase18.tscn")
const Design=preload("res://scripts/feel18/sound_design.gd")
const Data=preload("res://scripts/phase4/drawing_data.gd")
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func count(n: Node) -> int:
	var total:=1
	for c in n.get_children():total+=count(c)
	return total
func authority() -> Array:
	var state: Array=[game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rules.time_left,game.rules.phase,game.rig.yaw,game.rig.pitch,game.camera.transform,game.camera.fov,game.arena.spots.duplicate()]
	for a in game.fighters:state.append([a.transform,a.velocity,a.weapon.transform,a.weapon_pivot.transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.body_art.body.mesh,a.body_art.body.skin])
	return state
func fresh(style: String="balanced",nearby: bool=true) -> void:
	game.return_to_menu();game.select_map("toy_home");game.start_practice();game.accept_drawing()
	game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3) if nearby else Vector3(8,0,8))
	game.fighters[0].handling=style;game.rig.face(Vector3.BACK)
	game.preferences.feedback_strength=0.7;game.preferences.volume=0.65;game.preferences.reduced_motion=false
	game._process(0)
func swing_until_contact() -> Dictionary:
	var fx=game.get_node("SmashDirector");var before: int=fx.handled
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;game._unhandled_input(click)
	for step in range(80):
		game._physics_practice(1.0/60)
		if fx.handled>before:return game.event_history.back().duplicate(true)
		game._process(1.0/60)
		if step%20==0:await physics_frame
	return {}
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	var fx=game.get_node("SmashDirector")
	check(fx.active and fx.polished,"new entry enables the opt-in polish director")
	check(fx.effects.puffs.size()==24 and fx.trails.slots.size()==48,"extra puff/trail pools have fixed capacities")
	check(fx.audio.voices.size()==6,"one mixed hit uses a bounded six-voice positional pool")
	for w in fx.effects.words:check(not w.node.no_depth_test,"impact text keeps world depth testing")
	for key in Design.KEYS:
		var stream=Design.stream(key,0);var bytes: PackedByteArray=stream.data
		var peak:=0;var energy:=0.0;var total:=0.0
		for i in range(0,bytes.size(),2):
			var sample: int=bytes.decode_s16(i);peak=maxi(peak,absi(sample));total+=sample;energy+=sample*sample
		check(peak>250 and peak<28000,key+" has bounded nonzero authored PCM")
		check(absf(total/(bytes.size()/2))<400,key+" has no large DC offset")
		check(absi(bytes.decode_s16(0))<5 and absi(bytes.decode_s16(bytes.size()-2))<5,key+" fades at both endpoints")
		check(stream==Design.stream(key,0),key+" shares cached sample resource")
		check(bytes!=Design.stream(key,1).data,key+" has a deterministic alternative variant")
		if not key.begins_with("swing_"):
			var m: PackedByteArray=Design.stream(key,0,true).data;var me:=0.0
			for i in range(0,m.size(),2):me+=pow(m.decode_s16(i),2)
			check(me<energy,key+" occlusion recipe has lower energy")
	var rng:=RandomNumberGenerator.new();rng.seed=381;var state: int=rng.state
	Design.warm();check(rng.state==state,"audio generation does not touch an external random stream")
	for style in ["quick","balanced","heavy"]:
		fresh(style);await physics_frame
		var e:=await swing_until_contact()
		check(not e.is_empty() and e.outcome=="hit",style+" actual mouse input reaches swept contact")
		if e.is_empty():continue
		check(fx.last_contact.at.is_equal_approx(e.world_point),style+" VFX snapshot uses exact public contact point")
		check(fx.audio.onset_clock==fx.last_contact.time,style+" sound and contact have identical onset clock")
		check(fx.audio.last_key==style,style+" correct mixed transient/elastic-tail recipe")
		check(fx.reactions[1].age==0 and fx.reactions[1].scale.y<1,style+" victim is compressed before render advancement")
		check(game._motion(game.fighters[1].body_art).state=="hit",style+" Phase16 skeleton consumes the same contact")
		var p:=false
		for particle in fx.effects.particles:
			if particle.life>0 and particle.age==0:p=true
		check(p,style+" live particles have zero-age onset")
		var w=fx.effects.words[posmod(fx.effects.word_cursor-1,fx.effects.LABEL_CAPACITY)]
		check(w.node.position.is_equal_approx(w.at) and w.node.font_size<60,style+" compact label is placed immediately")
		var handled: int=fx.handled;var calls: int=fx.audio.calls
		var event:=e.duplicate(true);event.handling=style;event.finisher=false
		fx.contact(event);check(fx.handled==handled and fx.audio.calls==calls,style+" duplicate event cannot replay VFX or sound")
		var data:=authority()
		for step in range(35):game._process(1.0/60)
		check(authority()==data,style+" recoil/effects do not change camera, weapon authority, rules or assets")
		check(fx.effects.active_count()==0,style+" burst expires completely")
		check(game.rig.view_weapon.scale.is_equal_approx(Vector3.ONE*0.4),style+" original proportional display size preserved")
	# Genuine miss does not fabricate a hit, reaction or contact sound.
	fresh("balanced",false);await physics_frame
	var before: int=fx.handled;var sounds: int=fx.audio.calls;var trails_before: int=fx.trails.segments
	var miss:=await swing_until_contact()
	check(miss.is_empty() and fx.handled==before and fx.audio.calls==sounds,"real whiff has only swing sound, no hit event or impact")
	check(fx.trails.segments>trails_before,"miss traverses actual rendered weapon path and emits short trail segments")
	# Real blocker receives the existing wood outcome rather than target damage.
	fresh();var block:=StaticBody3D.new();block.collision_layer=1;game.add_child(block)
	var cs:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2.2,2.2,0.12);cs.shape=shape;block.add_child(cs);block.position=Vector3(0,1,1.72)
	await physics_frame;await physics_frame
	check(fx.occluded(Vector3(0,1,3),Vector3.BACK),"sound occlusion ray detects a real opaque wall, not hidden occupancy")
	var blocked:=await swing_until_contact()
	check(not blocked.is_empty() and blocked.outcome=="blocked","actual wall stops attack before target")
	check(fx.audio.last_key=="blocked" and game.rules.hp[1]==3,"wall uses dry knock and never causes free target damage")
	check(fx.reactions[1].life==0,"blocking does not start victim reaction")
	block.queue_free();await physics_frame;await process_frame
	fresh();await physics_frame;await swing_until_contact()
	var active_voice: AudioStreamPlayer3D=fx.audio.voices[0]
	active_voice.stream=Design.stream("heavy");active_voice.play()
	await process_frame
	check(active_voice.playing,"pause fixture starts an actual AudioStreamPlayer3D playback")
	game.paused=true
	var clock: float=fx.clock;var age: float=fx.reactions[1].age
	for i in range(4):game._process(1.0/30);fx._process(1.0/30)
	check(fx.clock==clock and fx.reactions[1].age==age,"pause freezes new effect clock and existing reaction age")
	check(fx.audio.paused_state and active_voice.stream_paused,"active impact voice receives pause state; idle voices need no playback pause")
	game.paused=false;game.preferences.volume=0;fx._process(0)
	check(fx.audio.volume==0,"mute reaches already active impact pool")
	for reduced in [true,false]:
		fresh();game.preferences.reduced_motion=reduced;game.preferences.feedback_strength=0 if not reduced else 1
		await physics_frame;await swing_until_contact()
		check(fx.effects.active_count()==0 and fx.reactions[1].life==0,"comfort/zero-strength suppress animated hit additions "+str(reduced))
		check(game.rules.hp[1]==2,"comfort/zero-strength do not alter damage "+str(reduced))
	# Bounded pool stress is cosmetic only; no synthetic authority hits.
	fresh();var old:=authority();var nodes:=count(game)
	for i in range(120):fx.effects.emit_contact(Vector3(0,1,2),Vector3.BACK,"hit","heavy",1.0)
	check(fx.effects.active_count()<=96 and fx.effects.puffs.size()==24,"burst stress stays within allocated capacities")
	check(count(game)==nodes and authority()==old,"burst stress creates no extra nodes or authority writes")
	fx.effects.advance(1,Basis.IDENTITY);check(fx.effects.active_count()==0,"all stressed particles expire")
	# Missing/nonfinite events are ignored.
	var original: int=fx.handled
	fx.contact({});fx.contact({"world_point":Vector3(INF,0,0),"normal":Vector3.BACK})
	check(fx.handled==original,"malformed contact facts are ignored safely")
	fx.trails.history[1]={"attack":1,"at":Vector3.ZERO};game.fighters[1].set_hidden(true,0)
	fx.trails.advance(1.0/60,game,true)
	check(not fx.trails.history.has(1),"hidden actor loses trail source without revealing a new position")
	fx.reset();check(fx.trails.history.is_empty() and fx.effects.active_count()==0 and fx.last_contact.is_empty(),"reset clears trails, contact facts and bursts")
	fx.set_polished(false);check(not fx.effects.polished and not fx.audio.polished,"comparison restores original presentation paths")
	check(fx.reactions[1].stars.get_child(0).scale.is_equal_approx(Vector3.ONE*0.21),"comparison restores original star scale without stale reduced size")
	fx.set_polished(true);check(fx.effects.polished and fx.audio.polished,"comparison reenables new paths without changing gameplay")
	for map_id in ["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu();game.select_map(map_id);game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
		await process_frame;await process_frame;game._process(0)
		check(game.arena.map_id==map_id,map_id+" is actually selected")
		check(game.fighters[1].body_art.skeleton.get_bone_count()==18,map_id+" retains original skinned rig")
		check(game.rig.drawn_size_view and game.rig.cute_sync,map_id+" keeps proportional lowered paws/contact view")
		old=authority();fx.set_polished(false);fx.set_polished(true)
		check(authority()==old,map_id+" toggle preserves all authority state")
	game.queue_free();await process_frame
	print("FEEL18_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
