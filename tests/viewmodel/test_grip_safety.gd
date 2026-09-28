extends SceneTree
## Additional review of invalid frames, degenerate arm links and sleeve shading topology.
const Fit = preload("res://scripts/viewmodel/grip_fit.gd")
const Meshes = preload("res://scripts/viewmodel/hand_mesh.gd")
const Data = preload("res://scripts/phase4/drawing_data.gd")
var checks := 0
var failures := 0
func check(value: bool, title: String) -> void:
	checks += 1
	if not value: failures += 1
	print(("PASS: " if value else "FAIL: ")+title)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var data = Data.new(); data.set_preset("fish")
	var source: Dictionary = data.to_dictionary()
	for value in [-0.2,0.0,NAN,INF]:
		check(not Fit.solve(data,Basis.IDENTITY,value).valid,"invalid display scale is rejected")
	check(not Fit.solve(data,Basis(Vector3.ZERO,Vector3.UP,Vector3.BACK),0.27).valid,"singular drawing basis is rejected")
	check(not Fit.solve(data,Basis(Vector3(NAN,0,0),Vector3.UP,Vector3.BACK),0.27).valid,"nonfinite drawing basis is rejected")
	check(Fit.solve(data,Basis.IDENTITY,0.27).valid and data.to_dictionary() == source,"valid fit preserves original drawing")
	var link := Node3D.new()
	for delta in [Vector3.ZERO,Vector3(0.000001,0,0),Vector3(0,0,0.3),Vector3(0.2,-0.4,0.3)]:
		Meshes.link(link,Vector3.ZERO,delta)
		check(link.transform.is_finite() and absf(link.basis.determinant()) > 0,"arm link has a finite nonsingular frame")
	link.free()
	var parent := Node3D.new()
	var sleeve := Meshes.sleeve(parent,"ReviewSleeve")
	var material := sleeve.material_override as StandardMaterial3D
	check(not material.uv1_triplanar and material.normal_scale < 0.2,"cloth weave uses restrained local shading")
	var arrays: Array = sleeve.mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_INDEX].size() > 0,"sleeve mesh shares indexed vertices")
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var valid_uv := 0
	for i in range(0,indices.size(),3):
		if absf((uv[indices[i+1]]-uv[indices[i]]).cross(uv[indices[i+2]]-uv[indices[i]])) > 0.0000001: valid_uv += 1
	check(valid_uv >= 384,"sleeve side triangles have non-collapsed UVs")
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	var finite_tangents := true
	for value in tangents: finite_tangents = finite_tangents and is_finite(value)
	check(tangents.size() == arrays[Mesh.ARRAY_VERTEX].size()*4 and finite_tangents,"normal-map tangents exist and are finite")
	for rounded in [true,false]:
		var mesh := Meshes.tube(PackedVector3Array([Vector3.ZERO,Vector3(0,0.15,0.01),Vector3(0.1,0.28,0.01)]),PackedFloat32Array([0.02,0.023,0.02]),rounded)
		var a: Array = mesh.surface_get_arrays(0)
		var points: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var ids: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var wrong := 0
		for i in range(0,ids.size(),3):
			var p := ids[i]; var q := ids[i+1]; var r := ids[i+2]
			if (points[q]-points[p]).cross(points[r]-points[p]).dot(normals[p]+normals[q]+normals[r]) > 0.0000001: wrong += 1
		check(wrong == 0,"tube and cap winding matches outward normals")
	parent.free()
	print("GRIP_SAFETY_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
