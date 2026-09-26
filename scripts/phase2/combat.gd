extends RefCounted
const Data = preload("res://scripts/weapon_data.gd")

static func contact(attacker, target, space: PhysicsDirectSpaceState3D) -> bool:
	if not attacker.attack_active() or not target.visible or target.hidden_in_box:
		return false
	if target.dash_time > 0.0 or attacker.hit_ids.has(target.get_instance_id()):
		return false
	var now: PackedVector3Array = attacker.global_hit_samples()
	var old: PackedVector3Array = attacker.previous_samples
	if old.size() != now.size():
		old = now
	var center: Vector3 = target.global_position + Vector3.UP
	# Relative movement catches a moving opponent, not just a stationary target.
	for i in range(now.size()):
		var relative_before: Vector3 = old[i] - target.old_center
		var relative_after: Vector3 = now[i] - center
		if Data.distance_to_segment(Vector3.ZERO,relative_before,relative_after) > 0.47 + Data.TUBE_RADIUS:
			continue
		var ray := PhysicsRayQueryParameters3D.create(attacker.weapon_pivot.global_position,center,1)
		if not space.intersect_ray(ray).is_empty():
			continue
		attacker.hit_ids[target.get_instance_id()] = true
		return true
	return false
