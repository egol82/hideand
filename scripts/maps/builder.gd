extends RefCounted
## Builds scenery, nav and collision from ONE public map plan. No hidden-player input.
const Catalog = preload("res://scripts/maps/catalog.gd")
const Plans = preload("res://scripts/maps/plans.gd")
const Kit = preload("res://scripts/maps/props.gd")
const Art = preload("res://scripts/phase4/art.gd")
const Toy = preload("res://scripts/toy_factory.gd")
const Studio = preload("res://scripts/graphics/studio.gd")
const FloorShader = preload("res://shaders/map_floor.gdshader")

static func build(arena) -> void:
	arena.config = Catalog.spec(arena.map_id)
	arena.dimensions = arena.config.size
	arena.active_rect = Rect2(-arena.dimensions*0.5,arena.dimensions)
	arena.set_meta("map_pack",true)
	arena.map_plan = Plans.layout(arena.map_id)
	arena.surface_zones.assign(arena.map_plan.zones)
	_shell(arena)
	for item in arena.map_plan.props:
		Kit.build(arena,item)
		_solid(arena,item)
		Studio.contact(arena,Vector3(item.at.x,0.024,item.at.y),item.size+Vector2.ONE*0.4)
	for i in range(arena.map_plan.hideouts.size()):
		var h: Dictionary = arena.map_plan.hideouts[i]
		var view := Kit.build(arena,h)
		# Hiding approach is explicit; collision is never rotated independently of the plan.
		view.set_meta("hideout_id",h.id)
		_solid(arena,h)
		arena.spots.append(Vector3(h.access.x,0,h.access.y))
		var title: String = {"pastry":"Pastry Cabinet","parcel":"Gift Parcel","prize_box":"Prize Locker","arcade_box":"Token Case","luggage":"Luggage Trunk","mail":"Mail Crate"}.get(h.kind,"Toy Locker")
		arena.spot_names.append("%02d · %s" % [i+1,title])
		arena.active_spots.append(i)
		var marker := Label3D.new()
		marker.name = "HideHint_%02d"%i; marker.text = "E · %02d"%(i+1)
		marker.font_size = 32; marker.pixel_size = 0.004
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED; marker.no_depth_test = false
		marker.position = Vector3(h.access.x,1.0,h.access.y); marker.visible = false
		arena.add_child(marker); arena.markers.append(marker)
		# Uniform public prop marker. It has no relationship to occupancy.
		Kit.sign_text(arena,"%02d"%(i+1),Vector3(h.at.x,2.15,h.at.y+0.82),24,Color("46636a"))
	for z in arena.surface_zones: _surface(arena,z)
	for landmark in arena.map_plan.landmarks:
		_signpost(arena,landmark)
	_decorate(arena)
	arena._build_navigation()

static func _solid(arena, item: Dictionary) -> void:
	# Bounds include small handles/front panels as well as the main solid.
	var size3 := Vector3(item.size.x+0.14,item.height,item.size.y+0.14)
	var at := Vector3(item.at.x,size3.y*0.5,item.at.y)
	var body := Toy.collider(arena,at,size3)
	body.name = "Solid_"+str(item.id)
	body.set_meta("map_prop_id",item.id)
	arena.obstacles.append(Rect2(item.at-Vector2(size3.x,size3.z)*0.5,Vector2(size3.x,size3.z)).grow(0.46))

static func _shell(a) -> void:
	var dims: Vector2 = a.dimensions
	var indoor: bool = a.map_id != "pocket_station"
	var height := 5.3 if indoor else 2.55
	Toy.collider(a,Vector3(0,-0.22,0),Vector3(dims.x,0.44,dims.y)).name = "MapFloorPhysics"
	var material := ShaderMaterial.new(); material.shader = FloorShader
	material.set_shader_parameter("tint_a",a.config.floor)
	material.set_shader_parameter("tint_b",a.config.floor.lightened(0.13))
	material.set_shader_parameter("repeat_tiles",dims*0.6)
	material.set_shader_parameter("carpet",a.map_id == "starlight_arcade")
	var floor_mesh := PlaneMesh.new(); floor_mesh.size = dims
	var n := MeshInstance3D.new(); n.name = "MapFloorArt"; n.mesh = floor_mesh; n.material_override = material; n.position.y = 0.008; a.add_child(n)
	for side in [-1,1]:
		var x: float = side*dims.x*0.5
		var z: float = side*dims.y*0.5
		_wall(a,Vector3(x,height*0.5,0),Vector3(0.30,height,dims.y),height)
		_wall(a,Vector3(0,height*0.5,z),Vector3(dims.x,height,0.30),height)
	if indoor:
		var ceiling := Kit.box(a,Vector3(0,height+0.03,0),Vector3(dims.x,0.10,dims.y),a.config.wall.lightened(0.25),"plaster",0.02)
		ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ceiling.set_meta("cutaway_roof",true)
		Toy.collider(a,Vector3(0,height+0.03,0),Vector3(dims.x,0.10,dims.y))
		for x in [-dims.x*0.3,0,dims.x*0.3]:
			Kit.box(a,Vector3(x,height-0.07,0),Vector3(0.10,0.14,dims.y-0.4),Color("cbb99a"))
			for z in [-dims.y*0.29,dims.y*0.29]:
				Kit.cylinder(a,Vector3(x,height-0.40,z),0.44,0.16,Color("f3d79f"),0.29)
				Kit.cylinder(a,Vector3(x,height-0.2,z),0.028,0.26,Color("aa9379"))

static func _wall(a, at: Vector3, size3: Vector3, height: float) -> void:
	Kit.box(a,at,size3,a.config.wall,"plaster",0.025)
	Toy.collider(a,at,size3)
	for y in [0.16,1.08,height-0.1]:
		var trim := Vector3(size3.x+0.08,0.13,size3.z+0.08)
		Kit.box(a,Vector3(at.x,y,at.z),trim,a.config.accent.lightened(0.26),"wood",0.03)
	var along_x := size3.x>size3.z
	var length: float = maxf(size3.x,size3.z)
	for i in range(int(length/3)):
		var d: float = -length*0.5+1.5+i*3
		Kit.box(a,Vector3(d if along_x else at.x,0.58,at.z if along_x else d),Vector3(0.045,0.82,0.045),a.config.accent.lightened(0.26),"wood",0.009)

static func _surface(a, z: Dictionary) -> void:
	var rect: Rect2 = z.rect
	var c := Color("e2b778") if z.loud else Color("81b8b0")
	if a.map_id == "starlight_arcade": c = Color("c9a6bf") if z.loud else Color("9ec8c2")
	if a.map_id == "pocket_station": c = Color("b69879") if z.loud else Color("7eaec4")
	var center: Vector2 = rect.get_center()
	Kit.box(a,Vector3(center.x,0.032,center.y),Vector3(rect.size.x,0.025,rect.size.y),c,"wood" if z.loud else "fabric",0.01).name = "Surface_"+str(z.id)
	# Short stripes encode loud surfaces; quiet runners use stitched borders. No flash.
	if z.loud:
		var count := int(maxf(rect.size.x,rect.size.y)/0.55)
		for i in range(count):
			var horizontal: bool = rect.size.x > rect.size.y
			var p := rect.position + (Vector2(0.25+i*0.55,rect.size.y*0.5) if horizontal else Vector2(rect.size.x*0.5,0.25+i*0.55))
			var s := Vector3(0.20,0.013,rect.size.y*0.70) if horizontal else Vector3(rect.size.x*0.70,0.013,0.20)
			Kit.box(a,Vector3(p.x,0.052,p.y),s,c.lightened(0.23),"foam",0.005)
	else:
		for dx in [-rect.size.x*0.42,rect.size.x*0.42]:
			Kit.box(a,Vector3(center.x+dx,0.052,center.y),Vector3(0.055,0.009,rect.size.y*0.94),Color("efe0be"),"fabric",0.003)

static func _signpost(a, landmark: Dictionary) -> void:
	var at: Vector2 = landmark.at
	# Signs sit directly above their associated solid. They do not float in a walk lane.
	var y := 4.35 if a.map_id=="starlight_arcade" else 3.75
	if landmark.en == "POCKET EXPRESS": y = 4.90
	var sign_board := Kit.box(a,Vector3(at.x,y,at.y),Vector3(3.4,0.65,0.13),a.config.accent,"wood",0.10)
	sign_board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.sign_text(a,landmark.en,Vector3(at.x,y,at.y+0.082),28,Color("f8ecd3"))

static func _decorate(a) -> void:
	var dims: Vector2 = a.dimensions
	if a.map_id == "sugar_market":
		for x in [-10.0,0,10.0]:
			# Bakery windows are art attached to solid boundary walls, not walkable doors.
			Kit.box(a,Vector3(x,2.85,-dims.y*0.5+0.18),Vector3(3.5,2.15,0.10),Color("f4e2c4"))
			Kit.box(a,Vector3(x,2.85,-dims.y*0.5+0.24),Vector3(3.20,1.85,0.04),Color("a6c7cb"))
			for offset in [-0.65,0.65]: Kit.box(a,Vector3(x+offset,2.85,-dims.y*0.5+0.28),Vector3(0.08,1.85,0.035),Color("e7d3af"))
			for i in range(7): Kit.box(a,Vector3(x-1.45+i*0.48,4.03,-dims.y*0.5+0.40),Vector3(0.44,0.25,0.42),Color("d78c8d") if i%2==0 else Color("f4dfb9"),"fabric")
	elif a.map_id == "starlight_arcade":
		# Stable star ceiling, no flashing and no moving navigation/occupancy exploits.
		for i in range(45):
			var x := -17.0+float((i*7)%35)
			var z := -13.0+float((i*11)%27)
			Art.ball(a,Vector3(x,5.17,z),Vector3(0.05,0.02,0.05),Color("e9d392"))
		for side in [-1,1]:
			Kit.box(a,Vector3(side*(dims.x*0.5-0.2),3.75,0),Vector3(0.08,0.13,dims.y-1),Color("b9dacb"),"foam",0.02)
	else:
		# Rails are below foot collision height; parked trains are static tested cover.
		for z in [-8.15,-5.85]: Kit.box(a,Vector3(0,0.040,z),Vector3(23,0.045,0.14),Color("867d6b"),"wood",0.015)
		for x in range(-11,12): Kit.box(a,Vector3(x,0.022,-7),Vector3(0.25,0.022,2.8),Color("b7a07b"),"wood",0.006)
		# Decorative bunting over existing kiosk footprints and high clear walkways.
		for side in [-1,1]:
			Kit.box(a,Vector3(0,4.77,side*12.5),Vector3(43,0.035,0.035),Color("d3ba90"),"fabric",0.009).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for i in range(12):
				var x := -20.0+i*3.6
				Kit.box(a,Vector3(x,4.4,side*12.5),Vector3(0.60,0.68,0.035),[Color("da9785"),Color("8fbeb5"),Color("e0c27f")][i%3],"fabric",0.03).rotation.z = 0.15
		for side in [-1,1]:
			for z in [-16.0,0,16.0]:
				# Trees outside the solid map boundary are backdrop only.
				var p := Vector3(side*(dims.x*0.5+1.4),0,z)
				Kit.cylinder(a,p+Vector3.UP*1.7,0.27,3.4,Color("b0926e"))
				Art.ball(a,p+Vector3.UP*3.6,Vector3(1.6,1.7,1.6),Color("93b58d"),"foam")
