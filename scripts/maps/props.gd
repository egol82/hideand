@tool
extends RefCounted
## A bounded, original toy scenery kit. Solids never exceed the footprint declared by Plans.
const Art = preload("res://scripts/phase4/art.gd")
const Studio = preload("res://scripts/graphics/studio.gd")
const INK := Color("304951")
const CREAM := Color("f3e4c9")
static var cylinders: Dictionary = {}

static func box(p: Node3D, at: Vector3, size3: Vector3, color: Color, material: String = "wood", bevel: float = 0.08) -> MeshInstance3D:
	return Art.box(p,at,size3,color,material,bevel)

static func cylinder(p: Node3D, at: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	if top < 0: top = radius
	var key := "%s/%s/%s" % [radius,height,top]
	if not cylinders.has(key):
		var m := CylinderMesh.new()
		m.bottom_radius = radius; m.top_radius = top; m.height = height; m.radial_segments = 24
		cylinders[key] = m
	var n := MeshInstance3D.new(); n.mesh = cylinders[key]; n.position = at
	n.material_override = Art.material(color,"wood"); p.add_child(n); return n

static func sign_text(p: Node3D, text: String, at: Vector3, pixels: int = 40, tint: Color = INK) -> Label3D:
	var n := Label3D.new(); n.text = text; n.font_size = pixels; n.pixel_size = 0.008
	n.position = at; n.modulate = tint; n.outline_size = 0; n.no_depth_test = false
	p.add_child(n); return n

static func build(parent: Node3D, item: Dictionary) -> Node3D:
	var r := Node3D.new(); r.name = item.id; r.position = Vector3(item.at.x,0,item.at.y)
	parent.add_child(r)
	var w: float = item.size.x
	var d: float = item.size.y
	var h: float = item.height
	var c: Color = item.color
	box(r,Vector3(0,0.11,0),Vector3(w,0.22,d),c.darkened(0.15))
	match item.kind:
		"cake":
			box(r,Vector3(0,0.70,0),Vector3(w,1.08,d),c)
			box(r,Vector3(0,1.29,0),Vector3(w,0.18,d),CREAM)
			cylinder(r,Vector3(0,1.58,0),1.36,0.5,Color("d695a0"))
			cylinder(r,Vector3(0,2.08,0),1.1,0.50,CREAM)
			cylinder(r,Vector3(0,2.59,0),0.79,0.5,Color("aad0bb"))
			for i in range(10):
				var a := TAU*i/10.0
				Art.ball(r,Vector3(cos(a)*0.92,2.36,sin(a)*0.92),Vector3(0.12,0.12,0.12),Color("e58e97"),"foam")
			Art.ball(r,Vector3(0,2.99,0),Vector3(0.30,0.28,0.30),Color("dc8585"),"foam")
			box(r,Vector3(0,0.75,d*0.5+0.008),Vector3(2.45,0.48,0.035),Color("ac716c"))
			sign_text(r,"SUGAR & SMASH",Vector3(0,0.76,d*0.5+0.033),30,CREAM)
		"counter", "oven", "jars":
			box(r,Vector3(0,0.82,0),Vector3(w,1.4,d),c)
			box(r,Vector3(0,1.56,0),Vector3(w,0.18,d),CREAM)
			if item.kind == "oven":
				box(r,Vector3(0,1.06,d*0.5+0.01),Vector3(w*0.76,0.6,0.04),INK)
				box(r,Vector3(0,1.1,d*0.5+0.04),Vector3(w*0.54,0.04,0.04),CREAM)
				for x in [-0.7,0,0.7]: cylinder(r,Vector3(x,1.81,0),0.28,0.36,Color("cda079"))
			else:
				# Opaque back display is genuine sight-blocking cover, not a glass fake.
				box(r,Vector3(0,1.90,-d*0.34),Vector3(w*0.93,0.55,d*0.25),c.lightened(0.18))
				for i in range(4):
					var x: float = -w*0.34+i*w*0.225
					cylinder(r,Vector3(x,1.80,d*0.16),0.18,0.30,Color("ba976c") if item.kind=="jars" else Color("e4b47c"))
					Art.ball(r,Vector3(x,1.99,d*0.16),Vector3(0.21,0.12,0.21),[CREAM,Color("d79baa"),Color("a4c7ac"),CREAM][i],"foam")
		"planet":
			box(r,Vector3(0,0.72,0),Vector3(w,1.3,d),c)
			box(r,Vector3(0,1.35,0),Vector3(w,0.1,d),Color("d9b976"))
			cylinder(r,Vector3(0,1.7,0),1.14,0.65,Color("567887"))
			Art.ball(r,Vector3(0,2.8,0),Vector3(1.26,1.26,1.26),Color("91b6ca"))
			var ring := TorusMesh.new(); ring.inner_radius = 1.5; ring.outer_radius = 1.63; ring.rings = 32; ring.ring_segments = 8
			var n := MeshInstance3D.new(); n.mesh = ring; n.position.y = 2.8; n.rotation.z = 0.18; n.material_override = Art.material(Color("e8c482")); r.add_child(n)
			for x in [-1.8,1.8]:
				box(r,Vector3(x,0.82,d*0.5+0.01),Vector3(0.64,0.64,0.05),Color("d5b473"))
			sign_text(r,"STAR HUB",Vector3(0,0.75,d*0.5+0.045),34,CREAM)
		"arcade", "prize":
			box(r,Vector3(0,h*0.45,0),Vector3(w,h*0.8,d),c)
			box(r,Vector3(0,h*0.92,0),Vector3(w,0.35,d),INK)
			for side in [-1,1]:
				var label := sign_text(r,"STAR POP" if c.r>c.g else "BEAT BOX",Vector3(0,h*0.92,side*(d*0.5+0.04)),25,CREAM)
				if side<0: label.rotation.y = PI
				box(r,Vector3(0,h*0.6,side*(d*0.5+0.008)),Vector3(w*0.77,h*0.34,0.03),Color("3d637c"))
				for i in range(3):
					Art.ball(r,Vector3(-w*0.24+i*w*0.24,h*0.58,side*(d*0.5+0.038)),Vector3(0.19,0.21,0.025),[Color("e6c683"),Color("e1a1af"),Color("a0d5c6")][i])
				box(r,Vector3(0,h*0.37,side*d*0.44),Vector3(w*0.85,0.12,d*0.10),CREAM)
				for x in [-w*0.22,w*0.22]: cylinder(r,Vector3(x,h*0.41,side*d*0.44),0.09,0.07,Color("db8d99"))
			for x in [-w*0.45,w*0.45]: box(r,Vector3(x,h*0.48,d*0.501),Vector3(0.065,h*0.7,0.045),CREAM,"foam",0.02)
		"engine", "carriage":
			box(r,Vector3(0,0.72,0),Vector3(w,0.78,d),c)
			box(r,Vector3(0,1.75,0),Vector3(w*0.9,1.4,d*0.86),c)
			box(r,Vector3(0,2.57,0),Vector3(w,0.34,d),CREAM,"wood",0.15)
			for side in [-1,1]:
				for x in [-w*0.24,w*0.24]:
					box(r,Vector3(x,1.88,side*d*0.436),Vector3(1.05,0.74,0.04),CREAM)
					box(r,Vector3(x,1.88,side*d*0.448),Vector3(0.86,0.54,0.025),Color("537984"))
					var wheel := cylinder(r,Vector3(x,0.48,side*(d*0.5-0.11)),0.36,0.18,INK); wheel.rotation.x = PI*0.5
			if item.kind == "engine": cylinder(r,Vector3(-w*0.24,2.72,0),0.22,0.24,c.darkened(0.25))
			sign_text(r,"01" if item.kind=="engine" else "EXPRESS",Vector3(0,0.79,d*0.5+0.025),30,CREAM)
		"kiosk":
			box(r,Vector3(0,1.1,0),Vector3(w,1.95,d),c)
			for x in [-w*0.43,w*0.43]: box(r,Vector3(x,2.4,0),Vector3(0.16,1.45,d*0.84),CREAM)
			box(r,Vector3(0,3.18,0),Vector3(w,0.25,d),CREAM)
			for i in range(7): box(r,Vector3(-w*0.43+i*w*0.143,3.34,0),Vector3(w/7*0.9,0.14,d),c,"fabric",0.04)
			box(r,Vector3(0,1.65,d*0.5+0.01),Vector3(w*0.76,0.43,0.04),INK)
		"planter":
			box(r,Vector3(0,0.61,0),Vector3(w,1.0,d),c.darkened(0.15))
			box(r,Vector3(0,1.66,0),Vector3(w*0.93,1.32,d*0.97),c,"foam",0.20)
			for i in range(5): Art.ball(r,Vector3(0,2.10,-d*0.38+i*d*0.19),Vector3(w*0.38,0.30,d*0.105),c.lightened(0.14),"foam")
		"clock":
			box(r,Vector3(0,1.4,0),Vector3(w,2.5,d),c)
			box(r,Vector3(0,3.32,0),Vector3(w*0.8,1.5,d*0.7),CREAM,"wood",0.22)
			var dial := cylinder(r,Vector3(0,3.38,d*0.36),0.64,0.035,Color("86b7af")); dial.rotation.x = PI*0.5
			box(r,Vector3(0,3.55,d*0.39),Vector3(0.05,0.36,0.04),INK)
			box(r,Vector3(0.16,3.39,d*0.39),Vector3(0.32,0.05,0.04),INK)
			box(r,Vector3(0,4.26,0),Vector3(w*0.97,0.23,d*0.8),Color("8db9ad"))
		_:
			# Hiding props share a stable visible solid with differently dressed fronts.
			box(r,Vector3(0,h*0.5,0),Vector3(w,h*0.88,d),c,"wood",0.14)
			box(r,Vector3(0,h*0.94,0),Vector3(w,0.12,d),CREAM)
			var face := Vector3(0,h*0.55,d*0.5+0.008)
			box(r,face,Vector3(w*0.70,h*0.58,0.04),c.darkened(0.12))
			box(r,face+Vector3(w*0.23,0,0.045),Vector3(0.07,0.28,0.07),CREAM)
			if item.kind in ["parcel","luggage","mail"]:
				box(r,Vector3(0,h*0.47,d*0.5+0.035),Vector3(0.10,h*0.76,0.02),CREAM)
				box(r,Vector3(0,h*0.77,d*0.5+0.05),Vector3(0.48,0.24,0.04),Color("f0d79f"))
			else:
				for x in [-0.42,0.0,0.42]: Art.ball(r,Vector3(x,h*0.64,d*0.5+0.045),Vector3(0.12,0.15,0.028),[CREAM,Color("e6a3a1"),Color("a4cdbb")][int((x+0.42)/0.42)],"foam")
	return r
