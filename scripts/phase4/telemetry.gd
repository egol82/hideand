extends RefCounted
## Opt-in local metrics only. No names, drawings, network addresses or external transmission.
const LIMIT := 4096
var enabled := false
var events: Array[Dictionary] = []
var dropped := 0
var time := 0.0

func record(kind: String, fields: Dictionary = {}) -> void:
	if not enabled: return
	if events.size() >= LIMIT:
		dropped += 1
		return
	var row := {"t":snappedf(time,0.001),"event":kind}
	for key in ["actor","target","mode","map","outcome","round","value"]:
		if fields.has(key): row[key] = fields[key]
	events.append(row)

func export_local() -> Error:
	if not enabled: return ERR_UNAUTHORIZED
	var file := FileAccess.open("user://phase4_session.json",FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"events":events,"dropped":dropped,"format":1}))
	return file.get_error()
