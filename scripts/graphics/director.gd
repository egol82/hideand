extends Node
## Presentation component: no rule/input/timer/score/physics writes.
const Studio = preload("res://scripts/graphics/studio.gd")
const Dressing = preload("res://scripts/graphics/dressing.gd")
const Art = preload("res://scripts/phase4/art.gd")
var game
var last_arena := 0
var last_preview := 0
var active := false

func _ready() -> void:
	game = get_parent()
	call_deferred("initialize")

func initialize() -> void:
	if not is_instance_valid(game) or active: return
	active = true
	game.environment_node.environment = Studio.environment()
	for node in game.get_children():
		if node is DirectionalLight3D:
			game.remove_child(node); node.queue_free()
	Studio.key_lights(game)
	for actor in game.fighters:
		# Hidden players' entire FacingRoot becomes invisible, including this decal-like plane.
		Studio.contact(actor.visual,Vector3(0,0.098,0),Vector2(1.30,0.92))
	game.child_entered_tree.connect(func(_node: Node): call_deferred("refresh_arena"))
	game.ui.modal.child_entered_tree.connect(func(_node: Node): call_deferred("refresh_ui"))
	game.rig.hand_root.child_entered_tree.connect(func(_node: Node): call_deferred("shade_view"))
	refresh_arena()
	refresh_ui()
	shade_view()

func refresh_arena() -> void:
	if not active or not is_instance_valid(game.arena): return
	if game.arena.get_instance_id() == last_arena: return
	last_arena = game.arena.get_instance_id()
	if game.arena.has_meta("map_pack"):
		_apply_map_lighting(game.arena.map_id)
	else:
		_apply_map_lighting("")
		Dressing.apply(game.arena)

func refresh_ui() -> void:
	if not active or not is_instance_valid(game.ui): return
	style_controls(game.ui.modal)
	if not is_instance_valid(game.ui.preview): return
	var preview: SubViewport = game.ui.preview
	if preview.get_instance_id() == last_preview: return
	last_preview = preview.get_instance_id()
	preview.msaa_3d = Viewport.MSAA_4X
	var stage: Node3D = game.ui.preview_actor.get_parent()
	for n in stage.get_children():
		if n is Light3D: stage.remove_child(n); n.queue_free()
		elif n is WorldEnvironment: n.environment = Studio.environment()
	Studio.key_lights(stage,true)
	Art.box(stage,Vector3(0,-0.11,0),Vector3(3.6,0.17,3.1),Color("809f97"),"wood",0.07)
	Studio.contact(stage,Vector3(0,-0.014,0),Vector2(1.7,1.3))

func style_controls(root: Node) -> void:
	if not root.has_meta("phase6_styled") and (root is PanelContainer or root is Button):
		root.set_meta("phase6_styled",true)
		var names: Array = ["panel"] if root is PanelContainer else ["normal","hover","pressed"]
		for state in names:
			var current = root.get_theme_stylebox(state)
			if not current is StyleBoxFlat: continue
			var style := current.duplicate() as StyleBoxFlat
			style.border_color = style.bg_color.lightened(0.13)
			style.set_border_width_all(1)
			style.shadow_color = Color(0.025,0.075,0.08,0.18)
			style.shadow_size = 5 if state != "pressed" else 0
			style.shadow_offset = Vector2(0,3)
			root.add_theme_stylebox_override(state,style)
	for child in root.get_children(): style_controls(child)

func shade_view() -> void:
	if not active or not is_instance_valid(game.rig): return
	shade_node(game.rig.hand_root)

func shade_node(node: Node) -> void:
	if node is MeshInstance3D and not node.has_meta("view_shaded"):
		if node.material_override is StandardMaterial3D:
			var material := node.material_override.duplicate() as StandardMaterial3D
			# Cosmetic view geometry cannot receive shadows from its detached authority copy.
			# Same albedo, normals and world lights; world/other-player materials stay untouched.
			material.disable_receive_shadows = true
			node.material_override = material
			node.set_meta("view_shaded",true)
	for child in node.get_children(): shade_node(child)

func _apply_map_lighting(id: String) -> void:
	# Keep readable exposure in the arcade, not a pitch-black competitive advantage.
	var e: Environment = game.environment_node.environment
	e.ambient_light_color = Color("e1e7e0")
	e.ambient_light_energy = 0.30
	var sky_mat := e.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_energy_multiplier = 0.42
	sky_mat.sun_angle_max = 30.0
	sky_mat.sky_top_color = Color("86b5ca")
	sky_mat.sky_horizon_color = Color("dfe9dc")
	if id=="starlight_arcade":
		e.ambient_light_color = Color("c7d9e2")
		e.ambient_light_energy = 0.34
	elif id=="sugar_market":
		e.ambient_light_color = Color("eee1d0")
	elif id=="pocket_station":
		e.ambient_light_color = Color("d6e4db")
		sky_mat.sky_energy_multiplier = 0.92
		sky_mat.sun_angle_max = 0.0
		sky_mat.sky_top_color = Color("8bc4da")
		sky_mat.sky_horizon_color = Color("e0eddc")
	game.environment_node.environment = e
	if game.has_node("WarmKey"):
		game.get_node("WarmKey").light_energy = 0.33 if id=="starlight_arcade" else 0.41
		game.get_node("WarmKey").light_color = Color("dedcec") if id=="starlight_arcade" else Color("ffe3bd")
