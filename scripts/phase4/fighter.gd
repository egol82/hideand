extends "res://scripts/phase3/fighter.gd"
const Attack = preload("res://scripts/phase4/attack_spec.gd")
const Form4 = preload("res://scripts/phase4/weapon_form.gd")
const Art4 = preload("res://scripts/phase4/art.gd")
var handling := "balanced"
var drawing_revision := 0
var attack_sequence := 0
var buffered := 0.0
var previous_elapsed := -1.0
var active_window := false
var blocked := false
var outcome := "idle"
var previous_transform := Transform3D.IDENTITY
var old_position := Vector3.ZERO
var motion := Vector3.ZERO
var dodge_direction := Vector3.ZERO
var swing_finished := false

func _ready() -> void:
	super._ready()
	var old := visual
	old.remove_child(weapon_pivot)
	remove_child(old)
	old.queue_free()
	visual = Art4.avatar(tint)
	add_child(visual)
	visual.add_child(weapon_pivot)
	old_position = position

func equip(data) -> void:
	weapon_data = data.clone()
	handling = str(data.to_dictionary().get("handling","balanced"))
	hit_samples = Form4.samples(weapon_data)
	if is_instance_valid(weapon):
		weapon_pivot.remove_child(weapon)
		weapon.queue_free()
	weapon = Form4.build(weapon_data)
	weapon_pivot.add_child(weapon)
	drawing_revision += 1
	cancel_attack()
	_apply_pose()
	previous_samples = global_hit_samples()

func _apply_pose() -> void:
	var pose := Attack.pose(handling,elapsed)
	# Absolute assignment: there is exactly one owner of the weapon transform.
	pose.x -= clampf(view_pitch,-0.9,0.9) if use_view_aim else 0.0
	weapon_pivot.rotation = pose

func begin_swing() -> bool:
	if hidden_in_box or not visible or down_time > 0 or weapon_data == null: return false
	if elapsed >= 0 or cooldown > 0:
		buffered = Attack.BUFFER
		return false
	elapsed = 0
	previous_elapsed = 0
	cooldown = Attack.duration(handling)
	attack_sequence += 1
	hit_ids.clear()
	blocked = false
	outcome = "pending"
	_apply_pose()
	previous_transform = weapon_pivot.global_transform
	return true

func cancel_attack() -> void:
	elapsed = -1
	previous_elapsed = -1
	buffered = 0
	cooldown = 0
	active_window = false
	blocked = false
	outcome = "idle"
	hit_ids.clear()

func step(delta: float, desired: Vector3, aim: Vector3) -> void:
	if not is_finite(delta) or delta <= 0: return
	old_position = position
	old_center = global_position+Vector3.UP*0.75
	previous_samples = global_hit_samples()
	previous_transform = weapon_pivot.global_transform
	previous_elapsed = elapsed
	swing_finished = false
	cooldown = maxf(0,cooldown-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	active_window = false
	if hidden_in_box or not visible:
		cancel_attack()
		velocity = Vector3.ZERO
		motion = Vector3.ZERO
		return
	if elapsed >= 0:
		elapsed += delta
		active_window = Attack.overlaps_active(handling,previous_elapsed,elapsed) and not blocked
		if elapsed >= Attack.duration(handling):
			swing_finished = true
			elapsed = -1
	if elapsed < 0 and buffered > 0:
		buffered = 0
		begin_swing()
	else:
		buffered = maxf(0,buffered-delta)
	if aim.length_squared() > 0.001:
		visual.rotation.y = atan2(aim.x,aim.z)
	var wish := desired.limit_length()
	motion = motion.move_toward(wish*SPEED,delta*(40 if wish.length_squared() > 0 else 52))
	var pace: float = Attack.spec(handling).move if elapsed >= 0 else 1.0
	var travel := motion*pace
	if dash_time > 0:
		dash_time = maxf(0,dash_time-delta)
		travel = dodge_direction*SPEED*2.25
	velocity.x = travel.x+knock_velocity.x
	velocity.z = travel.z+knock_velocity.z
	knock_velocity = knock_velocity.move_toward(Vector3.ZERO,delta*20)
	if is_on_floor(): velocity.y = maxf(velocity.y,0)
	else: velocity.y -= 18*delta
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.5: knock_velocity = knock_velocity.slide(normal)
	flash = maxf(0,flash-delta)
	move_phase += Vector2(velocity.x,velocity.z).length()*delta*2.9
	visual.position.y = absf(sin(move_phase))*minf(wish.length(),1)*0.038
	visual.scale = Vector3(1.08,0.91,1.08) if flash > 0 else Vector3.ONE
	visual.rotation.z = -sin(move_phase)*wish.length()*0.025
	visual.get_node("LeftFoot").position.z = 0.10+sin(move_phase)*0.10*wish.length()
	visual.get_node("RightFoot").position.z = 0.10-sin(move_phase)*0.10*wish.length()
	visual.get_node("RightArm").rotation.z = -Attack.progress(handling,elapsed)*0.4 if elapsed >= 0 else 0.0
	visual.get_node("Mouth").scale.y = 0.084 if flash > 0 else 0.042
	_apply_pose()

func attack_active() -> bool:
	return active_window and not blocked

func begin_dash(direction: Vector3) -> void:
	if dash_cooldown > 0 or hidden_in_box or not visible: return
	dodge_direction = direction.normalized() if direction.length_squared() > 0.001 else visual.global_basis.z
	dash_time = 0.13
	dash_cooldown = 0.85

func take_hit(direction: Vector3) -> bool:
	if hidden_in_box or not visible: return false
	flash = 0.14
	knock_velocity = direction.normalized()*6.2
	velocity.y = 1.8
	return true

func reset_fight(at: Vector3) -> void:
	super.reset_fight(at)
	motion = Vector3.ZERO
	knock_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	cancel_attack()
	old_position = at
	old_center = at+Vector3.UP*0.75
	_apply_pose()
	previous_transform = weapon_pivot.global_transform
