extends "res://scripts/phase3/first_person.gd"
const Art4 = preload("res://scripts/phase4/art.gd")
const Form4 = preload("res://scripts/phase4/weapon_form.gd")
const Attack4 = preload("res://scripts/phase4/attack_spec.gd")
const GripRig = preload("res://scripts/viewmodel/grip_rig.gd")
var grip_rig
var hand_sway := 0.65
var head_bob := 0.35
var feedback_strength := 0.65
var kick := 0.0
var kick_kind := ""
var last_actor := -1
var last_revision := -1
var display_progress := 0.0
var rebuild_count := 0
# Opt-in only: earlier test scenes retain their original viewmodel.
var cute_sync := false
# Opt-in for Phase12: one view scale for all drawings, no inverse reach normalisation.
var drawn_size_view := false
const DRAWING_VIEW_SCALE := 0.40
var rested_weapon_bounds := Rect2()
var contact_pose := Transform3D.IDENTITY
var contact_age := 1.0
var contact_fresh := false
var contact_actor := -1
var contact_attack := -1
var contact_point := Vector3.ZERO
var contact_local := Vector3.ZERO
var contact_rendered := false
var display_anchor := Vector3.ZERO
const CONTACT_LIFE := 0.055

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
	if drawn_size_view:
		hand_root.position += Vector3(0.055,-0.13,-0.11)
		_clear_center_view()
	if cute_sync:
		# Larger rest silhouette; during the active swing use projected authority geometry,
		# not a second unrelated screen-space swing curve.
		hand_root.position += Vector3(0.025,-0.045,-0.075)
		_align_attack(actor,delta)
	if is_instance_valid(grip_rig): grip_rig.update_pose(hand_root,sweep)
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
	mount.rotation_degrees = Vector3(-90,0,-42 if drawn_size_view else -12)
	hand_root.add_child(mount)
	view_weapon = Form4.build(actor.weapon_data)
	var display_scale := minf(0.27,0.44/maxf(0.1,actor.weapon_data.reach()))
	if cute_sync: display_scale = clampf(0.68/maxf(0.1,actor.weapon_data.reach()),0.32,0.46)
	if drawn_size_view: display_scale = DRAWING_VIEW_SCALE
	view_weapon.scale = Vector3.ONE*display_scale
	mount.add_child(view_weapon)
	display_anchor = Vector3.ZERO
	for point in actor.hit_samples:
		if point.length_squared() > display_anchor.length_squared(): display_anchor = point
	grip_rig = preload("res://scripts/viewmodel/cute_grip.gd").new() if cute_sync else GripRig.new()
	clear_contact()
	hand_root.add_child(grip_rig)
	grip_rig.configure(actor.weapon_data,mount.basis,view_weapon.scale.x,actor.tint)
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

func clear_contact() -> void:
	contact_age = 1.0
	contact_fresh = false
	contact_actor = -1
	contact_rendered = false

func register_contact(event: Dictionary, actor) -> void:
	if not cute_sync or actor.player_id != subject_id: return
	if event.get("outcome") not in ["hit","blocked"]: return
	if not event.get("weapon_transform") is Transform3D or not event.get("weapon_local_point") is Vector3: return
	var pose: Transform3D = event.weapon_transform
	var point: Vector3 = event.weapon_local_point
	var at: Vector3 = event.world_point
	if not pose.is_finite() or absf(pose.basis.determinant()) < 0.00001 or not at.is_finite() or not point.is_finite(): return
	# Swept collision resolves a contact between physics samples. Pin its selected
	# drawing point to that observed contact only in the cosmetic snapshot.
	pose.origin += at-pose*point
	contact_pose = pose
	contact_point = at
	contact_local = point
	contact_actor = actor.get_instance_id()
	contact_attack = actor.attack_sequence
	contact_age = 0.0
	contact_fresh = true
	contact_rendered = false

func _align_attack(actor, delta: float) -> void:
	subject_id = actor.player_id
	var s := Attack4.spec(actor.handling)
	var weight := 0.0
	if actor.elapsed >= 0:
		if actor.elapsed < s.windup: weight = smoothstep(0.0,s.windup,actor.elapsed)
		elif actor.elapsed <= s.windup+s.active: weight = 1.0
		else: weight = 1.0-smoothstep(0.0,s.recovery,actor.elapsed-s.windup-s.active)
	var sampled: Transform3D = actor.weapon.global_transform
	var same_contact: bool = actor.get_instance_id() == contact_actor and actor.attack_sequence == contact_attack and contact_age < CONTACT_LIFE
	if same_contact:
		if not contact_fresh: contact_age = minf(CONTACT_LIFE,contact_age+maxf(0,delta))
		contact_fresh = false
		var blend := smoothstep(0.0,CONTACT_LIFE,contact_age)
		sampled = contact_pose.interpolate_with(sampled,blend)
		weight = maxf(weight,1.0-blend)
		contact_rendered = true
	if weight <= 0: return
	# Project an actual drawing anchor to a safe viewmodel depth. At contact this is
	# the exact struck sample, not an independently timed screen swing. Keeping a
	# bounded depth prevents the enlarged prop/arms from crossing the near plane.
	var anchor := display_anchor
	if same_contact: anchor = contact_local.lerp(display_anchor,smoothstep(0.0,CONTACT_LIFE,contact_age))
	var local := view.global_transform.affine_inverse()*sampled
	var projected_anchor: Vector3 = local*anchor
	if projected_anchor.z >= -0.05: return
	var factor := view_weapon.scale.x
	var depth := maxf(0.90,actor.weapon_data.reach()*factor+0.18)
	var on_ray := projected_anchor*(depth/-projected_anchor.z)
	local.basis = local.basis.scaled(Vector3.ONE*factor)
	local.origin = on_ray-local.basis*anchor
	var geometry: Transform3D = mount.transform*view_weapon.transform
	var desired := local*geometry.affine_inverse()
	hand_root.transform = hand_root.transform.interpolate_with(desired,weight)

func _clear_center_view() -> void:
	if not is_instance_valid(view_weapon) or view_weapon.mesh == null: return
	# Move, never resize. A quiet centre window is reserved during idle; contact alignment
	# deliberately overrides this pose during an attack, so impacts never miss visually.
	var aabb := view_weapon.mesh.get_aabb()
	var local := hand_root.transform*mount.transform*view_weapon.transform
	var points: Array[Vector3] = []
	for i in range(8): points.append(local*aabb.get_endpoint(i))
	var viewport_size := get_viewport().get_visible_rect().size
	var centre_limit := viewport_size.x*0.66
	var horizon_limit := viewport_size.y*0.60
	var needed_drop := 0.0
	var projected_rect := Rect2()
	var first := true
	for point in points:
		if point.z >= -0.05: continue
		var screen := view.unproject_position(view.global_transform*point)
		if first: projected_rect=Rect2(screen,Vector2.ZERO); first=false
		else: projected_rect=projected_rect.expand(screen)
		if screen.x<centre_limit and screen.y<horizon_limit:
			var threshold := view.project_position(Vector2(screen.x,horizon_limit),-point.z)
			needed_drop=maxf(needed_drop,point.y-(view.global_transform.affine_inverse()*threshold).y)
	hand_root.position.y-=minf(0.56,needed_drop)
	rested_weapon_bounds=projected_rect
