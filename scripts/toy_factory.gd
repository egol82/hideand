extends RefCounted
## Same low-cost material/geometry vocabulary for room, avatars, and drawn weapons.

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mat.metallic = 0.0
	mat.metallic_specular = 0.25
	return mat

static func ellipsoid(parent: Node3D, center: Vector3, radii: Vector3, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var item := MeshInstance3D.new()
	item.mesh = sphere
	item.material_override = material(color)
	item.position = center
	item.scale = radii
	parent.add_child(item)
	return item

static func box(parent: Node3D, center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = material(color)
	item.position = center
	parent.add_child(item)
	return item

static func collider(parent: Node3D, center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	parent.add_child(body)
	return body

static func avatar(color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "ToyAvatar"
	ellipsoid(root, Vector3(0,0.68,0), Vector3(0.4,0.48,0.32), color)
	ellipsoid(root, Vector3(0,1.3,0), Vector3(0.57,0.49,0.44), color)
	ellipsoid(root, Vector3(-0.31,1.67,0), Vector3(0.14,0.2,0.15), color)
	ellipsoid(root, Vector3(0.31,1.67,0), Vector3(0.14,0.2,0.15), color)
	var left_leg := ellipsoid(root, Vector3(-0.23,0.18,0.04), Vector3(0.19,0.22,0.25), color)
	left_leg.name = "LeftFoot"
	var right_leg := ellipsoid(root, Vector3(0.23,0.18,0.04), Vector3(0.19,0.22,0.25), color)
	right_leg.name = "RightFoot"
	ellipsoid(root, Vector3(-0.46,0.86,0.07), Vector3(0.17,0.24,0.17), color)
	ellipsoid(root, Vector3(0.46,0.98,0.13), Vector3(0.17,0.21,0.17), color)
	var ink := Color("26333d")
	ellipsoid(root, Vector3(-0.18,1.38,0.408), Vector3(0.048,0.068,0.028), ink)
	ellipsoid(root, Vector3(0.18,1.38,0.408), Vector3(0.048,0.068,0.028), ink)
	ellipsoid(root, Vector3(0,1.2,0.437), Vector3(0.09,0.057,0.02), ink)
	ellipsoid(root, Vector3(0,1.22,0.447), Vector3(0.078,0.026,0.012), color)
	var cheek := color.lerp(Color("ee94a1"), 0.55)
	ellipsoid(root, Vector3(-0.32,1.24,0.359), Vector3(0.085,0.041,0.021), cheek)
	ellipsoid(root, Vector3(0.32,1.24,0.359), Vector3(0.085,0.041,0.021), cheek)
	return root

static func room(parent: Node3D) -> void:
	var floor_color := Color("cba77d")
	box(parent, Vector3(0,-0.2,0), Vector3(14,0.4,10), floor_color)
	collider(parent, Vector3(0,-0.2,0), Vector3(14,0.4,10))
	for z in range(-4,5):
		box(parent, Vector3(0,0.006,z), Vector3(14,0.009,0.028), Color("ba946c"))
	box(parent, Vector3(0,1.65,-5), Vector3(14,3.3,0.22), Color("e5dac7"))
	box(parent, Vector3(-7,1.65,0), Vector3(0.22,3.3,10), Color("cad6c9"))
	collider(parent, Vector3(0,1.6,-5.12), Vector3(14,3.2,0.3))
	collider(parent, Vector3(-7.12,1.6,0), Vector3(0.3,3.2,10))
	collider(parent, Vector3(7.1,1.6,0), Vector3(0.3,3.2,10))
	collider(parent, Vector3(0,1.6,5.1), Vector3(14,3.2,0.3))
	box(parent, Vector3(0,0.03,0), Vector3(7.2,0.04,5.3), Color("8dab9f"))
	for x in [-2.4,-1.2,0.0,1.2,2.4]:
		box(parent, Vector3(x,0.055,0), Vector3(0.5,0.015,5.3), Color("b9cbb8"))
	var sofa := Node3D.new()
	parent.add_child(sofa)
	sofa.position = Vector3(-3.3,0,-3.35)
	var coral := Color("d88575")
	box(sofa, Vector3(0,0.35,0), Vector3(3.6,0.45,1.55), coral)
	ellipsoid(sofa, Vector3(0,1.1,-0.5), Vector3(1.9,0.68,0.36), coral)
	for x in [-0.87,0.87]:
		ellipsoid(sofa, Vector3(x,0.67,0.12), Vector3(0.94,0.23,0.68), Color("e09684"))
	for x in [-1.8,1.8]:
		ellipsoid(sofa, Vector3(x,0.8,0), Vector3(0.26,0.48,0.84), coral)
	ellipsoid(sofa, Vector3(-0.85,1.0,-0.05), Vector3(0.4,0.4,0.18), Color("8bbdaf"))
	collider(sofa, Vector3(0,0.65,0), Vector3(4.0,1.3,1.7))
	for p in [Vector3(-4.8,0.65,1.1), Vector3(4.6,0.65,-2.3)]:
		box(parent,p,Vector3(1.5,1.3,1.4),Color("d7b788"))
		box(parent,p + Vector3(0,0.655,0),Vector3(0.17,0.014,1.42),Color("f3dfb4"))
		collider(parent,p,Vector3(1.5,1.3,1.4))
	var pot_pos := Vector3(5.5,0,-3.95)
	ellipsoid(parent,pot_pos + Vector3(0,0.45,0),Vector3(0.5,0.5,0.5),Color("eee5d2"))
	box(parent,pot_pos + Vector3(0,1.1,0),Vector3(0.09,1.2,0.09),Color("658360"))
	for i in range(7):
		var a := float(i) * 2.4
		var p := pot_pos + Vector3(cos(a)*0.4,1.2+float(i)*0.12,sin(a)*0.4)
		var leaf := ellipsoid(parent,p,Vector3(0.25,0.53,0.18),Color("83aa79"))
		leaf.rotation.z = sin(a)*0.75
	collider(parent,pot_pos + Vector3(0,0.6,0),Vector3(1,1.2,1))
