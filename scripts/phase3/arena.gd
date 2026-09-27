extends Node3D
## Every blocker is created together with its matching inflated navigation rectangle.
const Toy = preload("res://scripts/toy_factory.gd")
const Catalog = preload("res://scripts/phase3/map_catalog.gd")
const CELL := 1.0
var map_id := "toy_home"
var config: Dictionary
var dimensions := Vector2(24,20)
var navigation := AStarGrid2D.new()
var origin := Vector2.ZERO
var grid_size := Vector2i.ZERO
var obstacles: Array[Rect2] = []
var spots: Array[Vector3] = []
var spot_names: Array[String] = []
var markers: Array[Label3D] = []
var spawn_points: Array[Vector3] = [Vector3(-1.5,0,3),Vector3(-0.5,0,3),Vector3(0.5,0,3),Vector3(1.5,0,3)]
var escape_point := Vector3(3,0,2.5)

func _ready() -> void:
	config = Catalog.spec(map_id)
	map_id = config.id
	dimensions = config.size
	_build_shell()
	if map_id == "toy_home":
		_build_home()
	elif map_id == "warehouse":
		_build_warehouse()
	else:
		_build_garden()
	var centers: Array[Vector2] = Catalog.prop_centers(map_id)
	for i in range(centers.size()):
		_hideout(centers[i],i)
	Toy.box(self,Vector3(0,0.024,0),Vector3(7.5,0.035,7.5),Color("9bbfb1"))
	for x in [-2.5,0.0,2.5]:
		Toy.box(self,Vector3(x,0.047,0),Vector3(0.25,0.008,7.4),Color("d8dfbd"))
	_build_navigation()

func _build_shell() -> void:
	Toy.box(self,Vector3(0,-0.22,0),Vector3(dimensions.x,0.44,dimensions.y),config.floor)
	Toy.collider(self,Vector3(0,-0.22,0),Vector3(dimensions.x,0.44,dimensions.y))
	var h := 2.3 if map_id == "garden" else (5.8 if map_id == "warehouse" else 4.5)
	for x in [-dimensions.x*0.5,dimensions.x*0.5]:
		Toy.box(self,Vector3(x,h*0.5,0),Vector3(0.4,h,dimensions.y),config.wall)
		Toy.collider(self,Vector3(x,h*0.5,0),Vector3(0.4,h,dimensions.y))
	for z in [-dimensions.y*0.5,dimensions.y*0.5]:
		Toy.box(self,Vector3(0,h*0.5,z),Vector3(dimensions.x,h,0.4),config.wall)
		Toy.collider(self,Vector3(0,h*0.5,z),Vector3(dimensions.x,h,0.4))
	if map_id != "garden":
		var ceiling := Toy.box(self,Vector3(0,h+0.06,0),Vector3(dimensions.x,0.12,dimensions.y),Color("d6dcd1"))
		ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Toy.collider(self,Vector3(0,h+0.06,0),Vector3(dimensions.x,0.12,dimensions.y))
		for x in [-dimensions.x*0.25,dimensions.x*0.25]:
			Toy.box(self,Vector3(x,h-0.05,0),Vector3(0.35,0.06,dimensions.y*0.6),Color("f1e4ba"))
	# Navigation boundaries stop a full capsule short of the walls.
	for z in range(-int(dimensions.y*0.5)+1,int(dimensions.y*0.5),2):
		Toy.box(self,Vector3(0,0.007,z),Vector3(dimensions.x-0.5,0.008,0.025),config.floor.darkened(0.09))
	_sign(config.title,Vector3(0,3.1,-dimensions.y*0.5+0.24),0)

func _build_home() -> void:
	# Two partial partitions leave a six-metre central corridor and two side routes.
	for x in [-7.8,7.8]:
		_block(Vector3(x,1.55,-3.0),Vector3(4.4,3.1,0.28),Color("cbdbd0"))
		_block(Vector3(x,1.55,3.0),Vector3(4.4,3.1,0.28),Color("e5ccd0"))
	for x in [-7.0,0.0,7.0]:
		_window(Vector3(x,2.35,-9.74))
	_sign("LIVING",Vector3(-7.8,2.4,-2.8),0)
	_sign("PLAY ROOM",Vector3(7.8,2.4,3.2),0)
	for p in [Vector2(-10.4,-8.0),Vector2(10.4,8.0)]:
		_tree(p,1.8)

func _build_warehouse() -> void:
	for x in [-15.0,-7.0,7.0,15.0]:
		for z in [-6.0,6.0]:
			_shelf(Vector3(x,0,z))
	for z in [-15.0,15.0]:
		_arch(Vector3(0,0,z),"TOY DEPOT")
	for x in [-17.0,-8.0,8.0,17.0]:
		_window(Vector3(x,3.0,-17.74))
	for x in [-21.0,21.0]:
		Toy.box(self,Vector3(x,0.015,0),Vector3(0.14,0.01,30),Color("eed692"))

func _build_garden() -> void:
	Toy.box(self,Vector3(0,0.012,0),Vector3(7,0.016,dimensions.y-0.6),Color("decba7"))
	Toy.box(self,Vector3(0,0.015,0),Vector3(dimensions.x-0.6,0.016,6),Color("decba7"))
	for x in [-17.0,17.0]:
		for z in [-14.0,14.0]:
			_block(Vector3(x,0.9,z),Vector3(9,1.8,1.8),Color("6c966f"))
			for dx in [-3.0,0.0,3.0]:
				Toy.ellipsoid(self,Vector3(x+dx,1.8,z),Vector3(1.6,0.7,1.0),Color("8ab57d"))
	for z in [-16.0,16.0]:
		_arch(Vector3(0,0,z),"GARDEN PATH")
	for x in [-36.0,-27.0,-18.0,-9.0,9.0,18.0,27.0,36.0]:
		for z in [-25.0,25.0]:
			_tree(Vector2(x,z),3.8)
	for x in [-37.0,37.0]:
		for z in [-14.0,0.0,14.0]:
			_tree(Vector2(x,z),3.8)

func _hideout(p: Vector2, i: int) -> void:
	var color: Color = [Color("dfaba2"),Color("8fbad0"),Color("dfc68b"),Color("9dc3ae")][i%4]
	var center := Vector3(p.x,0,p.y)
	var kind := i%3
	if map_id == "garden" and kind == 0:
		_block(center+Vector3.UP*0.7,Vector3(2.0,1.4,1.6),Color("7aa476"))
		Toy.ellipsoid(self,center+Vector3.UP*1.4,Vector3(1.1,0.65,0.85),Color("aad394"))
	elif kind == 1:
		_block(center+Vector3.UP*1.1,Vector3(1.7,2.2,1.5),color)
		Toy.box(self,center+Vector3(0,1.1,0.765),Vector3(0.04,2.05,0.015),color.darkened(0.18))
		Toy.ellipsoid(self,center+Vector3(0.25,1.05,0.82),Vector3(0.055,0.055,0.06),Color("f5e5b5"))
	else:
		_block(center+Vector3.UP*0.68,Vector3(1.9,1.36,1.6),color)
		Toy.ellipsoid(self,center+Vector3.UP*1.36,Vector3(0.96,0.13,0.8),color.lightened(0.12))
		Toy.box(self,center+Vector3.UP*1.49,Vector3(0.18,0.01,1.52),Color("f1dfb5"))
	var access := p-p.normalized()*1.9
	spots.append(Vector3(access.x,0,access.y))
	spot_names.append("%02d · %s" % [i+1,["Toy chest","Locker","Gift box"][kind]])
	var marker := Label3D.new()
	marker.text = "E · %02d" % (i+1)
	marker.font_size = 36
	marker.pixel_size = 0.005
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.position = Vector3(access.x,1.0,access.y)
	marker.visible = false
	add_child(marker)
	markers.append(marker)

func _block(center: Vector3, size3: Vector3, color: Color) -> void:
	Toy.box(self,center,size3,color)
	Toy.collider(self,center,size3)
	obstacles.append(Rect2(Vector2(center.x-size3.x*0.5,center.z-size3.z*0.5),Vector2(size3.x,size3.z)).grow(0.46))

func _shelf(at: Vector3) -> void:
	_block(at+Vector3.UP*1.2,Vector3(3.0,2.4,1.4),Color("96b4b8"))
	for y in [0.35,1.15,1.95]:
		Toy.box(self,at+Vector3(0,y,0.72),Vector3(2.7,0.55,0.09),Color("b7d2c9"))
		for x in [-0.85,0.0,0.85]:
			Toy.ellipsoid(self,at+Vector3(x,y+0.1,0.85),Vector3(0.22,0.25,0.16),Color("ecc794"))

func _tree(p: Vector2, h: float) -> void:
	_block(Vector3(p.x,h*0.34,p.y),Vector3(0.55,h*0.68,0.55),Color("b8976d"))
	Toy.ellipsoid(self,Vector3(p.x,h*0.85,p.y),Vector3(h*0.4,h*0.4,h*0.36),Color("95be87"))

func _arch(at: Vector3, text: String) -> void:
	for x in [-3.8,3.8]:
		_block(at+Vector3(x,1.7,0),Vector3(0.5,3.4,0.5),Color("d9b994"))
	Toy.box(self,at+Vector3.UP*3.45,Vector3(8.1,0.55,0.5),config.accent)
	_sign(text,at+Vector3(0,3.45,0.27),0)

func _window(at: Vector3) -> void:
	Toy.box(self,at,Vector3(3,1.5,0.08),Color("f2e7ce"))
	Toy.box(self,at+Vector3(0,0,0.05),Vector3(2.8,1.3,0.03),Color("a5d4e4"))
	Toy.box(self,at+Vector3(0,0,0.08),Vector3(0.09,1.3,0.02),Color("f2e7ce"))

func _sign(text: String, at: Vector3, angle: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.rotation.y = angle
	label.font_size = 48
	label.pixel_size = 0.01
	label.modulate = Color("334e57")
	label.outline_size = 0
	add_child(label)

func _build_navigation() -> void:
	origin = -dimensions*0.5+Vector2.ONE
	grid_size = Vector2i(int(dimensions.x)-1,int(dimensions.y)-1)
	navigation.region = Rect2i(Vector2i.ZERO,grid_size)
	navigation.offset = origin
	navigation.cell_size = Vector2.ONE*CELL
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in range(grid_size.x):
		for z in range(grid_size.y):
			var p := origin+Vector2(x,z)*CELL
			for rect in obstacles:
				if rect.has_point(p):
					navigation.set_point_solid(Vector2i(x,z))
					break

func nearest_id(at: Vector3) -> Vector2i:
	var raw := (Vector2(at.x,at.z)-origin)/CELL
	var cell := Vector2i(clampi(roundi(raw.x),0,grid_size.x-1),clampi(roundi(raw.y),0,grid_size.y-1))
	if not navigation.is_point_solid(cell):
		return cell
	var best := Vector2i(int(grid_size.x/2),int(grid_size.y/2))
	var distance := INF
	for x in range(grid_size.x):
		for z in range(grid_size.y):
			var candidate := Vector2i(x,z)
			if not navigation.is_point_solid(candidate):
				var d := Vector2(candidate-cell).length_squared()
				if d < distance:
					distance = d
					best = candidate
	return best

func path_to(from: Vector3, to: Vector3) -> PackedVector2Array:
	return navigation.get_point_path(nearest_id(from),nearest_id(to))

func nearest_spot(at: Vector3, radius: float = 1.7) -> int:
	var best := -1
	for i in range(spots.size()):
		var d := Vector2(at.x-spots[i].x,at.z-spots[i].z).length()
		if d < radius:
			radius = d
			best = i
	return best

func has_sight(from: Vector3, to: Vector3) -> bool:
	return clear_ray(from+Vector3.UP,to+Vector3.UP)

func clear_ray(from: Vector3, to: Vector3) -> bool:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty()

func mark_near(at: Vector3, enabled: bool) -> void:
	var near := nearest_spot(at) if enabled else -1
	mark_target(near)

func mark_target(id: int) -> void:
	for i in range(markers.size()):
		markers[i].visible = i == id

func inside(at: Vector3) -> bool:
	return absf(at.x) < dimensions.x*0.5-0.5 and absf(at.z) < dimensions.y*0.5-0.5
