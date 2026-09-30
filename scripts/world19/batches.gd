extends RefCounted
## Identical small props are instanced by mesh/material and 8m spatial cell.
## Cover NEVER enters this batcher. Only project-authored decorative pieces are accepted.
const Art=preload("res://scripts/phase4/art.gd")
const CELL:=8.0
static var meshes: Dictionary={}
static func shape(id: String) -> Mesh:
	if meshes.has(id):return meshes[id]
	var m: Mesh
	if id=="ball":
		var sphere:=SphereMesh.new();sphere.radius=0.5;sphere.height=1;sphere.radial_segments=16;sphere.rings=8;m=sphere
	elif id=="cylinder":
		var cylinder:=CylinderMesh.new();cylinder.top_radius=0.5;cylinder.bottom_radius=0.5;cylinder.height=1;cylinder.radial_segments=16;m=cylinder
	else:m=Art.rounded(Vector3.ONE,0.07)
	meshes[id]=m;return m

static func build(pieces: Array) -> Node3D:
	var root:=Node3D.new();root.name="WorldFinish19"
	var groups: Dictionary={}
	for p in pieces:
		var cell:=Vector2i(floori(p.at.x/CELL),floori(p.at.z/CELL))
		var key: String="%s/%s/%s/%s/%s"%[p.shape,p.material,p.color.to_html(),cell,p.small]
		if not groups.has(key):groups[key]={"items":[],"cell":cell,"piece":p}
		groups[key].items.append(p)
	for key in groups:
		var group: Dictionary=groups[key];var p: Dictionary=group.piece
		var origin:=Vector3((group.cell.x+0.5)*CELL,0,(group.cell.y+0.5)*CELL)
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=shape(p.shape);mm.instance_count=group.items.size()
		var bounds:=AABB();var first:=true
		for i in range(group.items.size()):
			var item: Dictionary=group.items[i]
			var t:=Transform3D(Basis.from_euler(item.rotation).scaled(item.size),item.at-origin)
			mm.set_instance_transform(i,t)
			var b: AABB=t*mm.mesh.get_aabb()
			bounds=b if first else bounds.merge(b);first=false
		mm.custom_aabb=bounds.grow(0.03)
		var node:=MultiMeshInstance3D.new();node.name="Batch_%03d"%root.get_child_count();node.multimesh=mm;node.position=origin
		node.material_override=Art.material(p.color,p.material)
		node.set_meta("source19",node.material_override);node.set_meta("small19",p.small)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.gi_mode=GeometryInstance3D.GI_MODE_DYNAMIC
		root.add_child(node)
	root.set_meta("piece_count",pieces.size());root.set_meta("batch_count",groups.size())
	return root

static func apply(root: Node3D,studio,distance: float) -> void:
	for n in root.get_children():
		if not n is MultiMeshInstance3D:continue
		var src: StandardMaterial3D=n.get_meta("source19")
		n.material_override=src if studio.profile==0 else studio.converter.convert(src,studio.profile==2,false)
		n.visibility_range_end=distance if n.get_meta("small19") else 0.0
		n.visibility_range_end_margin=1.5 if n.visibility_range_end>0 else 0.0
