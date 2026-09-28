@tool
extends "res://scripts/phase4/arena.gd"
## Single source of truth for two physical floors, two ramp-backed staircases and hiding ports.
const Art = preload("res://scripts/phase4/art.gd")
const UPPER := 4.0
var graph := AStar3D.new()
var floor_blocks: Array = [[],[]]
var homes: Array[Dictionary] = []
var passages: Array[Dictionary] = []
var furnishings: Node3D
var layout_seed := 0

func _ready() -> void:
	map_id = "toy_manor"
	config = {"id":map_id,"title":"HIDEAWAY MANOR","ko":"숨바꼭질 대저택","size":Vector2(28,26),"hide":28.0,"seek":160.0,"floor":Color("d9b793"),"wall":Color("e7ddcd"),"accent":Color("a7c8ba")}
	dimensions = config.size; active_rect = Rect2(-14,-13,28,26)
	set_meta("map_pack",true)
	_shell_manor()
	# Modest world-only interior fill avoids a dark dollhouse below the upstairs slab.
	# It is an authored fill, not baked GI, and never depends on hiding occupants.
	for azimuth in [-35,145]:
		var fill:=DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-38,azimuth,0)
		fill.light_color=Color("efe5d1"); fill.light_energy=0.23; fill.light_cull_mask=1; fill.shadow_enabled=false; add_child(fill)
	var bounce:=DirectionalLight3D.new(); bounce.rotation_degrees=Vector3(48,40,0)
	bounce.light_color=Color("e5e1d0"); bounce.light_energy=0.19; bounce.light_cull_mask=1; add_child(bounce)
	for floor_index in range(2):
		var y := floor_index*UPPER
		_fixed(Vector3(0,y+1.25,-6),Vector3(0.25,2.5,6),Color("b7d0c4"),floor_index)
		for x in [-4.5,4.5]: _fixed(Vector3(x,y+1.25,3),Vector3(3,2.5,0.25),Color("e6c5bc"),floor_index)
		_island(Vector3(-4,y,-6),floor_index,"sofa" if floor_index==0 else "bed")
		_island(Vector3(4,y,-6),floor_index,"kitchen" if floor_index==0 else "wardrobe")
		_island(Vector3(0,y,7),floor_index,"play" if floor_index==0 else "bath")
		for x in [-6.5,6.5]:
			_zone(Rect2(x-1,-11,2,22),y,0.5,"carpet")
		_zone(Rect2(-3,-1.3,6,2.6),y,1.65,"chime")
		for x in [-6,6]:
			for z in [-9,7]:
				var lamp := OmniLight3D.new(); lamp.position = Vector3(x,y+3.15,z)
				lamp.light_color=Color("ffe7c4"); lamp.light_energy=0.28; lamp.omni_range=10; add_child(lamp)
		_labels(floor_index)
	passages = [
		{"id":"laundry","label":"빨래 슈트 / Laundry chute","from":Vector3(7,4,10),"to":Vector3(7,0,10),"via":Vector3(8.1,2,10),"duration":1.1,"hider_only":false,"noise":18.0},
		{"id":"toy_tunnel","label":"장난감 비밀길 / Toy passage","from":Vector3(-4.5,0,1.2),"to":Vector3(-4.5,0,4.8),"via":Vector3(-4.5,0,3),"duration":0.85,"hider_only":true,"noise":10.0}
	]
	for p in passages:
		for key in ["from","to"]:
			var at: Vector3=p[key]
			Art.box(self,at+Vector3(0,0.035,0),Vector3(1.1,0.05,1.1),Color("e5bf77"),"wood",0.03)
			_sign_manor(p.label,at+Vector3(0,1.9,0),Color("ebd2a2"))
	set_layout(0)

func _solid(at: Vector3, size3: Vector3) -> StaticBody3D:
	return Toy.collider(self,at,size3)
func _box(at: Vector3, size3: Vector3, tint: Color, family: String="wood") -> MeshInstance3D:
	return Art.box(self,at,size3,tint,family,0.06)
func _fixed(at: Vector3, size3: Vector3, tint: Color, level: int) -> void:
	_box(at,size3,tint); _solid(at,size3)
	floor_blocks[level].append(Rect2(Vector2(at.x,at.z)-Vector2(size3.x,size3.z)*0.5,Vector2(size3.x,size3.z)).grow(0.48))

func _shell_manor() -> void:
	_box(Vector3(0,-0.18,0),Vector3(28,0.36,26),Color("d9b793")); _solid(Vector3(0,-0.18,0),Vector3(28,0.36,26))
	for x in [-14,14]:
		_box(Vector3(x,3.8,0),Vector3(0.28,7.6,26),Color("c9d8ce"),"plaster"); _solid(Vector3(x,3.8,0),Vector3(0.28,7.6,26))
	for z in [-13,13]:
		_box(Vector3(0,3.8,z),Vector3(28,7.6,0.28),Color("eadaca"),"plaster"); _solid(Vector3(0,3.8,z),Vector3(28,7.6,0.28))
	# Central upstairs slab plus full-width end landings leave BOTH stairwells open.
	for spec in [[Vector3(0,3.86,0),Vector3(19,0.28,26)],[Vector3(-11.75,3.86,-10.5),Vector3(4.5,0.28,5)],[Vector3(-11.75,3.86,10.5),Vector3(4.5,0.28,5)],[Vector3(11.75,3.86,-10.5),Vector3(4.5,0.28,5)],[Vector3(11.75,3.86,10.5),Vector3(4.5,0.28,5)]]:
		_box(spec[0],spec[1],Color("eee5d2"),"plaster"); _solid(spec[0],spec[1])
	for side in [-1,1]:
		var angle: float = -side*atan(4.0/16.0)
		var at := Vector3(side*11,2-0.10*cos(angle),0)
		var size3 := Vector3(2.8,0.20,sqrt(272.0))
		_box(at,size3,Color("baad91")).rotation.x=angle
		_solid(at,size3).rotation.x=angle
		for i in range(32):
			var z := -7.75+i*0.5; var y: float = 2+side*z*0.25
			_box(Vector3(side*11,y-0.06,z),Vector3(2.72,0.09,0.48),Color("dfc5a0"))
		for x in [side*9.55,side*12.5]:
			_box(Vector3(x,2.64,0),Vector3(0.09,0.12,sqrt(272.0)),Color("9bc4b8")).rotation.x=angle
			for z in range(-8,9,2): _box(Vector3(x,2+side*z*0.25+0.35,z),Vector3(0.08,0.7,0.08),Color("cbd6bf"))
		# Guard upstairs edge; it does not block the lower-floor path.
		_box(Vector3(side*9.45,4.5,0),Vector3(0.10,1,15.8),Color("a3c7bb"))
		_solid(Vector3(side*9.45,4.5,0),Vector3(0.14,1,15.8))
	var roof:=_box(Vector3(0,7.65,0),Vector3(28,0.15,26),Color("eee5d4"),"plaster")
	roof.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; roof.set_meta("cutaway_roof",true)
	for floor_index in range(2):
		var y:=floor_index*4.0
		# Long boards and small wall panels provide scale without filling movement lanes.
		for z in range(-12,13,2): _box(Vector3(0,y+0.012,z),Vector3(18.7,0.012,0.020),Color("cfbda2"))
		for x in [-10,-5,5,10]:
			_box(Vector3(x,y+2.05,-12.82),Vector3(2.6,1.65,0.1),Color("f3e2c8"))
			_box(Vector3(x,y+2.05,-12.74),Vector3(2.36,1.42,0.04),Color("a3cbd7"))
			_box(Vector3(x,y+2.05,-12.69),Vector3(0.09,1.44,0.035),Color("f3e2c8"))
		for z in [-12.75,12.75]: _box(Vector3(0,y+0.18,z),Vector3(27.5,0.27,0.12),Color("c9ad8d"))

func _island(at: Vector3, level: int, kind: String) -> void:
	var tint: Color = {"sofa":Color("d8908d"),"bed":Color("b4afcc"),"kitchen":Color("9dbfb0"),"wardrobe":Color("ceb38c"),"play":Color("a4bcd0"),"bath":Color("c1dcd6")}[kind]
	var height := 1.30 if kind!="wardrobe" else 2.05
	_fixed(at+Vector3.UP*height*0.5,Vector3(3.5,height,2.0),tint,level)
	if kind in ["sofa","bed"]:
		for x in [-1.1,0,1.1]: _box(at+Vector3(x,height+0.12,0),Vector3(1.0,0.25,1.65),tint.lightened(0.13),"fabric")
		_box(at+Vector3(0,height+0.36,-0.7),Vector3(3.4,0.72,0.30),tint,"fabric")
	elif kind=="play":
		for x in [-0.85,0,0.85]: Art.ball(self,at+Vector3(x,1.5,0),Vector3.ONE*0.22,[Color("f1d59b"),Color("acccbc"),Color("e7ab9e")][int((x+0.85)/0.85)])
	else:
		_box(at+Vector3.UP*(height+0.05),Vector3(3.6,0.1,2.1),tint.lightened(0.3),"ceramic")
		for x in [-1.0,0,1.0]: _box(at+Vector3(x,height*0.5,1.03),Vector3(0.83,height*0.7,0.06),tint.lightened(0.08))

func _zone(rect: Rect2, y: float, noise: float, sound: String) -> void:
	surface_zones.append({"rect":rect,"y":y,"noise":noise,"sound":sound,"id":sound+str(y),"loud":noise>1})
	var center:=rect.get_center()
	_box(Vector3(center.x,y+0.015,center.y),Vector3(rect.size.x,0.022,rect.size.y),Color("91bdb2") if noise<1 else Color("e4ca9b"),"fabric" if noise<1 else "wood")
	for z in range(int(rect.position.y)+1,int(rect.end.y),2):
		for x in [rect.position.x+0.1,rect.end.x-0.1]: _box(Vector3(x,y+0.03,z),Vector3(0.08,0.015,0.34),Color("f0e4cc"),"fabric")

func _labels(level: int) -> void:
	var names := ["거실 / LIVING","주방 / KITCHEN","놀이방 / PLAYROOM"] if level==0 else ["침실 / BEDROOM","옷방 / WARDROBE","욕실 / BATH"]
	for i in range(3):
		var point: Vector3 = [Vector3(-4,2.55,-11.8),Vector3(4,2.55,-11.8),Vector3(0,2.65,11.5)][i]
		_sign_manor(names[i],point+Vector3.UP*level*4,Color("b3c9b4"))
		var p:=point+Vector3(0,level*4-0.05,0.12)
		# One simple graphic icon per room keeps orientation readable without tiny text.
		Art.ball(self,p+Vector3(-1.47,0,0.02),Vector3(0.11,0.11,0.025),Color("f1d28e"))
func _sign_manor(text: String, at: Vector3, color: Color) -> void:
	_box(at,Vector3(3.6,0.60,0.12),color)
	var n:=Label3D.new(); n.text=text; n.font_size=40; n.pixel_size=0.006; n.outline_size=0
	var font:=SystemFont.new(); font.font_names=PackedStringArray(["Noto Sans CJK KR","Malgun Gothic","sans-serif"]); n.font=font
	n.modulate=Color("345453"); n.position=at+Vector3(0,0,0.074); add_child(n)

func set_layout(seed_value: int) -> void:
	layout_seed=seed_value
	if is_instance_valid(furnishings): remove_child(furnishings); furnishings.queue_free()
	furnishings=Node3D.new(); furnishings.name="RoundFurniture"; add_child(furnishings)
	homes.clear(); spots.clear(); spot_names.clear(); active_spots.clear()
	for n in markers: if is_instance_valid(n): remove_child(n); n.queue_free()
	markers.clear()
	var r:=RandomNumberGenerator.new(); r.seed=seed_value
	for level in range(2):
		for j in range(6):
			var x: float = -6.5 if j%2==0 else 6.5
			var z: float = [-10.0,-2.0,8.0][j/2]
			x += -0.30 if r.randi()%2==0 else 0.30
			var at:=Vector3(x,level*4.0,z)
			var root:=Node3D.new(); root.position=at; root.name="Hide_%02d"%homes.size(); furnishings.add_child(root)
			var tint: Color = [Color("c4aa8e"),Color("9ebfaf"),Color("b9b3cd")][j/2]
			Art.box(root,Vector3(0,0.65,0),Vector3(1.7,1.3,1.3),tint,"wood",0.1)
			Art.box(root,Vector3(0,1.34,0),Vector3(1.82,0.12,1.4),tint.lightened(0.15),"fabric",0.05)
			for dx in [-0.32,0.32]: Art.ball(root,Vector3(dx,0.70,0.7),Vector3.ONE*0.07,Color("f1d5a4"))
			Toy.collider(root,Vector3(0,0.67,0),Vector3(1.82,1.34,1.4))
			# Distinct toy furniture silhouettes within the same conservative footprint.
			if j/2==0:
				Art.box(root,Vector3(0,1.13,0.43),Vector3(1.5,0.11,0.30),tint.lightened(0.3),"fabric",0.04)
			elif j/2==1:
				for dx in [-0.5,0,0.5]: Art.box(root,Vector3(dx,0.85,0.71),Vector3(0.06,0.7,0.045),tint.darkened(0.06),"fabric",0.02)
			else:
				Art.box(root,Vector3(0,0.85,0.73),Vector3(0.36,0.15,0.05),Color("f4daa4"),"wood",0.04)
			var exits: Array[Vector3]=[at+Vector3(-1.6,0,1.3),at+Vector3(1.6,0,1.3)]
			var index:=homes.size()
			var titles: Array = ["소파 뒤 / Sofa", "주방장 / Cupboard", "커튼 뒤 / Curtain", "장난감 상자 / Toy chest", "놀이 수납장 / Play chest", "선물 상자 / Parcel"] if level==0 else ["침대 아래 / Bed", "낮은 옷장 / Wardrobe", "커튼 뒤 / Curtain", "수건장 / Towels", "빨래 바구니 / Laundry", "수납 상자 / Trunk"]
			if j==0:
				Art.box(root,Vector3(0,1.44,0),Vector3(1.65,0.2,1.25),Color("eed3bb"),"fabric",0.1)
				Art.box(root,Vector3(-0.4,1.6,-0.1),Vector3(0.52,0.22,0.8),Color("a6c7c0"),"fabric",0.1)
			elif j==2:
				for dx in [-0.64,-0.32,0,0.32,0.64]: Art.box(root,Vector3(dx,1.2,0.68),Vector3(0.23,2.0,0.08),Color("ceb1bd"),"fabric",0.045)
			homes.append({"id":index,"at":at,"entry":at+Vector3(0,0,1.45),"exits":exits,"peek":at+Vector3(0,1.04,1.10),"zone":zone_name(at),"fake":false,"root":root,"title":titles[j]})
			spots.append(at+Vector3(0,0,1.45)); spot_names.append(titles[j]); active_spots.append(index)
			var marker:=Label3D.new(); marker.text="E"; marker.font_size=40; marker.pixel_size=0.006; marker.position=spots[-1]+Vector3.UP; marker.visible=false; marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(marker); markers.append(marker)
	_build_graph()

func _blocked(at: Vector3, level: int) -> bool:
	var p:=Vector2(at.x,at.z)
	for rect in floor_blocks[level]: if rect.has_point(p): return true
	for h in homes:
		if absf(h.at.y-at.y)<1 and Rect2(Vector2(h.at.x-0.91,h.at.z-0.7),Vector2(1.82,1.4)).grow(0.48).has_point(p): return true
	return false
func _build_graph() -> void:
	graph.clear(); var ids: Dictionary={}
	for level in range(2):
		for x in range(-8,9):
			for z in range(-11,12):
				var p:=Vector3(x,level*4,z)
				if _blocked(p,level): continue
				var id:=graph.get_available_point_id(); graph.add_point(id,p); ids[Vector3i(x,level,z)]=id
	for key in ids:
		for d in [Vector3i(1,0,0),Vector3i(0,0,1)]:
			if ids.has(key+d): graph.connect_points(ids[key],ids[key+d])
	for side in [-1,1]:
		var chain: Array[int]=[]
		for z in range(-9,10):
			var y:=clampf(2+side*z*0.25,0,4)
			var id:=graph.get_available_point_id(); graph.add_point(id,Vector3(side*11,y,z)); chain.append(id)
			if chain.size()>1: graph.connect_points(chain[-2],id)
		for endpoint in [chain[0],chain[-1]]:
			var p: Vector3=graph.get_point_position(endpoint)
			var nearest:=-1; var best:=INF
			for key in ids:
				var q: Vector3=graph.get_point_position(ids[key])
				if absf(q.y-p.y)>0.1: continue
				var distance:=q.distance_squared_to(p)
				if distance<best: best=distance; nearest=ids[key]
			if nearest>=0: graph.connect_points(endpoint,nearest)
	# Keep the inherited public 2D grid available for historical interfaces, not multi-floor bot movement.
	obstacles.clear()
	for rect in floor_blocks[0]: obstacles.append(rect)
	for h in homes:
		if h.at.y<1: obstacles.append(Rect2(Vector2(h.at.x-0.91,h.at.z-0.7),Vector2(1.82,1.4)).grow(0.48))
	_build_navigation()

func route3(from: Vector3,to: Vector3) -> PackedVector3Array:
	return graph.get_point_path(graph.get_closest_point(from),graph.get_closest_point(to))
func route_available(from: Vector3,to: Vector3) -> bool:
	return not route3(from,to).is_empty()
func surface_profile(at: Vector3) -> Dictionary:
	for zone in surface_zones:
		if absf(at.y-zone.y)<0.7 and zone.rect.has_point(Vector2(at.x,at.z)): return {"noise":zone.noise,"sound":zone.sound,"id":zone.id}
	return {"noise":1.0,"sound":"step","id":"wood"}
func inside(at: Vector3) -> bool:
	return absf(at.x)<13.5 and absf(at.z)<12.5 and at.y>-1 and at.y<8
func nearest_spot(at: Vector3,radius: float=1.7) -> int:
	var found:=-1
	for i in range(spots.size()):
		var d:=at.distance_to(spots[i]); if d<radius: found=i; radius=d
	return found
func zone_name(at: Vector3) -> String:
	return ("2F " if at.y>2.5 else "1F ")+("놀이/욕실 · SOUTH" if at.z>3 else ("거실/침실 · WEST" if at.x<0 else "주방/옷방 · EAST"))
