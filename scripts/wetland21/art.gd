extends RefCounted
## Phase22 checkpoint: authored wetland dressing with bounded clue visuals and no gameplay collision changes.
const Art=preload("res://scripts/phase4/art.gd")
static var splashes: Array=[]
static var ripple_mesh: TorusMesh

static func audio() -> Array:
	if not splashes.is_empty():return splashes
	for variant in range(3):
		var bytes:=PackedByteArray();bytes.resize(8820)
		var rng:=RandomNumberGenerator.new();rng.seed=21200+variant
		var low:=0.0;var phase:=0.0
		for i in range(4410):
			var t:=float(i)/4409.0
			var noise:=rng.randf_range(-1,1);low=lerpf(low,noise,0.16)
			phase+=TAU*(620.0-380*t+variant*29)/22050
			var env:=sin(t*PI)*exp(-t*4.5)
			bytes.encode_s16(i*2,int((low*0.8+sin(phase)*0.18)*env*14000))
		var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;wav.data=bytes
		splashes.append(wav)
	return splashes

static func no_shadow(n: MeshInstance3D) -> void:
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.gi_mode=GeometryInstance3D.GI_MODE_DISABLED

static func wet_print(parent: Node3D) -> Node3D:
	var root:=Node3D.new();root.name="WaterPrint21";parent.add_child(root);root.visible=false
	if ripple_mesh==null:
		ripple_mesh=TorusMesh.new();ripple_mesh.inner_radius=0.14;ripple_mesh.outer_radius=0.165;ripple_mesh.rings=20;ripple_mesh.ring_segments=6
	for side in [-1,1]:
		var n:=MeshInstance3D.new();n.mesh=ripple_mesh;n.material_override=Art.material(Color("bee5df"),"foam")
		n.position=Vector3(side*0.15,0.074,side*0.055);n.scale=Vector3(0.8,0.4,1.2);root.add_child(n);no_shadow(n)
		var drop:=Art.ball(root,Vector3(side*0.15,0.073,side*0.055),Vector3(0.09,0.013,0.15),Color("428d96"),"ceramic");no_shadow(drop)
	return root

static func reed_print(parent: Node3D) -> Node3D:
	var root:=Node3D.new();root.name="ReedPrint21";parent.add_child(root);root.visible=false
	for i in range(3):
		var n:=Art.box(root,Vector3(-0.13+0.13*i,0.041,0.02*(i%2)),Vector3(0.043,0.016,0.34),Color("d9c791"),"wood",0.006)
		n.rotation.y=-0.45+0.35*i;no_shadow(n)
	return root

static func _reed_stem(parent: Node3D,pos: Vector3,height: float,yaw: float,pitch: float,thickness: float,color: Color,leaf_color: Color,has_head: bool) -> void:
	var mesh:=CylinderMesh.new();mesh.top_radius=thickness*0.45;mesh.bottom_radius=thickness;mesh.height=height;mesh.radial_segments=8
	var stem:=MeshInstance3D.new();stem.mesh=mesh;stem.material_override=Art.material(color,"wood")
	stem.position=pos+Vector3(0,height*0.5,0);stem.rotation=Vector3(pitch,yaw,0);parent.add_child(stem)
	for side in [-1,1]:
		var leaf:=Art.box(parent,pos+Vector3(side*0.05,height*0.56,0),Vector3(0.03,0.01,height*0.46),leaf_color,"foam",0.015)
		leaf.rotation=Vector3(deg_to_rad(-28.0+8.0*side),yaw,pitch+side*0.65)
	if has_head:
		var head:=Art.ball(parent,pos+Vector3(0,height+0.05,0),Vector3(0.08,0.18,0.08),Color("af8f60"),"foam")
		head.rotation.y=yaw

static func _reed_cluster(parent: Node3D,rng: RandomNumberGenerator,extent: Vector2,count: int,height_scale: float=1.0,cattails: float=0.35) -> void:
	for i in range(count):
		var angle:=rng.randf()*TAU
		var spread:=pow(rng.randf(),0.72)
		var pos:=Vector3(cos(angle)*extent.x*spread,0,sin(angle)*extent.y*spread)
		var height:=height_scale*rng.randf_range(0.55,1.16)
		var yaw:=rng.randf()*TAU
		var pitch:=rng.randf_range(-0.16,0.16)
		_reed_stem(parent,pos,height,yaw,pitch,rng.randf_range(0.018,0.026),Color("7f9361"),Color("a9bc76"),rng.randf()<cattails)

static func _water_patch(parent: Node3D,r: Rect2,index: int) -> void:
	var root:=Node3D.new();root.name="WaterArea%02d"%index;root.position=Vector3(r.get_center().x,0,r.get_center().y);parent.add_child(root)
	var size:=r.size
	var mud:=Art.box(root,Vector3(0,0.01,0),Vector3(size.x+0.85,0.04,size.y+0.9),Color("6c7d53"),"fabric",0.25)
	mud.material_override=Art.material(Color("7a8861"),"fabric")
	var damp:=Art.box(root,Vector3(0,0.028,0),Vector3(size.x+0.35,0.025,size.y+0.42),Color("89956e"),"fabric",0.22)
	damp.material_override=Art.material(Color("8d9a70"),"fabric")
	var water:=Art.box(root,Vector3(0,0.04,0),Vector3(size.x-0.28,0.018,size.y-0.16),Color("6ba9ad"),"ceramic",0.18);no_shadow(water)
	for side in [-1,1]:
		for step in range(7):
			var t:=float(step)/6.0
			var pos:=Vector3(lerpf(-size.x*0.42,size.x*0.42,t),0.05,side*(size.y*0.5-0.03+0.06*sin(2.4*t+index)))
			var bank:=Art.ball(root,pos,Vector3(0.30,0.06,0.18),Color("74835e"),"fabric")
			if step%2==0:no_shadow(bank)
	for side in [-1,1]:
		for step in range(5):
			var t:=float(step)/4.0
			var pos:=Vector3(side*(size.x*0.5-0.03+0.05*cos(2.7*t+index)),0.05,lerpf(-size.y*0.32,size.y*0.32,t))
			var edge:=Art.ball(root,pos,Vector3(0.18,0.05,0.24),Color("70815d"),"fabric")
			no_shadow(edge)
	var rng:=RandomNumberGenerator.new();rng.seed=4400+index
	for i in range(8):
		var pos:=Vector3(rng.randf_range(-size.x*0.42,size.x*0.42),0.055,rng.randf_range(-size.y*0.26,size.y*0.26))
		var lily:=Art.ball(root,pos,Vector3(0.11,0.012,0.13),Color("9dbf7b"),"foam")
		lily.rotation.y=rng.randf()*TAU;no_shadow(lily)
	for side in [-1,1]:
		var clump:=Node3D.new();clump.position=Vector3(side*(size.x*0.5+0.08),0,lerpf(-size.y*0.18,size.y*0.18,0.35+0.3*side));root.add_child(clump)
		_reed_cluster(clump,rng,Vector2(0.18,0.16),4,0.58,0.0)

static func _reactive_tuft(parent: Node3D,index: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=7800+index
	Art.box(parent,Vector3(0,0.05,0),Vector3(0.78,0.08,0.72),Color("73835f"),"fabric",0.14)
	Art.box(parent,Vector3(0,0.08,0),Vector3(0.54,0.05,0.46),Color("84906b"),"fabric",0.10)
	for i in range(4):
		var rootlog:=Art.box(parent,Vector3(-0.18+0.12*i,0.10,-0.12+0.06*(i%2)),Vector3(0.24,0.08,0.10),Color("8c6b49"),"wood",0.035)
		rootlog.rotation.y=-0.45+0.28*i
	_reed_cluster(parent,rng,Vector2(0.40,0.64),13,1.0,0.42)
	for i in range(6):
		var pos:=Vector3(rng.randf_range(-0.36,0.36),0.18+rng.randf_range(0.0,0.18),rng.randf_range(-0.70,0.70))
		var sprig:=Art.ball(parent,pos,Vector3(0.08,0.12,0.08),Color("98b672"),"foam")
		sprig.rotation.y=rng.randf()*TAU

static func build(arena,water: Array,brush: Array) -> Array[Node3D]:
	var root: Node3D=arena.get_node_or_null("Wetland21Art")
	if root==null:
		root=Node3D.new();root.name="Wetland21Art";arena.add_child(root)
		for i in range(water.size()):_water_patch(root,water[i],i)
		for i in range(brush.size()):
			var r: Rect2=brush[i];var c: Vector2=r.get_center()
			var tuft:=Node3D.new();tuft.name="ReedTuft%02d"%i;tuft.position=Vector3(c.x,0,c.y);root.add_child(tuft)
			_reactive_tuft(tuft,i)
	var result: Array[Node3D]=[]
	for i in range(brush.size()):result.append(root.get_node("ReedTuft%02d"%i))
	return result
