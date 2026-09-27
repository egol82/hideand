extends RefCounted
## Crash-recoverable, bounded local JSON with one previous valid generation.
## Integrity digest detects accidental damage, NOT proof against malicious edits.
const LIMIT := 65536

static func _allowed(path: String) -> bool:
	return path.begins_with("user://") and not ".." in path and not "\\" in path and path.ends_with(".json")

static func _read(path: String, validator: Callable) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > LIMIT or file.get_length() < 2: return {}
	var parser := JSON.new()
	var parsed := parser.parse(file.get_as_text())
	file.close()
	if parsed != OK: return {}
	var raw: Variant = parser.data
	if not raw is Dictionary or raw.get("schema") != 1 or not raw.get("payload") is Dictionary or not raw.get("digest") is String: return {}
	var payload: Dictionary = raw.payload
	if JSON.stringify(payload,"",true).sha256_text() != raw.digest: return {}
	if validator.is_valid() and not validator.call(payload): return {}
	return payload

static func load_value(path: String, validator: Callable = Callable()) -> Dictionary:
	if not _allowed(path): return {"ok":false,"source":"invalid_path","data":{}}
	for suffix in ["",".bak"]:
		var payload := _read(path+suffix,validator)
		if not payload.is_empty(): return {"ok":true,"source":"current" if suffix.is_empty() else "backup","data":payload}
	return {"ok":false,"source":"missing_or_invalid","data":{}}

static func save_value(path: String, payload: Dictionary, validator: Callable = Callable()) -> Error:
	if not _allowed(path) or payload.is_empty(): return ERR_INVALID_PARAMETER
	if validator.is_valid() and not validator.call(payload): return ERR_INVALID_DATA
	# JSON parses numbers as floats. Hash the same canonical numeric representation on both sides.
	var normalized: Variant = JSON.parse_string(JSON.stringify(payload,"",true))
	if not normalized is Dictionary: return ERR_INVALID_DATA
	var encoded := JSON.stringify({"schema":1,"payload":normalized,"digest":JSON.stringify(normalized,"",true).sha256_text()},"",true)
	if encoded.to_utf8_buffer().size() > LIMIT: return ERR_INVALID_DATA
	var folder := ProjectSettings.globalize_path(path.get_base_dir())
	var error := DirAccess.make_dir_recursive_absolute(folder)
	if error != OK: return error
	var temp := path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(encoded)
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK: return error
	if _read(temp,validator).is_empty(): return ERR_FILE_CORRUPT
	# Never rotate corrupt current bytes over the last known-good backup.
	if FileAccess.file_exists(path):
		if not _read(path,validator).is_empty():
			if FileAccess.file_exists(path+".bak"):
				error = DirAccess.remove_absolute(path+".bak")
				if error != OK: return error
			error = DirAccess.rename_absolute(path,path+".bak")
		else:
			error = DirAccess.remove_absolute(path)
		if error != OK: return error
	error = DirAccess.rename_absolute(temp,path)
	# If promotion fails the previous valid generation still loads from .bak.
	return error
