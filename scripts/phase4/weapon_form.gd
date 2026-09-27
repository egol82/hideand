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

const Skin6 = preload("res://scripts/graphics/weapon_skin.gd")
static func build(data) -> MeshInstance3D:
	return Skin6.build(data,contours(data))

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
