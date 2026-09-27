extends RefCounted
## Original authored layouts, not copied competitor floorplans. Coordinates are x/z metres.
## Props: conservative solid footprint, height and visual family; hideouts have explicit access.
static func prop(id: String, kind: String, at: Vector2, size2: Vector2, height: float, color: Color) -> Dictionary:
	return {"id":id.replace(".","p").replace("-","m"),"kind":kind,"at":at,"size":size2,"height":height,"color":color}

static func hide(id: String, kind: String, at: Vector2, direction: Vector2, color: Color) -> Dictionary:
	return {"id":id.replace(".","p").replace("-","m"),"kind":kind,"at":at,"access":at+direction.normalized()*2.15,"size":Vector2(1.8,1.5),"height":2.0,"color":color}

static func zone(id: String, r: Rect2, loud: bool) -> Dictionary:
	return {"id":id,"rect":r,"noise":1.65 if loud else 0.5,"sound":"chime_step" if loud else "soft_step","loud":loud}

static func layout(id: String) -> Dictionary:
	match id:
		"sugar_market": return _market()
		"starlight_arcade": return _arcade()
		"pocket_station": return _station()
	return {"props":[],"hideouts":[],"zones":[],"landmarks":[],"loop":[]}

static func _market() -> Dictionary:
	var p: Array = [
		prop("cake_island","cake",Vector2(0,-6),Vector2(5,3.6),3.3,Color("e3aa8c")),
		prop("berry_counter","counter",Vector2(-6,2.6),Vector2(4.2,2.6),2.25,Color("d08b92")),
		prop("mint_counter","counter",Vector2(6,2.6),Vector2(4.2,2.6),2.25,Color("86b7a8")),
		prop("bakery_oven","oven",Vector2(-7,-5.6),Vector2(2.5,2.4),2.6,Color("90b8b1")),
		prop("tea_display","jars",Vector2(7,-5.6),Vector2(2.5,2.4),2.6,Color("d9b77f"))]
	var h: Array = []
	for side in [-1,1]:
		for z in [-8.0,0.0,8.0]: h.append(hide("pastry_%s_%s" % [side,z],"pastry",Vector2(side*11.5,z),Vector2(-side,0),Color("e6c79f") if side<0 else Color("a1c9b9")))
	for z in [-10.5,10.5]:
		for x in [-5.0,5.0]: h.append(hide("parcel_%s_%s" % [x,z],"parcel",Vector2(x,z),Vector2(0,-signf(z)),Color("e9ada1")))
	return {"props":p,"hideouts":h,"zones":[zone("bell_tile",Rect2(-1.9,2,3.8,7),true),zone("mint_runner",Rect2(-9.5,-2,2,8),false),zone("cream_runner",Rect2(7.5,-2,2,8),false)],"landmarks":[{"at":Vector2(0,-6),"en":"CAKE ISLAND","ko":"케이크 섬"},{"at":Vector2(-6,2.6),"en":"BERRY LANE","ko":"딸기 길"},{"at":Vector2(6,2.6),"en":"MINT LANE","ko":"민트 길"}],"loop":[Vector2(-3.7,-6),Vector2(0,-8.8),Vector2(3.7,-6),Vector2(0,-3.2)]}

static func _arcade() -> Dictionary:
	var p: Array = [prop("star_projector","planet",Vector2(0,-7),Vector2(5.6,3.8),4.2,Color("849dad"))]
	for side in [-1,1]:
		for z in [-6.0,6.0]: p.append(prop("cabinet_%s_%s" % [side,z],"arcade",Vector2(side*8,z),Vector2(3.2,4.0),2.75,Color("c19cb2") if side<0 else Color("82bcba")))
	p.append(prop("prize_display","prize",Vector2(0,10),Vector2(5.2,2.6),2.6,Color("d9b77b")))
	var h: Array = []
	for side in [-1,1]:
		for z in [-11.0,-3.7,3.7,11.0]: h.append(hide("prize_%s_%s" % [side,z],"prize_box",Vector2(side*16.7,z),Vector2(-side,0),Color("b797b0") if side<0 else Color("83afc0")))
	for z in [-13.0,13.0]:
		for x in [-8.0,8.0]: h.append(hide("case_%s_%s" % [x,z],"arcade_box",Vector2(x,z),Vector2(0,-signf(z)),Color("d6b77e")))
	h.append(hide("north_tokens","prize_box",Vector2(0,-13),Vector2.DOWN,Color("9ebaa6")))
	h.append(hide("south_tokens","arcade_box",Vector2(0,14),Vector2.UP,Color("a5b9ce")))
	return {"props":p,"hideouts":h,"zones":[zone("musical_tiles",Rect2(-5,0,10,2.4),true),zone("velvet_west",Rect2(-12,-10,2.3,20),false),zone("velvet_east",Rect2(9.7,-10,2.3,20),false)],"landmarks":[{"at":Vector2(0,-7),"en":"STAR HUB","ko":"별빛 허브"},{"at":Vector2(-8,6),"en":"NOVA GAMES","ko":"노바 게임"},{"at":Vector2(8,6),"en":"MOON GAMES","ko":"문 게임"}],"loop":[Vector2(-4,-7),Vector2(0,-10),Vector2(4,-7),Vector2(0,-4)]}

static func _station() -> Dictionary:
	var p: Array = []
	for i in range(3): p.append(prop("train_%d"%i,"engine" if i==0 else "carriage",Vector2(-7+i*7,-7),Vector2(4.4,3.1),2.85,[Color("86b9b2"),Color("d69378"),Color("deb76c")][i]))
	for side in [-1,1]:
		p.append(prop("ticket_kiosk_%s"%side,"kiosk",Vector2(side*15,7),Vector2(4.2,3.2),3.6,Color("93b0b9") if side<0 else Color("dc9d82")))
		p.append(prop("garden_planter_%s"%side,"planter",Vector2(side*15,-8),Vector2(3.3,7),2.4,Color("8eb18c")))
	p.append(prop("station_clock","clock",Vector2(0,-16),Vector2(3.8,2.7),4.6,Color("b59170")))
	var h: Array = []
	for side in [-1,1]:
		for z in [-14.0,-7.0,0.0,7.0,14.0]: h.append(hide("luggage_%s_%s"%[side,z],"luggage",Vector2(side*22,z),Vector2(-side,0),Color("a8bdaa") if side<0 else Color("d8ae88")))
	for z in [-17.0,17.0]:
		for x in [-15.0,-6.0,6.0,15.0]: h.append(hide("mail_%s_%s"%[x,z],"mail",Vector2(x,z),Vector2(0,-signf(z)),Color("99bcc5")))
	return {"props":p,"hideouts":h,"zones":[zone("gravel_crossing",Rect2(-11,-3,22,3),true),zone("blue_boardwalk",Rect2(-12.2,1,2.2,13),false),zone("blue_boardwalk_2",Rect2(10,1,2.2,13),false)],"landmarks":[{"at":Vector2(0,-16),"en":"POCKET EXPRESS","ko":"포켓 익스프레스"},{"at":Vector2(-15,7),"en":"TICKETS","ko":"표 파는 곳"},{"at":Vector2(15,7),"en":"PICNIC STOP","ko":"피크닉 쉼터"}],"loop":[Vector2(-3.5,-7),Vector2(0,-9.8),Vector2(3.5,-7),Vector2(0,-4.2)]}
