@tool
extends "res://scripts/phase3/arena.gd"
const Art4 = preload("res://scripts/phase4/art.gd")
var compact := true
var active_rect := Rect2(-12,-10,24,20)
var active_spots: Array[int] = []

func _ready() -> void:
	super._ready()
	active_rect = Rect2(-dimensions*0.5,dimensions)
	if compact and map_id == "garden": active_rect = Rect2(-27,-18,54,36)
	elif compact and map_id == "warehouse": active_rect = Rect2(-13,-16,26,32)
	if compact and map_id != "toy_home":
		for x in [active_rect.position.x,active_rect.end.x]:
			_zone_fence(Vector3(x,0.75,active_rect.get_center().y),Vector3(0.25,1.5,active_rect.size.y))
		for z in [active_rect.position.y,active_rect.end.y]:
			_zone_fence(Vector3(active_rect.get_center().x,0.75,z),Vector3(active_rect.size.x,1.5,0.25))
	for i in range(spots.size()):
		if active_rect.grow(-0.9).has_point(Vector2(spots[i].x,spots[i].z)): active_spots.append(i)
	# Upgrade boxes without changing the original physics/nav footprints.
	for node in get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh:
			var size3: Vector3 = node.mesh.size
			if minf(size3.x,minf(size3.y,size3.z)) > 0.08:
				node.mesh = Art4.rounded(size3,0.09)
	if map_id == "toy_home": _lounge()
	_build_navigation()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if not active_rect.grow(-0.7).has_point(origin+Vector2(x,y)):
				navigation.set_point_solid(Vector2i(x,y))

func _block(center: Vector3, size3: Vector3, color: Color) -> void:
	Art4.box(self,center,size3,color,"wood",0.09)
	Toy.collider(self,center,size3)
	obstacles.append(Rect2(Vector2(center.x-size3.x*0.5,center.z-size3.z*0.5),Vector2(size3.x,size3.z)).grow(0.46))

func _zone_fence(at: Vector3, size3: Vector3) -> void:
	Toy.collider(self,at,Vector3(size3.x,3.5,size3.z))
	obstacles.append(Rect2(Vector2(at.x-size3.x*0.5,at.z-size3.z*0.5),Vector2(size3.x,size3.z)).grow(0.46))
	Art4.box(self,at,Vector3(size3.x,0.12,size3.z),Color("72b9ad"),"wood",0.035)
	Art4.box(self,at+Vector3.UP*0.55,Vector3(size3.x,0.14,size3.z),Color("f4ce85"),"wood",0.04)
	var length := maxf(size3.x,size3.z)
	for n in range(int(length/2)+1):
		var offset := -length*0.5+n*2.0
		var point := Vector3(offset,0,0) if size3.x > size3.z else Vector3(0,0,offset)
		Art4.box(self,at+point,Vector3(0.16,1.5,0.16),Color("b2cfc0"),"wood",0.035)

func _lounge() -> void:
	# Distinct material families; stage retains paths to every public hiding place.
	var sofa := Vector3(0,0,-3.1)
	var tint := Color("d88176")
	var body := Art4.box(self,sofa+Vector3(0,0.43,0),Vector3(4.4,0.65,1.4),tint,"fabric",0.25)
	body.name = "LoungeSofaBase"
	Art4.box(self,sofa+Vector3(0,1.18,-0.45),Vector3(4.3,1.12,0.42),tint,"fabric",0.18)
	for x in [-2.08,2.08]:
		Art4.box(self,sofa+Vector3(x,0.89,0),Vector3(0.43,0.84,1.65),tint,"fabric",0.18)
	for x in [-1.26,0.0,1.26]:
		Art4.box(self,sofa+Vector3(x,0.80,0.1),Vector3(1.2,0.23,1.20),Color("e49b87"),"fabric",0.095)
	Art4.box(self,sofa+Vector3(-1.3,1.14,-0.08),Vector3(0.68,0.64,0.24),Color("7ab8b0"),"fabric",0.12).rotation.z = 0.22
	Art4.box(self,sofa+Vector3(1.28,1.12,-0.09),Vector3(0.60,0.58,0.22),Color("f4d48e"),"fabric",0.1).rotation.z = -0.25
	Toy.collider(self,sofa+Vector3.UP*0.8,Vector3(4.8,1.6,1.7))
	obstacles.append(Rect2(Vector2(sofa.x-2.4,sofa.z-0.85),Vector2(4.8,1.7)).grow(0.46))
	for x in [-5.0,5.0]:
		Art4.box(self,Vector3(x,0.68,-4.1),Vector3(1.0,0.16,1.0),Color("d4ac7d"),"wood",0.06)
		for dx in [-0.35,0.35]:
			Art4.box(self,Vector3(x+dx,0.31,-4.1),Vector3(0.13,0.65,0.7),Color("bd946d"),"wood",0.04)
		Toy.collider(self,Vector3(x,0.45,-4.1),Vector3(1,0.9,1))
		obstacles.append(Rect2(Vector2(x-0.5,-4.6),Vector2.ONE).grow(0.46))
		Art4.ball(self,Vector3(x,0.91,-4.1),Vector3(0.21,0.17,0.21),Color("ebd9b0"))
		Art4.box(self,Vector3(x,1.22,-4.1),Vector3(0.06,0.6,0.06),Color("c49a65"),"wood",0.025)
		Art4.box(self,Vector3(x,1.57,-4.1),Vector3(0.55,0.48,0.55),Color("b6d5ba"),"fabric",0.18)
		var light := OmniLight3D.new()
		light.position = Vector3(x,2.1,-4.1)
		light.light_color = Color("ffe1a5")
		light.light_energy = 0.24
		light.omni_range = 6
		add_child(light)
	for x in [-4.5,0,4.5]:
		Art4.box(self,Vector3(x,2.5,-9.66),Vector3(1.9,1.2,0.12),Color("ba9b7c"),"wood",0.045)
		Art4.box(self,Vector3(x,2.5,-9.56),Vector3(1.62,0.94,0.04),Color("9bc1bc"),"wood",0.015)
		Art4.ball(self,Vector3(x+0.35,2.65,-9.50),Vector3(0.16,0.16,0.015),Color("f1ce8f"))
	# Small visible stitches and geometric rug accents, below the collision floor.
	for x in range(-3,4):
		for z in [-3.6,3.6]: Art4.box(self,Vector3(x,0.055,z),Vector3(0.28,0.012,0.05),Color("f3dcc0"),"fabric",0.004)
	for z in [-9.7,9.7]:
		Art4.box(self,Vector3(0,0.17,z),Vector3(23.4,0.29,0.09),Color("ceb69a"),"wood",0.025)

func inside(at: Vector3) -> bool:
	return super.inside(at) and active_rect.grow(-0.5).has_point(Vector2(at.x,at.z))

func is_active(id: int) -> bool:
	return id in active_spots
