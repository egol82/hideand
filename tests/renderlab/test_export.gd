extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=load("res://assets/renderlab/generated/sugar_static.scn")
	if not scene is PackedScene: printerr("FAIL: exported scene missing"); quit(1); return
	var room=scene.instantiate(); root.add_child(room)
	var count:=0; var vertices:=0; var errors: Array=[]
	for node in room.get_children():
		if node is CollisionObject3D: errors.append("unexpected collision")
		if node is MeshInstance3D:
			count+=1
			if not node.mesh is ArrayMesh: errors.append("primitive not converted"); continue
			for i in range(node.mesh.get_surface_count()):
				var arrays=node.mesh.surface_get_arrays(i)
				if arrays[Mesh.ARRAY_TEX_UV2]==null or arrays[Mesh.ARRAY_TEX_UV2].size()!=arrays[Mesh.ARRAY_VERTEX].size(): errors.append("missing UV2")
				else:
					for uv in arrays[Mesh.ARRAY_TEX_UV2]:
						if not uv.is_finite() or uv.x<0 or uv.y<0 or uv.x>1.001 or uv.y>1.001: errors.append("invalid UV2")
				vertices+=arrays[Mesh.ARRAY_VERTEX].size()
	if count!=421 or vertices!=242079: errors.append("incomplete static snapshot")
	if not room.has_node("LightmapGI") or room.get_node("LightmapGI").light_data!=null: errors.append("unbaked authoring state expected")
	room.queue_free(); await process_frame
	if errors.is_empty(): print("STUDIO_EXPORT_VERIFY_PASS: 421 static meshes / 242079 vertices with real UV2; no baked GI yet"); quit()
	else: printerr("FAIL: ",errors); quit(1)
