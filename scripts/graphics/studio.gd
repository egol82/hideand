@tool
extends RefCounted
## Explicit art lighting, not a LightmapGI bake. Existing GL renderer is retained.
const Shadow = preload("res://shaders/contact_shadow.gdshader")
static var shadow_material: ShaderMaterial
static func environment() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var s := ProceduralSkyMaterial.new()
	s.sky_top_color = Color("86b5ca")
	s.sky_horizon_color = Color("dfe9dc")
	s.ground_bottom_color = Color("85765e")
	s.ground_horizon_color = Color("dfe9dc")
	s.sky_energy_multiplier = 0.42
	s.ground_energy_multiplier = 0.28
	sky.sky_material = s
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("e1e7e0")
	e.ambient_light_energy = 0.30
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	return e
static func key_lights(parent: Node3D, preview: bool = false) -> void:
	var key := DirectionalLight3D.new()
	key.name = "WarmKey"
	key.rotation_degrees = Vector3(-54,-32,0)
	key.light_color = Color("ffe3bd")
	key.light_energy = 0.46 if preview else 0.41
	key.shadow_enabled = true
	# Layer 19 is the camera-hidden subject; layer 20 is its cosmetic hand/weapon.
	# Neither should project invisible enlarged silhouettes onto the view model.
	key.shadow_caster_mask = 1
	key.shadow_blur = 3.0
	key.shadow_bias = 0.045
	key.directional_shadow_max_distance = 14 if preview else 90
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key.directional_shadow_blend_splits = true
	parent.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "CoolSoftFill"
	fill.rotation_degrees = Vector3(-28,147,0)
	fill.light_color = Color("c6e2e3")
	fill.light_energy = 0.16
	parent.add_child(fill)
static func contact(parent: Node3D, at: Vector3, size2: Vector2) -> MeshInstance3D:
	if shadow_material == null:
		shadow_material = ShaderMaterial.new()
		shadow_material.shader = Shadow
	var n := MeshInstance3D.new()
	n.name = "ArtContactShadow"
	var plane := PlaneMesh.new()
	plane.size = size2
	n.mesh = plane
	n.position = at
	n.material_override = shadow_material
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.set_meta("cosmetic_only",true)
	parent.add_child(n)
	return n
