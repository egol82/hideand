extends RefCounted
## Native UV2 geometry for the fixed manor only. Randomised cover is NEVER baked.
const Exporter=preload("res://scripts/renderlab/bake_export.gd")
const ScenePath:="res://assets/lighting15/manor_lighting.scn"
const DataPath:="res://assets/lighting15/manor_lighting.lmbake"
const Mat=preload("res://scripts/material14/materials.gd")

static func fixed_meshes(arena: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D]=[]
	# All manor fixed art is a direct child. RoundFurniture, actors, labels and clue pools are excluded.
	for n in arena.get_children():
		if n is MeshInstance3D and n.mesh!=null and not n.get_meta("cosmetic_only",false):out.append(n)
	return out

static func signature(nodes: Array[MeshInstance3D]) -> String:
	var rows:=PackedStringArray();var hashes: Dictionary={}
	for n in nodes:
		var key:=n.mesh.get_instance_id()
		if not hashes.has(key):
			var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256)
			for surface in range(n.mesh.get_surface_count()):
				var a: Array=n.mesh.surface_get_arrays(surface)
				var quantized:=PackedInt32Array()
				for v in a[Mesh.ARRAY_VERTEX]:quantized.append(roundi(v.x*10000));quantized.append(roundi(v.y*10000));quantized.append(roundi(v.z*10000))
				h.update(var_to_bytes(quantized));h.update(var_to_bytes(a[Mesh.ARRAY_INDEX]))
			hashes[key]=h.finish().hex_encode()
		var material=n.get_meta("studio_source",n.material_override)
		var pigment: String=str(material.albedo_color) if material is StandardMaterial3D else ""
		rows.append(str(n.transform)+hashes[key]+pigment)
	return "\n".join(rows).sha256_text()

static func light_rig() -> Node3D:
	var rig:=Node3D.new();rig.name="AuthoredLights"
	# The existing blue windows are sealed decorative panes. Interior portal spots represent
	# sunlight entering them; this does NOT claim physical sky transport through an opaque wall.
	for x in [-10.0,-5.0,5.0]:
		var sun:=SpotLight3D.new();sun.name="WindowPortal"+str(int(x)+10)
		sun.position=Vector3(x,2.65,-12.40)
		sun.rotation=Basis.looking_at(Vector3(0.18,-0.38,1).normalized(),Vector3.UP).get_euler()
		sun.light_color=Color("ffe5bb");sun.light_energy=3.5;sun.light_indirect_energy=1.15
		sun.spot_range=21;sun.spot_angle=53;sun.spot_angle_attenuation=0.55
		sun.shadow_enabled=true;sun.shadow_bias=0.025;sun.shadow_normal_bias=0.45
		sun.light_bake_mode=Light3D.BAKE_DYNAMIC;rig.add_child(sun)
	for spec in [[Vector3(-5.8,3.30,-3.0),1.15,Color("fff0d5"),11.0],
		[Vector3(4.8,3.25,5.5),0.85,Color("e5edf0"),14.0],
		[Vector3(-4.0,7.0,-5.0),1.65,Color("fff0d5"),16.0],
		[Vector3(4.0,7.0,6.0),1.35,Color("e5edf0"),16.0]]:
		var lamp:=OmniLight3D.new();lamp.name="CeilingFill"+str(rig.get_child_count())
		lamp.position=spec[0];lamp.light_energy=spec[1];lamp.light_color=spec[2];lamp.omni_range=spec[3]
		lamp.light_indirect_energy=1.0;lamp.shadow_enabled=true;lamp.shadow_bias=0.025;lamp.shadow_normal_bias=0.35
		lamp.light_bake_mode=Light3D.BAKE_DYNAMIC;rig.add_child(lamp)
	for n in rig.get_children():
		n.light_cull_mask=1|(1<<19);n.shadow_caster_mask=1
	return rig

func build(arena: Node3D) -> Dictionary:
	var sources:=fixed_meshes(arena)
	var root:=Node3D.new();root.name="ManorLighting15"
	root.set_meta("fixed_signature",signature(sources));root.set_meta("excludes_round_furniture",true)
	var exporter:=Exporter.new()
	for source in sources:exporter.gather(source,root,arena.global_transform.affine_inverse())
	var mesh_count:=root.get_child_count()
	var material:=Mat.new()
	for i in range(mesh_count):
		var n: MeshInstance3D=root.get_child(i)
		n.set_meta("source_index",i)
		var original: Material=n.material_override
		n.set_meta("bake_source",original)
		if original is StandardMaterial3D:n.material_override=material.convert(original,true,false)
		# Closed shell must occlude indirect transport, including the old diagnostic cutaway roof.
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var lights:=light_rig();root.add_child(lights)
	var gi:=LightmapGI.new();gi.name="LightmapGI"
	gi.quality=LightmapGI.BAKE_QUALITY_LOW;gi.bounces=3;gi.bounce_indirect_energy=1.0
	gi.interior=true;gi.environment_mode=LightmapGI.ENVIRONMENT_MODE_DISABLED
	gi.generate_probes_subdiv=LightmapGI.GENERATE_PROBES_SUBDIV_4
	gi.directional=true;gi.max_texture_size=2048;gi.use_denoiser=true
	root.add_child(gi)
	var probes:=Node3D.new();probes.name="ManualProbes";root.add_child(probes)
	# Uniform floor-specific samples, with denser points around the lower living-room route.
	for y in [0.35,1.15,2.7,4.35,5.15,6.7]:
		for x in [-12.0,-8.0,-4.0,0.0,4.0,8.0,12.0]:
			for z in [-11.0,-7.0,-3.0,1.0,5.0,9.0,11.0]:
				var point:=Vector3(x,y,z)
				var inside:=false
				for source in sources:
					if (source.transform*source.mesh.get_aabb()).grow(0.10).has_point(point):inside=true;break
				if inside:continue
				var p:=LightmapProbe.new();p.name="Probe_%03d"%probes.get_child_count();p.position=point;probes.add_child(p)
	owner_tree(root,root)
	var packed:=PackedScene.new();var error:=packed.pack(root)
	DirAccess.make_dir_recursive_absolute(ScenePath.get_base_dir())
	if error==OK:error=ResourceSaver.save(packed,ScenePath,ResourceSaver.FLAG_COMPRESS)
	var report: Dictionary=exporter.report.duplicate(true)
	report["fixed_signature"]=root.get_meta("fixed_signature");report["manual_probes"]=probes.get_child_count()
	report["source_fixed_count"]=sources.size();report["destination"]=ScenePath
	if error!=OK:report.errors.append(error_string(error))
	root.free()
	return report

static func owner_tree(n: Node,root: Node) -> void:
	for c in n.get_children():c.owner=root;owner_tree(c,root)
