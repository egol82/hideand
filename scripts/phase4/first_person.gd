extends "res://scripts/phase3/first_person.gd"
const Art4 = preload("res://scripts/phase4/art.gd")
const Form4 = preload("res://scripts/phase4/weapon_form.gd")
const Attack4 = preload("res://scripts/phase4/attack_spec.gd")
var hand_sway := 0.65
var head_bob := 0.35
var feedback_strength := 0.65
var kick := 0.0
var kick_kind := ""
var last_actor := -1
var last_revision := -1
var display_progress := 0.0
var rebuild_count := 0

func follow(actor, delta: float, aim_locked: bool, visible_hands: bool) -> void:
	var fraction := Engine.get_physics_interpolation_fraction()
	var at: Vector3 = actor.old_position.lerp(actor.global_position,fraction)
	if actor.old_position.distance_to(actor.global_position) > 3: at = actor.global_position
	position = at+Vector3.UP*EYE_HEIGHT
	if aim_locked:
		var facing: Vector3 = actor.visual.global_basis.z
		yaw = atan2(-facing.x,-facing.z)
		pitch = -0.04
	_apply_rotation() # Mouse rotation remains immediate, independent of translation interpolation.
	if actor.get_instance_id() != last_actor or actor.drawing_revision != last_revision:
		last_actor = actor.get_instance_id()
		last_revision = actor.drawing_revision
		_rebuild(actor)
	hand_root.visible = visible_hands
	wall_retract = move_toward(wall_retract,_wall_amount(),delta*9)
	gait += Vector2(actor.velocity.x,actor.velocity.z).length()*delta*2.7
	sway = sway.lerp(Vector2.ZERO,1-exp(-delta*12))
	kick = maxf(0,kick-delta)
	var pose := Attack4.pose(actor.handling,actor.elapsed)
	display_progress = Attack4.progress(actor.handling,actor.elapsed) if actor.elapsed >= 0 else 0
	var sweep := (pose.y+0.75)/1.8
	var bob := Vector3.ZERO
	if not reduced_motion and not aim_locked:
		bob = Vector3(sin(gait)*0.008,absf(cos(gait))*0.012,0)*head_bob
		bob += Vector3(-sway.x,sway.y,0)*hand_sway
	var recoil := 0.0 if reduced_motion else sin(kick/0.14*PI)*0.055*feedback_strength
	hand_root.position = Vector3(0.39-0.43*sweep,-0.34-0.19*wall_retract+0.04*sweep,-0.80+wall_retract*0.25+recoil)+bob
	hand_root.rotation = Vector3(-0.55*wall_retract,0.22*sweep,0.9*sweep)
	if wall_retract > 0.96: hand_root.visible = false

func feedback(kind: String) -> void:
	kick_kind = kind
	kick = 0.14

func _rebuild(actor) -> void:
	rebuild_count += 1
	for child in hand_root.get_children():
		hand_root.remove_child(child)
		child.queue_free()
	mount = Node3D.new()
	mount.rotation_degrees = Vector3(-90,0,-12)
	hand_root.add_child(mount)
	view_weapon = Form4.build(actor.weapon_data)
	view_weapon.scale = Vector3.ONE*minf(0.27,0.44/maxf(0.1,actor.weapon_data.reach()))
	mount.add_child(view_weapon)
	Art4.mitten(hand_root,Vector3(0,0,0),actor.tint)
	Art4.mitten(hand_root,Vector3(-0.17,-0.12,0.06),actor.tint,true).rotation.z = -0.27
	_layers(hand_root)

func _wall_amount() -> float:
	var closest := 2.0
	var eye := view.global_position
	# Multi-ray footprint catches side protrusions missed by the old centre-only probe.
	for offset in [Vector2.ZERO,Vector2(-0.38,0),Vector2(0.38,0),Vector2(0,0.30),Vector2(0,-0.27),Vector2(0.35,0.24),Vector2(-0.35,0.24)]:
		var target: Vector3 = eye-view.global_basis.z*1.15+view.global_basis.x*offset.x+view.global_basis.y*offset.y
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,target,1))
		if not hit.is_empty(): closest = minf(closest,eye.distance_to(hit.position))
	return clampf((0.96-closest)/0.73,0,1)
