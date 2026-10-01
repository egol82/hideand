extends RefCounted
## One authored convex landform: render triangles, collision and planting share its surface.
## No RNG, round state, water mesh or gameplay service participates in this profile.
const STEPS:=16
static var _faces: PackedVector3Array=PackedVector3Array()
static var _mesh: ArrayMesh

static func points() -> PackedVector3Array:
	var result:=PackedVector3Array()
	var rings: Array=[Vector4(1.0,0.0,0.0,0.0),Vector4(0.87,0.48,0.06,-0.10),Vector4(0.64,1.32,-0.12,0.08),Vector4(0.27,1.90,-0.35,0.18)]
	for ring: Vector4 in rings:
		for i in range(STEPS):
			var angle:=TAU*float(i)/float(STEPS)
			var radius:=0.96+0.04*cos(angle*3.0+0.4)
			result.append(Vector3(3.5*cos(angle)*radius*ring.x+ring.z,ring.y,3.0*sin(angle)*radius*ring.x+ring.w))
	return result

static func faces() -> PackedVector3Array:
	if not _faces.is_empty():return _faces
	var shape:=ConvexPolygonShape3D.new();shape.points=points()
	# Godot supplies the triangulated convex hull as well as its wireframe debug surface.
	# Use the triangle surface only; creating another rounded shell would diverge from physics.
	var hull:=shape.get_debug_mesh()
	for surface in range(hull.get_surface_count()):
		if hull.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
		var arrays:=hull.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():_faces.append_array(vertices)
		else:
			for index in indices:_faces.append(vertices[index])
	assert(not _faces.is_empty(),"North reed convex hull must supply render triangles")
	return _faces

static func mesh() -> ArrayMesh:
	if _mesh!=null:return _mesh
	_mesh=ArrayMesh.new()
	var mud:=SurfaceTool.new();mud.begin(Mesh.PRIMITIVE_TRIANGLES)
	var moss:=SurfaceTool.new();moss.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles:=faces()
	for i in range(0,triangles.size(),3):
		var a:=triangles[i];var b:=triangles[i+1];var c:=triangles[i+2]
		var normal: Vector3=(c-a).cross(b-a).normalized()
		var center: Vector3=(a+b+c)/3.0
		# Moss is part of the same closed surface, not an elevated rectangular plate.
		var tool: SurfaceTool=moss if normal.y>0.68 and center.y>0.60 else mud
		for vertex in [a,b,c]:
			tool.set_normal(normal);tool.set_uv(Vector2(vertex.x,vertex.z)*0.22);tool.add_vertex(vertex)
	mud.commit(_mesh);moss.commit(_mesh)
	return _mesh

static func surface_height(at: Vector2) -> float:
	var height: float=-INF
	var triangles:=faces()
	for i in range(0,triangles.size(),3):
		var a:=triangles[i];var b:=triangles[i+1];var c:=triangles[i+2]
		var u:=Vector2(b.x-a.x,b.z-a.z);var v:=Vector2(c.x-a.x,c.z-a.z)
		var offset:=at-Vector2(a.x,a.z)
		var determinant: float=u.cross(v)
		if absf(determinant)<0.000001:continue
		var s: float=offset.cross(v)/determinant
		var t: float=u.cross(offset)/determinant
		if s>=-0.00001 and t>=-0.00001 and s+t<=1.00001:
			height=maxf(height,a.y+s*(b.y-a.y)+t*(c.y-a.y))
	return height
