extends RefCounted
## Conversion is scene-local and read-only. Source materials are never modified.
const ShaderToy = preload("res://shaders/renderlab/toy_surface.gdshader")
const ShaderFloor = preload("res://shaders/renderlab/patisserie_floor.gdshader")
const FAMILIES := ["foam","vinyl","wood","fabric","plaster","ceramic"]
var cache: Dictionary = {}
func convert(source: StandardMaterial3D, stylized: bool, view_only: bool) -> Material:
	var kind: String = source.get_meta("toy_family","")
	if kind.is_empty():
		kind = "fabric" if source.roughness > 0.94 else ("foam" if source.roughness > 0.72 else "vinyl")
	if kind == "ink" or source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: return source
	var key := str(source.get_instance_id())+str(stylized)+str(view_only)
	if cache.has(key): return cache[key]
	var result: Material
	var r: float = {"foam":0.79,"vinyl":0.43,"wood":0.67,"fabric":0.93,"plaster":0.91,"ceramic":0.30}.get(kind,0.7)
	if stylized:
		var m := ShaderMaterial.new(); m.shader = ShaderToy
		m.set_shader_parameter("tint",source.albedo_color)
		m.set_shader_parameter("roughness",r)
		m.set_shader_parameter("family",maxi(0,FAMILIES.find(kind)))
		m.set_shader_parameter("view_only",view_only)
		result = m
	else:
		var m := source.duplicate() as StandardMaterial3D
		m.roughness = r; m.normal_scale *= 0.40
		m.metallic_specular = 0.34 if kind in ["vinyl","ceramic"] else 0.23
		m.disable_receive_shadows = view_only
		result = m
	result.resource_name = "ToyStudio/"+kind
	cache[key] = result
	return result
