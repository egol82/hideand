extends CharacterBody3D
const Toy = preload("res://scripts/toy_factory.gd")
const WeaponMesh = preload("res://scripts/weapon_mesh.gd")

const SPEED := 4.2
const SWING_DURATION := 0.48
const ACTIVE_START := 0.09
const ACTIVE_END := 0.34

var tint := Color("88d6b0")
var visual: Node3D
var weapon_pivot: Node3D
var weapon: MeshInstance3D
var weapon_data
var hit_samples := PackedVector3Array()
var previous_samples := PackedVector3Array()
var hit_ids: Dictionary = {}
var elapsed := -1.0
var cooldown := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector3.ZERO
var knock_velocity := Vector3.ZERO
var health := 3
var down_time := 0.0
var spawn_point := Vector3.ZERO
var move_phase := 0.0
var hidden_in_box := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.45
	collision.shape = capsule
	collision.position.y = 0.75
	add_child(collision)
	visual = Toy.avatar(tint)
	add_child(visual)
	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponGrip"
	weapon_pivot.position = Vector3(0.48,1.0,0.14)
	weapon_pivot.rotation = Vector3(-0.28,-0.9,0)
	visual.add_child(weapon_pivot)
	spawn_point = position

func equip(data) -> void:
	weapon_data = data.clone()
	hit_samples = weapon_data.local_samples()
	if is_instance_valid(weapon):
		weapon_pivot.remove_child(weapon)
		weapon.queue_free()
	weapon = WeaponMesh.build(weapon_data)
	weapon_pivot.add_child(weapon)
	elapsed = -1.0
	previous_samples = global_hit_samples()

func step(delta: float, desired: Vector3, aim: Vector3) -> void:
	cooldown = maxf(0.0,cooldown-delta)
	dash_cooldown = maxf(0.0,dash_cooldown-delta)
	if down_time > 0:
		down_time -= delta
		if down_time <= 0:
			reset_actor()
		return
	if hidden_in_box:
		velocity = Vector3.ZERO
		return
	previous_samples = global_hit_samples()
	var wish := desired.limit_length()
	if elapsed < 0 and aim.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(aim.x,aim.z),minf(1,delta*16))
	if dash_time > 0.0:
		dash_time -= delta
		wish = dash_direction * 2.0
	var speed_factor := 0.55 if elapsed >= 0.0 else 1.0
	velocity.x = wish.x * SPEED * speed_factor + knock_velocity.x
	velocity.z = wish.z * SPEED * speed_factor + knock_velocity.z
	knock_velocity = knock_velocity.move_toward(Vector3.ZERO,delta*18.0)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = maxf(velocity.y,0.0)
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var normal: Vector3 = get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.5:
			knock_velocity = knock_velocity.slide(normal)
	move_phase += delta * wish.length() * 12.0
	visual.position.y = absf(sin(move_phase)) * minf(wish.length(),1) * 0.065
	var squash := 1.0 - absf(sin(move_phase))*minf(wish.length(),1)*0.025
	visual.scale = Vector3(1.0/squash,squash,1.0/squash)
	if visual.has_node("LeftFoot"):
		(visual.get_node("LeftFoot") as Node3D).position.z = 0.04 + sin(move_phase)*0.09*minf(wish.length(),1)
		(visual.get_node("RightFoot") as Node3D).position.z = 0.04 - sin(move_phase)*0.09*minf(wish.length(),1)
	if elapsed >= 0.0:
		elapsed += delta
		var t := clampf((elapsed-ACTIVE_START)/(ACTIVE_END-ACTIVE_START),0,1)
		weapon_pivot.rotation.y = lerpf(-1.45,1.25,t)
		weapon_pivot.rotation.x = -0.16
		if elapsed > SWING_DURATION:
			elapsed = -1.0
	else:
		weapon_pivot.rotation.y = lerpf(weapon_pivot.rotation.y,-0.9,minf(1,delta*12))
		weapon_pivot.rotation.x = lerpf(weapon_pivot.rotation.x,-0.28,minf(1,delta*12))

func begin_swing() -> bool:
	if elapsed >= 0.0 or cooldown > 0.0 or down_time > 0.0 or hidden_in_box or weapon_data == null:
		return false
	elapsed = 0.0
	cooldown = SWING_DURATION + 0.14
	hit_ids.clear()
	weapon_pivot.rotation.y = -1.45
	previous_samples = global_hit_samples()
	return true

func begin_dash(direction: Vector3) -> void:
	if dash_cooldown > 0.0 or hidden_in_box or down_time > 0.0:
		return
	dash_direction = direction.normalized()
	if dash_direction.length_squared() < 0.01:
		dash_direction = visual.global_transform.basis.z
	dash_time = 0.13
	dash_cooldown = 0.8

func attack_active() -> bool:
	return elapsed >= ACTIVE_START and elapsed <= ACTIVE_END and down_time <= 0.0

func global_hit_samples() -> PackedVector3Array:
	var result := PackedVector3Array()
	if not is_instance_valid(weapon_pivot):
		return result
	for point in hit_samples:
		result.append(weapon_pivot.global_transform * point)
	return result

func take_hit(direction: Vector3) -> bool:
	if down_time > 0.0 or hidden_in_box:
		return false
	health -= 1
	knock_velocity = direction.normalized() * 8.0
	velocity.y = 2.8
	if health <= 0:
		down_time = 1.5
		visible = false
		collision_layer = 0
	return true

func reset_actor() -> void:
	position = spawn_point
	velocity = Vector3.ZERO
	knock_velocity = Vector3.ZERO
	health = 3
	down_time = 0.0
	visible = true
	collision_layer = 2
	hidden_in_box = false
	if is_instance_valid(visual):
		visual.visible = true

func toggle_hide() -> void:
	hidden_in_box = not hidden_in_box
	visual.visible = not hidden_in_box
	velocity = Vector3.ZERO
