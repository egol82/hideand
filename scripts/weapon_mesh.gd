extends RefCounted
## Builds an actual shaded 3D tube along the drawing. Rendering and hit samples share data.
const Toy = preload("res://scripts/toy_factory.gd")
const Data = preload("res://scripts/weapon_data.gd")
const SIDES := 8

static func build(data) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "DrawnToyWeapon"
	if not data.is_valid():
		return node
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius: float = Data.TUBE_RADIUS
	for stroke in data.strokes:
		if stroke.size() < 2:
			continue
		var path := PackedVector3Array()
		for point in stroke:
			var pos: Vector3 = data.point_to_world(point)
			if path.is_empty() or path[-1].distance_to(pos) > 0.002:
				path.append(pos)
		if path.size() < 2:
			continue
		var rings: Array[PackedVector3Array] = []
		var normals: Array[PackedVector3Array] = []
		for i in range(path.size()):
			var tangent: Vector3
			if i == 0:
				tangent = path[1] - path[0]
			elif i == path.size() - 1:
				tangent = path[i] - path[i-1]
			else:
				tangent = path[i+1] - path[i-1]
			if tangent.length_squared() < 0.00001:
				tangent = Vector3.FORWARD
			tangent = tangent.normalized()
			var right := tangent.cross(Vector3.UP).normalized()
			var ring := PackedVector3Array()
			var norms := PackedVector3Array()
			for side in range(SIDES):
				var angle := TAU * float(side) / float(SIDES)
				var normal := Vector3.UP * cos(angle) + right * sin(angle)
				ring.append(path[i] + normal * radius)
				norms.append(normal)
			rings.append(ring)
			normals.append(norms)
		for i in range(path.size() - 1):
			for side in range(SIDES):
				var nxt := (side + 1) % SIDES
				_emit(st,rings[i][side],normals[i][side])
				_emit(st,rings[i+1][side],normals[i+1][side])
				_emit(st,rings[i][nxt],normals[i][nxt])
				_emit(st,rings[i][nxt],normals[i][nxt])
				_emit(st,rings[i+1][side],normals[i+1][side])
				_emit(st,rings[i+1][nxt],normals[i+1][nxt])
		_cap(st,path[0],(path[0]-path[1]).normalized(),radius)
		_cap(st,path[-1],(path[-1]-path[-2]).normalized(),radius)
	var mesh := st.commit()
	node.mesh = mesh
	var mat := Toy.material(data.weapon_color())
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	return node

static func _emit(st: SurfaceTool, point: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	st.add_vertex(point)

static func _cap(st: SurfaceTool, center: Vector3, outward: Vector3, radius: float) -> void:
	var right := outward.cross(Vector3.UP).normalized()
	for band in range(3):
		var a := PI * 0.5 * float(band) / 3.0
		var b := PI * 0.5 * float(band+1) / 3.0
		for side in range(SIDES):
			var t0 := TAU*float(side)/float(SIDES)
			var t1 := TAU*float(side+1)/float(SIDES)
			var r0 := Vector3.UP*cos(t0)+right*sin(t0)
			var r1 := Vector3.UP*cos(t1)+right*sin(t1)
			var n0 := outward*sin(a)+r0*cos(a)
			var n1 := outward*sin(b)+r0*cos(b)
			var n2 := outward*sin(a)+r1*cos(a)
			var n3 := outward*sin(b)+r1*cos(b)
			_emit(st,center+n0*radius,n0)
			_emit(st,center+n1*radius,n1)
			_emit(st,center+n2*radius,n2)
			_emit(st,center+n2*radius,n2)
			_emit(st,center+n1*radius,n1)
			_emit(st,center+n3*radius,n3)
