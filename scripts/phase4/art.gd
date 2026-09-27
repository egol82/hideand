@tool
extends RefCounted
## Project-authored rounded meshes and a coherent (not identical) material family.
static var materials: Dictionary = {}
static var meshes: Dictionary = {}

static func material(color: Color, kind: String = "vinyl") -> StandardMaterial3D:
	var key := kind+color.to_html()
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = {"foam":0.88,"wood":0.62,"vinyl":0.53,"fabric":0.95,"ink":0.8}.get(kind,0.75)
	m.metallic_specular = 0.2 if kind == "foam" else 0.32
	materials[key] = m
	return m

static func rounded(size3: Vector3, radius: float = 0.12) -> ArrayMesh:
	var r := minf(radius,minf(size3.x,minf(size3.y,size3.z))*0.45)
	var key := str(size3)+str(r)
	if meshes.has(key): return meshes[key]
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size3*0.5
	var core := half-Vector3.ONE*r
	var count := 8
	for axis in range(3):
		for sign_value in [-1.0,1.0]:
			var a := (axis+1)%3
			var b := (axis+2)%3
			for i in range(count):
				for j in range(count):
					var points: Array[Vector3] = []
					var normals: Array[Vector3] = []
					var uvs: Array[Vector2] = []
					for d in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
						var p := Vector3.ZERO
						var uv := Vector2((i+d.x)/count,(j+d.y)/count)
						# Concentrate subdivisions at the bevel, retain a broad flat face.
						p[axis] = half[axis]*sign_value
						p[a] = _coordinate(uv.x,half[a],r)
						p[b] = _coordinate(uv.y,half[b],r)
						var c := p.clamp(-core,core)
						var n := (p-c).normalized()
						points.append(c+n*r)
						normals.append(n)
						uvs.append(uv)
					for idx in ([0,2,1,0,3,2] if sign_value > 0 else [0,1,2,0,2,3]):
						s.set_normal(normals[idx])
						s.set_uv(uvs[idx])
						s.add_vertex(points[idx])
	var mesh := s.commit()
	meshes[key] = mesh
	return mesh

static func _coordinate(t: float, half: float, r: float) -> float:
	if t < 0.375: return lerpf(-half,-half+r,t/0.375)
	if t > 0.625: return lerpf(half-r,half,(t-0.625)/0.375)
	return lerpf(-half+r,half-r,(t-0.375)/0.25)

static func box(parent: Node3D, at: Vector3, size3: Vector3, color: Color, kind: String = "wood", radius: float = 0.1) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = rounded(size3,radius)
	n.material_override = material(color,kind)
	n.position = at
	parent.add_child(n)
	return n

static func ball(parent: Node3D, at: Vector3, size3: Vector3, color: Color, kind: String = "vinyl") -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = 1
	m.height = 2
	m.radial_segments = 24
	m.rings = 12
	var n := MeshInstance3D.new()
	n.mesh = m
	n.scale = size3
	n.material_override = material(color,kind)
	n.position = at
	parent.add_child(n)
	return n

static func avatar(color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "VinylBuddy"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Continuous pear-shaped body/head: no intersecting head/body spheres.
	var profile := [Vector2(0.03,0.3),Vector2(0.30,0.33),Vector2(0.40,0.52),Vector2(0.42,0.78),Vector2(0.47,1.03),Vector2(0.54,1.25),Vector2(0.50,1.48),Vector2(0.35,1.65),Vector2(0.03,1.73)]
	var smooth: Array[Vector2] = []
	for j in range(profile.size()-1):
		var a: Vector2 = profile[maxi(0,j-1)]
		var b: Vector2 = profile[j]
		var c: Vector2 = profile[j+1]
		var d: Vector2 = profile[mini(profile.size()-1,j+2)]
		for sub in range(4):
			var t := float(sub)/4.0
			var q := 0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
			q.x = maxf(0.003,q.x)
			smooth.append(q)
	smooth.append(profile[-1])
	for j in range(smooth.size()-1):
		for k in range(48):
			var points: Array[Vector3] = []
			var norms: Array[Vector3] = []
			for pair in [Vector2(k,j),Vector2(k+1,j),Vector2(k+1,j+1),Vector2(k,j+1)]:
				var t: float = pair.x/48.0*TAU
				var at := int(pair.y)
				var q: Vector2 = smooth[at]
				var tangent := smooth[mini(smooth.size()-1,at+1)]-smooth[maxi(0,at-1)]
				points.append(Vector3(cos(t)*q.x,q.y,sin(t)*q.x*0.79))
				norms.append(Vector3(cos(t)*tangent.y,-tangent.x,sin(t)*tangent.y/0.79).normalized())
			for idx in [0,1,2,0,2,3]:
				surface.set_normal(norms[idx])
				surface.add_vertex(points[idx])
	var body := MeshInstance3D.new()
	body.mesh = surface.commit()
	body.material_override = material(color)
	root.add_child(body)
	for side in [-1,1]:
		ball(root,Vector3(side*0.31,1.65,0),Vector3(0.15,0.23,0.15),color)
		ball(root,Vector3(side*0.31,1.66,0.116),Vector3(0.08,0.12,0.02),color.lightened(0.25))
		var foot := box(root,Vector3(side*0.22,0.18,0.10),Vector3(0.34,0.32,0.44),color,"vinyl",0.14)
		foot.name = "LeftFoot" if side < 0 else "RightFoot"
		var arm := ball(root,Vector3(side*0.43,0.91,0.07),Vector3(0.13,0.28,0.15),color)
		arm.name = "LeftArm" if side < 0 else "RightArm"
		ball(root,Vector3(side*0.19,1.36,0.393),Vector3(0.043,0.064,0.026),Color("243b40"),"ink")
		ball(root,Vector3(side*0.178,1.379,0.415),Vector3(0.011,0.013,0.008),Color("fff2d6"))
		ball(root,Vector3(side*0.32,1.19,0.329),Vector3(0.08,0.035,0.019),color.lerp(Color("ed9b9b"),0.7))
	var mouth := ball(root,Vector3(0,1.19,0.404),Vector3(0.072,0.042,0.018),Color("31434a"),"ink")
	mouth.name = "Mouth"
	ball(root,Vector3(0,0.65,0.338),Vector3(0.22,0.24,0.028),color.lightened(0.16))
	return root

static func mitten(parent: Node3D, at: Vector3, color: Color, left: bool = false) -> Node3D:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	box(root,Vector3(0,-0.008,0.045),Vector3(0.15,0.17,0.17),color,"vinyl",0.055)
	ball(root,Vector3(-0.065 if not left else 0.065,0.025,-0.009),Vector3(0.052,0.068,0.072),color)
	box(root,Vector3(0,-0.075,0.126),Vector3(0.13,0.09,0.18),color.darkened(0.06),"vinyl",0.035)
	box(root,Vector3(0,-0.22,0.23),Vector3(0.105,0.30,0.115),color,"vinyl",0.05).rotation.x = -0.35
	return root
