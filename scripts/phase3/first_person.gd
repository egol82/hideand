extends Node3D
## Camera and cosmetic hand-held copy. World-space weapon samples remain authoritative.
const Toy = preload("res://scripts/toy_factory.gd")
const Form = preload("res://scripts/phase2/weapon_form.gd")
const VIEW_LAYER := 1 << 19
const SELF_LAYER := 1 << 18
const EYE_HEIGHT := 1.48
var view: Camera3D
var hand_root: Node3D
var mount: Node3D
var view_weapon: MeshInstance3D
var yaw := 0.0
var pitch := 0.0
var sensitivity := 0.0025
var invert_y := false
var reduced_motion := false
var weapon_key := ""
var subject_id := -1
var sway := Vector2.ZERO
var gait := 0.0
var wall_retract := 0.0

func _ready() -> void:
	view = Camera3D.new()
	view.projection = Camera3D.PROJECTION_PERSPECTIVE
	view.fov = 72
	view.near = 0.04
	view.far = 160
	view.cull_mask = ((1 << 20)-1) & ~SELF_LAYER
	add_child(view)
	view.current = true
	hand_root = Node3D.new()
	view.add_child(hand_root)
	mount = Node3D.new()
	mount.rotation_degrees = Vector3(-90,0,-12)
	hand_root.add_child(mount)

func look(delta: Vector2) -> void:
	if not delta.is_finite():
		return
	yaw = wrapf(yaw-delta.x*sensitivity,-PI,PI)
	pitch = clampf(pitch-delta.y*sensitivity*(-1.0 if invert_y else 1.0),deg_to_rad(-80),deg_to_rad(80))
	sway = (delta*0.0005).limit_length(0.03)
	_apply_rotation()

func face(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	yaw = atan2(-direction.x,-direction.z)
	pitch = 0
	_apply_rotation()

func forward() -> Vector3:
	return Vector3(-sin(yaw),0,-cos(yaw))

func move_vector(input: Vector2) -> Vector3:
	return (Vector3(cos(yaw),0,-sin(yaw))*input.x-forward()*input.y).limit_length()

func _apply_rotation() -> void:
	rotation = Vector3(0,yaw,0)
	if is_instance_valid(view):
		view.rotation = Vector3(pitch,0,0)

func follow(actor, delta: float, aim_locked: bool, visible_hands: bool) -> void:
	position = actor.global_position+Vector3.UP*EYE_HEIGHT
	if aim_locked:
		var facing: Vector3 = actor.visual.global_basis.z
		yaw = atan2(-facing.x,-facing.z)
		pitch = -0.04
	_apply_rotation()
	var key: String = str(actor.get_instance_id())+JSON.stringify(actor.weapon_data.to_dictionary())
	if key != weapon_key:
		weapon_key = key
		_rebuild(actor)
	hand_root.visible = visible_hands
	wall_retract = move_toward(wall_retract,_wall_amount(),delta*8)
	gait += Vector2(actor.velocity.x,actor.velocity.z).length()*delta*2.7
	sway = sway.lerp(Vector2.ZERO,minf(1,delta*12))
	var bob := Vector3.ZERO
	if not reduced_motion and not aim_locked:
		bob = Vector3(sin(gait)*0.009,absf(cos(gait))*0.011,0)
		bob += Vector3(-sway.x,sway.y,0)
	var swing := 0.0
	if actor.elapsed >= 0:
		var t := clampf(actor.elapsed/actor.SWING_DURATION,0,1)
		swing = sin(t*PI)
	hand_root.position = Vector3(0.44-0.57*swing,-0.27-0.17*wall_retract+0.10*swing,-0.82+0.15*wall_retract)+bob
	hand_root.rotation = Vector3(-0.65*wall_retract,0.1*swing,1.2*swing)
	if wall_retract > 0.96:
		hand_root.visible = false

func _rebuild(actor) -> void:
	for child in hand_root.get_children():
		hand_root.remove_child(child)
		child.queue_free()
	mount = Node3D.new()
	mount.rotation_degrees = Vector3(-90,0,-12)
	hand_root.add_child(mount)
	view_weapon = Form.build(actor.weapon_data)
	# This is a camera presentation scale, not a gameplay reach change.
	view_weapon.scale = Vector3.ONE*minf(0.27,0.54/maxf(0.1,actor.weapon_data.reach()))
	mount.add_child(view_weapon)
	Toy.ellipsoid(hand_root,Vector3(0,-0.02,0.04),Vector3(0.083,0.085,0.083),actor.tint)
	var arm := Toy.ellipsoid(hand_root,Vector3(0.04,-0.18,0.16),Vector3(0.072,0.21,0.08),actor.tint.darkened(0.07))
	arm.rotation.x = -0.5
	Toy.ellipsoid(hand_root,Vector3(-0.14,-0.04,0.07),Vector3(0.07,0.075,0.075),actor.tint)
	var left := Toy.ellipsoid(hand_root,Vector3(-0.21,-0.27,0.18),Vector3(0.065,0.19,0.075),actor.tint.darkened(0.07))
	left.rotation.z = -0.3
	_layers(hand_root)

func _layers(node: Node) -> void:
	if node is GeometryInstance3D:
		node.layers = VIEW_LAYER
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_layers(child)

func _wall_amount() -> float:
	var ray := PhysicsRayQueryParameters3D.create(view.global_position,view.global_position-view.global_basis.z*1.2,1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return 0
	var distance: float = view.global_position.distance_to(hit.position)
	return clampf((0.95-distance)/0.8,0,1)
