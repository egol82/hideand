extends SceneTree
const Scene=preload("res://scenes/phase12.tscn")
const Data=preload("res://scripts/phase4/drawing_data.gd")
const Form=preload("res://scripts/phase4/weapon_form.gd")
var game
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,description: String) -> void:
	checks+=1
	if not value: failures+=1
	print(("PASS: " if value else "FAIL: ")+description)
func stroke(length_value: float):
	var d=Data.new(); d.grip=Vector2(0.5,0.9)
	d.strokes.append(PackedVector2Array([d.grip,d.grip+Vector2(0,-length_value)])); return d
func shown_length(d) -> float:
	var rig=game.rig
	return game.camera.unproject_position(rig.view_weapon.to_global(d.point_to_world(d.strokes[0][0]))).distance_to(game.camera.unproject_position(rig.view_weapon.to_global(d.point_to_world(d.strokes[0][1]))))
func nodes(root_node: Node) -> int:
	var n:=1
	for child in root_node.get_children(): n+=nodes(child)
	return n
func contained(c: Control) -> bool:
	var rect:=Rect2(Vector2.ZERO,Vector2(root.size))
	var transform:=root.get_final_transform()*c.get_global_transform_with_canvas()
	var screen:=Rect2(transform*Vector2.ZERO,Vector2.ZERO)
	for point in [Vector2(c.size.x,0),c.size,Vector2(0,c.size.y)]: screen=screen.expand(transform*point)
	return rect.encloses(screen)
func all_buttons(n: Node) -> bool:
	if n is Button and n.focus_mode!=Control.FOCUS_ALL: return false
	for child in n.get_children():
		if not all_buttons(child): return false
	return true
func run() -> void:
	root.size=Vector2i(1280,720)
	game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await process_frame
	game.set_process(false)
	check(game.rig.drawn_size_view and game.rig.cute_sync,"new entry enables proportional scale and preserves round-paw contact alignment")
	game.start_practice(); game.accept_drawing(); game.rig.face(Vector3.FORWARD)
	var actor=game.fighters[0]
	var projected: Array[float]=[]
	for extent in [0.20,0.40,0.65]:
		var d=stroke(extent); var original: Dictionary=d.to_dictionary(); actor.equip(d)
		game._process(0); await process_frame
		projected.append(shown_length(d))
		check(is_equal_approx(game.rig.view_weapon.scale.x,0.40),"fixed view scale at drawing length "+str(extent))
		check(is_equal_approx(d.strokes[0][0].distance_to(d.strokes[0][1])*2.4,d.point_to_world(d.strokes[0][1]).length()),"drawing-size world length maintained "+str(extent))
		check(d.to_dictionary()==original and actor.weapon_data.to_dictionary()==original,"equipping does not rewrite original vectors "+str(extent))
		check(actor.hit_samples==Form.samples(d),"actual reach and shape still drive collision "+str(extent))
		check(game.rig.view_weapon.global_transform.is_finite(),"lowered view finite "+str(extent))
	check(absf(projected[1]/projected[0]-2.0)<0.06,"double drawn length produces double projected centreline, not equal-size props")
	check(projected[2]>projected[1]*1.5,"larger drawing stays visibly larger")
	for shape in ["fish","hammer","pan"]:
		var d=Data.new(); d.set_preset(shape); actor.equip(d); game._process(0)
		var vertices=game.rig.view_weapon.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var central:=0
		var safe:=Rect2(Vector2(root.size)*Vector2(0.22,0.15),Vector2(root.size)*Vector2(0.43,0.41))
		for i in range(0,vertices.size(),5):
			var at: Vector3=game.rig.view_weapon.to_global(vertices[i])
			if not game.camera.is_position_behind(at) and safe.has_point(game.camera.unproject_position(at)): central+=1
		check(central==0,shape+" idle drawing vertices leave central sight window clear")
	var hp: Array=game.rules.hp.duplicate(); var score: Array=game.rules.scores.duplicate(); var time: float=game.rules.time_left
	var count:=nodes(game.rig.hand_root); var revision: int=game.rig.rebuild_count
	for step in range(180): game._process(1.0/120)
	check(count==nodes(game.rig.hand_root) and revision==game.rig.rebuild_count,"lowering creates no new meshes per frame")
	check(game.rules.hp==hp and game.rules.scores==score and game.rules.time_left==time,"UI/pose updates do not change hp scores or time")
	for locale in ["ko","en"]:
		game.preferences.language=locale
		for dimensions in [Vector2i(1120,680),Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size=dimensions; await process_frame; await process_frame
			game.return_to_menu(); await process_frame; await process_frame
			check(contained(game.ui.page_panel),locale+str(dimensions)+" menu panel in viewport")
			check(all_buttons(game.ui.modal),locale+str(dimensions)+" every menu button keyboard-focusable")
			game.start_practice(); await process_frame; await process_frame; await process_frame
			check(contained(game.ui.canvas) and contained(game.ui.ready_button),locale+str(dimensions)+" canvas and equip action inside viewport")
			check(game.ui.page_panel.get_global_rect().encloses(game.ui.ready_button.get_global_rect()),locale+str(dimensions)+" equip action is not below a hidden scroll region")
			check(not game.ui.size_readout.text.is_empty(),locale+" live metric readout exists")
			# Real stroke input rather than a decorative image.
			var c=game.ui.canvas; c.clear_drawing(); var paper: Rect2=c.paper_rect()
			var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=paper.position+paper.size*Vector2(0.5,0.8); c._gui_input(press)
			var move:=InputEventMouseMotion.new(); move.position=paper.position+paper.size*Vector2(0.5,0.5); c._gui_input(move)
			press.pressed=false; c._gui_input(press)
			check(c.data.is_valid() and not game.ui.ready_button.disabled,"actual drawing input connects to equip "+locale+str(dimensions))
			var saved: Dictionary=c.data.to_dictionary(); game.ui.ready_button.pressed.emit(); await process_frame
			check(not game.ui.modal.visible and game.fighters[0].weapon_data.to_dictionary()==saved,"actual equip callback preserves drawn size "+locale+str(dimensions))
			game._process(0)
			check(not game.ui.extra.visible and not game.ui.detail.visible and game.ui.premium_hud.visible,"old verbose HUD is not stacked under new HUD")
			game.open_settings(); await process_frame; await process_frame
			check(game.paused and contained(game.ui.page_panel),"settings uses actual pause state "+locale+str(dimensions))
			game.ui.show_bindings(); await process_frame; check(game.ui.key_page,"binding capture preserved")
			game.ui.show_pause(); game.toggle_pause(); check(not game.paused,"return from settings resumes via original handler")
			game.ui.show_result(game.rules,true); await process_frame; check(contained(game.ui.page_panel),"result panel bounded "+locale+str(dimensions))
	root.size=Vector2i(1280,720); await process_frame
	for map_id in ["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu(); game.select_map(map_id); game.ui.show_menu(); await process_frame
		check(game.ui.board_view.arena==game.arena and not game.ui.board_view.show_player,map_id+" menu map is static and public-only")
		game.start_match(false); game.accept_drawing(); game._process(0)
		check(not game.ui.modal.visible,map_id+" actual hide-phase HUD reached")
		check(game.ui.premium_hud.info.role==game.ui.bi("숨는 사람","HIDER"),map_id+" role is meaningful, not debug text")
		game.ui.hide_view(true,false); check(game.ui.hide_top.visible and game.ui.hide_bottom.visible,map_id+" concealment masks preserved")
		game.ui.hide_view(false,false)
		game.ui.show_map(); await process_frame
		check(game.ui.board_view.show_player,map_id+" atlas uses local position only")
	game.return_to_menu(); game.ui.show_help()
	var esc:=InputEventKey.new(); esc.physical_keycode=KEY_ESCAPE; esc.pressed=true; game._input(esc)
	check(game.ui.page=="menu" and not game.paused,"Escape from guide returns to menu without trapping input")
	game.ui.show_help(); game.ui._guide_bindings(); check(game.settings_from_menu and game.paused,"guide-to-keybindings has valid back navigation")
	game.toggle_pause(); check(game.ui.page=="menu" and not game.paused,"keybindings can always return to title")
	game.queue_free(); await process_frame
	print("PREMIUM_UNIT_RESULT: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
