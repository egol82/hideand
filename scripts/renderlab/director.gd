extends Node
## Opt-in Toy Studio presentation. Does not write gameplay transforms, states or geometry samples.
const Materials = preload("res://scripts/renderlab/materials.gd")
const Lighting = preload("res://scripts/renderlab/lighting.gd")
const Bakery = preload("res://scripts/renderlab/patisserie.gd")
const Island = preload("res://scenes/art/sugar_island.scn")
const FloorShader = preload("res://shaders/renderlab/patisserie_floor.gdshader")
const SettingsPath := "user://toy_studio_v1.cfg"
var game
var active := false
var profile := 2 # 0 previous, 1 studio with standard materials, 2 custom soft-toy materials
var converter = Materials.new()
var records: Array[Dictionary] = []
var base_environment: Environment
var canonical_environment: Environment
var base_lights: Dictionary = {}
var canonical_lights: Dictionary = {}
var last_arena := 0
var last_hand := -1
var last_preview := 0
var extras: Node3D
var old_island: Node3D
var new_island: Node3D
var ui_layer: CanvasLayer
var button: Button
var panel: PopupPanel
var options: OptionButton
var copy_label: Label
var converted_count := 0
var restore_count := 0
var needs_refresh := false

func _ready() -> void:
	game=get_parent(); call_deferred("initialize")
func initialize() -> void:
	if active or not is_instance_valid(game): return
	active=true
	if not game.synthetic_run: load_setting()
	make_ui(); refresh_world()

func _process(_delta: float) -> void:
	if not active or not is_instance_valid(game.ui): return
	var allowed: bool = game.rules.phase==game.Rules.Phase.MENU or game.paused
	button.visible=allowed
	button.text="그래픽 비교" if game.preferences.language=="ko" else "Graphics comparison"
	if not allowed and panel.visible: panel.hide()
	if is_instance_valid(game.arena) and game.arena.get_instance_id()!=last_arena: refresh_world()
	var revision: int = game.rig.rebuild_count
	var preview_id: int = game.ui.preview.get_instance_id() if is_instance_valid(game.ui.preview) else 0
	if revision!=last_hand or preview_id!=last_preview or needs_refresh:
		last_hand=revision; last_preview=preview_id; needs_refresh=false
		apply_materials(game.rig.hand_root)
		if is_instance_valid(game.ui.preview_actor): apply_materials(game.ui.preview_actor.get_parent())

func refresh_world() -> void:
	if not is_instance_valid(game.arena): return
	last_arena=game.arena.get_instance_id()
	prune()
	# A new map must start from an unmodified baseline, never from the previous profile.
	if not canonical_lights.is_empty():
		for label in canonical_lights:
			var n: DirectionalLight3D=game.get_node(label); var b: Dictionary=canonical_lights[label]
			n.transform=b.transform; n.light_energy=b.energy; n.light_color=b.color
			n.shadow_bias=b.bias; n.shadow_normal_bias=b.normal_bias; n.shadow_blur=b.blur; n.directional_shadow_max_distance=b.distance
	if canonical_environment==null: canonical_environment=game.environment_node.environment.duplicate() as Environment
	game.environment_node.environment=canonical_environment.duplicate()
	game.get_node("GraphicsDirector")._apply_map_lighting(game.arena.map_id if game.arena.has_meta("map_pack") else "")
	base_environment=game.environment_node.environment.duplicate() as Environment
	base_lights.clear()
	for name_value in ["WarmKey","CoolSoftFill"]:
		if game.has_node(name_value):
			var light: DirectionalLight3D=game.get_node(name_value)
			base_lights[name_value]={"transform":light.transform,"energy":light.light_energy,"color":light.light_color,"bias":light.shadow_bias,"normal_bias":light.shadow_normal_bias,"blur":light.shadow_blur,"distance":light.directional_shadow_max_distance}
	if canonical_lights.is_empty(): canonical_lights=base_lights.duplicate(true)
	extras=null; old_island=null; new_island=null
	if game.arena.map_id=="sugar_market":
		extras=Bakery.details(game.arena); game.arena.add_child(extras)
		old_island=game.arena.get_node_or_null("cake_island")
		if is_instance_valid(old_island):
			new_island=Island.instantiate(); new_island.position=old_island.position
			extras.add_child(new_island)
	set_profile(profile,false)

func set_profile(value: int, persist: bool=false) -> void:
	if value<0 or value>2 or not active: return
	profile=value
	prune()
	for record in records:
		var n=record.node.get_ref()
		if is_instance_valid(n): n.material_override=record.source; n.cast_shadow=record.cast
	if is_instance_valid(base_environment): game.environment_node.environment=base_environment.duplicate()
	for name_value in base_lights:
		if not game.has_node(name_value): continue
		var n: DirectionalLight3D=game.get_node(name_value); var state: Dictionary=base_lights[name_value]
		n.transform=state.transform; n.light_energy=state.energy; n.light_color=state.color
		n.shadow_bias=state.bias; n.shadow_normal_bias=state.normal_bias; n.shadow_blur=state.blur; n.directional_shadow_max_distance=state.distance
	if is_instance_valid(extras): extras.visible=profile>0
	if is_instance_valid(old_island): old_island.visible=profile==0
	Lighting.apply(game,profile>0)
	converted_count=0
	apply_materials(game.arena)
	for actor in game.fighters: apply_materials(actor)
	apply_materials(game.rig.hand_root)
	var smash=game.get_node_or_null("SmashDirector")
	if is_instance_valid(smash):
		for ghost in smash.ghosts: apply_materials(ghost.root)
	if is_instance_valid(game.ui.preview_actor): apply_materials(game.ui.preview_actor.get_parent())
	if is_instance_valid(options): options.select(profile); update_copy()
	if persist and not game.synthetic_run: save_setting()

func apply_materials(node: Node) -> void:
	if node is MeshInstance3D:
		if not node.has_meta("studio_source"):
			node.set_meta("studio_source",node.material_override)
			records.append({"node":weakref(node),"source":node.material_override,"cast":node.cast_shadow})
		# Tiny overhead decoration is not gameplay cover; avoid long needle shadows from ceiling rods.
		if profile>0 and node.position.y>4.45 and node.mesh!=null:
			var size3: Vector3=node.mesh.get_aabb().size*node.scale
			if minf(size3.x,minf(size3.y,size3.z))<0.20: node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var source: Material=node.get_meta("studio_source")
		if profile==0:
			node.material_override=source
		elif node.name=="MapFloorArt" and game.arena.map_id=="sugar_market":
			var floor_material:=ShaderMaterial.new(); floor_material.shader=FloorShader
			node.material_override=floor_material
		elif source is StandardMaterial3D:
			var base: StandardMaterial3D=source
			if node.has_meta("cutaway_roof"):
				if not node.has_meta("studio_ceiling"):
					var c:=StandardMaterial3D.new(); c.albedo_color=Color("efe4d3"); c.roughness=0.91; c.set_meta("toy_family","plaster"); node.set_meta("studio_ceiling",c)
				base=node.get_meta("studio_ceiling")
			var view_only: bool = (node.layers & (1<<19))!=0
			node.material_override=converter.convert(base,profile==2,view_only); converted_count+=1
	for child in node.get_children(): apply_materials(child)

func prune() -> void:
	var live: Array[Dictionary]=[]
	for record in records:
		if is_instance_valid(record.node.get_ref()): live.append(record)
	records=live
	# Profile conversion cache is bounded by current scene sources, not every historical map.
	if converter.cache.size()>2048: converter.cache.clear()

func make_ui() -> void:
	ui_layer=CanvasLayer.new(); ui_layer.layer=35; add_child(ui_layer)
	button=Button.new(); button.text="Graphics comparison"; button.position=Vector2(24,84); button.size=Vector2(186,36)
	button.add_theme_font_size_override("font_size",16); ui_layer.add_child(button)
	panel=PopupPanel.new(); panel.size=Vector2i(620,300); ui_layer.add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,22)
	panel.add_child(margin)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",14); margin.add_child(column)
	var heading:=Label.new(); heading.text="TOY STUDIO  /  A · B · C"; heading.add_theme_font_size_override("font_size",25); column.add_child(heading)
	options=OptionButton.new(); options.add_item("A · ORIGINAL / 이전 그래픽"); options.add_item("B · STUDIO / 기본 재질 + 장면 마감"); options.add_item("C · SOFT TOY / 전용 장난감 셰이더")
	options.custom_minimum_size=Vector2(560,46); column.add_child(options)
	copy_label=Label.new(); copy_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; copy_label.custom_minimum_size=Vector2(560,100)
	copy_label.add_theme_font_size_override("font_size",17); column.add_child(copy_label)
	var close:=Button.new(); close.text="닫기 / Close"; close.custom_minimum_size.y=36; column.add_child(close)
	button.pressed.connect(func(): update_copy(); panel.popup_centered())
	options.item_selected.connect(func(i: int): set_profile(i,true))
	close.pressed.connect(panel.hide)
func update_copy() -> void:
	var method:=RenderingServer.get_current_rendering_method()
	if game.preferences.language=="ko":
		copy_label.text="같은 맵과 카메라에서 비교합니다.\n둥근 손 · 큰 무기 · 실제 접촉 싱크는 유지됩니다.\n현재 렌더러: "+method+"\n정적 간접광 베이크는 별도 제작 도구입니다."
	else:
		copy_label.text="Compare the SAME map and camera.\nRound paws, larger weapons and contact sync stay unchanged.\nRenderer: "+method+"\nStatic GI baking is a separate authoring operation."
func save_setting() -> void:
	var cfg:=ConfigFile.new(); cfg.set_value("studio","profile",profile)
	var error:=cfg.save(SettingsPath)
	if error!=OK: push_warning("Graphics profile was not saved: "+error_string(error))
func load_setting() -> void:
	if not FileAccess.file_exists(SettingsPath): return
	var file:=FileAccess.open(SettingsPath,FileAccess.READ)
	if file==null or file.get_length()>4096: return
	file.close()
	var cfg:=ConfigFile.new()
	if cfg.load(SettingsPath)!=OK: return
	var value=cfg.get_value("studio","profile",2)
	if value is int and value>=0 and value<=2: profile=value

func _exit_tree() -> void:
	for record in records:
		var n=record.node.get_ref()
		if is_instance_valid(n) and n.has_meta("studio_source"): n.remove_meta("studio_source")
	records.clear(); converter.cache.clear(); base_environment=null; canonical_environment=null
	canonical_lights.clear(); base_lights.clear()
