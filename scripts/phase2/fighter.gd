extends "res://scripts/actor.gd"
const Form = preload("res://scripts/phase2/weapon_form.gd")
var player_id := 0
var spot := -1
var nameplate: Label3D
var flash := 0.0
var old_center := Vector3.ZERO
var original_spawn := Vector3.ZERO

func _ready() -> void:
	super._ready()
	original_spawn = spawn_point
	nameplate = Label3D.new()
	nameplate.text = ["YOU", "MARSH", "BOBA", "NOODLE"][player_id]
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.position.y = 2.0
	nameplate.pixel_size = 0.005
	nameplate.font_size = 32
	add_child(nameplate)

func equip(data) -> void:
	weapon_data = data.clone()
	hit_samples = Form.samples(weapon_data)
	if is_instance_valid(weapon):
		weapon_pivot.remove_child(weapon)
		weapon.queue_free()
	weapon = Form.build(weapon_data)
	weapon_pivot.add_child(weapon)
	elapsed = -1.0
	previous_samples = global_hit_samples()

func step(delta: float, desired: Vector3, aim: Vector3) -> void:
	old_center = global_position + Vector3.UP
	super.step(delta,desired,aim)
	flash = maxf(0.0, flash-delta)
	if flash > 0.0:
		visual.scale = Vector3(1.12,0.9,1.12)

func take_hit(direction: Vector3) -> bool:
	# Round life and eliminations belong to match_rules, not Phase 1 auto-respawn.
	if hidden_in_box or not visible:
		return false
	flash = 0.12
	knock_velocity = direction.normalized()*6.5
	velocity.y = 2.1
	return true

func set_hidden(value: bool, at_spot: int = -1) -> void:
	hidden_in_box = value
	spot = at_spot if value else -1
	visual.visible = not value
	nameplate.visible = not value
	velocity = Vector3.ZERO
	knock_velocity = Vector3.ZERO
	collision_layer = 0 if value else 2

func reset_fight(at: Vector3) -> void:
	set_hidden(false)
	position = at
	visible = true
	elapsed = -1.0
	cooldown = 0.0
	dash_time = 0.0
	dash_cooldown = 0.0
	down_time = 0.0
	health = 3
	hit_ids.clear()
	weapon_pivot.rotation = Vector3(-0.28,-0.9,0)
	previous_samples = global_hit_samples()
	old_center = at + Vector3.UP

func show_weapon(value: bool) -> void:
	if is_instance_valid(weapon):
		weapon.visible = value
