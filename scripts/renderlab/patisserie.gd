extends RefCounted
## Original authored bakery detail. All added solids stay over existing counter footprints.
const Bevel = preload("res://scripts/renderlab/shapes.gd")
static var meshes: Dictionary = {}
static var materials: Dictionary = {}
static func mat(c: Color, family: String="wood") -> StandardMaterial3D:
	var key:=c.to_html()+family
	if materials.has(key): return materials[key]
	var m:=StandardMaterial3D.new(); m.albedo_color=c
	m.roughness={"wood":0.68,"foam":0.80,"vinyl":0.44,"ceramic":0.32,"ink":0.70}.get(family,0.8)
	m.metallic_specular=0.25; m.set_meta("toy_family",family)
	m.resource_name="StudioSource/"+family
	materials[key]=m; return m
static func mesh_node(p: Node3D, mesh: Mesh, at: Vector3, c: Color, family: String="wood", scale3: Vector3=Vector3.ONE) -> MeshInstance3D:
	var n:=MeshInstance3D.new(); n.mesh=mesh; n.position=at; n.scale=scale3
	n.material_override=mat(c,family); p.add_child(n); return n
static func box(p: Node3D, at: Vector3, size3: Vector3, c: Color, r: float=0.08) -> MeshInstance3D:
	return mesh_node(p,Bevel.rounded(size3,r),at,c)
static func ball(p: Node3D, at: Vector3, radii: Vector3, c: Color) -> MeshInstance3D:
	if not meshes.has("sphere"):
		var s:=SphereMesh.new(); s.radius=1.0; s.height=2.0; s.radial_segments=32; s.rings=16; meshes.sphere=s
	return mesh_node(p,meshes.sphere,at,c,"foam",radii)
static func cylinder(p: Node3D, at: Vector3, r: float,h: float,c: Color) -> MeshInstance3D:
	var key:="cylinder/%s/%s"%[r,h]
	if not meshes.has(key):
		var mesh:=CylinderMesh.new(); mesh.top_radius=r; mesh.bottom_radius=r; mesh.height=h; mesh.radial_segments=64
		meshes[key]=mesh
	return mesh_node(p,meshes[key],at,c,"foam")
static func ring(p: Node3D, at: Vector3, r: float, thick: float, c: Color) -> MeshInstance3D:
	var key:="torus/%s/%s"%[r,thick]
	if not meshes.has(key):
		var mesh:=TorusMesh.new(); mesh.inner_radius=r-thick; mesh.outer_radius=r+thick; mesh.rings=64; mesh.ring_segments=12
		meshes[key]=mesh
	return mesh_node(p,meshes[key],at,c,"foam")
static func text(p: Node3D, value: String, at: Vector3, pixels: int=38, c: Color=Color("fff2da")) -> void:
	var n:=Label3D.new(); n.text=value; n.position=at; n.font_size=pixels; n.pixel_size=0.006
	n.modulate=c; n.outline_size=0; n.no_depth_test=false; p.add_child(n)
static func create_island() -> Node3D:
	var root:=Node3D.new(); root.name="StudioCakeIsland"
	# The original main cover envelope is retained: same footprint and opaque front/back.
	box(root,Vector3(0,0.16,0),Vector3(5.0,0.30,3.6),Color("b68b76"),0.12)
	box(root,Vector3(0,0.77,0),Vector3(4.97,0.98,3.57),Color("d99e88"),0.11)
	box(root,Vector3(0,1.29,0),Vector3(5.0,0.18,3.6),Color("f6e9d1"),0.075)
	for side in [-1,1]:
		for x in [-1.74,0.0,1.74]:
			box(root,Vector3(x,0.79,side*1.795),Vector3(1.50,0.72,0.026),Color("cc8f7f"),0.011)
			box(root,Vector3(x,0.82,side*1.815),Vector3(1.36,0.58,0.022),Color("dfa58c"),0.010)
		box(root,Vector3(0,0.89,side*1.831),Vector3(2.45,0.48,0.035),Color("697f77"),0.016)
		var label_root:=Node3D.new(); root.add_child(label_root)
		label_root.position=Vector3(0,0,side*1.853)
		if side<0: label_root.rotation.y=PI
		text(label_root,"SUGAR & SMASH",Vector3(0,0.90,0),33)
		for x in [-2.25,2.25]: ball(root,Vector3(x,0.90,side*1.835),Vector3(0.055,0.055,0.019),Color("edcf97"))
	cylinder(root,Vector3(0,1.415,0),1.48,0.07,Color("c9ad89"))
	cylinder(root,Vector3(0,1.45,0),1.45,0.05,Color("fcf0d9"))
	var colors: Array[Color]=[Color("d8919d"),Color("f4d6a2"),Color("9fcab8")]
	var radii: Array[float]=[1.34,1.06,0.78]
	for tier in range(3):
		var r: float=radii[tier]; var y:=1.69+tier*0.48
		cylinder(root,Vector3(0,y,0),r,0.45,colors[tier])
		ring(root,Vector3(0,y-0.205,0),r-0.018,0.046,colors[tier].darkened(0.04))
		cylinder(root,Vector3(0,y+0.220,0),r-0.015,0.032,Color("fff0d9"))
		ring(root,Vector3(0,y+0.205,0),r-0.013,0.060,Color("fff0d9"))
		for k in range(16-tier*3):
			var angle:=TAU*k/(16-tier*3)
			var dip:=0.065 if k%2==0 else 0.095
			ball(root,Vector3(cos(angle)*(r-0.025),y+0.17-dip*0.45,sin(angle)*(r-0.025)),Vector3(0.09,dip,0.075),Color("fff0d9"))
		for k in range(16):
			var angle:=TAU*k/16
			ball(root,Vector3(cos(angle)*(r-0.085),y+0.258,sin(angle)*(r-0.085)),Vector3(0.076,0.063,0.076),Color("fff0d9"))
	for k in range(7):
		var angle:=TAU*k/7
		var at:=Vector3(cos(angle)*0.57,2.99,sin(angle)*0.57)
		ball(root,at,Vector3(0.092,0.120,0.092),Color("cf777f"))
		ball(root,at+Vector3.UP*0.10,Vector3(0.088,0.018,0.056),Color("93bca0"))
	ball(root,Vector3(0,3.04,0),Vector3(0.20,0.17,0.20),Color("d57380"))
	return root
static func details(arena) -> Node3D:
	var root:=Node3D.new(); root.name="StudioBakeryDetails"
	for item in arena.map_plan.props:
		if item.kind not in ["counter","jars","oven"]: continue
		var at:=Vector3(item.at.x,0,item.at.y)
		for side in [-1,1]:
			for x in [-item.size.x*0.30,0,item.size.x*0.30]:
				box(root,at+Vector3(x,0.82,side*(item.size.y*0.5+0.018)),Vector3(item.size.x*0.25,0.92,0.027),item.color.lightened(0.08),0.013)
			box(root,at+Vector3(0,0.27,side*(item.size.y*0.5+0.04)),Vector3(item.size.x*0.93,0.09,0.03),Color("e7c79f"),0.013)
	# Kitchen trim/blackboard are attached to the already solid back boundary, no new walk blocker.
	for x in [-5.25,5.25]:
		box(root,Vector3(x,2.65,-12.78),Vector3(2.9,2.02,0.06),Color("b99477"),0.029)
		box(root,Vector3(x,2.65,-12.72),Vector3(2.67,1.81,0.036),Color("536e68"),0.016)
		text(root,"BAKED WITH JOY",Vector3(x,3.09,-12.69),26)
		text(root,"CAKE  /  TEA\nCOOKIES  /  PIE",Vector3(x,2.49,-12.69),22,Color("e6cfaa"))
		for y in [2.12,2.97]: box(root,Vector3(x,y,-12.675),Vector3(2.04,0.014,0.012),Color("d7be95"),0.004)
	return root
