extends SceneTree
const Exporter=preload("res://scripts/renderlab/bake_export.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://ci-artifacts/studio-export.json"))
	if not report is Dictionary or not report.get("errors",["missing"]).is_empty(): printerr("FAIL: export manifest missing or invalid"); quit(1); return
	var scene=load("res://assets/renderlab/generated/sugar_static.scn")
	if not scene is PackedScene: printerr("FAIL: exported scene missing"); quit(1); return
	var room=scene.instantiate(); root.add_child(room)
	var count:=0; var vertices:=0; var triangles:=0; var errors: Array=[]
	var evaluator=Exporter.new()
	for node in room.get_children():
		if node is CollisionObject3D: errors.append("unexpected collision")
		if node is MeshInstance3D:
			count+=1
			if not node.mesh is ArrayMesh: errors.append("primitive not converted"); continue
			var node_triangles:=0
			for i in range(node.mesh.get_surface_count()):
				var arrays=node.mesh.surface_get_arrays(i)
				if arrays[Mesh.ARRAY_TEX_UV2]==null or arrays[Mesh.ARRAY_TEX_UV2].size()!=arrays[Mesh.ARRAY_VERTEX].size(): errors.append("missing UV2")
				else:
					for uv in arrays[Mesh.ARRAY_TEX_UV2]:
						if not uv.is_finite() or uv.x<0 or uv.y<0 or uv.x>1.001 or uv.y>1.001: errors.append("invalid UV2")
				vertices+=arrays[Mesh.ARRAY_VERTEX].size()
				var indices=arrays[Mesh.ARRAY_INDEX]
				node_triangles+=int((indices.size() if indices!=null and indices.size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3)
			triangles+=node_triangles
			var measured: Dictionary=evaluator.measure(node.mesh)
			var source_area: float=node.get_meta("source_surface_area",-1.0)
			if source_area<0 or absf(measured.area-source_area)>maxf(0.00001,source_area*0.00001): errors.append("source surface area changed")
			var actual: AABB=measured.bounds
			var source: AABB=node.get_meta("source_aabb",AABB())
			if not actual.position.is_equal_approx(source.position) or not actual.size.is_equal_approx(source.size): errors.append("source bounds changed")
	# UV seam duplication can differ by platform; verify source area/bounds and this run's actual manifest instead.
	if count!=421 or vertices!=int(report.get("vertices",-1)) or triangles!=int(report.get("triangles",-1)) or vertices<200000: errors.append("incomplete static snapshot")
	if not room.has_node("LightmapGI") or room.get_node("LightmapGI").light_data!=null: errors.append("unbaked authoring state expected")
	room.queue_free(); await process_frame
	if errors.is_empty(): print("STUDIO_EXPORT_VERIFY_PASS: %d static meshes / %d UV2 vertices / %d triangles with preserved source area/bounds; no baked GI yet"%[count,vertices,triangles]); quit()
	else: printerr("FAIL: ",errors); quit(1)
