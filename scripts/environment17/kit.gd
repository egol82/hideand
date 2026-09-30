extends RefCounted
## Curated scenery recipes with material-batched output. No collider, light, text or hidden-state access.
const Art=preload("res://scripts/phase4/art.gd")
const G=preload("res://scripts/environment17/geometry.gd")
const CREAM=Color("eedcc0")
const BRASS=Color("bb9060")
const WOOD=Color("876d51")
const INK=Color("405c53")
static var recipes: Dictionary={}
static var builds:=0
var pieces: Array[Dictionary]=[]

func add(mesh: Mesh,at: Vector3,color: Color,kind: String="wood",angles: Vector3=Vector3.ZERO) -> void:
	pieces.append({"mesh":mesh,"transform":Transform3D(Basis.from_euler(angles),at),"color":color,"kind":kind})
func box(at: Vector3,size3: Vector3,color: Color,kind: String="wood",radius: float=0.045,rot: Vector3=Vector3.ZERO) -> void:
	add(Art.rounded(size3,radius),at,color,kind,rot)
func pad(at: Vector3,size3: Vector3,color: Color,rot: Vector3=Vector3.ZERO,tuft: float=0.0) -> void:
	add(G.pillow(size3,tuft),at,color,"fabric",rot)
	var path:=G.piping(size3.x-0.01,size3.z-0.01,0.0)
	add(G.cord(path,0.008,true),at,color.lightened(0.23),"fabric",rot)
func handle(at: Vector3,width: float=0.24) -> void:
	add(G.cord(PackedVector3Array([Vector3(-width/2,0,0),Vector3(-width/2,0,0.045),Vector3(width/2,0,0.045),Vector3(width/2,0,0)]),0.019),at,BRASS)
func book(at: Vector3,size3: Vector3,color: Color,angle: float=0.0) -> void:
	box(at,size3,color,"fabric",0.022,Vector3(0,angle,0))
	box(at+Vector3(0,0.003,size3.z/2+0.001),Vector3(size3.x*0.87,size3.y*0.53,0.014),CREAM,"plaster",0.007,Vector3(0,angle,0))
func seam(at: Vector3,length_value: float,color: Color,vertical: bool=false) -> void:
	var direction:=Vector3.UP if vertical else Vector3.RIGHT
	add(G.cord(PackedVector3Array([-direction*length_value/2,direction*length_value/2]),0.007),at,color,"fabric")
func round_part(at: Vector3,profile: PackedVector2Array,color: Color,kind: String="ceramic",flutes: float=0) -> void:
	add(G.lathe(profile,flutes),at,color,kind)

func sofa(bed: bool=false) -> void:
	var rose:=Color("bc7772") if not bed else Color("a39bb6")
	var cloth:=Color("d7a09a") if not bed else Color("c3bad4")
	# A tailored upholstery shell leaves the original baked solid core and its cover envelope intact.
	box(Vector3(0,0.76,1.004),Vector3(3.48,0.98,0.09),rose,"fabric",0.04)
	box(Vector3(0,0.22,1.013),Vector3(3.48,0.14,0.10),WOOD)
	for x in [-1.61,1.61]:
		box(Vector3(x,0.17,0.94),Vector3(0.21,0.32,0.20),WOOD,"wood",0.04,Vector3(0,0,x*-0.02))
		box(Vector3(x,1.44,0.03),Vector3(0.29,0.52,1.94),rose,"fabric",0.13)
		seam(Vector3(x,1.47,1.016),0.27,CREAM,true)
	for x in [-1.08,0,1.08]:
		pad(Vector3(x,1.436,0.02),Vector3(1.04,0.29,1.65),cloth,Vector3.ZERO,0.025)
		# Existing back block remains as a light-occluding core below this curved face.
		pad(Vector3(x,1.67,-0.66),Vector3(1.08,0.35,0.74),rose,Vector3(PI/2-0.08,0,0),0.025)
		seam(Vector3(x,0.71,1.057),0.73,rose.lightened(0.22))
	# Small familiar objects add scale without putting any loose prop into a walking lane.
	pad(Vector3(-0.83,1.79,0.16),Vector3(0.66,0.26,0.53),Color("729d91"),Vector3(-0.30,0,0.19),0.036)
	pad(Vector3(0.90,1.78,0.19),Vector3(0.58,0.22,0.50),CREAM,Vector3(-0.22,0,-0.12),0.02)
	if bed:
		box(Vector3(0,1.608,0.44),Vector3(1.00,0.08,0.75),Color("8ba6a5"),"fabric",0.025)
		for x in [-0.32,0,0.32]:seam(Vector3(x,1.652,0.46),0.60,CREAM)
	else:
		book(Vector3(0.13,1.634,0.48),Vector3(0.60,0.08,0.40),Color("637d6d"),-0.10)

func island(kind: String) -> void:
	var color:=Color("86a795")
	var height:=1.3
	if kind=="wardrobe":color=Color("b59a70");height=2.05
	if kind=="play":color=Color("85a6b8")
	if kind=="bath":color=Color("a2c1bd")
	for x in [-1.15,0,1.15]:
		box(Vector3(x,height*0.52,1.047),Vector3(1.02,height*0.78,0.056),color,"wood",0.045)
		box(Vector3(x,height*0.52,1.081),Vector3(0.85,height*0.62,0.027),color.lightened(0.10),"wood",0.032)
		handle(Vector3(x,height*0.73,1.102))
	box(Vector3(0,0.13,1.042),Vector3(3.5,0.13,0.075),WOOD)
	if kind in ["kitchen","bath"]:
		round_part(Vector3(0,height+0.112,0.03),PackedVector2Array([Vector2(0.001,0),Vector2(0.43,0),Vector2(0.50,0.065),Vector2(0.44,0.085),Vector2(0.001,0.028)]),CREAM)
		add(G.cord(PackedVector3Array([Vector3(0,0,0),Vector3(0,0.36,0),Vector3(0,0.43,0.07),Vector3(0,0.42,0.27)]),0.035),Vector3(0,height+0.10,-0.51),BRASS)
		for x in [0.94,1.18]:
			round_part(Vector3(x,height+0.10,0.13),PackedVector2Array([Vector2(0.001,0),Vector2(0.09,0),Vector2(0.105,0.20),Vector2(0.087,0.20),Vector2(0.075,0.02)]),Color("d6b791"))
		if kind=="bath":
			for i in range(3):pad(Vector3(-1.0,height+0.16+i*0.085,0),Vector3(0.60,0.07,0.57),CREAM)
		else:
			book(Vector3(-1.08,height+0.155,0),Vector3(0.66,0.08,0.52),Color("d09b73"))
	elif kind=="play":
		for i in range(3):
			box(Vector3(-1.1+i*0.30,1.47,0.43),Vector3(0.24,0.25,0.24),[Color("b57e6a"),CREAM,Color("7fae99")][i],"wood",0.04,Vector3(0,i*0.15,0))
		book(Vector3(0.92,1.38,-0.44),Vector3(0.76,0.13,0.62),Color("b89278"))
	else:
		# Decorative rail seams and pulls suggest crafted joinery, not an interactive extra door.
		for x in [-1.63,1.63]:box(Vector3(x,1.04,1.076),Vector3(0.06,1.76,0.033),CREAM)

func cupboard(style: int,upstairs: bool=false) -> void:
	var color: Color=[Color("bea284"),Color("8daea0"),Color("a7a3bc")][style/2]
	# Fixed lid/base envelope retained, even for the curtain variant, so cover remains opaque.
	box(Vector3(0,0.67,0),Vector3(1.72,1.32,1.32),color,"wood",0.095)
	box(Vector3(0,1.34,0),Vector3(1.81,0.12,1.40),color.lightened(0.2),"fabric",0.055)
	box(Vector3(0,0.12,0.635),Vector3(1.7,0.11,0.13),WOOD)
	for x in [-0.79,0.79]:box(Vector3(x,0.70,0.664),Vector3(0.08,1.06,0.04),color.lightened(0.23))
	if style==0:
		pad(Vector3(0,1.47,0),Vector3(1.64,0.22,1.24),CREAM)
		pad(Vector3(-0.40,1.665,-0.10),Vector3(0.53,0.25,0.80),Color("90b8ac"),Vector3(0,0,0.045),0.022)
		for x in [-0.42,0.42]:
			box(Vector3(x,0.72,0.691),Vector3(0.70,0.79,0.035),color.lightened(0.05));handle(Vector3(x,0.83,0.72))
	elif style==2:
		add(G.drape(1.55,2.0),Vector3(0,2.20,0.675),Color("c6a6b3"),"fabric")
		box(Vector3(0,2.22,0.67),Vector3(1.70,0.08,0.12),WOOD)
		for x in [-0.47,0.47]:box(Vector3(x,0.93,0.742),Vector3(0.18,0.08,0.02),CREAM,"fabric",0.018)
	else:
		for x in [-0.40,0.40]:
			box(Vector3(x,0.72,0.687),Vector3(0.68,0.88,0.052),color.lightened(0.12),"wood",0.025)
			handle(Vector3(x,0.89,0.72),0.18)
		if style in [3,4,5]:
			box(Vector3(0,0.52,0.726),Vector3(0.36,0.12,0.02),CREAM)
			# Original toy pictogram made from strokes, no fonts or copied franchise icons.
			for x in [-0.075,0.075]:seam(Vector3(x,0.52,0.744),0.065,INK,true)
	# No item is added to the top in the RoundParcel region, preserving the old shuffle cue.

func window() -> void:
	# Sits against the old opaque pane; not new curtain cover in a movement lane.
	box(Vector3(0,-0.87,0.075),Vector3(2.82,0.16,0.30),CREAM)
	box(Vector3(0,0.88,0.01),Vector3(2.87,0.08,0.10),WOOD)
	for x in [-1.16,1.16]:
		add(G.drape(0.36,1.62),Vector3(x,0.81,0.03),Color("acbdb1"),"fabric")
		box(Vector3(x,-0.27,0.12),Vector3(0.39,0.055,0.025),BRASS,"fabric",0.01)
	box(Vector3(0,0,0.06),Vector3(2.4,0.05,0.075),CREAM)

func lamp() -> void:
	# Open, fluted shade matches an existing light; adds no light and cannot shadow-block its source.
	round_part(Vector3.ZERO,PackedVector2Array([Vector2(0.30,0.02),Vector2(0.35,0.02),Vector2(0.22,0.38),Vector2(0.19,0.38),Vector2(0.30,0.02)]),CREAM,"fabric",0.027)
	box(Vector3(0,0.44,0),Vector3(0.028,0.22,0.028),WOOD)
	round_part(Vector3(0,0.55,0),PackedVector2Array([Vector2(0.001,0),Vector2(0.13,0),Vector2(0.13,0.035),Vector2(0.001,0.035)]),BRASS)

func wall_art() -> void:
	box(Vector3.ZERO,Vector3(1.46,1.04,0.095),WOOD)
	box(Vector3(0,0,0.056),Vector3(1.31,0.88,0.026),CREAM,"plaster")
	box(Vector3(0,0,0.075),Vector3(1.17,0.74,0.02),Color("87aaa5"),"plaster")
	# Original relief landscape, intentionally not a texture copied from another game.
	box(Vector3(-0.17,-0.18,0.094),Vector3(0.66,0.44,0.022),Color("547569"),"wood",0.06,Vector3(0,0,0.32))
	box(Vector3(0.29,-0.17,0.11),Vector3(0.52,0.42,0.02),Color("aec0a5"),"wood",0.06,Vector3(0,0,-0.27))
	add(G.lathe(PackedVector2Array([Vector2(0,0),Vector2(0.10,0),Vector2(0.10,0.024),Vector2(0,0.024)])),Vector3(0.30,0.17,0.101),Color("e2be77"),"wood",Vector3(PI/2,0,0))

func architecture() -> void:
	# Modest relief only on existing opaque walls and railings, leaving all aisle widths intact.
	for level in [0,1]:
		var y: float=level*4.0
		for z in [-12.79,12.79]:
			for x in [-11.0,-8.0,-4.0,0.0,4.0,8.0,11.0]:
				box(Vector3(x,y+0.61,z),Vector3(2.1,0.69,0.045),Color("c6b799"),"wood",0.027)
				box(Vector3(x,y+0.61,z+(-0.033 if z>0 else 0.033)),Vector3(1.97,0.56,0.025),Color("dfd0b7"),"plaster",0.02)
		for side in ([-1,1] if level==0 else []):
			for z in range(-8,9,4):
				var at:=Vector3(side*12.5,2+side*z*0.25+0.73,z)
				box(at,Vector3(0.12,0.08,0.12),CREAM,"wood",0.035)
		# A narrow frame line on the room-divider face adds an intentional architectural scale.
		for x in [-0.155,0.155]:
			box(Vector3(x,y+0.20,-6),Vector3(0.06,0.23,5.98),Color("bfa685"))

func bake_recipe() -> Array[Dictionary]:
	var buckets: Dictionary={}
	for part in pieces:
		var key: String=part.kind+part.color.to_html()
		if not buckets.has(key):
			var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			buckets[key]={"tool":tool,"color":part.color,"kind":part.kind}
		var item: Dictionary=buckets[key]
		item.tool.append_from(part.mesh,0,part.transform)
	var out: Array[Dictionary]=[]
	for key in buckets:
		var b: Dictionary=buckets[key]
		b.tool.index()
		out.append({"mesh":b.tool.commit(),"color":b.color,"kind":b.kind,"key":key})
	return out

static func make(kind: String) -> Node3D:
	if not recipes.has(kind):
		var kit=load("res://scripts/environment17/kit.gd").new()
		if kind=="sofa":kit.sofa()
		elif kind=="bed":kit.sofa(true)
		elif kind in ["kitchen","wardrobe","play","bath"]:kit.island(kind)
		elif kind.begins_with("home_"):kit.cupboard(int(kind.trim_prefix("home_")))
		elif kind=="window":kit.window()
		elif kind=="lamp":kit.lamp()
		elif kind=="wall_art":kit.wall_art()
		elif kind=="architecture":kit.architecture()
		else:push_error("Unknown scenery recipe: "+kind);return Node3D.new()
		recipes[kind]=kit.bake_recipe();builds+=1
	var root:=Node3D.new();root.name=kind.to_pascal_case()+"17";root.set_meta("recipe17",kind)
	for part in recipes[kind]:
		var m:=MeshInstance3D.new();m.name=part.key;m.mesh=part.mesh;m.material_override=Art.material(part.color,part.kind)
		m.gi_mode=GeometryInstance3D.GI_MODE_DYNAMIC;m.layers=1;m.set_meta("cosmetic_only",true)
		# Contact/large shadows still come from the old closed core; fine shells do not add needle shadows.
		m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind.begins_with("home_") else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	return root
