extends SceneTree
const Data = preload("res://scripts/weapon_data.gd")
const Builder = preload("res://scripts/weapon_mesh.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+title)
	else:
		print("PASS: "+title)

func _run() -> void:
	var empty = Data.new()
	check(not empty.is_valid(),"blank drawing cannot be equipped")
	var blank_mesh := Builder.build(empty)
	check(blank_mesh.mesh == null,"blank drawing has no mesh")
	blank_mesh.free()
	for kind in ["hammer","fish","pan"]:
		var data = Data.new()
		data.set_preset(kind)
		check(data.is_valid(),kind+" valid drawing")
		check(data.ink_used() <= Data.MAX_INK,kind+" within ink budget")
		check(data.point_count() <= Data.MAX_POINTS,kind+" within point budget")
		check(data.reach() <= Data.MAX_REACH+0.0001,kind+" reach cap")
		var serialized: Variant = JSON.parse_string(JSON.stringify(data.to_dictionary()))
		var roundtrip = Data.new()
		check(roundtrip.load_dictionary(serialized),kind+" JSON accepts valid data")
		check(is_equal_approx(data.ink_used(),roundtrip.ink_used()),kind+" roundtrip shape length")
		var copy = data.clone()
		copy.strokes.clear()
		check(data.is_valid(),kind+" clone does not mutate source")
		var mesh := Builder.build(data)
		check(mesh.mesh != null,kind+" mesh exists")
		if mesh.mesh != null:
			check(mesh.mesh.get_surface_count() == 1,kind+" one mesh surface")
			check(mesh.mesh.get_aabb().size.y > 0.1,kind+" has actual volume")
			var material := mesh.material_override as StandardMaterial3D
			check(material != null and material.roughness >= 0.75,kind+" shared toy style")
		mesh.free()
		var samples: PackedVector3Array = data.local_samples()
		check(samples.size() > 0,kind+" hit samples generated")
		var bounded := true
		for point in samples:
			bounded = bounded and point.is_finite() and point.length() <= Data.MAX_REACH
		check(bounded,kind+" samples bounded and finite")
	var huge = Data.new()
	huge.grip = Vector2.ZERO
	huge.strokes.append(PackedVector2Array([Vector2.ZERO,Vector2.ONE]))
	check(huge.reach() <= Data.MAX_REACH+0.0001,"diagonal drawing is capped")
	check(Data.distance_to_segment(Vector3.ZERO,Vector3(-1,0,0),Vector3(1,0,0)) < 0.001,"swept collision catches between-frame hit")
	check(Data.distance_to_segment(Vector3(0,0,2),Vector3(-1,0,0),Vector3(1,0,0)) > 1.99,"swept collision rejects out-of-range target")
	check(is_equal_approx(Data.distance_to_segment(Vector3(1,0,0),Vector3.ZERO,Vector3.ZERO),1),"zero-length collision segment is safe")
	var bad = Data.new()
	check(not bad.load_dictionary({"version":1,"strokes":[[[0,0],[2,2]]]}),"out-of-bounds points rejected")
	check(not bad.load_dictionary({"version":1,"strokes":[[[0,0],[NAN,0.5]]]}),"NaN rejected")
	check(not bad.load_dictionary({"version":{},"strokes":[]}),"malformed version rejected")
	check(not bad.load_dictionary({"version":1,"color":{},"strokes":[]}),"malformed color rejected")
	var too_many: Array = []
	for i in range(Data.MAX_POINTS+1):
		too_many.append([0.5,0.5])
	check(not bad.load_dictionary({"version":1,"strokes":[too_many]}),"excess points rejected before meshing")
	var too_many_strokes: Array = []
	for i in range(Data.MAX_STROKES+1):
		too_many_strokes.append([[0.5,0.5],[0.51,0.51]])
	check(not bad.load_dictionary({"version":1,"strokes":too_many_strokes}),"excess strokes rejected")
	var snap = Data.new()
	snap.strokes.append(PackedVector2Array([Vector2(0.1,0.5),Vector2(0.9,0.5)]))
	snap.snap_grip(Vector2(0.4,0.9))
	check(snap.grip.is_equal_approx(Vector2(0.4,0.5)),"grip snaps onto actual stroke")
	print("PHASE1_UNIT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
