extends RefCounted
const Data4 = preload("res://scripts/phase4/drawing_data.gd")
const Store = preload("res://scripts/quality/safe_store.gd")
const SLOTS := 8
const DIRECTORY := "user://phase5_toys"
const LEGACY := "user://phase4_toys"
const BYTE_LIMIT := 65536

static func validate(payload: Dictionary) -> bool:
	if payload.get("version") != 1 or not payload.get("toy") is Dictionary: return false
	var data = Data4.new()
	return data.load_dictionary(payload.toy) and data.is_valid()

static func save_slot(data, slot: int, directory: String = DIRECTORY) -> Error:
	if slot < 0 or slot >= SLOTS or data == null: return ERR_INVALID_PARAMETER
	return Store.save_value(directory.path_join("%d.json" % slot),{"version":1,"toy":data.to_dictionary()},validate)

static func read_slot(slot: int, directory: String = DIRECTORY) -> Dictionary:
	if slot < 0 or slot >= SLOTS: return {"data":null,"source":"invalid"}
	var result := Store.load_value(directory.path_join("%d.json" % slot),validate)
	if result.ok:
		var data = Data4.new()
		data.load_dictionary(result.data.toy)
		return {"data":data,"source":result.source}
	# Old slots remain read-only. A corrupt new slot must not silently load stale legacy data.
	var path := directory.path_join("%d.json" % slot)
	if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak"):
		return {"data":null,"source":"invalid"}
	if directory != DIRECTORY: return {"data":null,"source":"empty"}
	var file := FileAccess.open(LEGACY.path_join("%d.json" % slot),FileAccess.READ)
	if file == null: return {"data":null,"source":"empty"}
	if file.get_length() > BYTE_LIMIT: return {"data":null,"source":"invalid"}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK: return {"data":null,"source":"invalid"}
	var raw: Variant = parser.data
	var data = Data4.new()
	if raw is Dictionary and data.load_dictionary(raw) and data.is_valid(): return {"data":data,"source":"legacy"}
	return {"data":null,"source":"invalid"}

static func load_slot(slot: int):
	return read_slot(slot).data
