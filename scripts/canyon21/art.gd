extends RefCounted
## Solid toy markers and eight reusable non-colliding wind toys; never an occupancy overlay.
const Art=preload("res://scripts/phase4/art.gd")
static var wind_samples: Array=[]
static func wind_audio() -> Array:
	if not wind_samples.is_empty():return wind_samples
	for variant in range(3):
		var rng:=RandomNumberGenerator.new();rng.seed=21300+variant
		var data:=PackedByteArray();data.resize(15436)
		var low:=0.0
		for i in range(7718):
			var t:=float(i)/7717;low=lerpf(low,rng.randf_range(-1,1),0.07)
			data.encode_s16(i*2,int(low*sin(t*PI)*10000))
		var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;wav.data=data
		wind_samples.append(wav)
	return wind_samples
static func quiet_mesh(n: MeshInstance3D) -> void:
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
static func build(arena,ends: Array[Vector3],centers: Array[Vector3]) -> Node3D:
	var root: Node3D=arena.get_node_or_null("Canyon21Art")
	if root!=null:return root
	root=Node3D.new();root.name="Canyon21Art";arena.add_child(root)
	# Low paint/wood marks do not change colliders or hide the exposed rider.
	for i in range(ends.size()):
		var p:=ends[i]
		quiet_mesh(Art.box(root,p+Vector3.UP*0.035,Vector3(1.1,0.018,0.8),Color("deb672"),"wood",0.008))
		var arrow:=1.0 if i==0 else -1.0
		for x in [-1,1]:
			var n:=Art.box(root,p+Vector3(x*0.13,0.057,0),Vector3(0.055,0.015,0.36),Color("fff0bf"),"foam",0.004)
			n.rotation.y=x*arrow*0.55;quiet_mesh(n)
		var label:=Label3D.new();label.name="LaneLabel%d"%i
		label.text="1.35s\nLOUD  /  OPEN";label.position=p+Vector3(1.0,0.8,0)
		label.font_size=30;label.pixel_size=0.0035;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false
		root.add_child(label)
	for i in range(7):
		var p:=ends[0].lerp(ends[1],float(i+1)/8)
		quiet_mesh(Art.box(root,p+Vector3.UP*0.03,Vector3(0.18,0.009,0.22),Color("cf9e62"),"wood",0.003))
	for i in range(centers.size()):
		var group:=Node3D.new();group.name="WindPad%d"%i;group.position=centers[i];root.add_child(group)
		quiet_mesh(Art.box(group,Vector3(0,0.027,0),Vector3(2.4,0.01,2.4),Color("c79d74"),"wood",0.004))
		for j in range(4):
			var toy:=Node3D.new();toy.name="WindToy%d"%j;group.add_child(toy)
			toy.position=Vector3(-0.65+0.42*j,0.13,-0.55+0.36*(j%3));toy.set_meta("rest",toy.position)
			quiet_mesh(Art.ball(toy,Vector3.ZERO,Vector3(0.14,0.14,0.14),Color("b88456"),"wood"))
			quiet_mesh(Art.box(toy,Vector3(0,0.01,0),Vector3(0.045,0.23,0.19),Color("e3c58a"),"wood",0.017))
		var flag:=Art.box(group,Vector3(-1,0.82,0),Vector3(0.45,0.20,0.04),Color("9cb8a3"),"cloth",0.02)
		flag.name="WindFlag";quiet_mesh(flag)
		quiet_mesh(Art.box(group,Vector3(-1.23,0.5,0),Vector3(0.055,1.0,0.055),Color("845c45"),"wood",0.014))
	return root
