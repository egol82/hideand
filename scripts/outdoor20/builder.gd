extends RefCounted
## Physical cover, conservative nav rectangles and silhouettes come from the same immutable plan.
const P=preload("res://scripts/outdoor20/plans.gd")
const Art=preload("res://scripts/phase4/art.gd")
const Toy=preload("res://scripts/toy_factory.gd")
const Batch=preload("res://scripts/world19/batches.gd")
static func build(a) -> void:
	a.config=P.spec(a.map_id);a.dimensions=a.config.size;a.active_rect=Rect2(-a.dimensions*0.5,a.dimensions)
	a.map_plan=P.layout(a.map_id);a.surface_zones.assign(a.map_plan.zones);a.spawn_points.assign(a.map_plan.spawn)
	a.set_meta("map_pack",true);a.set_meta("outdoor20",true)
	var shell:=Node3D.new();shell.name="OutdoorShell";a.add_child(shell)
	Art.box(shell,Vector3(0,-0.2,0),Vector3(a.dimensions.x,0.4,a.dimensions.y),a.config.floor,"fabric",0.08)
	Toy.collider(a,Vector3(0,-0.2,0),Vector3(a.dimensions.x,0.4,a.dimensions.y)).name="OutdoorFloor"
	# Low solid planted embankments bound the playfield visibly. No roof or invisible water death.
	for side in [-1,1]:
		for ax in [0,1]:
			var at:=Vector3(side*a.dimensions.x*0.5,0.75,0) if ax==0 else Vector3(0,0.75,side*a.dimensions.y*0.5)
			var size3:=Vector3(0.5,1.5,a.dimensions.y) if ax==0 else Vector3(a.dimensions.x,1.5,0.5)
			Art.box(shell,at,size3,a.config.wall,"wood",0.18);Toy.collider(a,at,size3)
	for c in a.map_plan.props:_cover(a,c)
	if a.map_id=="amber_canyon":
		# High stone lintel is decorative, leaving a 4m navigable opening between real pillars.
		Art.box(shell,Vector3(0,4.35,-12),Vector3(8.0,0.8,2.0),Color("c38b69"),"plaster",0.3)
	for i in range(a.map_plan.homes.size()):_home(a,i,a.map_plan.homes[i])
	var decor: Array=[]
	for z in a.surface_zones:
		var r: Rect2=z.rect;var c: Vector2=r.get_center()
		var wet_deck: bool=a.map_id=="reedwater_bend" and z.loud
		# Only the wetland backing is flush: the old plate hid the timber supports.
		Art.box(shell,Vector3(c.x,0.001 if wet_deck else 0.012,c.y),Vector3(r.size.x,0.002 if wet_deck else 0.02,r.size.y),Color("b7cba0") if not z.loud else Color("cfb687"),"fabric" if not z.loud else "wood",0.006)
		if z.loud and a.map_id!="amber_canyon":
			for x in range(int(r.size.x/0.42)):
				# Thicker timber, unchanged 0.0425m deck top; no raised walk collider.
				piece(decor,"box",Vector3(r.position.x+0.2+x*0.42,0.0225 if wet_deck else 0.03,c.y),Vector3(0.34,0.04 if wet_deck else 0.025,r.size.y*0.9),Color("b49568"),"wood",false)
			if a.map_id=="reedwater_bend":_boardwalk_supports(decor,r)
	# Deterministic low ground accents are not cover and never indicate occupation.
	for i in range(180):
		var x: float=-a.dimensions.x*0.5+1.2+fmod(i*5.731,a.dimensions.x-2.4)
		var z: float=-a.dimensions.y*0.5+1.2+fmod(i*9.173,a.dimensions.y-2.4)
		var at:=Vector3(x,0,z)
		if _blocked(a,Vector2(x,z)):continue
		var leaf:=Color("6d9667") if a.map_id!="amber_canyon" else Color("8d9b73")
		piece(decor,"ball",at+Vector3(0,0.10,0),Vector3(0.23,0.20,0.17),leaf,"foam",true)
		piece(decor,"ball",at+Vector3(0.15,0.08,0.06),Vector3(0.20,0.14,0.16),leaf,"foam",true)
		if i%3==0:piece(decor,"ball",at+Vector3(0.06,0.21,0),Vector3(0.10,0.10,0.10),Color("f4db94"),"foam",true)
	# Backdrop trees and ridges are outside the visible boundary, never misleading reachable cover.
	for i in range(24):
		var theta:=TAU*i/24;var at:=Vector3(cos(theta)*(a.dimensions.x*0.5+6),0,sin(theta)*(a.dimensions.y*0.5+6))
		piece(decor,"ball",at+Vector3.UP*(2.2+i%3),Vector3(5,4.4+i%3,4),a.config.wall.lightened(0.07*(i%3)),"foam",false)
	var root:=Batch.build(decor);root.name="OutdoorAccents";a.add_child(root)
	var label:=Label3D.new();label.text=a.config.title;label.font_size=40;label.pixel_size=0.013;label.position=Vector3(0,3.3,-a.dimensions.y*0.5+0.4);a.add_child(label)
	a._build_navigation()
static func _blocked(a,p: Vector2) -> bool:
	for r in a.obstacles:
		if r.grow(0.35).has_point(p):return true
	for z in a.surface_zones:
		if z.rect.has_point(p):return true
	return false
static func piece(p: Array,shape: String,at: Vector3,size3: Vector3,color: Color,material: String,small: bool) -> void:
	p.append({"shape":shape,"at":at,"size":size3,"color":color,"material":material,"small":small,"rotation":Vector3.ZERO})
static func _cover(a,c: Dictionary) -> void:
	var root:=Node3D.new();root.name="Cover_"+c.id;root.position=Vector3(c.at.x,0,c.at.y);a.add_child(root)
	root.set_meta("cover20",true)
	var size3:=Vector3(c.size.x,c.height,c.size.y)
	var tint: Color=a.config.wall
	if c.kind in ["tree","willow","log"]:tint=Color("9b7958")
	if c.kind=="reeds":tint=Color("64866a")
	if c.kind=="rock":tint=Color("9ca28d") if a.map_id!="amber_canyon" else Color("b18469")
	if c.kind in ["tree","willow"]:
		# Match round trunk art with a real cylinder, not an invisible square tree collider.
		var trunk:=CylinderMesh.new();trunk.top_radius=c.size.x*0.5;trunk.bottom_radius=c.size.x*0.5;trunk.height=c.height;trunk.radial_segments=20
		var art:=MeshInstance3D.new();art.mesh=trunk;art.material_override=Art.material(tint,"wood");art.position.y=c.height*0.5;root.add_child(art)
		var body:=StaticBody3D.new();body.name="CoverPhysics";body.collision_layer=1;root.add_child(body)
		var collider:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=c.size.x*0.5;shape.height=c.height;collider.shape=shape;collider.position.y=c.height*0.5;body.add_child(collider)
	elif c.kind=="reeds" and a.map_id=="reedwater_bend":
		_wetland_reed_cover(root,c)
		Toy.collider(root,Vector3.UP*c.height*0.5,size3).name="CoverPhysics"
	elif c.kind=="rock" and a.map_id=="reedwater_bend":
		_wetland_rock_cover(root,c,tint)
		Toy.collider(root,Vector3.UP*c.height*0.5,size3).name="CoverPhysics"
	else:
		Art.box(root,Vector3.UP*c.height*0.5,size3,tint,"wood" if c.kind=="log" else "plaster",0.35)
		Toy.collider(root,Vector3.UP*c.height*0.5,size3).name="CoverPhysics"
	a.obstacles.append(Rect2(c.at-c.size*0.5,c.size).grow(0.46))
	if c.kind=="willow":
		if a.map_id=="reedwater_bend":_wetland_willow(root,c.height)
		else:
			for j in range(3):
				var leaf:=MeshInstance3D.new();leaf.mesh=Batch.shape("ball");leaf.material_override=Art.material(Color("81a48e"),"foam");leaf.scale=Vector3(4.7-j*0.5,2.1,3.8);leaf.position=Vector3(-0.7+j*0.7,c.height+0.3+0.4*(j%2),0);root.add_child(leaf)
	elif c.kind=="tree":
		for j in range(3):
			var width: float=maxf(c.size.x+1.0,3.2)*(1.0-j*0.17)
			var canopy:=CylinderMesh.new();canopy.bottom_radius=width*0.65;canopy.top_radius=width*0.12;canopy.height=1.6;canopy.radial_segments=12
			var n:=MeshInstance3D.new();n.mesh=canopy;n.material_override=Art.material(Color("648d69") if c.kind=="tree" else Color("81a48e"),"foam");n.position=Vector3(0,c.height+0.35+j*1.0,0);root.add_child(n)
		for side in [-1,1]:Art.box(root,Vector3(side*c.size.x*0.32,0.2,0),Vector3(c.size.x*0.3,0.4,c.size.y),tint.darkened(0.05),"wood",0.1)
	elif c.kind=="reeds":
		if a.map_id!="reedwater_bend":
			# Opaque reed-island core keeps identical occlusion at every detail range.
			for i in range(18):
				var x: float=-c.size.x*0.45+fmod(i*1.371,c.size.x*0.9)
				var z: float=-c.size.y*0.45+fmod(i*2.173,c.size.y*0.9)
				Art.box(root,Vector3(x,c.height+0.25,z),Vector3(0.10,0.65+0.16*(i%3),0.10),Color("acb876"),"wood",0.025)
				Art.box(root,Vector3(x,c.height+0.7,z),Vector3(0.17,0.35,0.17),Color("b29268"),"foam",0.075)
			# Decorative water band is a shallow visual surround, not swimming or a death trigger.
			Art.box(root,Vector3(0,0.024,0),Vector3(c.size.x+1.0,0.03,c.size.y+1.0),Color("7bb9b7"),"ceramic",0.014)
	elif c.kind in ["mesa","arch","rock"]:
		for i in range(3):Art.box(root,Vector3(0,c.height*(0.24+i*0.25),0.015),Vector3(c.size.x*0.97,0.08,c.size.y*1.015),tint.lightened(0.14),"plaster",0.025)
	else:
		for side in [-1,1]:
			Art.box(root,Vector3(side*(c.size.x*0.5+0.015),c.height*0.5,0),Vector3(0.03,c.height*0.70,c.size.y*0.70),Color("dbc39b"),"wood",0.01)
static func _wetland_reed_cover(root: Node3D,c: Dictionary) -> void:
	var mud:=Color("6e7f5e")
	var wet:=Color("7ca2a0")
	Art.box(root,Vector3(0,0.16,0),Vector3(c.size.x+0.85,0.22,c.size.y+0.95),wet,"ceramic",0.22)
	Art.box(root,Vector3(0,0.32,0),Vector3(c.size.x+0.35,0.24,c.size.y+0.40),Color("7c8b65"),"fabric",0.24)
	# The rounded mesh's inner box equals the entire unchanged collider.
	# A 0.06m opaque skin covers its corners, not just the centre or maximum height.
	var skin:=0.06
	Art.box(root,Vector3(0,c.height*0.5,0),Vector3(c.size.x,c.height,c.size.y)+Vector3.ONE*skin*2.0,mud,"fabric",skin)
	Art.box(root,Vector3(-c.size.x*0.10,c.height*0.91,-c.size.y*0.08),Vector3(c.size.x*0.46,c.height*0.42,c.size.y*0.44),Color("7f8f69"),"fabric",0.28)
	Art.box(root,Vector3(c.size.x*0.15,c.height*0.94,c.size.y*0.08),Vector3(c.size.x*0.40,c.height*0.38,c.size.y*0.36),Color("73845f"),"fabric",0.24)
	for side in [-1,1]:
		for i in range(4):
			var rootlog:=Art.box(root,Vector3(side*(c.size.x*0.42+0.08*i),0.18,-c.size.y*0.12+0.20*i),Vector3(0.42,0.12,0.14),Color("8e6b46"),"wood",0.04)
			rootlog.rotation.y=side*0.38+0.18*i
	var ring:=Node3D.new();root.add_child(ring)
	for i in range(22):
		var angle:=TAU*float(i)/22.0
		var edge:=Vector3(cos(angle)*c.size.x*0.42,0,sin(angle)*c.size.y*0.38)
		var stem:=CylinderMesh.new();stem.top_radius=0.018;stem.bottom_radius=0.028;stem.height=1.05+0.22*float(i%4)
		var stem_node:=MeshInstance3D.new();stem_node.mesh=stem;stem_node.material_override=Art.material(Color("849965"),"wood")
		# Stem feet at about height-0.12 now overlap the continuous height+0.06 mud.
		stem_node.position=edge+Vector3(0,c.height+stem.height*0.5-0.12,0);stem_node.rotation=Vector3(0.05*sin(angle*2.0),angle,0.05*cos(angle*1.6));ring.add_child(stem_node)
		var head:=Art.ball(ring,edge+Vector3(0,c.height+stem.height-0.04,0),Vector3(0.08,0.18,0.08),Color("b18f61"),"foam")
		head.rotation.y=angle
		if i%2==0:
			var leaf:=Art.box(ring,edge+Vector3(0,c.height+stem.height*0.55,0),Vector3(0.03,0.01,0.54),Color("a8bc79"),"foam",0.014)
			leaf.rotation=Vector3(-0.22,angle+0.25,0.62)
	for i in range(7):
		var shrub:=Art.ball(root,Vector3(-c.size.x*0.22+0.42*i, c.height+0.22+0.08*(i%2), -c.size.y*0.12+0.28*sin(i*0.9)),Vector3(0.22,0.16,0.18),Color("92b36d"),"foam")
		shrub.rotation.y=0.7*i
static func _wetland_willow(root: Node3D,height: float) -> void:
	var trunk_tint:=Color("8b6b4a")
	for i in range(3):
		var rootarm:=Art.box(root,Vector3(-0.22+0.22*i,0.18,0.12-0.10*(i%2)),Vector3(0.26,0.13,0.22),trunk_tint,"wood",0.05)
		rootarm.rotation.y=-0.65+0.4*i
	var branch_specs: Array=[[Vector3(0.12,height*0.92,0.0),Vector3(0.12,0.0,-0.72),0.17],[Vector3(-0.05,height*0.82,0.0),Vector3(-0.18,0.0,0.78),0.13]]
	for spec in branch_specs:
		var branch:=CylinderMesh.new();branch.top_radius=spec[2]*0.55;branch.bottom_radius=spec[2];branch.height=1.4;branch.radial_segments=12
		var art:=MeshInstance3D.new();art.mesh=branch;art.material_override=Art.material(trunk_tint,"wood");art.position=spec[0];art.rotation=spec[1];root.add_child(art)
	var canopy_points: Array=[Vector3(-0.95,height+0.55,0.0),Vector3(0.25,height+0.82,-0.45),Vector3(0.85,height+0.38,0.32),Vector3(-0.15,height+0.22,0.58)]
	for i in range(canopy_points.size()):
		var puff:=Art.ball(root,canopy_points[i],Vector3(1.55-0.14*i,0.78+0.08*(i%2),1.18-0.10*i),Color("7d9d84"),"foam")
		puff.rotation.y=0.55*i
		for s in [-1,1]:
			var strand:=Art.box(root,canopy_points[i]+Vector3(s*0.44,-0.78+0.12*i,0.12*s),Vector3(0.05,1.12-0.08*i,0.05),Color("87aa8a"),"foam",0.02)
			strand.rotation=Vector3(0.0,0.22*i,s*0.16)
static func _wetland_rock_cover(root: Node3D,c: Dictionary,tint: Color) -> void:
	# Full-height opaque stone encloses the existing box, including upper corners.
	var skin:=0.06
	Art.box(root,Vector3(0,c.height*0.5,0),Vector3(c.size.x,c.height,c.size.y)+Vector3.ONE*skin*2.0,tint,"plaster",skin)
	Art.box(root,Vector3(-c.size.x*0.12,c.height*0.94,-c.size.y*0.08),Vector3(c.size.x*0.62,c.height*0.34,c.size.y*0.56),tint.lightened(0.08),"plaster",0.20)
	Art.box(root,Vector3(c.size.x*0.22,c.height*0.92,c.size.y*0.15),Vector3(c.size.x*0.36,c.height*0.26,c.size.y*0.34),tint.darkened(0.08),"plaster",0.18)
	for i in range(3):
		Art.box(root,Vector3(0,c.height*(0.18+i*0.22),0.02),Vector3(c.size.x*0.92,0.07,c.size.y*0.98),tint.lightened(0.12),"plaster",0.025)
	for side in [-1,1]:
		Art.ball(root,Vector3(side*(c.size.x*0.42),0.20,-0.15*side),Vector3(0.26,0.10,0.20),Color("7c8665"),"fabric")
static func _boardwalk_supports(decor: Array,r: Rect2) -> void:
	var center:=r.get_center().y
	# Low-profile edge rails and exposed supports, not a false elevated bridge.
	for side in [-1,1]:
		piece(decor,"box",Vector3(r.get_center().x,0.019,center+side*r.size.y*0.47),Vector3(r.size.x-0.10,0.038,0.08),Color("916b49"),"wood",false)
	for x in range(int(r.size.x/1.68)+1):
		var px:=r.position.x+0.38+minf(float(x)*1.68,r.size.x-0.38)
		for side in [-1,1]:
			piece(decor,"box",Vector3(px,0.0275,center+side*r.size.y*0.47),Vector3(0.14,0.055,0.12),Color("7b5d40"),"wood",false)
		piece(decor,"box",Vector3(px,0.013,center),Vector3(0.16,0.022,r.size.y*0.98),Color("916b49"),"wood",false)
static func _home(a,i: int,at: Vector2) -> void:
	var root:=Node3D.new();root.name="NatureHide_%02d"%i;root.position=Vector3(at.x,0,at.y);a.add_child(root)
	root.set_meta("hideout_id",i)
	var tint: Color=Color("ad8964") if a.map_id=="pine_hollow" else (Color("9baf88") if a.map_id=="reedwater_bend" else Color("b99778"))
	Art.box(root,Vector3(0,0.8,0),Vector3(1.7,1.6,1.5),tint,"wood",0.17)
	Toy.collider(root,Vector3(0,0.8,0),Vector3(1.7,1.6,1.5)).name="HidePhysics"
	a.obstacles.append(Rect2(at-Vector2(0.85,0.75),Vector2(1.7,1.5)).grow(0.46))
	for x in [-0.54,0.54]:Art.box(root,Vector3(x,0.79,0.775),Vector3(0.08,1.3,0.06),tint.lightened(0.2),"wood",0.02)
	Art.box(root,Vector3(0,1.66,0),Vector3(1.78,0.18,1.58),a.config.accent,"foam",0.07)
	Art.box(root,Vector3(0.35,1.0,0.81),Vector3(0.17,0.08,0.10),Color("e6cc92"),"wood",0.03)
	var icon:=Art.box(root,Vector3(0,1.27,0.80),Vector3(0.28,0.25,0.05),Color("eedfbd"),"foam",0.05);icon.rotation.z=0.2
	var entry:=Vector3(at.x,0,at.y+1.5);a.spots.append(entry);a.active_spots.append(i)
	a.spot_names.append(("솔방울 보관함" if a.map_id=="pine_hollow" else ("갈대 바구니" if a.map_id=="reedwater_bend" else "탐험 보급함"))+" %02d"%(i+1))
	var marker:=Label3D.new();marker.text="E · %02d"%(i+1);marker.position=entry+Vector3.UP;marker.font_size=32;marker.pixel_size=0.004;marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.visible=false;a.add_child(marker);a.markers.append(marker)
