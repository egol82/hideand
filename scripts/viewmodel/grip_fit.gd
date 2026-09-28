extends RefCounted
## Pure, bounded geometry fitting. Reads original strokes; never edits drawings or attack data.
const Data = preload("res://scripts/weapon_data.gd")
const EPS := 0.00001

static func solve(data, drawing_basis: Basis, display_scale: float) -> Dictionary:
	if not is_finite(display_scale) or display_scale <= 0.0 or not drawing_basis.is_finite() or absf(drawing_basis.determinant()) < EPS:
		return invalid_fit()
	var anchor := Vector3.ZERO
	var axis := Vector3.UP
	var best := INF
	var endpoints: Array[Vector3] = []
	var segments: Array = []
	for stroke in data.strokes:
		for i in range(1,stroke.size()):
			var a: Vector3 = drawing_basis*data.point_to_world(stroke[i-1])*display_scale
			var b: Vector3 = drawing_basis*data.point_to_world(stroke[i])*display_scale
			if not a.is_finite() or not b.is_finite() or a.distance_squared_to(b) < EPS*EPS: continue
			segments.append([a,b])
			var q := Geometry3D.get_closest_point_to_segment(Vector3.ZERO,a,b)
			var d := q.length_squared()
			if d < best:
				best = d; anchor = q; endpoints = [a,b]
	if endpoints.is_empty():
		return invalid_fit()
	# Point into the longer side of the real stroke, not an invented canonical handle.
	axis = (endpoints[1]-anchor).normalized() if endpoints[1].distance_to(anchor) >= endpoints[0].distance_to(anchor) else (endpoints[0]-anchor).normalized()
	if axis.length_squared() < 0.5: axis = (endpoints[1]-endpoints[0]).normalized()
	var radius := Data.TUBE_RADIUS*display_scale
	# Collect collinear intervals, merge only overlapping runs connected to the grip.
	# Curved/split drawings safely use a short main grip + wrist support, not a floating second fist.
	var intervals: Array[Vector2] = []
	var tolerance := maxf(0.0025,radius*0.30)
	for segment in segments:
		var a: Vector3 = segment[0]-anchor
		var b: Vector3 = segment[1]-anchor
		if (a-axis*a.dot(axis)).length() > tolerance or (b-axis*b.dot(axis)).length() > tolerance: continue
		if absf((b-a).normalized().dot(axis)) < 0.985: continue
		intervals.append(Vector2(minf(a.dot(axis),b.dot(axis)),maxf(a.dot(axis),b.dot(axis))))
	intervals.sort_custom(func(a: Vector2,b: Vector2): return a.x < b.x)
	var run := 0.0
	for interval in intervals:
		if interval.y < 0: continue
		if interval.x <= run+0.001: run = maxf(run,interval.y)
	var main_offset := minf(0.055,run*0.48)
	var mode := "pinch" if run < 0.095 else "brace"
	var support := anchor
	if run >= 0.31:
		mode = "shaft"
		main_offset = 0.215
		support = anchor+axis*0.058
	var forward := Vector3.BACK-axis*axis.dot(Vector3.BACK)
	if forward.length_squared() < 0.01: forward = Vector3.RIGHT-axis*axis.dot(Vector3.RIGHT)
	forward = forward.normalized()
	var right := axis.cross(forward).normalized()
	return {"valid":true,"anchor":anchor,"axis":axis,"basis":Basis(right,axis,forward).orthonormalized(),"run":run,"radius":radius,"main":anchor+axis*main_offset,"support":support,"mode":mode}

static func invalid_fit() -> Dictionary:
	return {"valid":false,"anchor":Vector3.ZERO,"axis":Vector3.UP,"basis":Basis.IDENTITY,"run":0.0,"radius":0.016,"main":Vector3.ZERO,"support":Vector3.ZERO,"mode":"brace"}
