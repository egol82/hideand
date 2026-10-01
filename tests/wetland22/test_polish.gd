extends SceneTree
## Additive visual contracts. The original North58 and all gameplay tests remain unchanged.
const Builder=preload("res://scripts/outdoor20/builder.gd")
const Profile=preload("res://scripts/outdoor20/north_reed_profile.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func build_fixture() -> Node3D:
	var fixture:=Node3D.new();root.add_child(fixture)
	Builder._north_reed_cover(fixture,{"size":Vector2(7,6)})
	return fixture
func visual_signature(fixture: Node3D) -> Array:
	var result: Array=[]
	for node: Node3D in fixture.get_node("NorthReedDecor").find_children("*","Node3D",true,false):
		var entry: Array=[str(fixture.get_path_to(node)),node.transform]
		if node is MeshInstance3D:
			entry.append(node.mesh.get_aabb())
			if node.material_override is StandardMaterial3D:entry.append(node.material_override.albedo_color)
		result.append(entry)
	return result
func run() -> void:
	seed(8027);var expected:=randf();seed(8027)
	var first:=build_fixture()
	check(randf()==expected,"north decorative build does not consume gameplay's global random stream")
	seed(91);var second:=build_fixture()
	check(visual_signature(first)==visual_signature(second),"all planted visual transforms, mesh bounds and colours repeat across different random seeds")
	var terrain: MeshInstance3D=first.get_node("NorthReedTerrain")
	check(terrain.get_surface_override_material(0)==terrain.get_surface_override_material(1),"both exact hull partitions share the continuous bank material")
	var material: ShaderMaterial=terrain.get_surface_override_material(0)
	check(material.shader.resource_path=="res://shaders/outdoor20/north_bank.gdshader","continuous surface-locked bank treatment is used only by the north fixture")
	var decor: Node3D=first.get_node("NorthReedDecor")
	var heights: Dictionary={};var angles: Array[float]=[];var radii: Array[float]=[]
	var stem_grounded:=true;var heads_attached:=true;var leaves_rooted:=true;var local_bounds:=true
	var moss_sizes: Dictionary={};var root_sizes: Dictionary={};var root_grounded:=true
	for anchor: Node3D in decor.get_children():
		if anchor.name.begins_with("Reed_"):
			var stalk: Node3D=anchor.get_node("Stalk")
			var stem: MeshInstance3D=stalk.get_node("Stem")
			var head: MeshInstance3D=stalk.get_node("Head")
			heights[snappedf(stem.mesh.height,0.001)]=true
			angles.append(atan2(anchor.position.z,anchor.position.x));radii.append(Vector2(anchor.position.x,anchor.position.z).length())
			stem_grounded=stem_grounded and absf(stem.position.y-stem.mesh.height*0.5+0.035)<0.00001
			heads_attached=heads_attached and head.position.distance_to(Vector3(0,stem.mesh.height-0.025,0))<0.00001 and head.get_parent()==stem.get_parent()
			if stalk.has_node("Leaf"):
				var leaf: MeshInstance3D=stalk.get_node("Leaf")
				leaves_rooted=leaves_rooted and leaf.position.distance_to(Vector3(0,-0.01,0))<0.00001 and leaf.mesh is ArrayMesh and leaf.material_override.cull_mode==BaseMaterial3D.CULL_DISABLED
		elif anchor.name.begins_with("Moss_"):
			var cap: MeshInstance3D=anchor.get_child(0);moss_sizes[cap.scale]=true
			check(cap.position.y<0 and cap.scale.y<0.13,"moss cushion is shallow and embedded: "+str(anchor.name))
		elif anchor.name.begins_with("Root_"):
			var frame: Node3D=anchor.get_child(0);var log_node: MeshInstance3D=frame.get_child(0)
			root_sizes[snappedf(log_node.mesh.height,0.001)]=true
			for end in [-1.0,1.0]:
				var point: Vector3=first.to_local(frame.to_global(Vector3(end*log_node.mesh.height*0.5,0,0)))
				var gap: float=point.y-Profile.surface_height(Vector2(point.x,point.z))
				root_grounded=root_grounded and is_finite(gap) and gap<=0.036 and gap>=-0.10
	for mesh: MeshInstance3D in decor.find_children("*","MeshInstance3D",true,false):
		var local: Transform3D=first.global_transform.affine_inverse()*mesh.global_transform
		var bounds: AABB=local*mesh.mesh.get_aabb()
		local_bounds=local_bounds and bounds.position.x>=-3.5 and bounds.end.x<=3.5 and bounds.position.z>=-3.0 and bounds.end.z<=3.0
	angles.sort();radii.sort()
	var widest_gap: float=angles[0]+TAU-angles[-1]
	for i in range(angles.size()-1):widest_gap=maxf(widest_gap,angles[i+1]-angles[i])
	check(heights.size()>=18,"authored reed height diversity replaces the four-height repeating rhythm")
	check(widest_gap>0.65 and radii[-1]-radii[0]>0.70,"loose patches have visible negative gaps and staggered depths, never an evenly spaced ring")
	check(stem_grounded and heads_attached and leaves_rooted,"stems embed and heads/rooted blades stay in their own tilted stalk frames")
	check(moss_sizes.size()==5 and root_sizes.size()==6,"all five moss cushions and six root lengths are distinct")
	check(root_grounded,"both ends of every root stay embedded in the actual bank surface")
	check(local_bounds,"every decorative mesh remains inside the original north footprint, leaving adjacent routes clear")
	check(decor.find_children("*","CollisionObject3D",true,false).is_empty(),"polished decoration introduces no physics bodies")
	first.queue_free();second.queue_free();await process_frame
	print("NORTH_REED22_POLISH_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
