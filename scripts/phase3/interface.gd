extends "res://scripts/phase2/interface.gd"
const Catalog3 = preload("res://scripts/phase3/map_catalog.gd")
const Reticle3 = preload("res://scripts/phase3/reticle.gd")
const Board3 = preload("res://scripts/phase3/map_board.gd")
var crosshair
var compass: Label
var action_hint: Label
var map_title: Label

func _ready() -> void:
	super._ready()
	map_title = root.get_child(0).get_child(0).get_child(0)
	crosshair = Reticle3.new()
	root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass = label("",16,Color("f2e6c4"))
	root.add_child(compass)
	compass.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	compass.offset_top = 90
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass.add_theme_color_override("font_shadow_color",Color("253f43"))
	compass.add_theme_constant_override("shadow_offset_y",2)
	action_hint = label("",18,Color("effcdd"))
	root.add_child(action_hint)
	action_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	action_hint.offset_left = -320
	action_hint.offset_right = 320
	action_hint.offset_top = 36
	action_hint.offset_bottom = 92
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint.add_theme_color_override("font_shadow_color",Color("153b3d"))
	action_hint.add_theme_constant_override("shadow_offset_y",2)
	# Modals must remain in front of the reticle/hints.
	root.move_child(modal,-1)

func refresh(state) -> void:
	super.refresh(state)
	if not is_instance_valid(game.rig):
		return
	map_title.text = "HIDE & SMASHING\nFP / "+game.arena.config.title
	map_title.add_theme_font_size_override("font_size",16)
	var playing: bool = game.world_view_active()
	crosshair.visible = playing and not game.paused and not game.is_spectating()
	crosshair.target = game.focus_spot >= 0
	crosshair.hit = game.hit_feedback > 0
	crosshair.queue_redraw()
	compass.visible = playing and not game.paused
	var heading := fposmod(rad_to_deg(-game.rig.yaw),360)
	var directions := ["N","NE","E","SE","S","SW","W","NW"]
	compass.text = "%s  %03d°     ·     %s" % [directions[int(round(heading/45))%8],int(heading),"SPECTATING" if game.is_spectating() else "FIRST PERSON"]
	action_hint.visible = crosshair.visible
	action_hint.text = ""
	if game.fighters[0].hidden_in_box:
		action_hint.text = "HIDDEN · [E] LEAVE"
	elif game.focus_spot >= 0:
		action_hint.text = "[E] %s\n%s" % ["INSPECT" if state.seeker == 0 else "HIDE",game.arena.spot_names[game.focus_spot]]
	if state.phase in [Rules.Phase.REVEAL,Rules.Phase.DUEL]:
		objective.text = "%s %s  vs  %s %s  ·  5 SECOND DUEL\nMouse look  ·  LMB swing  ·  Shift dodge  ·  Esc pause" % [NAMES[state.seeker],"♥".repeat(state.hp[state.seeker]),NAMES[state.opponent],"♥".repeat(state.hp[state.opponent])]
	elif state.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK]:
		objective.text = "%s  ·  %d HIDERS LEFT\nWASD move  ·  Mouse look  ·  E interact  ·  Shift dash  ·  M map  ·  Esc pause" % ["SEEKER: look at a hideout and inspect" if state.seeker == 0 else "HIDER: find cover and press E",state.remaining()]
		if game.is_spectating():
			objective.text = "SPECTATING %s — other players are fighting\nYour view returns when the duel ends. Esc: pause." % NAMES[game.view_target()]

func show_menu() -> void:
	var box := _card(710)
	box.add_child(label("HIDE & SMASHING",34))
	box.add_child(label("FIRST PERSON · YOUR DRAWING IN YOUR HANDS",17))
	var choose := OptionButton.new()
	_control_ink(choose)
	choose.custom_minimum_size.y = 42
	for id in Catalog3.IDS:
		var cfg: Dictionary = Catalog3.spec(id)
		choose.add_item("%s  /  %d × %d m" % [cfg.title,cfg.size.x,cfg.size.y])
	choose.select(Catalog3.IDS.find(game.map_id))
	choose.item_selected.connect(func(index: int):
		game.select_map(Catalog3.IDS[index])
		show_menu()
	)
	box.add_child(choose)
	var cfg: Dictionary = game.arena.config
	box.add_child(label(cfg.subtitle+"\n%d hideouts · %ds hiding · %ds searching" % [game.arena.spots.size(),cfg.hide,cfg.seek],15))
	var board := Board3.new()
	board.arena = game.arena
	board.custom_minimum_size = Vector2(650,145)
	box.add_child(board)
	box.add_child(button("PLAY — SEEK FIRST",game.start_match.bind(true)))
	box.add_child(button("PLAY — HIDE FIRST",game.start_match.bind(false)))
	box.add_child(label("1 human + 3 bots · four rotating-seeker rounds · offline\nMouse look / WASD move / E interact. Esc opens controls & comfort settings.",14))
	box.add_child(button("QUIT",game.get_tree().quit))

func show_pause() -> void:
	var box := _card(710)
	box.add_child(label("PAUSED — FIRST PERSON",27))
	box.add_child(label("WASD move · Mouse look · LMB swing · Shift dash\nE hide/inspect · C taunt · M map · F11 fullscreen · F12 screenshot\nDiscovery moves both duelists to the central arena. Survive 5s to escape.",14))
	_settings(box)
	box.add_child(button("RESUME",game.toggle_pause))
	box.add_child(button("MAP LAYOUT",show_map))
	box.add_child(button("RETURN TO TITLE",game.return_to_menu))

func _settings(box: VBoxContainer) -> void:
	super._settings(box)
	box.add_child(label("MOUSE SENSITIVITY",13))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.008
	sensitivity.step = 0.0001
	sensitivity.value = game.preferences.mouse_sensitivity
	sensitivity.value_changed.connect(game.set_sensitivity)
	box.add_child(sensitivity)
	box.add_child(label("VERTICAL FIELD OF VIEW (55–90 degrees)",13))
	var fov := HSlider.new()
	fov.min_value = 55
	fov.max_value = 90
	fov.step = 1
	fov.value = game.preferences.vertical_fov
	fov.value_changed.connect(game.set_fov)
	box.add_child(fov)
	var invert := CheckBox.new()
	invert.text = "Invert vertical mouse look"
	_control_ink(invert)
	invert.button_pressed = game.preferences.invert_y
	invert.toggled.connect(game.set_invert_y)
	box.add_child(invert)

func show_map() -> void:
	var box := _card(760)
	box.add_child(label(game.arena.config.title+" / MAP",26))
	var board := Board3.new()
	board.arena = game.arena
	board.player_position = game.fighters[0].position
	board.facing = game.rig.forward()
	board.custom_minimum_size = Vector2(700,390)
	box.add_child(board)
	box.add_child(label("Mint: you · Gold: public hideout locations · Gray: obstacles\nOther players and hidden occupants are NEVER displayed. Game paused.",14))
	box.add_child(button("RESUME [M / ESC]",game.toggle_pause))
