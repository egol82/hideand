extends RefCounted
## New maps are explicit whitelist entries. Historical Phase 3 catalog stays unchanged.
const Legacy = preload("res://scripts/phase3/map_catalog.gd")
const Plans = preload("res://scripts/maps/plans.gd")
const Nature = preload("res://scripts/outdoor20/plans.gd")
const NEW_IDS := ["sugar_market", "starlight_arcade", "pocket_station"]
const IDS := ["toy_home", "warehouse", "garden", "sugar_market", "starlight_arcade", "pocket_station", "pine_hollow", "reedwater_bend", "amber_canyon"]

static func is_new(id: String) -> bool:
	return id in NEW_IDS

static func spec(id: String) -> Dictionary:
	if id in Nature.IDS: return Nature.spec(id)
	if not is_new(id): return Legacy.spec(id)
	var s: Dictionary = {
		"sugar_market": {"title":"SUGAR MARKET", "ko":"슈가 마켓", "size":Vector2(30,26), "hide":17.0, "seek":105.0, "sky":Color("cee2db"), "floor":Color("e0c2a0"), "wall":Color("e8d2bf"), "accent":Color("ca837f"), "tip_en":"Circle the cake display. Tiles are loud; mint runners are quiet.", "tip_ko":"케이크 진열대를 돌아 따돌리세요. 타일은 시끄럽고 민트 러그는 조용합니다."},
		"starlight_arcade": {"title":"STARLIGHT ARCADE", "ko":"별빛 오락실", "size":Vector2(40,32), "hide":21.0, "seek":135.0, "sky":Color("90afb9"), "floor":Color("67858d"), "wall":Color("688c9d"), "accent":Color("e5bb77"), "tip_en":"Break sight behind cabinets. Cross chime tiles or take the carpet loop.", "tip_ko":"게임기 뒤에서 시야를 끊으세요. 소리 타일과 카펫 우회로를 고를 수 있습니다."},
		"pocket_station": {"title":"POCKET STATION", "ko":"포켓 기차역", "size":Vector2(52,40), "hide":26.0, "seek":165.0, "sky":Color("b2d4de"), "floor":Color("c9c5a0"), "wall":Color("a3bcaa"), "accent":Color("c99069"), "tip_en":"Weave between parked carriages. Gravel is loud; blue runners are quiet.", "tip_ko":"멈춰 있는 객차 사이로 빠져나가세요. 자갈은 시끄럽고 파란 러그는 조용합니다."}
	}[id].duplicate(true)
	s.id = id
	s.subtitle = s.tip_en
	# Hand-authored four-player layouts are already dense. Compact does not cut them apart.
	s.compact_size = s.size
	return s

static func prop_centers(id: String) -> Array[Vector2]:
	if id in Nature.IDS: return Nature.layout(id).homes
	if not is_new(id): return Legacy.prop_centers(id)
	var out: Array[Vector2] = []
	for h in Plans.layout(id).hideouts: out.append(h.at)
	return out

static func name_for(id: String, ko: bool) -> String:
	if id in Nature.IDS: return Nature.spec(id).ko if ko else Nature.spec(id).title
	if is_new(id): return spec(id).ko if ko else spec(id).title
	return {"toy_home":["TOY HOUSE","장난감 집"],"warehouse":["TOY WAREHOUSE","장난감 창고"],"garden":["SECRET GARDEN","비밀 정원"]}.get(id,[id,id])[1 if ko else 0]
