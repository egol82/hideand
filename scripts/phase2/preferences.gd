extends RefCounted
const PATH := "user://preferences.cfg"
var reduced_motion := false
var volume := 0.7
var best_score := 0

func load_local() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	var motion: Variant = config.get_value("settings","reduced_motion",false)
	var level: Variant = config.get_value("settings","volume",0.7)
	var score: Variant = config.get_value("records","best_score",0)
	if motion is bool:
		reduced_motion = motion
	if (level is float or level is int) and is_finite(float(level)):
		volume = clampf(float(level),0.0,1.0)
	if score is int:
		best_score = clampi(score,0,9999)

func save_local() -> Error:
	var config := ConfigFile.new()
	config.set_value("settings","reduced_motion",reduced_motion)
	config.set_value("settings","volume",volume)
	config.set_value("records","best_score",best_score)
	return config.save(PATH)
