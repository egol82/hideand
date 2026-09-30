extends "res://scripts/lighting15/director.gd"
## Shared character/shader/IK/VFX already spans the maps; this adds measured lighting art presets.
var world_lighting:=true
const THEMES:={
"sugar_market":[Color("ffe3ba"),1.02,Color("d4e8e4"),0.40,0.30,Vector3(-48,-24,0)],
"starlight_arcade":[Color("d9e5ff"),0.88,Color("e9cadf"),0.42,0.34,Vector3(-60,-12,0)],
"pocket_station":[Color("ffe0ac"),1.10,Color("c9e7ee"),0.37,0.29,Vector3(-43,-32,0)],
"toy_home":[Color("ffe0b6"),1.02,Color("d1e2e0"),0.40,0.29,Vector3(-50,-26,0)],
"warehouse":[Color("e1edee"),1.00,Color("f0dec2"),0.37,0.31,Vector3(-67,-10,0)],
"garden":[Color("ffe3b1"),1.15,Color("c5e0dc"),0.35,0.29,Vector3(-44,-35,0)]}
func apply_lighting() -> void:
	super.apply_lighting()
	if not active or not world_lighting or profile==0:return
	var id: String=game.arena.map_id
	if not THEMES.has(id):return
	var p: Array=THEMES[id]
	var key: DirectionalLight3D=game.get_node("WarmKey")
	var fill: DirectionalLight3D=game.get_node("CoolSoftFill")
	key.light_color=p[0];key.light_energy=p[1]*0.40;key.rotation_degrees=p[5]
	fill.light_color=p[2];fill.light_energy=p[3]*0.48
	var env: Environment=game.environment_node.environment
	env.ambient_light_color=p[2];env.ambient_light_energy=p[4]
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env.tonemap_white=4.0;env.tonemap_exposure=1.0
