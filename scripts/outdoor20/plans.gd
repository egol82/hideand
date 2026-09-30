extends RefCounted
## Original authored layouts. Flat walkable loops; occluding cover and navigation share one plan.
const IDS := ["pine_hollow","reedwater_bend","amber_canyon"]
static func spec(id: String) -> Dictionary:
	var rows: Dictionary={
	"pine_hollow":["PINE HOLLOW","솔방울 숲",Vector2(34,30),18.0,110.0,Color("c9ded3"),Color("8ba77b"),Color("6f8263"),Color("d6b77b"),"거목 양쪽으로 시야를 끊고, 통나무 길과 이끼 우회로를 고르세요.","Circle the great tree. Take the log trail or the quiet moss flank."],
	"reedwater_bend":["REEDWATER BEND","갈대 물굽이",Vector2(40,32),22.0,135.0,Color("c2dfe4"),Color("9bab80"),Color("7b9985"),Color("e1c996"),"갈대섬 두 곳 사이 세 갈림길. 빠른 나무길은 소리를 남깁니다.","Three crossings weave around two reed islands. The boardwalk is noisy."],
	"amber_canyon":["AMBER CANYON","노을 협곡",Vector2(42,34),23.0,145.0,Color("ead7bb"),Color("d2b58d"),Color("bb896b"),Color("98aa89"),"바위 틈에서 방향을 바꾸거나, 넓은 모래 외곽길로 돌아가세요.","Cut through rock gaps or take the wide sandy outer loop."]}
	var r: Array=rows[id]
	return {"id":id,"title":r[0],"ko":r[1],"size":r[2],"compact_size":r[2],"hide":r[3],"seek":r[4],"sky":r[5],"floor":r[6],"wall":r[7],"accent":r[8],"tip_ko":r[9],"tip_en":r[10],"subtitle":r[10]}
static func cover(id: String,kind: String,x: float,z: float,w: float,d: float,h: float) -> Dictionary:
	return {"id":id,"kind":kind,"at":Vector2(x,z),"size":Vector2(w,d),"height":h}
static func zone(id: String,r: Rect2,loud: bool) -> Dictionary:
	return {"id":id,"rect":r,"loud":loud,"noise":1.65 if loud else 0.42,"sound":"step" if loud else "soft_step"}
static func layout(id: String) -> Dictionary:
	var p: Array=[];var homes: Array[Vector2]=[];var z: Array=[];var loops: Array=[]
	if id=="pine_hollow":
		p=[cover("great_tree","tree",0,-5,4.4,4.4,4.7),cover("log_west","log",-7,0,5,1.65,1.9),cover("log_east","log",7,-8,1.65,5,1.9),cover("stone_nw","rock",-8,-9,3.0,2.6,2.2),cover("stone_se","rock",7,5,3.4,2.8,2.3),cover("pine_sw","tree",-7,7,1.7,1.7,3.3),cover("pine_ne","tree",9,-2,1.7,1.7,3.3)]
		homes.assign([Vector2(-12,-11),Vector2(-12,-4),Vector2(-12,6),Vector2(-2,-12),Vector2(5,-12),Vector2(12,-7),Vector2(12,3),Vector2(11,10),Vector2(1,10),Vector2(-7,11)])
		z=[zone("moss_flank",Rect2(-14,-12,3,24),false),zone("log_trail",Rect2(-3,-10,6,2),true),zone("wood_crossing",Rect2(-4,-1,8,2),true)]
		loops=[[Vector2(-4,-9),Vector2(4,-9),Vector2(4,-1),Vector2(-4,-1)]]
	elif id=="reedwater_bend":
		# Two separate solid reed islands leave north, middle and south crossings: a figure-eight.
		p=[cover("reed_north","reeds",0,-7,7,6,2.0),cover("reed_south","reeds",0,6,9,5,2.0),cover("willow_west","willow",-10,-5,2.0,2.0,3.6),cover("willow_east","willow",11,5,2.0,2.0,3.6),cover("bank_rock_w","rock",-10,5,3,2.5,2),cover("bank_rock_e","rock",10,-8,3,3,2.0)]
		homes.assign([Vector2(-15,-12),Vector2(-15,-2),Vector2(-15,9),Vector2(-7,-12),Vector2(7,-12),Vector2(15,-9),Vector2(15,0),Vector2(15,10),Vector2(7,12),Vector2(-5,12)])
		z=[zone("north_boardwalk",Rect2(-9,-12,18,2),true),zone("middle_boardwalk",Rect2(-9,-1,18,2),true),zone("quiet_bank",Rect2(-14,-10,2.5,21),false),zone("south_moss",Rect2(-9,10,18,2),false)]
		loops=[[Vector2(-6,-12),Vector2(6,-12),Vector2(6,0),Vector2(-6,0)],[Vector2(-6,0),Vector2(6,0),Vector2(6,10),Vector2(-6,10)]]
	else:
		p=[cover("mesa_w","mesa",-7,-5,5,8,3.4),cover("mesa_e","mesa",6,4,5,8,3.8),cover("north_spire","mesa",5,-9,3.5,3.2,3),cover("south_spire","mesa",-6,8,3,3,2.8),cover("arch_w","arch",-3,-12,2,2,4.0),cover("arch_e","arch",3,-12,2,2,4.0),cover("shelter","rock",12,-1,3,2.6,2.1)]
		homes.assign([Vector2(-16,-12),Vector2(-16,-3),Vector2(-16,8),Vector2(-10,13),Vector2(1,12),Vector2(13,12),Vector2(16,5),Vector2(16,-5),Vector2(12,-12),Vector2(0,-6)])
		z=[zone("gravel_gap",Rect2(-3,-10,5,15),true),zone("outer_sand",Rect2(-14,-10,3,22),false),zone("south_sand",Rect2(-12,10,24,2),false)]
		loops=[[Vector2(-11,-10),Vector2(-3,-10),Vector2(-3,1),Vector2(-11,1)],[Vector2(2,-2),Vector2(10,-2),Vector2(10,10),Vector2(2,10)]]
	return {"props":p,"homes":homes,"zones":z,"loops":loops,"contact_at":Vector3(0,0,2.0),"spawn":[Vector3(-1.5,0,2.0),Vector3(-0.5,0,2.0),Vector3(0.5,0,2.0),Vector3(1.5,0,2.0)]}
