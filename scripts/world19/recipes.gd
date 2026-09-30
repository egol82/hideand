extends RefCounted
## Original themed relief; no hidden state, RNG, colliders or game objects.
const Catalog=preload("res://scripts/maps/catalog.gd")
const Plans=preload("res://scripts/maps/plans.gd")
const IDS:=["sugar_market","starlight_arcade","pocket_station","toy_home","warehouse","garden"]
const CREAM:=Color("eadac0")
const BRASS:=Color("b99358")
const WOOD:=Color("795d47")
var pieces: Array=[]
func add(at: Vector3,size3: Vector3,color: Color,material: String="wood",small: bool=true,shape: String="box",rot: Vector3=Vector3.ZERO) -> void:
	pieces.append({"at":at,"size":size3,"color":color,"material":material,"small":small,"shape":shape,"rotation":rot})
func flower(at: Vector3,color: Color) -> void:
	for j in range(5):
		var a:=TAU*j/5.0
		add(at+Vector3(cos(a)*0.12,0,sin(a)*0.12),Vector3(0.22,0.09,0.22),color,"foam",true,"ball")
	add(at+Vector3.UP*0.025,Vector3(0.12,0.09,0.12),BRASS,"foam",true,"ball")
func book(at: Vector3,color: Color) -> void:
	add(at,Vector3(0.52,0.12,0.38),color,"fabric")
	add(at+Vector3(0,0,0.194),Vector3(0.44,0.07,0.012),CREAM,"plaster")
func pastry(at: Vector3) -> void:
	add(at,Vector3(0.49,0.045,0.49),CREAM,"ceramic",true,"cylinder")
	add(at+Vector3.UP*0.10,Vector3(0.31,0.16,0.30),Color("c58a55"),"foam",true,"ball")
	add(at+Vector3.UP*0.19,Vector3(0.25,0.07,0.23),Color("e5b8b1"),"foam",true,"ball")
	add(at+Vector3.UP*0.235,Vector3(0.07,0.07,0.07),Color("b95e68"),"foam",true,"ball")

func make(id: String) -> Array:
	pieces.clear()
	if id not in IDS:return pieces
	var s:=Catalog.spec(id);var dims: Vector2=s.size
	# Boundary-mounted joinery, not new cover. Thin relief is always visible.
	if id not in ["garden","pocket_station"]:
		for side in [-1,1]:
			for x in range(-int(dims.x/2)+2,int(dims.x/2),2):
				add(Vector3(x,0.54,side*(dims.y/2-0.225)),Vector3(1.75,0.69,0.022),s.accent.lightened(0.35),"wood",false)
				add(Vector3(x,0.54,side*(dims.y/2-0.249)),Vector3(1.51,0.48,0.018),s.wall,"wood",false)
	if Catalog.is_new(id):
		var plan:=Plans.layout(id)
		for p in plan.props:
			var at:=Vector3(p.at.x,0,p.at.y);var w: float=p.size.x;var d: float=p.size.y
			if id=="sugar_market":
				if p.kind in ["counter","jars","oven"]:
					for i in range(3):
						var x: float=-w*0.32+i*w*0.32
						add(at+Vector3(x,0.74,d/2+0.034),Vector3(w*0.28,0.91,0.034),p.color.lightened(0.22),"wood",false)
						add(at+Vector3(x,1.02,d/2+0.052),Vector3(0.23,0.045,0.038),BRASS)
						pastry(at+Vector3(x,1.69,d*0.26))
					for i in range(11):add(at+Vector3(-w*0.45+i*w*0.09,1.50,d/2+0.02),Vector3(0.05,0.04,0.015),CREAM,"fabric")
			elif id=="starlight_arcade":
				if p.kind=="arcade":
					for side in [-1,1]:
						for j in range(4):
							add(at+Vector3(-w*0.28+j*w*0.185,0.57,side*(d/2+0.025)),Vector3(0.055,0.34,0.021),WOOD)
							add(at+Vector3(-w*0.29+j*w*0.19,2.51,side*(d/2+0.026)),Vector3(0.075,0.075,0.035),CREAM,"vinyl",true,"ball")
						for x in [-w*0.36,w*0.36]:add(at+Vector3(x,1.69,side*(d/2+0.035)),Vector3(0.045,0.91,0.025),BRASS,"wood",false)
				elif p.kind=="prize":
					for j in range(7):
						var b:=at+Vector3(-2.0+j*0.67,2.79,0)
						add(b,Vector3(0.32,0.28,0.30),CREAM,"vinyl",true,"ball")
						for x in [-0.10,0.10]:add(b+Vector3(x,0.14,0),Vector3(0.10,0.19,0.10),CREAM,"vinyl",true,"ball")
			else:
				if p.kind in ["engine","carriage"]:
					for side in [-1,1]:
						add(at+Vector3(0,1.03,side*(d/2+0.014)),Vector3(w*0.90,0.10,0.02),CREAM,"wood",false)
						for j in range(12):add(at+Vector3(-w*0.43+j*w*0.078,0.71,side*(d/2+0.026)),Vector3(0.048,0.048,0.025),BRASS,"wood",true,"ball")
						for x in [-w*0.24,w*0.24]:
							add(at+Vector3(x,1.88,side*(d*0.46)),Vector3(0.034,0.52,0.024),CREAM,"wood",false)
				elif p.kind=="planter":
					for j in range(9):flower(at+Vector3(0,2.43,-d*0.42+j*d*0.105),Color("e0ad8b"))
		# Relief frames of existing hiding furniture remain identical for occupied and empty sites.
		for h in plan.hideouts:
			var at:=Vector3(h.at.x,0,h.at.y)
			for x in [-0.71,0.71]:add(at+Vector3(x,1.05,0.778),Vector3(0.045,1.38,0.026),CREAM,"wood",false)
			for x in [-0.60,0.60]:
				for y in [0.48,1.67]:add(at+Vector3(x,y,0.802),Vector3(0.065,0.065,0.025),BRASS,"wood",true,"ball")
	else:
		var centers:=Catalog.prop_centers(id)
		for i in range(centers.size()):
			var at:=Vector3(centers[i].x,0,centers[i].y)
			if id=="garden":
				if i%3==0:
					for j in range(7):flower(at+Vector3(-0.73+j*0.24,1.94,0),Color("eac28d"))
				else:
					for j in range(4):add(at+Vector3(-0.58+j*0.39,0.54,0.78),Vector3(0.04,0.70,0.025),CREAM,"wood",false)
			else:
				for x in [-0.69,0.69]:add(at+Vector3(x,0.71,0.82),Vector3(0.05,0.94,0.020),CREAM,"wood",false)
				for j in range(7):add(at+Vector3(-0.52+j*0.17,0.89,0.835),Vector3(0.045,0.025,0.020),BRASS)
				if id=="warehouse":
					add(at+Vector3(0,0.51,0.83),Vector3(0.48,0.24,0.023),CREAM,"wood",false)
					for j in range(6):add(at+Vector3(-0.17+j*0.065,0.51,0.848),Vector3(0.022,0.15,0.01),WOOD)
		if id=="toy_home":
			for x in [-1.26,0.0,1.26]:
				for j in range(10):
					add(Vector3(x-0.45+j*0.10,0.929,-2.49),Vector3(0.036,0.012,0.012),CREAM,"fabric")
			for x in [-5.0,5.0]:book(Vector3(x+0.12,0.82,-3.85),Color("ae8067"))
		elif id=="warehouse":
			for x in [-10.0,10.0]:
				for z in [-12.0,0.0,12.0]:
					for j in range(6):add(Vector3(x-0.8+j*0.32,1.98,z+0.76),Vector3(0.16,0.04,0.03),CREAM)
		else:
			for x in [-17.0,17.0]:
				for z in [-14.0,14.0]:
					for i in range(20):flower(Vector3(x-3.9+i*0.4,2.25,z),Color("e6a5ab"))
	return pieces
