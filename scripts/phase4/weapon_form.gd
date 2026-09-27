extends RefCounted
const Base = preload("res://scripts/phase2/weapon_form.gd")
const Tubes = preload("res://scripts/weapon_mesh.gd")
const Art = preload("res://scripts/phase4/art.gd")
const DEPTH := 0.06

static func contours(data) -> Array[PackedVector2Array]:
	var all: Array[PackedVector2Array] = Base.contours(data)
	var safe: Array[PackedVector2Array] = []
	for i in range(all.size()):
		var ambiguous := false
		for j in range(all.size()):
			if i == j: continue
			# Nested/intersecting loops could represent holes. Preserve as lines rather than fill incorrectly.
			if Geometry2D.is_point_in_polygon(all[i][0],all[j]) or Geometry2D.is_point_in_polygon(all[j][0],all[i]):
				ambiguous = true
			for a in range(all[i].size()):
				for b in range(all[j].size()):
					if Geometry2D.segment_intersects_segment(all[i][a],all[i][(a+1)%all[i].size()],all[j][b],all[j][(b+1)%all[j].size()]) != null:
						ambiguous = true
		if not ambiguous: safe.append(all[i])
	return safe

static func build(data) -> MeshInstance3D:
	var weapon := Tubes.build(data)
	var mat := Art.material(data.weapon_color(),"foam").duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	weapon.material_override = mat
	var polys := contours(data)
	if polys.is_empty(): return weapon
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in polys:
		var triangles := Geometry2D.triangulate_polygon(p)
		for side in [-1.0,1.0]:
			for i in triangles:
				var v: Vector3 = data.point_to_world(p[i])+Vector3.UP*DEPTH*side
				s.set_normal(Vector3.UP*side)
				s.add_vertex(v)
		for i in range(p.size()):
			var a: Vector3 = data.point_to_world(p[i])
			var b: Vector3 = data.point_to_world(p[(i+1)%p.size()])
			for v in [a+Vector3.UP*DEPTH,b+Vector3.UP*DEPTH,a-Vector3.UP*DEPTH,a-Vector3.UP*DEPTH,b+Vector3.UP*DEPTH,b-Vector3.UP*DEPTH]:
				s.set_normal((b-a).cross(Vector3.UP).normalized())
				s.add_vertex(v)
	var fill := MeshInstance3D.new()
	fill.name = "SafeFoamFill"
	fill.mesh = s.commit()
	fill.material_override = mat
	weapon.add_child(fill)
	return weapon

static func samples(data) -> PackedVector3Array:
	var result: PackedVector3Array = data.local_samples(0.11)
	for poly in contours(data):
		var step: float = 0.13/data.world_scale()
		var y := 0.0
		while y <= 1 and result.size() < Base.MAX_SAMPLES:
			var x := 0.0
			while x <= 1 and result.size() < Base.MAX_SAMPLES:
				if Geometry2D.is_point_in_polygon(Vector2(x,y),poly): result.append(data.point_to_world(Vector2(x,y)))
				x += step
			y += step
	return result
