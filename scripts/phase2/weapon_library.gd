extends RefCounted
const Data = preload("res://scripts/phase2/drawing_data.gd")
const SLOTS := 8
const DIRECTORY := "user://weapon_library"
const BYTE_LIMIT := 65536

static func save_slot(data, slot: int) -> Error:
	if slot < 0 or slot >= SLOTS or not data.is_valid():
		return ERR_INVALID_PARAMETER
	var copy = Data.new()
	if not copy.load_dictionary(data.to_dictionary()):
		return ERR_INVALID_DATA
	var directory := ProjectSettings.globalize_path(DIRECTORY)
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return error
	var path := directory.path_join("%d.json" % slot)
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(copy.to_dictionary()))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	return DirAccess.rename_absolute(path+".tmp",path)

static func load_slot(slot: int):
	if slot < 0 or slot >= SLOTS:
		return null
	var path := DIRECTORY.path_join("%d.json" % slot)
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > BYTE_LIMIT:
		return null
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if not raw is Dictionary:
		return null
	var data = Data.new()
	if not data.load_dictionary(raw) or not data.is_valid():
		return null
	return data
