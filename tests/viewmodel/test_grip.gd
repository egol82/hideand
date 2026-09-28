extends SceneTree
const Scene = preload("res://scenes/phase8.tscn")
const Fit = preload("res://scripts/viewmodel/grip_fit.gd")
const Data = preload("res://scripts/phase4/drawing_data.gd")
const Form = preload("res://scripts/phase4/weapon_form.gd")
const Attack = preload("res://scripts/phase4/attack_spec.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print(("PASS: " if value else "FAIL: ")+label)
func drawing(kind: String):
	var d = Data.new()
	if kind in ["fish","pan","hammer"]: d.set_preset(kind)
	else:
		d.grip = Vector2(0.5,0.88)
		if kind == "staff": d.strokes.append(PackedVector2Array([d.grip,Vector2(0.5,0.08)]))
		elif kind == "sideways": d.strokes.append(PackedVector2Array([d.grip,Vector2(0.95,0.88)]))
		elif kind == "tiny": d.strokes.append(PackedVector2Array([d.grip,Vector2(0.5,0.85)]))
		elif kind == "split":
			d.strokes.append(PackedVector2Array([d.grip,Vector2(0.5,0.77)]))
			d.strokes.append(PackedVector2Array([Vector2(0.5,0.4),Vector2(0.5,0.08)]))
		elif kind == "reversed":
			d.grip = Vector2(0.5,0.1); d.strokes.append(PackedVector2Array([d.grip,Vector2(0.5,0.9)]))
	return d
func node_count(node: Node) -> int:
	var total := 1
	for child in node.get_children(): total += node_count(child)
	return total
func physical_count(node: Node) -> int:
	var total := 1 if node is CollisionObject3D else 0
	for child in node.get_children(): total += physical_count(child)
	return total
func safe_meshes(node: Node) -> bool:
	if node is MeshInstance3D:
		if node.layers != (1<<19): return false
		if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: return false
		if node.mesh == null: return false
		for surface in range(node.mesh.get_surface_count()):
			var a: Array = node.mesh.surface_get_arrays(surface)
			if a[Mesh.ARRAY_VERTEX].size() > 50000: return false
			for v in a[Mesh.ARRAY_VERTEX]:
				if not v.is_finite(): return false
	for child in node.get_children():
		if not safe_meshes(child): return false
	return true
func run() -> void:
	var game = Scene.instantiate(); root.add_child(game); game.automated = true
	await process_frame; await process_frame
	game.start_practice(); game.accept_drawing()
	var actor = game.fighters[0]; var rig = game.rig
	for kind in ["fish","pan","hammer","staff","sideways","tiny","split","reversed"]:
		var d = drawing(kind)
		var original: Dictionary = d.to_dictionary()
		actor.equip(d); rig.follow(actor,1.0/60,false,true)
		await process_frame
		game.get_node("GraphicsDirector").shade_view()
		var grip = rig.grip_rig; var fit: Dictionary = grip.fit
		check(fit.valid,kind+" fitted to real drawing")
		check(fit.basis.determinant() > 0.99 and fit.basis.is_finite(),kind+" orthonormal positive frame")
		check(fit.anchor.length() < 0.0001,kind+" selected grip anchors actual stroke")
		check(d.to_dictionary() == original and actor.weapon_data.to_dictionary() == original,kind+" original data unchanged")
		check(Form.samples(d) == actor.hit_samples,kind+" authority samples unchanged")
		check(physical_count(grip) == 0,kind+" no physics added by hand geometry")
		check(safe_meshes(grip),kind+" bounded finite meshes, isolated view layer, no shadow caster")
		check(grip.right_hand.has_node("Thumb") and grip.right_hand.has_node("Finger3"),kind+" wrapped fingers and opposing thumb")
		check(grip.right_hand.position.is_equal_approx(fit.main),kind+" right palm remains at solved contact")
		check(grip.left_arm.position.distance_to(grip.right_arm.position) > 0.02,kind+" forearms have separate wrist origins")
		check(actor.weapon.global_basis.get_scale().is_equal_approx(Vector3.ONE),kind+" world weapon remains unit scale")
		if kind == "staff": check(fit.mode == "shaft", "long connected staff supports two hands on its shaft")
		if kind in ["fish","split"]: check(fit.mode != "shaft",kind+" no lower phantom handle")
		if kind == "tiny": check(fit.mode == "pinch","tiny drawing uses compact grip")
		var before_count := node_count(rig.hand_root); var rebuilds: int = rig.rebuild_count
		var main: Vector3 = grip.right_hand.position
		var support: Vector3 = grip.left_hand.position
		for style in Attack.IDS:
			actor.handling = style
			for rate in [30,60,120]:
				for step in range(rate):
					actor.elapsed = Attack.duration(style)*step/rate
					rig.follow(actor,1.0/rate,false,true)
				check(grip.right_hand.position.is_equal_approx(main) and grip.left_hand.position.is_equal_approx(support),kind+" "+style+" contacts stable "+str(rate))
		check(node_count(rig.hand_root) == before_count and rig.rebuild_count == rebuilds,kind+" animation creates no nodes/meshes or rebuilds")
		actor.cancel_attack()
	var empty = Data.new()
	check(not Fit.solve(empty,Basis.IDENTITY,0.27).valid,"empty drawing does not invent a grip")
	var palette = drawing("fish"); actor.equip(palette); rig.follow(actor,1.0/60,false,true)
	var outline_before: Dictionary = actor.weapon_data.to_dictionary()
	var samples_before: PackedVector3Array = actor.hit_samples.duplicate()
	var authority_before: Transform3D = actor.weapon.global_transform
	var clocks_before: float = game.rules.time_left
	for reduced in [true,false]:
		rig.reduced_motion = reduced
		for feedback in ["hit","hurt","blocked","miss"]:
			rig.feedback(feedback)
			for i in range(30): rig.follow(actor,1.0/60,false,true)
		check(actor.weapon.global_transform.is_equal_approx(authority_before),"comfort and feedback never transform world weapon "+str(reduced))
	check(actor.weapon_data.to_dictionary() == outline_before and actor.hit_samples == samples_before,"feedback never mutates weapon shape/samples")
	check(game.rules.time_left == clocks_before,"cosmetic update never changes game clock")
	check(physical_count(rig) == 0,"entire first-person rig is cosmetic")
	for id in ["toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu(); game.select_map(id); game.start_practice(); game.accept_drawing()
		game._process(1.0/60); await process_frame; await process_frame
		check(is_instance_valid(rig.grip_rig.right_hand),id+" same natural grip on actual game entry")
		rig.follow(game.fighters[0],1.0/60,false,false)
		check(not rig.hand_root.visible,id+" hiding/spectator flag hides all hands and sleeves")
		rig.follow(game.fighters[0],1.0/60,false,true)
		game.get_node("GripPresentation").layout()
		check(game.ui.detail.position.y < 130,id+" key hints outside bottom-right hand area")
	var graphics = game.get_node("GraphicsDirector")
	graphics.shade_view()
	check(rig.view_weapon.material_override != actor.weapon.material_override,"view and authority materials stay independent")
	check(not actor.weapon.material_override.disable_receive_shadows,"world shadow receiving preserved")
	game.queue_free(); await process_frame
	print("GRIP_UNIT_RESULT: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
