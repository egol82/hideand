extends SceneTree
const Scene=preload("res://scenes/phase21.tscn")
const Helpers=preload("res://tests/pine21/test_pine.gd")
const Contract=preload("res://tests/wetland22/north_contract.gd")
const Profile=preload("res://scripts/outdoor20/north_reed_profile.gd")
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func triangles(mesh: Mesh,helpers) -> Array:
	var result: Array=[]
	for surface in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
		var arrays: Array=mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:=PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX]!=null:indices=arrays[Mesh.ARRAY_INDEX]
		var count: int=vertices.size() if indices.is_empty() else indices.size()
		for i in range(0,count,3):
			var face:=PackedVector3Array()
			for j in range(3):face.append(vertices[i+j] if indices.is_empty() else vertices[indices[i+j]])
			result.append(helpers.normalized_vertices(face))
	result.sort_custom(func(left: Array,right: Array) -> bool:return str(left)<str(right))
	return result
func ray(from: Vector3,to: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(from,to,1)
	return game.arena.get_world_3d().direct_space_state.intersect_ray(query)
func run() -> void:
	var helpers:=Helpers.new()
	var pinned:=Contract.points()
	var reversed:=PackedVector3Array()
	for i in range(pinned.size()-1,-1,-1):reversed.append(pinned[i])
	check(helpers.normalized_vertices(pinned)==helpers.normalized_vertices(reversed),"actual shared Convex serializer ignores point ordering")
	var changed:=pinned.duplicate();changed[0]+=Vector3(0.01,0,0)
	check(helpers.normalized_vertices(pinned)!=helpers.normalized_vertices(changed),"actual shared Convex serializer detects displaced hull vertices")
	check(pinned.size()==64 and helpers.normalized_vertices(Profile.points())==helpers.normalized_vertices(pinned),"production north profile matches the independent approved 64-point contract")
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame;game.set_process(false)
	game.return_to_menu();game.select_map("reedwater_bend")
	await process_frame;await physics_frame;await physics_frame
	var north: Node3D=game.arena.get_node("Cover_reed_north")
	var shapes: Array=north.find_children("*","CollisionShape3D",true,false)
	check(shapes.size()==1 and north.find_children("*","StaticBody3D",true,false).size()==1,"north has one terrain body and one shape, never the old Box alongside it")
	var shape: CollisionShape3D=shapes[0]
	check(shape.get_parent().collision_layer==1 and shape.get_parent().collision_mask==0 and not shape.disabled,"north preserves the original physical layer and mask with an enabled replacement shape")
	check([shape.global_transform,shape.shape.get_class(),helpers.shape_geometry(shape.shape)]==Contract.collision(helpers),"live arena uses the exact approved north Convex shape and world transform")
	var terrain: MeshInstance3D=north.get_node("NorthReedTerrain")
	check(terrain.transform==Transform3D.IDENTITY and terrain.mesh.get_surface_count()==2,"mud and moss share one unshifted terrain mesh with two material surfaces")
	check(triangles(terrain.mesh,helpers)==triangles(shape.shape.get_debug_mesh(),helpers),"every visible terrain triangle matches the actual collision hull; no floating moss plate")
	var outward:=true;var upper_moss:=true
	for surface in range(terrain.mesh.get_surface_count()):
		var arrays: Array=terrain.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		for i in range(0,vertices.size(),3):
			var normal: Vector3=(vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).normalized()
			for j in range(3):outward=outward and normal.dot(normals[i+j])>0.999
			if surface==1:upper_moss=upper_moss and normal.y>0.68
	check(outward and upper_moss,"terrain normals face outwards and moss occupies upper hull faces, never a bottom or detached plate")
	var decor: Node3D=north.get_node("NorthReedDecor")
	var anchors:=0;var stems:=0;var heads:=0;var leaves:=0;var moss:=0;var roots:=0
	for anchor: Node3D in decor.get_children():
		if not anchor.has_meta("north_surface_anchor"):continue
		anchors+=1
		var sample:=Vector2(anchor.position.x,anchor.position.z)
		check(is_finite(anchor.position.y) and absf(anchor.position.y-Profile.surface_height(sample))<0.00001,"decoration anchor follows the actual terrain: "+anchor.name)
		stems+=anchor.find_children("Stem","MeshInstance3D",true,false).size()
		heads+=anchor.find_children("Head","MeshInstance3D",true,false).size()
		leaves+=anchor.find_children("Leaf","MeshInstance3D",true,false).size()
		if anchor.name.begins_with("Moss_"):moss+=1
		if anchor.name.begins_with("Root_"):roots+=1
	check([anchors,stems,heads,leaves,moss,roots]==[35,24,24,12,5,6],"all original north stems, heads, leaves, moss tufts and roots remain on planted anchors")
	check(decor.find_children("*","CollisionObject3D",true,false).is_empty(),"planted reed decorations add no hidden physics walls")
	for sample in [Vector2.ZERO,Vector2(-1.5,-1.0),Vector2(1.5,1.0),Vector2(-3.0,0),Vector2(0,-2.5),Vector2(0,2.5)]:
		var world:=north.global_position+Vector3(sample.x,0,sample.y)
		var hit:=ray(world+Vector3.UP*3.0,world+Vector3.DOWN*0.1)
		check(not hit.is_empty() and hit.collider==shape.get_parent() and absf(hit.position.y-Profile.surface_height(sample))<0.012,"real physics surface matches planted terrain height at "+str(sample))
	for sample in [Vector2(-3.3,-2.8),Vector2(3.3,-2.8),Vector2(-3.3,2.8),Vector2(3.3,2.8)]:
		var world:=north.global_position+Vector3(sample.x,0,sample.y)
		var hit:=ray(world+Vector3.UP*1.0,world+Vector3.DOWN*0.1)
		check(not hit.is_empty() and hit.collider.name=="OutdoorFloor" and absf(hit.position.y)<0.012,"removed square corner is physically open with floor, never an invisible old wall "+str(sample))
	check(not game.arena.clear_ray(Vector3(-4,1,-7),Vector3(4,1,-7)),"north landform still physically blocks cross-island line of sight")
	check(game.arena.clear_ray(Vector3(-4,1.95,-7),Vector3(4,1.95,-7)),"the replacement does not retain a hidden two-metre Box above its sculpted top")
	game.queue_free();helpers.free();await process_frame
	print("NORTH_REED22_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
