extends RefCounted
## Versioned, stateless route sockets. Does not consume any game/AI/audio random stream.
const VERSION:=1
const IDS: Array[String]=["pine_hollow","reedwater_bend","amber_canyon"]
const COUNT:=9
static func index_for(map_id: String,match_seed: int,round_index: int) -> int:
	var value:=0
	for byte in (map_id+"/"+str(match_seed)).to_utf8_buffer():value=(value*131+byte)%2147483647
	return posmod(value+posmod(round_index,COUNT)*4,COUNT)
static func plan(map_id: String,match_seed: int,round_index: int) -> Dictionary:
	if map_id not in IDS or round_index<0:return {}
	var sockets: Array=[]
	match map_id:
		"pine_hollow":
			sockets=[[Vector2(-5,-6),Vector2(-5,-3.5),Vector2(-6.5,-5)],[Vector2(5,-3.5),Vector2(6,-3.5),Vector2(4,-3)]]
		"reedwater_bend":
			sockets=[[Vector2(-8,-7.5),Vector2(-8,-2.4),Vector2(-7.2,-4.4)],[Vector2(8.2,2.5),Vector2(8.2,5),Vector2(8.2,7.5)]]
		"amber_canyon":
			sockets=[[Vector2(-8,2.5),Vector2(-8,4),Vector2(-5.5,3.5)],[Vector2(9,-4.5),Vector2(9.5,-6),Vector2(10.5,-5.7)]]
	var index:=index_for(map_id,match_seed,round_index)
	var picks: Array[int]=[index%3,int(index/3)]
	var placements: Array[Vector2]=[sockets[0][picks[0]],sockets[1][picks[1]]]
	var prefix: String={"pine_hollow":"PH","reedwater_bend":"RW","amber_canyon":"AC"}[map_id]
	return {"map":map_id,"seed":match_seed,"round":round_index,"version":VERSION,"index":index,"id":"%s-v%d-%d"%[prefix,VERSION,index],"positions":placements,"size":Vector3(1.6,1.65,0.85)}
static func serial(p: Dictionary) -> Dictionary:
	var out:=p.duplicate(true)
	if p.is_empty():return out
	out.positions=[]
	for v in p.positions:out.positions.append([v.x,v.y])
	out.size=[p.size.x,p.size.y,p.size.z]
	return out
