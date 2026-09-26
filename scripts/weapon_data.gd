extends RefCounted
## Canonical drawing data. No AI call, network, or pre-made weapon substitution.
## Shape is a set of open strokes; closed contours are NOT automatically filled.

const MAX_STROKES := 16
const MAX_POINTS := 512
const MAX_INK := 4.0
const MIN_POINT_DISTANCE := 0.006
const MAX_REACH := 2.2
const MIN_REACH := 0.5
const TUBE_RADIUS := 0.065
const PALETTE := ["#88d6b0", "#f1b579", "#df92b2", "#8fbbe4", "#c2aadf"]

var strokes: Array[PackedVector2Array] = []
var grip := Vector2(0.5, 0.88)
var color_index: int = 1

func ink_used() -> float:
	var total := 0.0
	for stroke in strokes:
		for i in range(1, stroke.size()):
			total += stroke[i - 1].distance_to(stroke[i])
	return total

func point_count() -> int:
	var count := 0
	for stroke in strokes:
		count += stroke.size()
	return count

func is_valid() -> bool:
	return point_count() >= 2 and ink_used() >= 0.012

func weapon_color() -> Color:
	return Color(PALETTE[clampi(color_index, 0, PALETTE.size() - 1)])

func drawing_radius() -> float:
	var radius := 0.01
	for stroke in strokes:
		for point in stroke:
			radius = maxf(radius, point.distance_to(grip))
	return radius

func world_scale() -> float:
	return minf(2.4, (MAX_REACH - TUBE_RADIUS) / drawing_radius())

func reach() -> float:
	return drawing_radius() * world_scale() + TUBE_RADIUS

func point_to_world(point: Vector2) -> Vector3:
	return Vector3(point.x - grip.x, 0.0, grip.y - point.y) * world_scale()

func local_samples(spacing: float = 0.09) -> PackedVector3Array:
	var result := PackedVector3Array()
	for stroke in strokes:
		if stroke.is_empty():
			continue
		result.append(point_to_world(stroke[0]))
		for i in range(1, stroke.size()):
			var a := point_to_world(stroke[i - 1])
			var b := point_to_world(stroke[i])
			var steps := maxi(1, ceili(a.distance_to(b) / spacing))
			for j in range(1, steps + 1):
				result.append(a.lerp(b, float(j) / float(steps)))
	return result

func clone():
	var copy = get_script().new()
	copy.grip = grip
	copy.color_index = color_index
	for stroke in strokes:
		copy.strokes.append(stroke.duplicate())
	return copy

func to_dictionary() -> Dictionary:
	var packed: Array = []
	for stroke in strokes:
		var points: Array = []
		for point in stroke:
			points.append([point.x, point.y])
		packed.append(points)
	return {"version": 1, "grip": [grip.x, grip.y], "color": color_index, "strokes": packed}

func load_dictionary(raw: Dictionary) -> bool:
	if not _valid_number(raw.get("version", null)) or float(raw["version"]) != 1.0:
		return false
	if not raw.get("strokes", null) is Array:
		return false
	var input: Array = raw["strokes"]
	if input.size() > MAX_STROKES:
		return false
	var new_strokes: Array[PackedVector2Array] = []
	var count := 0
	var ink := 0.0
	for raw_stroke in input:
		if not raw_stroke is Array:
			return false
		var stroke := PackedVector2Array()
		for pair in raw_stroke:
			if not _valid_pair(pair):
				return false
			count += 1
			if count > MAX_POINTS:
				return false
			var p := Vector2(float(pair[0]), float(pair[1]))
			if p.x < 0.0 or p.x > 1.0 or p.y < 0.0 or p.y > 1.0:
				return false
			if not stroke.is_empty():
				ink += p.distance_to(stroke[-1])
			stroke.append(p)
		if stroke.size() >= 2:
			new_strokes.append(stroke)
	if ink > MAX_INK + 0.0001:
		return false
	var grip_pair = raw.get("grip", [0.5, 0.88])
	if not _valid_pair(grip_pair):
		return false
	var new_grip := Vector2(float(grip_pair[0]), float(grip_pair[1]))
	if new_grip.x < 0.0 or new_grip.x > 1.0 or new_grip.y < 0.0 or new_grip.y > 1.0:
		return false
	if not _valid_number(raw.get("color", 1)):
		return false
	strokes = new_strokes
	grip = new_grip
	color_index = clampi(int(raw.get("color", 1)), 0, PALETTE.size() - 1)
	return true

func snap_grip(requested: Vector2) -> void:
	var closest := requested.clamp(Vector2.ZERO,Vector2.ONE)
	var best := INF
	for stroke in strokes:
		for i in range(1,stroke.size()):
			var candidate := Geometry2D.get_closest_point_to_segment(requested,stroke[i-1],stroke[i])
			var distance := candidate.distance_squared_to(requested)
			if distance < best:
				best = distance
				closest = candidate
	grip = closest

static func _valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _valid_pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for item in value:
		if not (item is int or item is float):
			return false
		if not is_finite(float(item)):
			return false
	return true

static func distance_to_segment(point: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	if ab.length_squared() < 0.0000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)

func set_preset(kind: String) -> void:
	strokes.clear()
	grip = Vector2(0.5, 0.88)
	if kind == "fish":
		strokes.append(PackedVector2Array([
			Vector2(0.5,0.88), Vector2(0.5,0.63), Vector2(0.36,0.53),
			Vector2(0.29,0.37), Vector2(0.34,0.23), Vector2(0.49,0.13),
			Vector2(0.66,0.25), Vector2(0.71,0.4), Vector2(0.62,0.55),
			Vector2(0.5,0.63)]))
		strokes.append(PackedVector2Array([
			Vector2(0.37,0.51), Vector2(0.2,0.58), Vector2(0.31,0.36)]))
		strokes.append(PackedVector2Array([Vector2(0.53,0.28), Vector2(0.61,0.36)]))
		strokes.append(PackedVector2Array([Vector2(0.61,0.28), Vector2(0.53,0.36)]))
	elif kind == "pan":
		strokes.append(PackedVector2Array([Vector2(0.5,0.88),Vector2(0.5,0.62)]))
		var ring := PackedVector2Array()
		for i in range(25):
			var a := TAU * float(i) / 24.0
			ring.append(Vector2(0.5,0.37) + Vector2(cos(a),sin(a)) * 0.25)
		strokes.append(ring)
	else:
		strokes.append(PackedVector2Array([Vector2(0.5,0.88),Vector2(0.5,0.38)]))
		strokes.append(PackedVector2Array([
			Vector2(0.2,0.38),Vector2(0.2,0.16),Vector2(0.8,0.16),
			Vector2(0.8,0.38),Vector2(0.2,0.38)]))
