extends RefCounted
## Visual-only bevel, with conservative fallback for concave/offset topology changes.
const Stroke = preload("res://scripts/graphics/round_stroke.gd")
const Surface = preload("res://scripts/graphics/surfaces.gd")
const DEPTH := 0.052
static func build(data, polygons: Array[PackedVector2Array]) -> MeshInstance3D:
	var root := Stroke.build(data)
	root.set_meta("visual_skin_version",6)
	var mat := Surface.make(data.weapon_color(),"foam").duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	root.material_override = mat
	if polygons.is_empty(): return root
	var s := SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in polygons:
		var q := inset(p,0.025/data.world_scale())
		var beveled := not q.is_empty()
		if not beveled: q = p
		var tri := Geometry2D.triangulate_polygon(q)
		for sign_y in [-1.0,1.0]:
			for i in tri: emit(s,data.point_to_world(q[i])+Vector3.UP*DEPTH*sign_y,Vector3.UP*sign_y)
		for i in range(p.size()):
			var j := (i+1)%p.size()
			var a: Vector3 = data.point_to_world(p[i]); var b: Vector3 = data.point_to_world(p[j])
			var c: Vector3 = data.point_to_world(q[i]); var d: Vector3 = data.point_to_world(q[j])
			var out: Vector3 = ((a+b)-(c+d)).normalized() if beveled else (b-a).cross(Vector3.UP).normalized()
			var edge_depth := 0.027 if beveled else DEPTH
			for v in [a+Vector3.UP*edge_depth,b+Vector3.UP*edge_depth,a-Vector3.UP*edge_depth,a-Vector3.UP*edge_depth,b+Vector3.UP*edge_depth,b-Vector3.UP*edge_depth]: emit(s,v,out)
			if beveled:
				for sign_y in [-1.0,1.0]:
					var up: Vector3 = Vector3.UP*sign_y
					var normal: Vector3 = (out+up).normalized()
					for v in [a+up*edge_depth,b+up*edge_depth,c+up*DEPTH,c+up*DEPTH,b+up*edge_depth,d+up*DEPTH]: emit(s,v,normal)
	var fill := MeshInstance3D.new(); fill.name = "SafeFoamFill"
	fill.mesh = s.commit(); fill.material_override = mat
	root.add_child(fill)
	return root
static func emit(s: SurfaceTool, point: Vector3, normal: Vector3) -> void:
	s.set_normal(normal); s.set_uv(Vector2(point.x,point.z)); s.add_vertex(point)
static func inset(p: PackedVector2Array, distance: float) -> PackedVector2Array:
	var empty := PackedVector2Array()
	var paths := Geometry2D.offset_polygon(p,-distance,Geometry2D.JOIN_MITER)
	if paths.size() != 1 or paths[0].size() != p.size(): return empty
	var raw: PackedVector2Array = paths[0]
	if Geometry2D.is_polygon_clockwise(raw) != Geometry2D.is_polygon_clockwise(p): raw.reverse()
	var best := 0; var closest := INF
	for i in range(raw.size()):
		if p[0].distance_squared_to(raw[i]) < closest:
			closest = p[0].distance_squared_to(raw[i]); best = i
	var q := PackedVector2Array()
	for i in range(p.size()):
		var point := raw[(i+best)%raw.size()]
		if not Geometry2D.is_point_in_polygon(point,p) or point.distance_to(p[i]) > distance*4.0: return empty
		q.append(point)
	if Geometry2D.triangulate_polygon(q).is_empty(): return empty
	return q
