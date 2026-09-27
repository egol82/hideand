extends RefCounted
const Data4 = preload("res://scripts/phase4/drawing_data.gd")
const SLOTS := 8
const DIRECTORY := "user://phase4_toys"
const BYTE_LIMIT := 65536

static func save_slot(data, slot: int) -> Error:
	if slot < 0 or slot >= SLOTS or not data.is_valid(): return ERR_INVALID_PARAMETER
	var copy = Data4.new()
	if not copy.load_dictionary(data.to_dictionary()): return ERR_INVALID_DATA
	var raw := JSON.stringify(copy.to_dictionary())
	if raw.to_utf8_buffer().size() > BYTE_LIMIT: return ERR_INVALID_DATA
	var path := ProjectSettings.globalize_path(DIRECTORY)
	var error := DirAccess.make_dir_recursive_absolute(path)
	if error != OK: return error
	path = path.path_join("%d.json" % slot)
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(raw)
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK: return error
	return DirAccess.rename_absolute(path+".tmp",path)

static func load_slot(slot: int):
	if slot < 0 or slot >= SLOTS: return null
	var file := FileAccess.open(DIRECTORY.path_join("%d.json" % slot),FileAccess.READ)
	if file == null or file.get_length() > BYTE_LIMIT: return null
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if not raw is Dictionary: return null
	var data = Data4.new()
	return data if data.load_dictionary(raw) and data.is_valid() else null
