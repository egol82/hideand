extends RefCounted
## Dimensions use Godot world units (1 unit is treated as 1 metre in UI).
const IDS := ["toy_home", "warehouse", "garden"]

static func spec(id: String) -> Dictionary:
	match id:
		"warehouse":
			return {"id":id,"title":"TOY WAREHOUSE","subtitle":"MEDIUM / aisles, lockers and stacked toys","size":Vector2(48,36),"hide":22.0,"seek":135.0,"sky":Color("b5d7df"),"floor":Color("bfcaca"),"wall":Color("c6d8dc"),"accent":Color("e4bb72")}
		"garden":
			return {"id":id,"title":"SECRET GARDEN","subtitle":"LARGE / hedges, paths and garden hideouts","size":Vector2(80,56),"hide":32.0,"seek":210.0,"sky":Color("b6dce7"),"floor":Color("86ae87"),"wall":Color("b7c997"),"accent":Color("f0cf91")}
		_:
			return {"id":"toy_home","title":"TOY HOUSE","subtitle":"SMALL / connected rooms and cozy cover","size":Vector2(24,20),"hide":14.0,"seek":80.0,"sky":Color("bad9df"),"floor":Color("d4b48d"),"wall":Color("e8dcc6"),"accent":Color("9ecac0")}

static func prop_centers(id: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if id == "garden":
		for x in [-33.0,-22.0,-11.0,11.0,22.0,33.0]:
			for z in [-21.0,-7.0,7.0,21.0]:
				result.append(Vector2(x,z))
	elif id == "warehouse":
		for x in [-18.0,-10.0,10.0,18.0]:
			for z in [-12.0,0.0,12.0]:
				result.append(Vector2(x,z))
		result.append(Vector2(0,-13))
		result.append(Vector2(0,13))
	else:
		result.assign([Vector2(-8,-6),Vector2(-8,0),Vector2(-8,6),Vector2(0,-7),Vector2(8,-6),Vector2(8,0),Vector2(8,6),Vector2(0,7)])
	return result
