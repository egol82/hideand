extends "res://scripts/phase3/preferences.gd"
const PATH4 := "user://phase4_settings.cfg"
var mode := "field"
var compact := true
var hand_sway := 0.65
var head_bob := 0.35
var feedback_strength := 0.65
var sound_cues := true
var recording := false

func load_local() -> void:
	super.load_local()
	var c := ConfigFile.new()
	if c.load(PATH4) != OK:
		return
	var m: Variant = c.get_value("play","mode","field")
	mode = m if m is String and m in ["field","classic"] else "field"
	for key in ["compact","sound_cues","recording"]:
		var v: Variant = c.get_value("play",key,get(key))
		if v is bool: set(key,v)
	for key in ["hand_sway","head_bob","feedback_strength"]:
		var v: Variant = c.get_value("comfort",key,get(key))
		if (v is float or v is int) and is_finite(float(v)): set(key,clampf(float(v),0,1))

func save_local() -> Error:
	var result := super.save_local()
	if result != OK: return result
	var c := ConfigFile.new()
	c.set_value("play","mode",mode)
	for key in ["compact","sound_cues","recording"]: c.set_value("play",key,get(key))
	for key in ["hand_sway","head_bob","feedback_strength"]: c.set_value("comfort",key,get(key))
	return c.save(PATH4)
