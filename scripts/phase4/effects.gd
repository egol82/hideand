extends Node3D
## Fixed-size cosmetic pool: contact facts spawn particles, never the reverse.
const CAPACITY := 64
var multimesh: MultiMesh
var particles: Array[Dictionary] = []
var cursor := 0
var enabled := true

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	var shape := BoxMesh.new()
	shape.size = Vector3.ONE
	multimesh.mesh = shape
	multimesh.instance_count = CAPACITY
	var draw := MultiMeshInstance3D.new()
	draw.multimesh = multimesh
	draw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.material_override = m
	add_child(draw)
	for i in range(CAPACITY):
		particles.append({"p":Vector3.ZERO,"v":Vector3.ZERO,"life":0.0})
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))

func burst(at: Vector3, blocked: bool = false) -> void:
	if not enabled: return
	for n in range(8):
		var a := TAU*n/8
		particles[cursor] = {"p":at,"v":Vector3(cos(a),0.6+float(n%3)*0.25,sin(a))*1.8,"life":0.28}
		multimesh.set_instance_color(cursor,Color("edbb85") if blocked else Color("ffe1a4"))
		cursor = (cursor+1)%CAPACITY

func advance(delta: float) -> void:
	for i in range(CAPACITY):
		var p: Dictionary = particles[i]
		if p.life <= 0: continue
		p.life = maxf(0,p.life-delta)
		p.p += p.v*delta
		p.v.y -= delta*3
		var weight: float = p.life/0.28
		var basis := Basis.from_euler(Vector3(i*0.6,weight*4,i*0.3)).scaled(Vector3(0.055,0.018,0.09)*weight)
		multimesh.set_instance_transform(i,Transform3D(basis,p.p))

func reset() -> void:
	cursor = 0
	for i in range(particles.size()):
		particles[i].life = 0.0
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
