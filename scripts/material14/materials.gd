extends "res://scripts/renderlab/materials.gd"
## New materials are opt-in scene-local conversions. Source resources and geometry stay immutable.
const V2=preload("res://shaders/material14/toy_v2.gdshader")
const Tiles=preload("res://scripts/material14/microtextures.gd")
const SPECS: Dictionary={
	"foam":[0.86,3.0,0.00070,0.10,0.0,0.022],
	"vinyl":[0.40,2.0,0.0,0.44,0.065,0.014],
	"wood":[0.64,1.2,0.00016,0.24,0.025,0.010],
	"fabric":[0.96,2.0,0.00120,0.07,0.0,0.085],
	"plaster":[0.93,2.2,0.00024,0.07,0.0,0.010],
	"ceramic":[0.29,2.0,0.0,0.52,0.10,0.0]
}
var generation:=2
var detail:=true
var conversions:=0
func family_of(source: StandardMaterial3D) -> String:
	var kind: String=source.get_meta("toy_family","")
	if kind.is_empty():kind="fabric" if source.roughness>0.94 else ("foam" if source.roughness>0.72 else "vinyl")
	return kind
func convert(source: StandardMaterial3D,stylized: bool,view_only: bool) -> Material:
	return convert_role(source,stylized,view_only,"surface")
func convert_role(source: StandardMaterial3D,stylized: bool,view_only: bool,role: String) -> Material:
	var kind:=family_of(source)
	if generation!=2 or not stylized:return super.convert(source,stylized,view_only)
	if kind not in SPECS or source.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or source.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED:return source
	var key:="v2/"+str(source.get_instance_id())+"/"+str(view_only)+"/"+role+"/"+str(detail)
	if cache.has(key):return cache[key]
	var values: Array=SPECS[kind]
	var m:=ShaderMaterial.new();m.shader=V2;m.resource_name="Material14/"+kind+"/"+role
	m.set_shader_parameter("tint",source.albedo_color)
	m.set_shader_parameter("family",FAMILIES.find(kind))
	m.set_shader_parameter("view_only",view_only)
	m.set_shader_parameter("character_body",role=="body")
	m.set_shader_parameter("foam_cutout",role=="cutout")
	m.set_shader_parameter("micro_tile",Tiles.texture_for(kind))
	for i in range(6):m.set_shader_parameter(["roughness","detail_scale","relief","specular_strength","coat_strength","sheen_strength"][i],values[i])
	m.set_shader_parameter("detail_amount",1.0 if detail else 0.0)
	cache[key]=m;conversions+=1
	return m
