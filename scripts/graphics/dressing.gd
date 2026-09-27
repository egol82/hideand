@tool
extends RefCounted
const Art = preload("res://scripts/phase4/art.gd")
const Surfaces = preload("res://scripts/graphics/surfaces.gd")
const Studio = preload("res://scripts/graphics/studio.gd")
const Layout = preload("res://scenes/graphics/lounge_dressing.tscn")
const Floor = preload("res://shaders/floor_boards.gdshader")

static func apply(arena) -> void:
	if arena.has_node("VisualDressing"): return
	var r := Node3D.new(); r.name = "VisualDressing"; arena.add_child(r)
	r.set_meta("cosmetic_only",true)
	# Recolor surfaces; never remove cover, collision nodes, public hideout IDs or nav cells.
	for node in arena.get_children():
		if not node is MeshInstance3D: continue
		var ext: Vector3 = node.mesh.get_aabb().size*node.scale.abs()
		if node.material_override is StandardMaterial3D:
			var old: StandardMaterial3D = node.material_override
			if ext.y > 3.0 and minf(ext.x,ext.z) < 0.6:
				node.material_override = Surfaces.make(Color("e3dfcd") if arena.map_id == "toy_home" else old.albedo_color,"plaster")
			elif node.position.y > 4.0 and ext.x > 10:
				node.material_override = Surfaces.make(Color("e9e4d7"),"plaster")
		if node.position.y < 0 and ext.x > 10 and arena.map_id != "garden":
			var floor_mat := ShaderMaterial.new(); floor_mat.shader = Floor
			node.material_override = floor_mat
		if ext.y < 0.02 and ext.x > 10: node.visible = false # superseded floor seam lines only
		if arena.map_id == "toy_home":
			if node.position.z < -9.4 and node.position.y > 1.3 and ext.y < 2.2: node.visible = false # authored wall composition replaces old flat pictures/windows
			if absf(absf(node.position.x)-5) < 0.05 and absf(node.position.z+4.1) < 0.05 and node.position.y > 0.78: node.visible = false # shade/stem replaced, table stays
	if arena.map_id == "toy_home":
		r.add_child(Layout.instantiate())
		_house_details(r)
		Studio.contact(r,Vector3(0,0.016,-3.1),Vector2(5.5,2.6))
		for x in [-5.0,5.0]: Studio.contact(r,Vector3(x,0.017,-4.1),Vector2(1.5,1.5))
	# Grounding under existing, always-public furniture only, not hidden occupants.
	for i in range(arena.spots.size()):
		var p: Vector3 = arena.spots[i]
		p += Vector3(p.x,0,p.z).normalized()*1.9
		Studio.contact(r,Vector3(p.x,0.029,p.z),Vector2(2.7,2.25))

static func _house_details(r: Node3D) -> void:
	var trim := Color("f1e8d5")
	for z in [-9.72,9.72]:
		Art.box(r,Vector3(0,0.56,z),Vector3(23.5,1.08,0.035),Color("b5c5b7"),"wood",0.012)
		for y in [0.10,1.08,4.32]: Art.box(r,Vector3(0,y,z+0.015*signf(-z)),Vector3(23.5,0.08,0.09),trim,"wood",0.02)
		for x in range(-11,12,2): Art.box(r,Vector3(x,0.59,z+0.031*signf(-z)),Vector3(0.048,0.91,0.032),trim,"wood",0.009)
	for x in [-11.72,11.72]:
		Art.box(r,Vector3(x,0.56,0),Vector3(0.035,1.08,19.45),Color("b5c5b7"),"wood",0.012)
		for y in [0.10,1.08,4.32]: Art.box(r,Vector3(x+0.015*signf(-x),y,0),Vector3(0.09,0.08,19.45),trim,"wood",0.02)
		for z in range(-9,10,2): Art.box(r,Vector3(x+0.031*signf(-x),0.59,z),Vector3(0.032,0.91,0.048),trim,"wood",0.009)
	# Soft-edged rug layers remain below feet and never become collision.
	Art.box(r,Vector3(0,0.053,0),Vector3(7.6,0.045,7.6),Color("d9c9a7"),"fabric",0.02)
	Art.box(r,Vector3(0,0.079,0),Vector3(7.35,0.012,7.35),Color("6f9e95"),"fabric",0.004)
	Art.box(r,Vector3(0,0.087,0),Vector3(7.05,0.009,7.05),Color("a8c2b3"),"fabric",0.004)
	for x in range(-3,4):
		for z in [-3.50,3.50]: Art.box(r,Vector3(x,0.095,z),Vector3(0.045,0.006,0.075),Color("f2dfbb"),"fabric",0.002)
	# Sofa stitching and piping. All remain within existing sofa's gameplay footprint.
	for x in [-1.26,0,1.26]:
		for z in [-3.55,-2.50]: Art.box(r,Vector3(x,0.916,z),Vector3(1.05,0.014,0.020),Color("f0c0a5"),"fabric",0.006)
	for x in [-1.3,1.3]:
		Art.box(r,Vector3(x,1.2,-3.32),Vector3(0.59,0.016,0.018),Color("f4dab6"),"fabric",0.006)
	# Small low-frequency ceiling coffers give the eye a scale reference.
	for x in [-6.0,0.0,6.0]: Art.box(r,Vector3(x,4.39,0),Vector3(0.13,0.09,19.45),trim,"wood",0.025)
	for z in [-5.0,5.0]: Art.box(r,Vector3(0,4.39,z),Vector3(23.45,0.09,0.13),trim,"wood",0.025)
