extends Node3D
## Matching room collision and navigation bounds. Hidden occupants are owned by game.gd.
const Toy = preload("res://scripts/toy_factory.gd")
const CELL := 0.5
const ORIGIN := Vector2(-6.5, -4.5)
var navigation := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var spots: Array[Vector3] = [Vector3(-4.8,0,2.35), Vector3(-3.3,0,-1.95), Vector3(4.6,0,-1.05), Vector3(4.6,0,3.7), Vector3(-5.8,0,0.1), Vector3(-1.2,0,3.95)]
var spot_names := ["Cardboard box", "Sofa", "Gift box", "Toy chest", "Bookshelf", "Beanbag"]
var markers: Array[Label3D] = []

func _ready() -> void:
	Toy.room(self)
	# These are the collision dimensions used by Phase 1's Toy.room.
	_block(Vector2(-3.3,-3.35), Vector2(4.0,1.7))
	_block(Vector2(-4.8,1.1), Vector2(1.5,1.4))
	_block(Vector2(4.6,-2.3), Vector2(1.5,1.4))
	_block(Vector2(5.5,-3.95), Vector2(1,1))
	_prop(Vector3(4.6,0.48,2.4), Vector3(1.75,0.95,1.3), Color("92b9cc"))
	Toy.ellipsoid(self,Vector3(4.6,1.0,2.4),Vector3(0.87,0.16,0.65),Color("b1cfda"))
	_prop(Vector3(-6.2,0.75,-1.25),Vector3(1.0,1.5,1.35),Color("c8aa82"))
	for i in range(5):
		Toy.box(self,Vector3(-6.13+0.14*i,1.65,-1.0),Vector3(0.11,0.35,0.45),Color("a4c9bb") if i%2==0 else Color("e4b899"))
	Toy.ellipsoid(self,Vector3(-1.2,0.38,2.9),Vector3(0.8,0.45,0.65),Color("c9a7cb"))
	Toy.collider(self,Vector3(-1.2,0.3,2.9),Vector3(1.5,0.6,1.2))
	_block(Vector2(-1.2,2.9),Vector2(1.5,1.2))
	# Window, trim and a few cohesive toy props; no external textures or meshes.
	Toy.box(self,Vector3(1.2,2.0,-4.84),Vector3(2.8,1.6,0.08),Color("edf0d4"))
	Toy.box(self,Vector3(1.2,2.0,-4.78),Vector3(2.5,1.32,0.03),Color("b5d8df"))
	Toy.box(self,Vector3(1.2,2.0,-4.74),Vector3(0.09,1.4,0.04),Color("f4e8cf"))
	Toy.box(self,Vector3(1.2,2.0,-4.74),Vector3(2.6,0.09,0.04),Color("f4e8cf"))
	for i in range(3):
		Toy.ellipsoid(self,Vector3(2.0+i*0.38,0.15,-3.8),Vector3.ONE*0.16,Color("edcd75"))
	for i in range(spots.size()):
		var label := Label3D.new()
		label.text = "E"
		label.font_size = 36
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("fff1ce")
		label.position = spots[i] + Vector3.UP*0.65
		label.visible = false
		add_child(label)
		markers.append(label)
	_build_navigation()

func _prop(center: Vector3, dimensions: Vector3, color: Color) -> void:
	Toy.box(self,center,dimensions,color)
	Toy.collider(self,center,dimensions)
	_block(Vector2(center.x,center.z),Vector2(dimensions.x,dimensions.z))

func _block(center: Vector2, dimensions: Vector2) -> void:
	obstacles.append(Rect2(center-dimensions*0.5,dimensions).grow(0.41))

func _build_navigation() -> void:
	navigation.region = Rect2i(0,0,27,19)
	navigation.cell_size = Vector2.ONE*CELL
	navigation.offset = ORIGIN
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in range(27):
		for z in range(19):
			var p := ORIGIN + Vector2(x,z)*CELL
			for obstacle in obstacles:
				if obstacle.has_point(p):
					navigation.set_point_solid(Vector2i(x,z))
					break

func nearest_id(position_3d: Vector3) -> Vector2i:
	var raw := (Vector2(position_3d.x,position_3d.z)-ORIGIN)/CELL
	var id := Vector2i(clampi(roundi(raw.x),0,26),clampi(roundi(raw.y),0,18))
	if not navigation.is_point_solid(id):
		return id
	var best := Vector2i(13,9)
	var distance := INF
	for x in range(27):
		for z in range(19):
			var candidate := Vector2i(x,z)
			if not navigation.is_point_solid(candidate):
				var d := Vector2(candidate-id).length_squared()
				if d < distance:
					distance = d
					best = candidate
	return best

func path_to(from: Vector3, to: Vector3) -> PackedVector2Array:
	return navigation.get_point_path(nearest_id(from),nearest_id(to))

func nearest_spot(position_3d: Vector3, radius: float = 1.05) -> int:
	var best := -1
	for i in range(spots.size()):
		var distance := Vector2(position_3d.x-spots[i].x,position_3d.z-spots[i].z).length()
		if distance < radius:
			radius = distance
			best = i
	return best

func has_sight(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from+Vector3.UP,to+Vector3.UP,1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func mark_near(position_3d: Vector3, enabled: bool) -> void:
	var near := nearest_spot(position_3d,1.4) if enabled else -1
	for i in range(markers.size()):
		markers[i].visible = i == near
