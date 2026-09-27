extends "res://scripts/phase2/interface.gd"
const Art4 = preload("res://scripts/phase4/art.gd")
const Form4 = preload("res://scripts/phase4/weapon_form.gd")
const Canvas4 = preload("res://scripts/phase4/drawing_canvas.gd")
const Library4 = preload("res://scripts/phase4/weapon_library.gd")
const Attack4 = preload("res://scripts/phase4/attack_spec.gd")
const Catalog4 = preload("res://scripts/phase3/map_catalog.gd")
const Board4 = preload("res://scripts/phase3/map_board.gd")
const Overlay4 = preload("res://scripts/phase4/overlay.gd")
var role_label: Label
var action_hint: Label
var detail: Label
var overlay4

func _ready() -> void:
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role_label = _hud_label(Vector2(24,20),Vector2(240,52),18)
	timer = _hud_label(Vector2(510,20),Vector2(260,52),22)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	standings = _hud_label(Vector2(970,20),Vector2(288,52),15)
	standings.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective = _hud_label(Vector2(24,624),Vector2(530,70),17)
	detail = _hud_label(Vector2(834,650),Vector2(420,44),13)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay4 = Overlay4.new()
	overlay4.game = game
	root.add_child(overlay4)
	overlay4.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay4.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_hint = _hud_label(Vector2(440,410),Vector2(400,42),17)
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = _hud_label(Vector2(270,102),Vector2(740,50),28)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal = Control.new()
	root.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.resized.connect(_layout_hud)

func _hud_label(at: Vector2, dimensions: Vector2, pixels: int) -> Label:
	var n := label("",pixels,Color("fff1d4"))
	n.add_theme_color_override("font_shadow_color",Color("193942"))
	n.add_theme_constant_override("shadow_offset_x",1)
	n.add_theme_constant_override("shadow_offset_y",2)
	n.position = at
	n.size = dimensions
	root.add_child(n)
	return n

func _layout_hud() -> void:
	if not is_instance_valid(timer): return
	timer.position.x = root.size.x*0.5-130
	standings.position.x = root.size.x-310
	objective.position.y = root.size.y-86
	detail.position = root.size-Vector2(446,70)
	action_hint.position = root.size*0.5+Vector2(-200,50)
	toast.position.x = root.size.x*0.5-370

func refresh(state) -> void:
	var in_play: bool = game.world_view_active()
	for node in [role_label,timer,standings,objective,detail,action_hint]: node.visible = in_play and not game.paused
	if is_instance_valid(draw_heading): draw_heading.text = "MAKE YOUR TOY     %02d" % ceili(state.time_left)
	if is_instance_valid(wait_clock): wait_clock.text = "Search begins in %02d" % ceili(state.time_left)
	var phase_names := ["TITLE","DRAW","HIDE","SEEK","FOUND","SKIRMISH","RESULT","COMPLETE"]
	timer.text = "%s  %02d    ·    %d / 4" % [phase_names[state.phase],ceili(state.time_left),mini(4,state.round_index+1)]
	role_label.text = ("SEEKER" if state.seeker == 0 else "HIDER")+"\n"+game.arena.config.title
	standings.text = "%d HIDERS LEFT   ·   YOUR SCORE %d" % [state.remaining(),state.scores[0]]
	objective.text = "%s TOY  ·  %s\n%s" % [game.fighters[0].handling.to_upper(),"♥".repeat(state.hp[0]),"DODGE READY" if game.fighters[0].dash_cooldown <= 0 else "DODGE RECOVERING"]
	detail.text = "WASD move · LMB swing · E inspect / hide\nShift dodge · C taunt · Esc settings"
	action_hint.text = ""
	if game.fighters[0].hidden_in_box: action_hint.text = "HIDDEN    [E] LEAVE"
	elif game.focus_spot >= 0: action_hint.text = "[E] "+("INSPECT" if state.seeker == 0 else "HIDE")
	if game.is_spectating():
		role_label.text = "SPECTATING "+NAMES[game.view_target()]
		objective.text = "CAUGHT THIS ROUND\nNext round rotates the seeker."
	if game.local_notice_time > 0: action_hint.text = game.local_notice
	overlay4.queue_redraw()

func show_menu() -> void:
	var box := _card(750)
	box.add_child(label("HIDE & SMASHING",34))
	box.add_child(label("MAKE A TOY. FIND YOUR FRIENDS. SMASH YOUR WAY OUT.",16))
	var choose := OptionButton.new()
	_control_ink(choose)
	for id in Catalog4.IDS: choose.add_item(str(Catalog4.spec(id).title))
	choose.select(Catalog4.IDS.find(game.map_id))
	choose.item_selected.connect(func(i: int): game.select_map(Catalog4.IDS[i]); show_menu())
	box.add_child(choose)
	var mode := OptionButton.new()
	_control_ink(mode)
	mode.add_item("FIELD CHASE · fight where you are found (8s)")
	mode.add_item("CLASSIC DUEL · centre arena (5s comparison)")
	mode.select(0 if game.rules.mode == "field" else 1)
	mode.item_selected.connect(func(i: int): game.set_mode("field" if i == 0 else "classic"))
	box.add_child(mode)
	var compact_box := CheckBox.new()
	_control_ink(compact_box)
	compact_box.text = "4-player active search zone (large maps kept)"
	compact_box.button_pressed = game.preferences.compact
	compact_box.toggled.connect(func(value: bool): game.set_compact(value); show_menu())
	box.add_child(compact_box)
	box.add_child(label("%d active hideouts / %d total · %d × %d m world" % [game.arena.active_spots.size(),game.arena.spots.size(),game.arena.dimensions.x,game.arena.dimensions.y],14))
	box.add_child(button("PLAY — SEEK FIRST",game.start_match.bind(true)))
	box.add_child(button("PLAY — HIDE FIRST",game.start_match.bind(false)))
	box.add_child(label("One human + three bots. Offline prototype.\nFirst escape +1 (once). Survive +3. Never found +2.",14))
	box.add_child(button("QUIT",game.get_tree().quit))

var handling_control: OptionButton
var fill_control: CheckBox

func show_drawing(data) -> void:
	var box := _card(1080)
	draw_heading = label("MAKE YOUR TOY",28)
	box.add_child(draw_heading)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",20)
	box.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	canvas = Canvas4.new()
	canvas.custom_minimum_size = Vector2(500,350)
	left.add_child(canvas)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	for pair in [["UNDO",canvas.undo],["CLEAR",canvas.clear_drawing],["GRIP",func(): canvas.grip_mode = true]]: actions.add_child(button(pair[0],pair[1]))
	var palette := HBoxContainer.new()
	left.add_child(palette)
	for i in range(5):
		var b := button(["MINT","PEACH","PINK","BLUE","LILAC"][i],canvas.set_color_index.bind(i))
		b.add_theme_stylebox_override("normal",panel(Color(data.PALETTE[i]),8))
		palette.add_child(b)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 460
	columns.add_child(right)
	_make_preview(right)
	var style := OptionButton.new()
	handling_control = style
	_control_ink(style)
	for name in ["QUICK · faster recovery / lighter push","BALANCED · all-round toy","HEAVY · slower recovery / bigger push"]: style.add_item(name)
	style.select(Attack4.IDS.find(data.handling))
	style.item_selected.connect(func(i: int): canvas.data.handling = Attack4.IDS[i]; _preview_changed())
	right.add_child(style)
	var fill := CheckBox.new()
	fill_control = fill
	_control_ink(fill)
	fill.text = "Fill safe closed outlines (holes stay open)"
	fill.button_pressed = data.fill_closed
	fill.toggled.connect(func(value: bool): canvas.data.fill_closed = value; _preview_changed())
	right.add_child(fill)
	ink = label("",14)
	right.add_child(ink)
	var examples := HBoxContainer.new()
	right.add_child(examples)
	for name in ["hammer","fish","pan"]: examples.add_child(button(name.capitalize(),canvas.set_preset.bind(name)))
	var saves := HBoxContainer.new()
	right.add_child(saves)
	slot = OptionButton.new()
	_control_ink(slot)
	for i in range(8): slot.add_item("Slot %d" % (i+1))
	saves.add_child(slot)
	saves.add_child(button("SAVE",_save))
	saves.add_child(button("LOAD",_load))
	ready_button = button("READY — LET'S PLAY",game.accept_drawing)
	ready_button.add_theme_stylebox_override("normal",panel(Color("9dcdb7"),10))
	right.add_child(ready_button)
	canvas.drawing_changed.connect(_preview_changed)
	canvas.set_data(data)

func _make_preview(box: VBoxContainer) -> void:
	super._make_preview(box)
	var parent := preview_actor.get_parent()
	preview_actor.remove_child(preview_grip)
	parent.remove_child(preview_actor)
	preview_actor.queue_free()
	preview_actor = Art4.avatar(Color("88d6b0"))
	parent.add_child(preview_actor)
	preview_actor.add_child(preview_grip)

func _preview_changed() -> void:
	if not is_instance_valid(canvas) or not is_instance_valid(preview_grip): return
	if is_instance_valid(preview_weapon):
		preview_grip.remove_child(preview_weapon)
		preview_weapon.queue_free()
	preview_weapon = Form4.build(canvas.data)
	preview_grip.add_child(preview_weapon)
	ink.text = "INK %d%%  ·  REACH %.2fm\n%s  ·  %.2fs attack  ·  %d safe fills" % [int(canvas.data.ink_used()/4*100),canvas.data.reach(),canvas.data.handling.to_upper(),Attack4.duration(canvas.data.handling),Form4.contours(canvas.data).size()]
	ready_button.disabled = not canvas.data.is_valid()

func _save() -> void:
	canvas.finish_stroke()
	var result := Library4.save_slot(canvas.data,slot.selected)
	ink.text = "Toy and handling saved." if result == OK else "Save failed: "+error_string(result)

func _load() -> void:
	var data = Library4.load_slot(slot.selected)
	if data != null:
		canvas.set_data(data)
		handling_control.select(Attack4.IDS.find(data.handling))
		fill_control.set_pressed_no_signal(data.fill_closed)
	else: ink.text = "Empty or invalid toy file."

func show_pause() -> void:
	var box := _card(760)
	box.add_child(label("PAUSED · CONTROLS & COMFORT",25))
	box.add_child(label("Camera stays under your control. Comfort options do not change timers.\nWASD move · LMB attack · Shift dodge · E hide/inspect · C taunt · F12 capture",14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",24)
	box.add_child(row)
	var a := VBoxContainer.new()
	a.custom_minimum_size.x = 320
	row.add_child(a)
	var b := VBoxContainer.new()
	b.custom_minimum_size.x = 320
	row.add_child(b)
	_slider(a,"Mouse sensitivity",game.preferences.mouse_sensitivity,0.0005,0.008,0.0001,game.set_sensitivity)
	_slider(a,"Vertical FOV",game.preferences.vertical_fov,55,90,1,game.set_fov)
	_slider(a,"Effects volume",game.preferences.volume,0,1,0.05,game.set_volume)
	_check(a,"Invert mouse Y",game.preferences.invert_y,game.set_invert_y)
	_check(a,"Reduced motion",game.preferences.reduced_motion,game.set_reduced_motion)
	_slider(b,"Hand sway",game.preferences.hand_sway,0,1,0.05,game.set_comfort.bind("hand_sway"))
	_slider(b,"Walking bob",game.preferences.head_bob,0,1,0.05,game.set_comfort.bind("head_bob"))
	_slider(b,"Contact animation",game.preferences.feedback_strength,0,1,0.05,game.set_comfort.bind("feedback_strength"))
	_check(b,"Optional local test metrics",game.preferences.recording,game.set_recording)
	box.add_child(button("RESUME",game.toggle_pause))
	box.add_child(button("MAP (public sites only)",show_map))
	box.add_child(button("BACK TO TITLE",game.return_to_menu))

func _slider(box: VBoxContainer, title: String, value: float, lo: float, hi: float, step_size: float, action: Callable) -> void:
	box.add_child(label(title,14))
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step_size
	slider.value = value
	slider.value_changed.connect(action)
	box.add_child(slider)

func _check(box: VBoxContainer, title: String, value: bool, action: Callable) -> void:
	var check := CheckBox.new()
	_control_ink(check)
	check.text = title
	check.button_pressed = value
	check.toggled.connect(action)
	box.add_child(check)

func show_map() -> void:
	var box := _card(740)
	box.add_child(label(game.arena.config.title,24))
	box.add_child(label("Public layout. No opponent coordinates. Zone gates mark the active area.",14))
	var board := Board4.new()
	board.arena = game.arena
	board.player_position = game.fighters[0].position
	board.custom_minimum_size = Vector2(660,350)
	box.add_child(board)
	box.add_child(button("RESUME",game.toggle_pause))

func _control_ink(control: Control) -> void:
	super._control_ink(control)
	if control is OptionButton:
		control.add_theme_stylebox_override("normal",panel(Color("dce5d7"),8))
		control.add_theme_stylebox_override("hover",panel(Color("c5dcca"),8))
		control.add_theme_stylebox_override("pressed",panel(Color("b9d5c4"),8))
