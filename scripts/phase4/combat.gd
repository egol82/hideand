extends RefCounted
## Authority creates typed-outcome events; display/score/audio consume the same facts.
const Attack = preload("res://scripts/phase4/attack_spec.gd")
const RADIUS := 0.425

static func event(attacker, target, at: Vector3, normal: Vector3, outcome: String, surface: String = "vinyl") -> Dictionary:
	return {"attack_id":attacker.attack_sequence,"attacker_id":attacker.player_id,"target_id":target.player_id if target != null else -1,"world_point":at,"normal":normal,"surface":surface,"outcome":outcome}

static func contact(attacker, target, space: PhysicsDirectSpaceState3D) -> Dictionary:
	if not attacker.attack_active() or not target.visible or target.hidden_in_box or target.dash_time > 0:
		return {}
	if attacker.hit_ids.has(target.get_instance_id()): return {}
	if attacker.position.distance_to(target.position) > attacker.weapon_data.reach()+1.5: return {}
	var now: Transform3D = attacker.weapon_pivot.global_transform
	var old: Transform3D = attacker.previous_transform
	var angular := old.basis.get_rotation_quaternion().angle_to(now.basis.get_rotation_quaternion())
	var steps := clampi(ceili(angular/0.15),1,12)
	var elapsed_delta: float = attacker.elapsed-attacker.previous_elapsed
	var s := Attack.spec(attacker.handling)
	var t0 := 0.0
	var t1 := 1.0
	if elapsed_delta > 0.00001:
		t0 = clampf((s.windup-attacker.previous_elapsed)/elapsed_delta,0,1)
		t1 = clampf((s.windup+s.active-attacker.previous_elapsed)/elapsed_delta,0,1)
	var center: Vector3 = target.global_position+Vector3.UP*0.75
	for j in range(steps):
		var lo := lerpf(t0,t1,float(j)/steps)
		var hi := lerpf(t0,t1,float(j+1)/steps)
		var from := old.interpolate_with(now,lo)
		var to := old.interpolate_with(now,hi)
		var c0: Vector3 = target.old_center.lerp(center,lo)
		var c1: Vector3 = target.old_center.lerp(center,hi)
		for point in attacker.hit_samples:
			var a: Vector3 = from*point
			var b: Vector3 = to*point
			var closest := Geometry3D.get_closest_points_between_segments(a-c0,b-c1,Vector3(0,-0.365,0),Vector3(0,0.365,0))
			if closest[0].distance_squared_to(closest[1]) > RADIUS*RADIUS: continue
			var at := closest[0]+c1
			# Check both swept path and grip-to-contact segment, never the target centre.
			for ends in [[a,b],[to.origin,at]]:
				var query := PhysicsRayQueryParameters3D.create(ends[0],ends[1],1)
				query.hit_from_inside = true
				var obstruction := space.intersect_ray(query)
				if not obstruction.is_empty():
					attacker.blocked = true
					attacker.outcome = "blocked"
					return event(attacker,null,obstruction.position,obstruction.normal,"blocked","wood")
			attacker.hit_ids[target.get_instance_id()] = true
			attacker.outcome = "hit"
			return event(attacker,target,at,(attacker.position-target.position).normalized(),"hit")
	return {}

static func wall_contact(attacker, space: PhysicsDirectSpaceState3D) -> Dictionary:
	if not attacker.attack_active() or attacker.outcome != "pending": return {}
	var now: Transform3D = attacker.weapon_pivot.global_transform
	var step := maxi(1,attacker.hit_samples.size()/20)
	for i in range(0,attacker.hit_samples.size(),step):
		var at: Vector3 = now*attacker.hit_samples[i]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(now.origin,at,1))
		if not hit.is_empty():
			attacker.blocked = true
			attacker.outcome = "blocked"
			return event(attacker,null,hit.position,hit.normal,"blocked","wood")
	return {}

static func viewer_feedback(e: Dictionary, viewer: int) -> String:
	if e.outcome == "hit":
		if e.attacker_id == viewer: return "hit"
		if e.target_id == viewer: return "hurt"
	elif e.attacker_id == viewer:
		return e.outcome
	return "other"
