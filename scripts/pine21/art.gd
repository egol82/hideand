extends RefCounted
## Static public visuals and a small cached rustle. No occupancy, random gameplay or physics reads.
const Art=preload("res://scripts/phase4/art.gd")
static var sounds: Array=[]
static func rustles() -> Array:
	if not sounds.is_empty(): return sounds
	for variant in range(3):
		var rng:=RandomNumberGenerator.new();rng.seed=21071+variant
		var bytes:=PackedByteArray();bytes.resize(7938) # 180ms mono 16-bit, 22.05kHz.
		var low:=0.0
		for i in range(3969):
			var t:=float(i)/3968.0
			var noise:=rng.randf_range(-1,1);low=lerpf(low,noise,0.18)
			var env:=sin(t*PI)*exp(-t*4.0)*(0.65+0.35*pow(sin(t*36+variant),2))
			var sample:=int((noise-low*0.7)*env*12000)
			bytes.encode_s16(i*2,sample)
		var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;wav.data=bytes
		sounds.append(wav)
	return sounds
static func leaf(parent: Node3D,p: Vector3,color: Color,size_value: float=0.18) -> void:
	var n:=Art.ball(parent,p,Vector3(size_value,0.018,size_value*0.5),color,"foam")
	n.rotation.y=p.x*9+p.z*3
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func build(arena,rects: Array,bush_ids: Array) -> void:
	if arena.has_node("Pine21Art"): return
	var root:=Node3D.new();root.name="Pine21Art";arena.add_child(root)
	for rect in rects:
		var c: Vector2=rect.get_center()
		Art.box(root,Vector3(c.x,0.018,c.y),Vector3(rect.size.x,0.025,rect.size.y),Color("a78550"),"fabric",0.008)
		for i in range(24):
			var p:=Vector3(rect.position.x+0.2+fmod(i*1.317,rect.size.x-0.4),0.046,rect.position.y+0.15+fmod(i*0.713,rect.size.y-0.3))
			leaf(root,p,Color("d9b568") if i%2==0 else Color("bd885b"))
	for id in bush_ids:
		var home: Node3D=arena.get_node("NatureHide_%02d"%id)
		# Same closed cover envelope and original HidePhysics; not a new unreachable interior.
		for child in home.get_children():
			if child is MeshInstance3D: child.visible=false
		var hedge:=Node3D.new();hedge.name="ShortThicket21";home.add_child(hedge)
		Art.box(hedge,Vector3(0,0.8,0),Vector3(1.7,1.6,1.5),Color("557c4d"),"foam",0.17)
		for i in range(9):
			var p:=Vector3(-0.52+(i%3)*0.52,1.56+(i%2)*0.06,-0.45+(i/3)*0.40)
			Art.ball(hedge,p,Vector3(0.29,0.20,0.28),Color("80a668"),"foam")
		Art.box(hedge,Vector3(0,0.94,0.77),Vector3(0.47,0.3,0.04),Color("dfc38b"),"wood",0.04)
		var sign:=Label3D.new();sign.text="4s";sign.position=Vector3(0,0.94,0.8);sign.font_size=30;sign.pixel_size=0.005;sign.modulate=Color("243a29")
		hedge.add_child(sign)
