extends RefCounted
## Studio lighting presets, not a baked/global-illumination claim.
static func apply(game, studio: bool) -> void:
	var env: Environment = game.environment_node.environment
	if not studio: return
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dae5e4")
	env.ambient_light_energy = 0.34
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	if game.has_node("WarmKey"):
		var key: DirectionalLight3D = game.get_node("WarmKey")
		key.light_color = Color("ffe9cf"); key.light_energy = 0.35
		key.rotation_degrees = Vector3(-48,-24,0)
		key.directional_shadow_max_distance = 50 if game.arena.map_id=="sugar_market" else 90
		key.shadow_bias=0.022; key.shadow_normal_bias=1.0; key.shadow_blur=2.0
	if game.has_node("CoolSoftFill"):
		game.get_node("CoolSoftFill").light_energy = 0.17
		game.get_node("CoolSoftFill").light_color = Color("dfe3d7")
		game.get_node("CoolSoftFill").rotation_degrees = Vector3(32,147,0)
	if game.arena.map_id == "starlight_arcade":
		env.ambient_light_color = Color("c6d3ed")
		env.ambient_light_energy = 0.34
	elif game.arena.map_id == "pocket_station":
		env.ambient_light_energy = 0.34
	var method := RenderingServer.get_current_rendering_method()
	# Do not advertise unsupported Compatibility features as active.
	if method == "forward_plus":
		env.ssao_enabled = true; env.ssao_radius=0.65; env.ssao_intensity=0.60
		env.ssao_light_affect=0.15
		env.glow_enabled = true; env.glow_intensity=0.35
