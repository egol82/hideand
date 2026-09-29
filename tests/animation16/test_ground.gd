extends SceneTree
const Scene=preload("res://scenes/phase16.tscn")
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func run() -> void:
	var game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await physics_frame;game.set_process(false)
	var actor=game.fighters[1];var anim=game._motion(actor.body_art)
	for a in game.fighters:
		if a!=actor:a.set_hidden(true,0)
	for side in [-1,1]:
		for up in [true,false]:
			var start:=Vector3(side*11,0,9 if side==-1 else -9)
			var end:=Vector3(side*11,4,-9 if side==-1 else 9)
			if not up:var swap:=start;start=end;end=swap
			actor.reset_fight(start);actor.show_weapon(false);anim.reset()
			var supported:=0;var valid:=true;var slopes:=0;var max_error:=0.0
			for step in range(480):
				var desired: Vector3=end-actor.position;desired.y=0
				actor.step(1.0/60,desired.normalized(),desired)
				anim.update_actor(actor,null,1.0/60,false)
				if anim.ground_hits==2:supported+=1
				if actor.is_on_floor() and actor.get_floor_normal().y<0.99:slopes+=1
				for i in range(actor.body_art.skeleton.get_bone_count()):
					if not actor.body_art.skeleton.get_bone_pose(i).is_finite():valid=false
				for j in range(anim.ground_hits):
					if not anim.foot_targets[j].is_finite():valid=false
				if step%60==0:await physics_frame
				if actor.position.distance_to(end)<0.45:break
			check(actor.position.distance_to(end)<0.5,"physical staircase traversal side=%d up=%s"%[side,up])
			check(supported>30,"both feet have real floor-ray targets during stair traversal")
			check(slopes>20,"test really traversed ramp-backed stair slope")
			check(valid,"all stair IK bones and targets remain finite")
	# Same target on a flat landing with the visual body bobbing: planted world foot does not chase the bob.
	actor.reset_fight(Vector3(0,0,0))
	for i in range(12):actor.step(1.0/60,Vector3.ZERO,Vector3.BACK)
	anim.update_actor(actor,null,0,false)
	var locked: Vector3=anim.foot_targets[0]
	for i in range(30):actor.body_art.position.y=0.012*sin(i*0.2);anim.update_actor(actor,null,1.0/60,false)
	check(anim.foot_targets[0].distance_to(locked)<0.0001,"stance target stays in world space despite body bounce")
	actor.velocity.y=2;actor.position.y=1.2;actor.step(1.0/60,Vector3.ZERO,Vector3.BACK);anim.update_actor(actor,null,1.0/60,false)
	check(anim.state=="air" and anim.ground_hits==0 and anim.plants[0].is_empty(),"airborne movement releases planted feet")
	game.queue_free();await process_frame
	print("ANIMATION16_GROUND_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
