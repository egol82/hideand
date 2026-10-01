extends "res://scripts/world19/studio.gd"
## Outdoor direct-light presets only. The existing manor lightmaps are untouched.
const Nature=preload("res://scripts/outdoor20/plans.gd")
var nature_stamp: Array=[]
func apply_lighting() -> void:
	super.apply_lighting()
	if not active or not world_lighting or profile==0 or game.arena.map_id not in Nature.IDS:return
	var id: String=game.arena.map_id
	var key: DirectionalLight3D=game.get_node("WarmKey");var fill: DirectionalLight3D=game.get_node("CoolSoftFill")
	key.light_color=Color("ffe2ad") if id!="reedwater_bend" else Color("f8e9bf")
	key.light_energy=0.43 if id!="amber_canyon" else 0.47
	if id=="reedwater_bend":key.light_energy=0.46
	key.rotation_degrees=Vector3(-46,-32,0) if id!="amber_canyon" else Vector3(-35,-55,0)
	fill.light_color=Color("cce1d7") if id!="reedwater_bend" else Color("bed9e4")
	fill.light_energy=0.16 if id!="reedwater_bend" else 0.19
	var env: Environment=game.environment_node.environment
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=game.arena.config.sky;env.ambient_light_energy=0.32
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env.tonemap_exposure=1.0
	env.background_mode=Environment.BG_COLOR;env.background_color=game.arena.config.sky
	nature_stamp=[]
func _process(delta: float) -> void:
	super._process(delta)
	if not active or game.arena.map_id not in Nature.IDS:return
	var layer=game.arena.get_node_or_null("OutdoorAccents")
	var world=get_parent().get_node_or_null("World19")
	if layer==null or world==null:return
	var stamp: Array=[layer.get_instance_id(),world.detail_distance,profile,converter.generation,converter.detail]
	if stamp!=nature_stamp:
		nature_stamp=stamp
		preload("res://scripts/world19/batches.gd").apply(layer,self,world.detail_distance)
		if is_instance_valid(world.status_label):world.status_label.text="야외 장식 %d개 → %d개 공간 묶음\n거리 옵션은 풀·꽃만 제어합니다. 나무·바위·갈대 엄폐는 유지됩니다.\nOutdoor direct light · no additional GI bake"%[layer.get_meta("piece_count"),layer.get_meta("batch_count")]
