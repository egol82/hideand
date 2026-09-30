extends RefCounted
## Analytic positional IK in skeleton space; clamps unreachable targets, never stretches bones.
static func solve(s: Skeleton3D, upper: int, lower: int, tip: int, target: Vector3, pole: Vector3) -> Dictionary:
	if not target.is_finite() or not pole.is_finite(): return {"valid":false}
	var origin := s.get_bone_global_pose(upper).origin
	var rest_a := s.get_bone_pose_position(lower)
	var rest_b := s.get_bone_pose_position(tip)
	var la := rest_a.length(); var lb := rest_b.length()
	if la < 0.0001 or lb < 0.0001: return {"valid":false}
	var offset := target-origin
	var direction := offset.normalized() if offset.length()>0.00001 else Vector3.DOWN
	var distance := clampf(offset.length(),absf(la-lb)+0.0005,la+lb-0.0005)
	var bend := pole-direction*pole.dot(direction)
	if bend.length_squared() < 0.00001:
		var helper := Vector3.RIGHT if absf(direction.x)<0.8 else Vector3.BACK
		bend = helper-direction*helper.dot(direction)
	bend = bend.normalized()
	var along := (la*la-lb*lb+distance*distance)/(2.0*distance)
	var height := sqrt(maxf(0.0,la*la-along*along))
	var elbow := origin+direction*along+bend*height
	var endpoint := origin+direction*distance
	var qa := Quaternion(rest_a.normalized(),(elbow-origin).normalized())
	var qb := Quaternion(rest_b.normalized(),(endpoint-elbow).normalized())
	var parent := s.get_bone_parent(upper)
	var parent_q := s.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion() if parent>=0 else Quaternion.IDENTITY
	s.set_bone_pose_rotation(upper,(parent_q.inverse()*qa).normalized())
	s.set_bone_pose_rotation(lower,(qa.inverse()*qb).normalized())
	return {"valid":true,"requested":target,"endpoint":s.get_bone_global_pose(tip).origin,"clamped":absf(distance-offset.length())>0.001,"length_a":la,"length_b":lb}

static func orient(s: Skeleton3D,tip: int,world_in_skeleton: Basis) -> void:
	var parent := s.get_bone_parent(tip)
	var parent_q := s.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion()
	s.set_bone_pose_rotation(tip,(parent_q.inverse()*world_in_skeleton.orthonormalized().get_rotation_quaternion()).normalized())
