extends SceneTree
const Scene=preload("res://scenes/phase16.tscn")
const Clips=preload("res://scripts/animation16/clips.gd")
const IK=preload("res://scripts/animation16/two_bone.gd")
const Data=preload("res://scripts/phase4/drawing_data.gd")
const Attack=preload("res://scripts/phase4/attack_spec.gd")
var checks:=0
var failures:=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+text)
func nodes(n: Node) -> int:
	var count:=1
	for child in n.get_children():count+=nodes(child)
	return count
func bones(sk: Skeleton3D) -> Array:
	var out: Array=[]
	for i in range(sk.get_bone_count()):out.append(sk.get_bone_pose(i))
	return out
func authority() -> Array:
	var out: Array=[game.rules.time_left,game.rules.hp.duplicate(),game.rules.scores.duplicate(),game.rules.phase,game.rig.transform,game.arena.spots.duplicate()]
	for a in game.fighters:out.append([a.transform,a.velocity,a.weapon.global_transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.body_art.body.mesh,a.body_art.body.skin,a.collision_layer,a.collision_mask])
	return out
func valid_bones(sk: Skeleton3D) -> bool:
	for i in range(sk.get_bone_count()):
		if not sk.get_bone_pose(i).is_finite() or not sk.get_bone_pose_scale(i).is_equal_approx(Vector3.ONE):return false
	return true
func settle(actor) -> void:
	for i in range(12):actor.step(1.0/60,Vector3.ZERO,Vector3.BACK)
	game._sync_characters(1.0/60)
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	game.select_map("toy_home");game.start_practice();game.accept_drawing()
	var actor=game.fighters[1];actor.reset_fight(Vector3(0,0,2.3));settle(actor)
	var m=game._motion(actor.body_art);var sk: Skeleton3D=actor.body_art.skeleton
	var fx=game.get_node("SmashDirector");var reaction=fx.reactions[1]
	var lib=Clips.library()
	check(lib.get_animation_list().size()==12,"twelve actual named skeletal clips")
	check(lib==Clips.library(),"library cached and shared, not regenerated every update")
	for name in Clips.STATES:
		var clip=lib.get_animation(name);var safe:=true
		for t in range(clip.get_track_count()):
			if clip.track_get_type(t) not in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D]:safe=false
			if not str(clip.track_get_path(t)).begins_with("Skeleton3D:"):safe=false
		check(safe,name+" contains only bone tracks, no event or authority tracks")
		for rate in [30,60,120]:
			m.reset()
			for step in range(rate):m.evaluate(name,float(step)/rate,1.0/rate)
			check(valid_bones(sk),name+" finite unit-scale bones at "+str(rate)+"Hz")
	m.evaluate("ko",0.8,0);m.reset();m.evaluate("idle",0.2,0)
	check(m.player.assigned_animation=="idle","reset from KO actually restores idle clip, not only its state label")
	# Solve actual skeleton chains, with a rotated torso and distant/degenerate targets.
	for target in [Vector3(0.45,0.90,0.13),Vector3(0.48,1.0,0.14),Vector3(1.8,2,2),Vector3(0.33,1,0)]:
		sk.reset_bone_poses();sk.set_bone_pose_rotation(1,Quaternion(Vector3.UP,0.21))
		var report=IK.solve(sk,7,8,9,target,Vector3(0.8,-1,-0.2))
		check(report.valid and valid_bones(sk),"rotated-parent IK yields finite pose "+str(target))
		check(absf(sk.get_bone_global_pose(8).origin.distance_to(sk.get_bone_global_pose(7).origin)-report.length_a)<0.0001,"IK preserves upper limb length")
		check(absf(sk.get_bone_global_pose(9).origin.distance_to(sk.get_bone_global_pose(8).origin)-report.length_b)<0.0001,"IK preserves lower limb length")
		if not report.clamped:check(report.endpoint.distance_to(target)<0.0001,"reachable IK endpoint meets target")
	check(not IK.solve(sk,7,8,9,Vector3(INF,0,0),Vector3.UP).valid,"nonfinite IK request is rejected")
	actor.reset_fight(Vector3(0,0,2.3));settle(actor)
	for type in Attack.IDS:
		actor.handling=type;actor.begin_swing();var s=Attack.spec(type)
		for entry in [["windup",s.windup*0.5],["attack",s.windup+s.active*0.5],["recover",s.windup+s.active+s.recovery*0.5]]:
			actor.elapsed=entry[1];actor._apply_pose();m.update_actor(actor,reaction,0,false)
			check(m.state==entry[0],type+" shared AttackSpec selects "+entry[0])
			check(absf(m.sample_time-0.5)<0.001,type+" clip clock equals authoritative half-stage")
			check(m.right_error<0.025 or m.hand_clamped,type+" hand reaches real stroke or explicitly clamps")
		actor.cancel_attack()
	# Hands: old data/collisions unaffected by varying input directions/large shapes.
	for shape in ["fish","pan","hammer"]:
		var d=Data.new();d.set_preset(shape);actor.equip(d)
		m.update_actor(actor,reaction,0,false)
		check(actor.weapon_data.to_dictionary()==d.to_dictionary(),shape+" IK never modifies drawing")
		check(m.right_error<0.025 or m.hand_clamped,shape+" actual reachable primary grip")
	var staff=Data.new();staff.grip=Vector2(0.50,0.88);staff.strokes.append(PackedVector2Array([staff.grip,Vector2(0.50,0.08)]));actor.equip(staff)
	# Test a geometrically reachable left-facing shaft and an unreachable opposite pose.
	actor.weapon_pivot.rotation=Vector3(0,-PI/2,0);m.update_actor(actor,reaction,0,false)
	check(m.grip_mode=="two_hand" and m.left_error<0.005,"two-handed long REAL shaft when both arms can reach")
	actor.weapon_pivot.rotation=Vector3(0,PI/2,0);m.update_actor(actor,reaction,0,false)
	check(m.grip_mode=="one_hand","support hand releases unreachable shaft without bone stretch")
	actor.reset_fight(Vector3(0,0,2.3));settle(actor);actor.show_weapon(false)
	check(actor.is_on_floor(),"foot tests use an actual grounded CharacterBody")
	m.update_actor(actor,reaction,0,false)
	check(m.ground_hits==2,"actual floor rays support both feet")
	var count:=nodes(game);var before:=authority()
	for i in range(60):game._sync_characters(1.0/60)
	check(authority()==before,"pose/IK updates preserve capsule, movement, weapon, clock and score")
	check(nodes(game)==count,"steady update does not create scene nodes")
	var old_phase: float=m.locomotion_phase
	for i in range(20):m.update_actor(actor,reaction,1.0/60,false)
	check(is_equal_approx(old_phase,m.locomotion_phase),"stationary actor does not walk in place")
	for i in range(12):actor.step(1.0/60,Vector3.RIGHT*0.6,Vector3.BACK);game._sync_characters(1.0/60)
	check(m.state=="walk" and m.locomotion_phase!=old_phase,"real movement drives walk clip by distance")
	actor.begin_dash(Vector3.RIGHT);actor.step(1.0/60,Vector3.RIGHT,Vector3.BACK);game._sync_characters(1.0/60)
	check(m.state=="run","actual dash selects run clip")
	actor.reset_fight(Vector3(0,0,2.3));settle(actor)
	game.paused=true;var pose:=bones(sk);var clock: float=m.local_clock
	for i in range(12):game._process(1.0/60)
	check(bones(sk)==pose and m.local_clock==clock,"pause freezes final IK pose and all local motion clocks")
	game.paused=false
	m.update_actor(actor,reaction,0,true);clock=m.local_clock
	for i in range(12):m.update_actor(actor,reaction,1.0/60,true)
	check(m.local_clock==clock and is_zero_approx(m.ear_angle),"comfort mode disables breathing/ear secondary motion")
	actor.set_hidden(true,0);m.update_actor(actor,reaction,0,false,false)
	check(m.state=="hide" and not actor.body_art.body.is_visible_in_tree(),"hide pose never exposes hidden body")
	m.update_actor(actor,reaction,0,false,true)
	check(m.state=="peek" and not actor.body_art.features.LeftEye.is_visible_in_tree(),"peek pose does not bypass approved exposure markers")
	actor.set_hidden(false)
	# A real attack/contact starts HIT pose on the same consume-event call, at age zero.
	game.return_to_menu();game.select_map("toy_home");game.start_practice();game.accept_drawing()
	var a=game.fighters[0];var b=game.fighters[1]
	a.reset_fight(Vector3(0,0,1));b.reset_fight(Vector3(0,0,2.3));a.handling="balanced";game.rig.face(Vector3.BACK)
	game.preferences.reduced_motion=false;game.preferences.feedback_strength=1;game._process(0)
	var hit_before: int=fx.handled
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;game._unhandled_input(click)
	var contact:=false
	for step in range(60):
		game._physics_practice(1.0/60)
		if fx.handled>hit_before:
			contact=true
			var victim=game._motion(b.body_art)
			check(victim.state=="hit" and victim.sample_time<0.0001,"actual contact already applied zero-age HIT bone pose before render advance")
			check(fx.effects.emissions>0 if "emissions" in fx.effects else fx.handled>hit_before,"contact VFX and skeleton share confirmed event")
			break
		await physics_frame
	check(contact,"actual input and swept collision reached target")
	for map_id in ["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu();game.select_map(map_id);game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1);game._process(0)
		await process_frame;await process_frame
		check(game.arena.map_id==map_id,map_id+" selected map is really active")
		check(game._motion(game.fighters[1].body_art).player.has_animation("run"),map_id+" live actor uses native clips")
		check(game.fighters[1].body_art.skeleton.get_bone_count()==18,map_id+" original skeleton is preserved")
		check(game.rig.view_weapon.scale.is_equal_approx(Vector3.ONE*0.40),map_id+" proportional first-person weapon is preserved")
	game.queue_free();await process_frame
	print("ANIMATION16_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
