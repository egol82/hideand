extends SceneTree
const Scene = preload("res://scenes/phase6.tscn")
const BaseGame = preload("res://scripts/phase4/game.gd")
const Data = preload("res://scripts/phase4/drawing_data.gd")
const Form = preload("res://scripts/phase4/weapon_form.gd")
const WeaponSkin = preload("res://scripts/graphics/weapon_skin.gd")
const Surface = preload("res://scripts/graphics/surfaces.gd")
const Art = preload("res://scripts/phase4/art.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print(("PASS: " if value else "FAIL: ")+label)
func physics_count(node: Node) -> int:
	var n := 1 if node is CollisionObject3D else 0
	for child in node.get_children(): n += physics_count(child)
	return n
func mesh_finite(node: Node) -> bool:
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var vertices: PackedVector3Array = node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			if vertices.size() > 100000: return false
			for v in vertices:
				if not v.is_finite(): return false
	for c in node.get_children():
		if not mesh_finite(c): return false
	return true
func fingerprint(arena) -> Dictionary:
	var cells: Array = []
	for x in range(arena.grid_size.x):
		for y in range(arena.grid_size.y): cells.append(arena.navigation.is_point_solid(Vector2i(x,y)))
	return {"size":arena.dimensions,"active":arena.active_rect,"spots":arena.spots.duplicate(),"ids":arena.active_spots.duplicate(),"obstacles":arena.obstacles.duplicate(),"cells":cells,"physics":physics_count(arena)}
func run() -> void:
	for kind in ["foam","fabric","wood","plaster","vinyl"]:
		var m := Surface.make(Color("9ec7bd"),kind)
		check(m == Surface.make(Color("9ec7bd"),kind),kind+" material cache")
		check(m.roughness >= 0 and m.roughness <= 1,kind+" bounded roughness")
		if kind != "vinyl":
			check(m.normal_texture.get_size() == Vector2(128,128),kind+" normal tile dimensions")
			check(m.normal_texture.get_image().has_mipmaps(),kind+" normal mipmaps")
	check(Surface.make(Color.WHITE,"foam") != Surface.make(Color.WHITE,"vinyl"),"material families remain distinct")
	for kind in ["hammer","fish","pan"]:
		var data = Data.new(); data.set_preset(kind)
		var original: Dictionary = data.to_dictionary()
		var samples: PackedVector3Array = Form.samples(data)
		var node := Form.build(data)
		check(mesh_finite(node),kind+" finite bounded render mesh")
		check(data.to_dictionary() == original,kind+" original vector drawing untouched")
		check(Form.samples(data) == samples,kind+" collision samples unaffected by rendering")
		check(node.mesh.get_aabb().size.y < 0.15,kind+" radial depth budget preserved")
		check(physics_count(node) == 0,kind+" skin creates no physics")
		node.free()
	var empty = Data.new(); var empty_mesh := Form.build(empty)
	check(empty_mesh.mesh == null,"empty drawing has no invented mesh"); empty_mesh.free()
	var thin := PackedVector2Array([Vector2(0.1,0.1),Vector2(0.11,0.1),Vector2(0.11,0.8),Vector2(0.1,0.8)])
	check(WeaponSkin.inset(thin,0.02).is_empty(),"collapsed inset safely falls back")
	var baseline = BaseGame.new(); root.add_child(baseline); baseline.automated = true
	await process_frame
	var expected: Dictionary = {}
	for id in ["toy_home","warehouse","garden"]:
		baseline.select_map(id); await process_frame
		expected[id] = fingerprint(baseline.arena)
	baseline.queue_free(); await process_frame
	var game = Scene.instantiate(); root.add_child(game); game.automated = true
	await process_frame; await process_frame
	var director = game.get_node("GraphicsDirector")
	check(director.active,"graphics component attached to actual default entry")
	check(game.get_node("WarmKey").shadow_caster_mask == 1,"camera-hidden authority excluded from shadow casting")
	for id in ["toy_home","warehouse","garden"]:
		game.select_map(id); await process_frame; await process_frame
		var result := fingerprint(game.arena)
		for field in expected[id].keys(): check(result[field] == expected[id][field],id+" unchanged "+field)
		check(game.arena.has_node("VisualDressing"),id+" visuals restored after map switch")
		check(physics_count(game.arena.get_node("VisualDressing")) == 0,id+" visual dressing never becomes gameplay collision")
		var count: int = game.arena.get_child_count(); director.refresh_arena()
		check(game.arena.get_child_count() == count,id+" idempotent dressing")
	game.start_practice(); await process_frame; await process_frame
	check(game.ui.preview.has_node("Node3D/WarmKey") or director.last_preview != 0,"preview stage registered")
	var count: int = game.ui.preview_actor.get_parent().get_child_count()
	director.refresh_ui()
	check(game.ui.preview_actor.get_parent().get_child_count() == count,"preview decorations are not duplicated")
	check(game.ui.preview.msaa_3d == Viewport.MSAA_4X,"turntable uses antialiased rendering")
	game.accept_drawing(); game._process(1.0/60)
	await process_frame; await process_frame
	director.shade_view()
	check(game.rig.view_weapon.material_override.disable_receive_shadows,"view weapon avoids detached authority shadow artefacts")
	check(not game.fighters[0].weapon.material_override.disable_receive_shadows,"world weapon keeps ordinary shadow receiving")
	check(game.rig.view_weapon.material_override != game.fighters[0].weapon.material_override,"view material copy isolated")
	var actor = game.fighters[1]
	check(actor.visual.has_node("ArtContactShadow"),"actor has grounding helper")
	actor.visual.visible = false
	check(not actor.visual.get_node("ArtContactShadow").is_visible_in_tree(),"hidden actor cannot leak its contact shadow")
	actor.visual.visible = true
	var before: Dictionary = game.fighters[0].weapon_data.to_dictionary()
	game.fighters[0].take_hit(Vector3.BACK)
	for n in range(90): game.fighters[0].step(1.0/60,Vector3.ZERO,Vector3.FORWARD)
	check(game.fighters[0].weapon.global_basis.get_scale().is_equal_approx(Vector3.ONE),"cosmetic changes cannot scale world weapon")
	check(game.fighters[0].weapon_data.to_dictionary() == before,"hit reaction does not rewrite drawing")
	game.queue_free(); await process_frame
	print("GRAPHICS_UNIT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
