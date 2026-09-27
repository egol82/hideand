extends RefCounted
## One bounded generation file instead of rewriting three nested ConfigFiles per slider tick.
const Store = preload("res://scripts/quality/safe_store.gd")
const PATH5 := "user://phase5/settings.json"
const BOOLS := ["reduced_motion","invert_y","compact","sound_cues","recording"]
const RANGES := {"volume":Vector2(0,1),"mouse_sensitivity":Vector2(0.0005,0.008),"vertical_fov":Vector2(55,90),"hand_sway":Vector2(0,1),"head_bob":Vector2(0,1),"feedback_strength":Vector2(0,1)}
var reduced_motion := false
var volume := 0.7
var best_score := 0
var mouse_sensitivity := 0.0025
var vertical_fov := 72.0
var invert_y := false
var map_id := "toy_home"
var mode := "field"
var compact := true
var hand_sway := 0.65
var head_bob := 0.35
var feedback_strength := 0.65
var sound_cues := true
var recording := false
var language := "en"
var load_source := "default"

static func validate(data: Dictionary) -> bool:
	var keys: Array = ["version","mode","map_id","language","best_score"]+BOOLS+RANGES.keys()
	if data.size() != keys.size(): return false
	for key in data:
		if key not in keys: return false
	if data.get("version") != 1 or data.get("mode") not in ["field","classic"] or data.get("map_id") not in ["toy_home","warehouse","garden"] or data.get("language") not in ["en","ko"]: return false
	for key in BOOLS:
		if not data.get(key) is bool: return false
	for key in RANGES:
		var v: Variant = data.get(key)
		if not (v is float or v is int) or not is_finite(float(v)) or v < RANGES[key].x or v > RANGES[key].y: return false
	var score: Variant = data.get("best_score")
	return (score is float or score is int) and is_finite(float(score)) and score == floor(score) and score >= 0 and score <= 9999

func payload() -> Dictionary:
	var data := {"version":1,"mode":mode,"map_id":map_id,"language":language,"best_score":best_score}
	for key in BOOLS+RANGES.keys(): data[key] = get(key)
	return data

func load_local(path: String = PATH5) -> void:
	language = "ko" if OS.get_locale_language() == "ko" else "en"
	var result := Store.load_value(path,validate)
	if result.ok:
		load_source = result.source
		for key in result.data:
			if key != "version": set(key,result.data[key])
	elif path == PATH5:
		_import_legacy()

func save_local(path: String = PATH5) -> Error:
	return Store.save_value(path,payload(),validate)

func _import_legacy() -> void:
	var mapping := {"preferences.cfg":{"settings":{"reduced_motion":"reduced_motion","volume":"volume"},"records":{"best_score":"best_score"},"fps":{"sensitivity":"mouse_sensitivity","fov":"vertical_fov","invert_y":"invert_y","map":"map_id"}},"phase4_settings.cfg":{"play":{"mode":"mode","compact":"compact","sound_cues":"sound_cues","recording":"recording"},"comfort":{"hand_sway":"hand_sway","head_bob":"head_bob","feedback_strength":"feedback_strength"}}}
	var candidate := payload()
	for filename in mapping:
		var file := FileAccess.open("user://"+filename,FileAccess.READ)
		if file == null or file.get_length() > 32768: continue
		var config := ConfigFile.new()
		var error := config.parse(file.get_as_text())
		file.close()
		if error != OK: continue
		for section in mapping[filename]:
			for key in mapping[filename][section]:
				var name: String = mapping[filename][section][key]
				var trial := candidate.duplicate()
				trial[name] = config.get_value(section,key,candidate[name])
				if validate(trial): candidate = trial
	for key in candidate:
		if key != "version": set(key,candidate[key])
	load_source = "legacy"
