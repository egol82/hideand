extends "res://scripts/phase2/interface.gd"
const Art4 = preload("res://scripts/phase4/art.gd")
const Form4 = preload("res://scripts/phase4/weapon_form.gd")
const Canvas4 = preload("res://scripts/phase4/drawing_canvas.gd")
const Library4 = preload("res://scripts/phase4/weapon_library.gd")
const Attack4 = preload("res://scripts/phase4/attack_spec.gd")
const Catalog4 = preload("res://scripts/maps/catalog.gd")
const Board4 = preload("res://scripts/maps/board.gd")
const Overlay4 = preload("res://scripts/phase4/overlay.gd")
const Copy = preload("res://scripts/quality/copy.gd")
var role_label: Label
var action_hint: Label
var detail: Label
var overlay4
var handling_control: OptionButton
var fill_control: CheckBox
var binding_action := ""
var key_page := false
var binding_status: Label
var slot_write_confirm := -1
var menu_font = Copy.font()
var storage_directory := Library4.DIRECTORY

func s(key: String) -> String:
	return Copy.get_text(key,game.preferences.language)

func map_name(id: String) -> String:
	return Catalog4.name_for(id,game.preferences.language == "ko")

func _ready() -> void:
	root = Control.new()
	root.theme = Theme.new()
	root.theme.default_font = menu_font
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role_label = _hud_label(Vector2(24,20),Vector2(270,52),18)
	timer = _hud_label(Vector2(480,20),Vector2(320,52),22)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	standings = _hud_label(Vector2(944,20),Vector2(310,52),16)
	standings.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective = _hud_label(Vector2(24,624),Vector2(650,70),16)
	detail = _hud_label(Vector2(834,650),Vector2(420,44),13)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay4 = Overlay4.new()
	overlay4.game = game
	root.add_child(overlay4)
	overlay4.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay4.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_hint = _hud_label(Vector2(330,410),Vector2(620,42),17)
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = _hud_label(Vector2(230,102),Vector2(820,50),26)
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
	timer.position.x = root.size.x*0.5-160
	standings.position.x = root.size.x-336
	objective.position.y = root.size.y-86
	detail.position = root.size-Vector2(446,70)
	action_hint.position = root.size*0.5+Vector2(-310,50)
	toast.position.x = root.size.x*0.5-410

func refresh(state) -> void:
	var in_play: bool = game.world_view_active() and not modal.visible
	for node in [role_label,timer,standings,objective,detail,action_hint]: node.visible = in_play and not game.paused
	var locale := 1 if game.preferences.language == "ko" else 0
	if is_instance_valid(draw_heading):
		draw_heading.text = s("next_toy") if game.workshop.opened else (s("untimed") if game.practice_mode else s("make")+"     %02d" % ceili(state.time_left))
	if is_instance_valid(wait_clock): wait_clock.text = s("wait") % ceili(state.time_left)
	timer.text = "%s  %02d  ·  %d / 4" % [Copy.PHASES[state.phase][locale],ceili(state.time_left),mini(4,state.round_index+1)]
	role_label.text = s("seeker" if state.seeker == 0 else "hider")+"\n"+map_name(game.map_id)
	standings.text = s("remaining") % [state.remaining(),state.scores[0]]
	objective.text = "%s · %s\n%s" % [s(game.fighters[0].handling).split(" · ")[0],"♥".repeat(state.hp[0]),s("dodgeready" if game.fighters[0].dash_cooldown <= 0 else "dodgewait")]
	detail.text = "%s %s · %s %s · %s %s\n%s %s · Esc %s" % [game.controls.hint("attack"),s("attack"),game.controls.hint("interact"),s("interact"),game.controls.hint("dash"),s("dash"),game.controls.hint("map"),s("map"),s("settings")]
	action_hint.text = ""
	if game.fighters[0].hidden_in_box: action_hint.text = s("hidden") % game.controls.hint("interact")
	elif game.focus_spot >= 0: action_hint.text = s("inspect" if state.seeker == 0 else "hide") % game.controls.hint("interact")
	if game.is_spectating():
		role_label.text = s("spectating")+NAMES[game.view_target()]
		objective.text = s("caught") % game.controls.hint("workshop") if state.round_index < 3 else s("last_round")
	if game.local_notice_time > 0: action_hint.text = s("hear_step") if game.local_notice == "FOOTSTEPS NEARBY" else game.local_notice
	if game.practice_mode:
		role_label.text = s("training")
		timer.text = s("practice").split(" · ")[0]
		standings.text = s("training_hits") % [game.practice.hits,game.practice.blocked,game.practice.misses]
		var flags: Array = []
		for value in game.practice.states(): flags.append("[✓]" if value else "[ ]")
		objective.text = s("training_tasks") % flags
		objective.text += "\n"+s("training_done" if game.practice.completed else "training_hint")
		detail.text = s("training_draw") % game.controls.hint("workshop")
		action_hint.text = ""
	overlay4.queue_redraw()

func show_menu() -> void:
	var box := _card(790)
	box.add_child(label("HIDE & SMASHING",34))
	box.add_child(label(s("tagline"),17))
	if game.preferences.load_source == "backup" or game.controls.load_source == "backup": box.add_child(label(s("settings_recovered"),13))
	box.add_child(button(s("practice"),game.start_practice))
	var choose := OptionButton.new()
	_control_ink(choose)
	for id in Catalog4.IDS: choose.add_item(map_name(id))
	choose.select(Catalog4.IDS.find(game.map_id))
	choose.item_selected.connect(func(i: int): game.select_map(Catalog4.IDS[i]); show_menu())
	box.add_child(choose)
	if Catalog4.is_new(game.map_id):
		var row_map := HBoxContainer.new()
		row_map.add_theme_constant_override("separation",14)
		box.add_child(row_map)
		var preview_map = preload("res://scripts/maps/preview.gd").new()
		preview_map.map_id = game.map_id
		preview_map.custom_minimum_size = Vector2(138,84)
		row_map.add_child(preview_map)
		var info := Catalog4.spec(game.map_id)
		var text := label(info.tip_ko if game.preferences.language=="ko" else info.tip_en,15)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(530,82)
		row_map.add_child(text)
	var mode := OptionButton.new()
	_control_ink(mode)
	mode.add_item(s("field")); mode.add_item(s("classic"))
	mode.select(0 if game.rules.mode == "field" else 1)
	mode.item_selected.connect(func(i: int): game.set_mode("field" if i == 0 else "classic"))
	box.add_child(mode)
	_check(box,s("compact"),game.preferences.compact,func(value: bool): game.set_compact(value); show_menu())
	box.add_child(label(s("room_info") % [game.arena.active_spots.size(),game.arena.spots.size(),game.arena.dimensions.x,game.arena.dimensions.y],14))
	var row := HBoxContainer.new()
	box.add_child(row)
	for pair in [["seek_first",true],["hide_first",false]]:
		var b := button(s(pair[0]),game.start_match.bind(pair[1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	box.add_child(label(s("offline"),14))
	box.add_child(label(s("points"),14))
	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	bottom.add_child(button(s("settings"),game.open_settings))
	bottom.add_child(button(s("quit"),game.get_tree().quit))
	_language(bottom)

func show_drawing(data) -> void:
	var box := _card(1070)
	draw_heading = label(s("make"),25)
	box.add_child(draw_heading)
	if game.workshop.opened: box.add_child(label(s("live_round"),14))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",14)
	box.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	canvas = Canvas4.new()
	canvas.custom_minimum_size = Vector2(474,320)
	left.add_child(canvas)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	for pair in [["undo",canvas.undo],["clear",canvas.clear_drawing],["grip",func(): canvas.grip_mode = true]]:
		actions.add_child(button(s(pair[0]),pair[1]))
	var palette := HBoxContainer.new()
	left.add_child(palette)
	for i in range(5):
		var b := button(str(i+1),canvas.set_color_index.bind(i))
		b.custom_minimum_size.x = 64
		b.add_theme_stylebox_override("normal",panel(Color(data.PALETTE[i]),8))
		palette.add_child(b)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 470
	columns.add_child(right)
	_make_preview(right)
	handling_control = OptionButton.new()
	_control_ink(handling_control)
	for key in Attack4.IDS: handling_control.add_item(s(key))
	handling_control.select(Attack4.IDS.find(data.handling))
	handling_control.item_selected.connect(func(i: int): canvas.data.handling = Attack4.IDS[i]; _preview_changed())
	right.add_child(handling_control)
	fill_control = CheckBox.new()
	_control_ink(fill_control)
	fill_control.text = s("fill")
	fill_control.button_pressed = data.fill_closed
	fill_control.toggled.connect(func(value: bool): canvas.data.fill_closed = value; _preview_changed())
	right.add_child(fill_control)
	ink = label("",14)
	right.add_child(ink)
	var examples := HBoxContainer.new()
	right.add_child(examples)
	var names := ["망치","물고기","프라이팬"] if game.preferences.language == "ko" else ["Hammer","Fish","Pan"]
	for i in range(3): examples.add_child(button(names[i],canvas.set_preset.bind(["hammer","fish","pan"][i])))
	var saves := HBoxContainer.new()
	right.add_child(saves)
	slot = OptionButton.new()
	_control_ink(slot)
	for i in range(8):
		var record := Library4.read_slot(i,storage_directory)
		slot.add_item(s("slot") % (i+1)+("  ·" if record.data != null else "  —"))
	slot.item_selected.connect(func(_i: int): slot_write_confirm = -1)
	saves.add_child(slot)
	saves.add_child(button(s("save"),_save))
	saves.add_child(button(s("load"),_load))
	ready_button = button(s("queue" if game.workshop.opened else ("test_toy" if game.practice_mode else "ready")),game.accept_drawing)
	ready_button.add_theme_stylebox_override("normal",panel(Color("9dcdb7"),10))
	right.add_child(ready_button)
	if game.workshop.opened: left.add_child(button(s("spectate"),game.close_workshop))
	elif game.practice_mode: left.add_child(button(s("title"),game.return_to_menu))
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
	ink.text = s("stats") % [int(canvas.data.ink_used()/4*100),canvas.data.reach(),s(canvas.data.handling).split(" · ")[0],Attack4.duration(canvas.data.handling),Form4.contours(canvas.data).size()]
	ready_button.disabled = not canvas.data.is_valid()

func _save() -> void:
	canvas.finish_stroke()
	if Library4.read_slot(slot.selected,storage_directory).data != null and slot_write_confirm != slot.selected:
		slot_write_confirm = slot.selected
		ink.text = s("confirm_slot")
		return
	var result := Library4.save_slot(canvas.data,slot.selected,storage_directory)
	ink.text = s("saved") if result == OK else s("save_error")+error_string(result)
	slot_write_confirm = -1
	if result == OK: slot.set_item_text(slot.selected,s("slot") % (slot.selected+1)+"  ·")

func _load() -> void:
	var record := Library4.read_slot(slot.selected,storage_directory)
	if record.data != null:
		canvas.set_data(record.data)
		handling_control.select(Attack4.IDS.find(record.data.handling))
		fill_control.set_pressed_no_signal(record.data.fill_closed)
		if record.source == "backup": ink.text = s("recovered")
		elif record.source == "legacy": ink.text = s("legacy")
	else: ink.text = s("empty")
	slot_write_confirm = -1

func show_pause() -> void:
	var box := _card(850)
	box.add_child(label(s("settings") if game.settings_from_menu else s("paused"),26))
	box.add_child(label(s("comfort_note"),14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",26)
	box.add_child(row)
	var a := VBoxContainer.new(); a.custom_minimum_size.x = 370; row.add_child(a)
	var b := VBoxContainer.new(); b.custom_minimum_size.x = 370; row.add_child(b)
	_slider(a,s("sensitivity"),game.preferences.mouse_sensitivity,0.0005,0.008,0.0001,game.set_sensitivity)
	_slider(a,s("fov"),game.preferences.vertical_fov,55,90,1,game.set_fov)
	_slider(a,s("volume"),game.preferences.volume,0,1,0.05,game.set_volume)
	_check(a,s("invert"),game.preferences.invert_y,game.set_invert_y)
	_check(a,s("reduced"),game.preferences.reduced_motion,game.set_reduced_motion)
	_check(a,s("cues"),game.preferences.sound_cues,game.set_sound_cues)
	_slider(b,s("sway"),game.preferences.hand_sway,0,1,0.05,game.set_comfort.bind("hand_sway"))
	_slider(b,s("bob"),game.preferences.head_bob,0,1,0.05,game.set_comfort.bind("head_bob"))
	_slider(b,s("contact"),game.preferences.feedback_strength,0,1,0.05,game.set_comfort.bind("feedback_strength"))
	_check(b,s("metrics"),game.preferences.recording,game.set_recording)
	_language(b)
	box.add_child(button(s("remap"),show_bindings))
	box.add_child(button(s("back" if game.settings_from_menu else "resume"),game.toggle_pause))
	if not game.settings_from_menu: box.add_child(button(s("title"),game.return_to_menu))

func _language(box: Container) -> void:
	var choice := OptionButton.new()
	_control_ink(choice)
	choice.add_item("English"); choice.add_item("한국어")
	choice.select(1 if game.preferences.language == "ko" else 0)
	choice.item_selected.connect(func(i: int): game.set_language("ko" if i == 1 else "en"))
	box.add_child(choice)

func show_bindings() -> void:
	var box := _card(820)
	key_page = true
	box.add_child(label(s("key_title"),26))
	box.add_child(label(s("key_note"),14))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",8)
	box.add_child(grid)
	for id in game.controls.IDS:
		grid.add_child(label(s("backward" if id == "back" else id),15))
		var b := button(game.controls.hint(id),_select_binding.bind(id))
		b.custom_minimum_size.x = 90
		grid.add_child(b)
	binding_status = label("",15)
	box.add_child(binding_status)
	box.add_child(button(s("reset_keys"),func(): game.controls.reset(); game.save_controls(); show_bindings(); binding_status.text = s("default_restored")))
	box.add_child(button(s("back"),show_pause))

func _select_binding(id: String) -> void:
	binding_action = id
	binding_status.text = s("press_key")

func capture_binding(e: InputEvent) -> bool:
	if binding_action.is_empty(): return false
	var code: int = game.controls.event_code(e)
	if code == KEY_ESCAPE:
		binding_action = ""
		binding_status.text = ""
		return true
	if code == 0: return e is InputEventMouseButton or e is InputEventKey
	var result: String = game.controls.rebind(binding_action,code)
	if result == "ok":
		binding_action = ""
		game.save_controls()
		show_bindings()
	else:
		binding_status.text = s("key_invalid") if result == "reserved" else s("key_busy")+s("backward" if result == "back" else result)
	return true

func show_wait() -> void:
	var box := _card(650)
	(modal.get_child(0) as ColorRect).color = Color("20343d")
	box.add_child(label(s("nopeek"),32))
	box.add_child(label(s("waiting"),18))
	wait_clock = label("",28)
	box.add_child(wait_clock)

func show_result(state, complete: bool) -> void:
	var box := _card(820)
	box.add_child(label(s("complete" if complete else "result"),29))
	box.add_child(label(s("points"),14))
	var order: Array[int] = [0,1,2,3]
	order.sort_custom(func(a: int,b: int): return state.scores[a] > state.scores[b])
	for i in order:
		var row := HBoxContainer.new()
		box.add_child(row)
		var name := label(NAMES[i]+(" ★" if complete and state.scores[i] == state.scores.max() else ""),22)
		name.custom_minimum_size.x = 165
		row.add_child(name)
		var delta_score: int = state.scores[i]-state.round_start_scores[i]
		row.add_child(label(s("round_award") % [delta_score,state.scores[i]],18))
		var badge := ""
		if i == state.seeker and state.remaining() == 0: badge = s("sweep")
		elif i != state.seeker and state.alive[i]: badge = s("never_found" if state.discoveries[i] == 0 else ("escaped" if state.escapes[i] > 0 else "survivor"))
		if not badge.is_empty(): row.add_child(label(badge,14))
	box.add_child(button(s("title" if complete else "continue"),game.return_to_menu if complete else game.next_round))

func show_map() -> void:
	var box := _card(740)
	box.add_child(label(map_name(game.map_id),24))
	box.add_child(label(s("map_note"),14))
	var board := Board4.new()
	board.arena = game.arena
	board.player_position = game.fighters[0].position
	board.custom_minimum_size = Vector2(660,350)
	box.add_child(board)
	if Catalog4.is_new(game.map_id):
		box.add_child(label("황금 줄무늬: 소리 타일 · 민트/파란 러그: 조용한 길" if game.preferences.language == "ko" else "Gold stripes: noisy tiles · mint/blue runners: quiet routes",14))
	box.add_child(button(s("resume"),game.toggle_pause))

func _slider(box: VBoxContainer, title: String, value: float, lo: float, hi: float, step_size: float, action: Callable) -> void:
	box.add_child(label(title,14))
	var slider := HSlider.new()
	slider.min_value = lo; slider.max_value = hi; slider.step = step_size; slider.value = value
	slider.value_changed.connect(action)
	box.add_child(slider)

func _check(box: Container, title: String, value: bool, action: Callable) -> void:
	var check := CheckBox.new()
	_control_ink(check)
	check.text = title
	check.button_pressed = value
	check.toggled.connect(action)
	box.add_child(check)

func _clear() -> void:
	binding_action = ""
	key_page = false
	slot_write_confirm = -1
	super._clear()

func notify(text: String, seconds: float = 1.7) -> void:
	var aliases := {"FOUND! SMASH YOUR WAY OUT":"found","ESCAPED! FIND NEW COVER":"escape","READY OR NOT!":"start_seek","HIDE! CHOOSE YOUR ESCAPE ROUTE":"hide_now","EMPTY... TRY ANOTHER SPOT":"empty_prop"}
	super.notify(s(aliases[text]) if aliases.has(text) else text,seconds)

func _control_ink(control: Control) -> void:
	super._control_ink(control)
	if control is OptionButton:
		control.add_theme_stylebox_override("normal",panel(Color("dce5d7"),8))
		control.add_theme_stylebox_override("hover",panel(Color("c5dcca"),8))
		control.add_theme_stylebox_override("pressed",panel(Color("b9d5c4"),8))

func button(text: String, action: Callable) -> Button:
	var b := super.button(text,action)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("458882")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(9)
	b.add_theme_stylebox_override("focus",focus)
	return b
