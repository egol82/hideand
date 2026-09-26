extends RefCounted
## Bounded, deterministic extrusion for simple closed portions of the user's own strokes.
const Tubes = preload("res://scripts/weapon_mesh.gd")
const Toy = preload("res://scripts/toy_factory.gd")
const DEPTH := 0.055
const CLOSE_EPS := 0.018
const MAX_CONTOUR_POINTS := 128
const MAX_SAMPLES := 1400

static func contours(data) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not data.fill_closed:
		return result
	var candidates := 0
	for stroke in data.strokes:
		# Find one explicit loop per stroke, including loops drawn after an open handle.
		var found := false
		for first in range(stroke.size()):
			if found:
				break
			for last in range(stroke.size() - 1, first + 3, -1):
				if stroke[first].distance_to(stroke[last]) > CLOSE_EPS:
					continue
				if last - first > MAX_CONTOUR_POINTS:
					continue
				candidates += 1
				if candidates > 64:
					return result
				var poly := PackedVector2Array()
				for i in range(first, last):
					if poly.is_empty() or poly[-1].distance_to(stroke[i]) > 0.001:
						poly.append(stroke[i])
				if _simple(poly):
					result.append(poly)
					found = true
					break
	return result

static func _simple(poly: PackedVector2Array) -> bool:
	if poly.size() < 3 or poly.size() > MAX_CONTOUR_POINTS:
		return false
	var area := 0.0
	for i in range(poly.size()):
		area += poly[i].cross(poly[(i + 1) % poly.size()])
	if absf(area) < 0.003:
		return false
	for i in range(poly.size()):
		for j in range(i + 1, poly.size()):
			if j == i + 1 or (i == 0 and j == poly.size() - 1):
				continue
			if Geometry2D.segment_intersects_segment(poly[i], poly[(i+1)%poly.size()], poly[j], poly[(j+1)%poly.size()]) != null:
				return false
	return Geometry2D.triangulate_polygon(poly).size() == (poly.size() - 2) * 3

static func build(data) -> MeshInstance3D:
	var weapon: MeshInstance3D = Tubes.build(data)
	var polygons := contours(data)
	if polygons.is_empty():
		return weapon
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for poly in polygons:
		var indices := Geometry2D.triangulate_polygon(poly)
		for i in range(0, indices.size(), 3):
			for side in [1.0, -1.0]:
				for j in range(3):
					var index: int = indices[i + (j if side > 0 else 2-j)]
					var p: Vector3 = data.point_to_world(poly[index])
					p.y = DEPTH * side
					_emit(surface, p, Vector3.UP * side)
		for i in range(poly.size()):
			var a: Vector3 = data.point_to_world(poly[i])
			var b: Vector3 = data.point_to_world(poly[(i+1)%poly.size()])
			var n := (b-a).cross(Vector3.UP).normalized()
			for p in [a+Vector3.UP*DEPTH,b+Vector3.UP*DEPTH,a-Vector3.UP*DEPTH,a-Vector3.UP*DEPTH,b+Vector3.UP*DEPTH,b-Vector3.UP*DEPTH]:
				_emit(surface, p, n)
	var fill := MeshInstance3D.new()
	fill.name = "ClosedContourFill"
	fill.mesh = surface.commit()
	var mat := Toy.material(data.weapon_color())
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill.material_override = mat
	weapon.add_child(fill)
	return weapon

static func _emit(surface: SurfaceTool, point: Vector3, normal: Vector3) -> void:
	surface.set_normal(normal)
	surface.add_vertex(point)

static func samples(data) -> PackedVector3Array:
	var result: PackedVector3Array = data.local_samples(0.11)
	for poly in contours(data):
		# Grid spacing is in world units and is bounded by normalized drawing limits.
		var step: float = 0.13 / data.world_scale()
		var y := 0.0
		while y <= 1.0 and result.size() < MAX_SAMPLES:
			var x := 0.0
			while x <= 1.0 and result.size() < MAX_SAMPLES:
				if Geometry2D.is_point_in_polygon(Vector2(x,y), poly):
					result.append(data.point_to_world(Vector2(x,y)))
				x += step
			y += step
	return result
