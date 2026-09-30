extends RefCounted
## Bounded, depth-tested toy ripples and reed tufts. No occupancy or collision input.
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

static func build(arena,water: Array,brush: Array) -> Array[Node3D]:
	var root: Node3D=arena.get_node_or_null("Wetland21Art")
	if root==null:
		root=Node3D.new();root.name="Wetland21Art";arena.add_child(root)
		for r in water:
			var c: Vector2=r.get_center()
			var n:=Art.box(root,Vector3(c.x,0.044,c.y),Vector3(r.size.x,0.008,r.size.y),Color("79b4b8"),"ceramic",0.003);no_shadow(n)
			# Surface marks indicate the shallow, passable wet crossing before a player enters.
			for i in range(7):
				var p:=Vector3(r.position.x+0.35+float(i)*(r.size.x-0.7)/6,0.051,c.y+0.25*sin(i*2))
				no_shadow(Art.box(root,p,Vector3(0.24,0.006,0.023),Color("bbdcd4"),"foam",0.003))
		for i in range(brush.size()):
			var r: Rect2=brush[i];var c: Vector2=r.get_center()
			var tuft:=Node3D.new();tuft.name="ReedTuft%02d"%i;tuft.position=Vector3(c.x,0,c.y);root.add_child(tuft)
			for j in range(7):
				var x: float=-0.43+0.14*j;var z: float=-0.8+fmod(j*0.53,1.6);var h: float=0.48+0.08*(j%3)
				no_shadow(Art.box(tuft,Vector3(x,h*0.5,z),Vector3(0.055,h,0.055),Color("a4b575"),"wood",0.02))
				no_shadow(Art.ball(tuft,Vector3(x,h+0.03,z),Vector3(0.09,0.12,0.07),Color("b59868"),"foam"))
	var result: Array[Node3D]=[]
	for i in range(brush.size()):result.append(root.get_node("ReedTuft%02d"%i))
	return result
