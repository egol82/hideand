extends "res://scripts/phase2/preferences.gd"
var mouse_sensitivity := 0.0025
var vertical_fov := 72.0
var invert_y := false
var map_id := "toy_home"

func load_local() -> void:
	super.load_local()
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	var s: Variant = c.get_value("fps","sensitivity",0.0025)
	var f: Variant = c.get_value("fps","fov",72.0)
	if (s is float or s is int) and is_finite(float(s)):
		mouse_sensitivity = clampf(float(s),0.0005,0.008)
	if (f is float or f is int) and is_finite(float(f)):
		vertical_fov = clampf(float(f),55.0,90.0)
	var inverted: Variant = c.get_value("fps","invert_y",false)
	invert_y = inverted if inverted is bool else false
	var saved: Variant = c.get_value("fps","map","toy_home")
	if saved in ["toy_home","warehouse","garden"]:
		map_id = saved

func save_local() -> Error:
	var result := super.save_local()
	if result != OK:
		return result
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("fps","sensitivity",mouse_sensitivity)
	c.set_value("fps","fov",vertical_fov)
	c.set_value("fps","invert_y",invert_y)
	c.set_value("fps","map",map_id)
	return c.save(PATH)
