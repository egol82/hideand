extends RefCounted
## Actual editable static meshes + UV2, not a claimed lightmap bake.
var mesh_cache: Dictionary={}
var measures: Dictionary={}
var report: Dictionary={"meshes":0,"unique_unwraps":0,"vertices":0,"triangles":0,"errors":[],"light_data_baked":false}
func export_room(arena: Node3D, destination: String) -> Dictionary:
	var root:=Node3D.new(); root.name="SugarStaticStudio"
	gather(arena,root,arena.global_transform.affine_inverse())
	var gi:=LightmapGI.new(); gi.name="LightmapGI"; gi.quality=LightmapGI.BAKE_QUALITY_LOW
	gi.bounces=3; gi.interior=true; gi.generate_probes_subdiv=LightmapGI.GENERATE_PROBES_SUBDIV_4
	gi.environment_mode=LightmapGI.ENVIRONMENT_MODE_CUSTOM_COLOR
	gi.environment_custom_color=Color("dce5e2"); gi.environment_custom_energy=0.15
	gi.max_texture_size=2048
	root.add_child(gi); gi.owner=root
	var light:=DirectionalLight3D.new(); light.name="WindowSun"
	light.rotation_degrees=Vector3(-48,-24,0); light.light_color=Color("ffe9cf"); light.light_energy=0.85
	light.light_bake_mode=Light3D.BAKE_DYNAMIC; light.shadow_enabled=true
	root.add_child(light); light.owner=root
	# Static local fills are explicit, not dynamic combat lamps.
	for x in [-9.0,0.0,9.0]:
		var fill:=OmniLight3D.new(); fill.position=Vector3(x,4.1,-7)
		fill.light_energy=1.2; fill.light_color=Color("f9e3c6"); fill.omni_range=10
		fill.light_bake_mode=Light3D.BAKE_STATIC; root.add_child(fill); fill.owner=root
	var env:=WorldEnvironment.new(); env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR; env.environment.background_color=Color("a4c8cc")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d9e0df"); env.environment.ambient_light_energy=0.12
	root.add_child(env); env.owner=root
	var camera:=Camera3D.new(); camera.name="ReviewCamera"; camera.fov=72
	camera.position=Vector3(3.5,1.55,-1.0); camera.rotation=Vector3(0,0.5,0)
	root.add_child(camera); camera.owner=root; camera.current=true
	var scene:=PackedScene.new(); var error:=scene.pack(root)
	if error==OK:
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		error=ResourceSaver.save(scene,destination,ResourceSaver.FLAG_COMPRESS)
	if error!=OK: report.errors.append(error_string(error))
	report["path"]=destination
	root.free(); mesh_cache.clear(); measures.clear()
	return report
func gather(node: Node, target: Node3D, inverse: Transform3D) -> void:
	if node is Node3D and not node.is_visible_in_tree(): return
	if node is MeshInstance3D and node.mesh!=null and node.layers==1 and not node.get_meta("cosmetic_only",false) and node.name!="ArtContactShadow":
		var transform3: Transform3D=inverse*node.global_transform
		var key:=str(node.mesh.get_instance_id())+str(transform3.basis)
		var copy: ArrayMesh
		if mesh_cache.has(key): copy=mesh_cache[key]
		else:
			copy=ArrayMesh.new()
			for surface in range(node.mesh.get_surface_count()):
				var primitive: int = node.mesh.surface_get_primitive_type(surface) if node.mesh is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
				if primitive != Mesh.PRIMITIVE_TRIANGLES:
					report.errors.append("Unsupported non-triangle mesh: "+str(node.name)); continue
				copy.add_surface_from_arrays(primitive,node.mesh.surface_get_arrays(surface))
			var result:=copy.lightmap_unwrap(Transform3D(transform3.basis,Vector3.ZERO),0.20)
			if result!=OK:
				report.errors.append(str(node.name)+": "+error_string(result)); return
			mesh_cache[key]=copy; report.unique_unwraps+=1
		for surface in range(copy.get_surface_count()):
			var arrays:=copy.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_TEX_UV2]==null or arrays[Mesh.ARRAY_TEX_UV2].size()!=arrays[Mesh.ARRAY_VERTEX].size(): report.errors.append("Missing UV2: "+str(node.name))
			report.vertices+=arrays[Mesh.ARRAY_VERTEX].size()
		var source_measure := measure(node.mesh)
		var output_measure := measure(copy)
		if absf(source_measure.area-output_measure.area)>maxf(0.00001,source_measure.area*0.00001): report.errors.append("Surface area changed: "+str(node.name))
		var source_bounds: AABB = source_measure.bounds
		var unwrapped_bounds: AABB = output_measure.bounds
		if not source_bounds.position.is_equal_approx(unwrapped_bounds.position) or not source_bounds.size.is_equal_approx(unwrapped_bounds.size): report.errors.append("Vertex bounds changed: "+str(node.name))
		var n:=MeshInstance3D.new(); n.name="Static_%04d"%report.meshes
		n.mesh=copy; n.transform=transform3; n.material_override=node.material_override
		n.set_meta("source_surface_area",source_measure.area)
		n.set_meta("source_aabb",source_bounds)
		report.triangles += output_measure.triangles
		n.cast_shadow=node.cast_shadow; n.gi_mode=GeometryInstance3D.GI_MODE_STATIC
		target.add_child(n); n.owner=target; report.meshes+=1
	for child in node.get_children(): gather(child,target,inverse)

func measure(mesh: Mesh) -> Dictionary:
	var key := mesh.get_instance_id()
	if measures.has(key): return measures[key]
	var area := 0.0; var triangles := 0; var has_bounds := false; var bounds := AABB()
	for surface in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices = arrays[Mesh.ARRAY_INDEX]
		var indexed: bool = indices != null and indices.size() > 0
		var count: int = indices.size() if indexed else vertices.size()
		triangles += int(count / 3)
		for v in vertices:
			if not has_bounds: bounds=AABB(v,Vector3.ZERO); has_bounds=true
			else: bounds=bounds.expand(v)
		for i in range(0,count-2,3):
			var a: Vector3=vertices[indices[i] if indexed else i]
			var b: Vector3=vertices[indices[i+1] if indexed else i+1]
			var c: Vector3=vertices[indices[i+2] if indexed else i+2]
			area+=(b-a).cross(c-a).length()*0.5
	var result:={"area":area,"bounds":bounds,"triangles":triangles}
	measures[key]=result
	return result
