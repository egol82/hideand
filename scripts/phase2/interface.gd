extends CanvasLayer
## UI is built from native controls. No concept illustration is used as a fake game screen.
const Rules = preload("res://scripts/phase2/match_rules.gd")
const Canvas = preload("res://scripts/phase2/drawing_canvas.gd")
const Form = preload("res://scripts/phase2/weapon_form.gd")
const Toy = preload("res://scripts/toy_factory.gd")
const Library = preload("res://scripts/phase2/weapon_library.gd")
const NAMES := ["YOU", "MARSH", "BOBA", "NOODLE"]
const INK := Color("293e47")
var game
var root: Control
var modal: Control
var timer: Label
var objective: Label
var standings: Label
var toast: Label
var canvas
var ink: Label
var ready_button: Button
var preview: SubViewport
var preview_actor: Node3D
var preview_grip: Node3D
var preview_weapon: MeshInstance3D
var slot: OptionButton
var wait_clock: Label
var draw_heading: Label
var message_seconds := 0.0

func _ready() -> void:
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 84
	top.add_theme_stylebox_override("panel",panel(Color(0.1,0.17,0.2,0.94),0))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	var title := label("HIDE & SMASHING\nPHASE 2  /  OFFLINE",19,Color("b5ddd2"))
	title.custom_minimum_size.x = 260
	row.add_child(title)
	timer = label("",25,Color("fff1c9"))
	timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(timer)
	standings = label("",15,Color("fff1c9"))
	standings.custom_minimum_size.x = 320
	standings.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(standings)
	objective = label("",17,Color("fff1c9"))
	root.add_child(objective)
	objective.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	objective.offset_top = -72
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.1,0.17,0.2,0.94)
	objective.add_theme_stylebox_override("normal",backing)
	toast = label("",32,Color("fff0b4"))
	root.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = 106
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal = Control.new()
	root.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if message_seconds > 0.0:
		message_seconds -= delta
		if message_seconds <= 0.0:
			toast.text = ""
	if is_instance_valid(preview_actor) and game != null and not game.preferences.reduced_motion:
		preview_actor.rotation.y += delta*0.32

func refresh(rules) -> void:
	var names := ["WELCOME", "DRAW", "HIDE", "SEEK", "FOUND!", "SMASH!", "ROUND OVER", "MATCH OVER"]
	timer.text = "%s  %02d   /   ROUND %d OF 4" % [names[rules.phase],ceili(rules.time_left),mini(rules.round_index+1,4)]
	standings.text = "YOU %d    MARSH %d\nBOBA %d    NOODLE %d" % rules.scores
	if is_instance_valid(wait_clock):
		wait_clock.text = "Search begins in %02d" % ceili(rules.time_left)
	if is_instance_valid(draw_heading):
		draw_heading.text = "DRAW YOUR WEAPON   ·   %02d" % ceili(rules.time_left)
	if rules.phase in [Rules.Phase.REVEAL,Rules.Phase.DUEL]:
		objective.text = "%s  %s   vs   %s  %s\nLMB swing  ·  Shift dodge  ·  Survive 5 seconds to escape" % [NAMES[rules.seeker],"♥".repeat(rules.hp[rules.seeker]),NAMES[rules.opponent],"♥".repeat(rules.hp[rules.opponent])]
	elif rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK]:
		var role := "SEEKER: inspect hiding spots with E" if rules.seeker == 0 else "HIDER: E near a marked prop to hide / leave"
		if not rules.alive[0]:
			role = "CAPTURED — spectating the rest of this round"
		objective.text = "%s  ·  %d hiders remain\nWASD move  ·  Mouse aim  ·  C taunt  ·  Esc pause/help  ·  F11 fullscreen" % [role,rules.remaining()]
	else:
		objective.text = "Draw. Hide. Get found. Smash your way out."

func _clear() -> void:
	canvas = null
	preview = null
	preview_actor = null
	preview_grip = null
	preview_weapon = null
	draw_heading = null
	wait_clock = null
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()

func hide_modal() -> void:
	_clear()
	modal.hide()

func _card(width: float = 620.0) -> VBoxContainer:
	_clear()
	modal.show()
	var shade := ColorRect.new()
	shade.color = Color(0.05,0.10,0.12,0.84)
	modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	modal.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := PanelContainer.new()
	box.custom_minimum_size.x = width
	box.add_theme_stylebox_override("panel",panel(Color("f6efdf"),20))
	center.add_child(box)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	box.add_child(stack)
	return stack

func show_menu() -> void:
	var box := _card()
	box.add_child(label("HIDE & SMASHING",36))
	box.add_child(label("Your doodle. Your toy weapon. Your escape.",19))
	box.add_child(label("1 player + 3 bots  ·  4 rounds  ·  no network required",15))
	box.add_child(button("PLAY — SEEK FIRST",game.start_match.bind(true)))
	box.add_child(button("PLAY — HIDE FIRST",game.start_match.bind(false)))
	_settings(box)
	box.add_child(label("Capture: +3  /  Escape: +2  /  Survive a round: +2\nEveryone takes one turn as seeker. Best local score: %d" % game.preferences.best_score,15))
	box.add_child(button("QUIT",game.get_tree().quit))

func show_wait() -> void:
	var box := _card()
	(modal.get_child(0) as ColorRect).color = Color("20343d")
	box.add_child(label("NO PEEKING!",36))
	box.add_child(label("The hiders are finding their spots.",20))
	wait_clock = label("",28)
	box.add_child(wait_clock)
	box.add_child(label("When the search begins: move close to a prop and press E.",16))

func show_pause() -> void:
	var box := _card()
	box.add_child(label("PAUSED",32))
	box.add_child(label("WASD: move    Mouse: aim    LMB: swing\nShift: dodge (brief protection, then cooldown)\nE: hide / inspect    C: taunt (reveals your location)\nF11: fullscreen    F12: real engine screenshot\n\nFound players duel on the central rug.\nOther players and the search timer freeze during duels.\nA hider who survives five seconds escapes.",17))
	_settings(box)
	box.add_child(button("RESUME",game.toggle_pause))
	box.add_child(button("RETURN TO TITLE",game.return_to_menu))

func _settings(box: VBoxContainer) -> void:
	var motion := CheckBox.new()
	motion.text = "Reduced motion (no camera shake / preview rotation)"
	motion.add_theme_color_override("font_color",INK)
	motion.button_pressed = game.preferences.reduced_motion
	motion.toggled.connect(game.set_reduced_motion)
	box.add_child(motion)
	box.add_child(label("SOUND EFFECTS",13))
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = game.preferences.volume
	volume.value_changed.connect(game.set_volume)
	box.add_child(volume)

func show_drawing(data) -> void:
	var box := _card(1080)
	draw_heading = label("DRAW YOUR WEAPON",28)
	box.add_child(draw_heading)
	box.add_child(label("Keep your own shape. Closed simple loops can become solid foam toys.",16))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",20)
	box.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	canvas = Canvas.new()
	canvas.custom_minimum_size = Vector2(500,380)
	left.add_child(canvas)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	actions.add_child(button("UNDO",canvas.undo))
	actions.add_child(button("CLEAR",canvas.clear_drawing))
	actions.add_child(button("SET GRIP",func(): canvas.grip_mode = true))
	var palette := HBoxContainer.new()
	left.add_child(palette)
	var names := ["MINT","PEACH","PINK","BLUE","LILAC"]
	for i in range(names.size()):
		var b := button(names[i],canvas.set_color_index.bind(i))
		b.add_theme_stylebox_override("normal",panel(Color(data.PALETTE[i]),8))
		palette.add_child(b)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 470
	columns.add_child(right)
	right.add_child(label("LIVE 3D TOY PREVIEW",17))
	_make_preview(right)
	var fill := CheckBox.new()
	fill.text = "Fill simple closed loops"
	fill.add_theme_color_override("font_color",INK)
	fill.button_pressed = data.fill_closed
	fill.toggled.connect(func(value: bool):
		canvas.data.fill_closed = value
		canvas.queue_redraw()
		_preview_changed()
	)
	right.add_child(fill)
	ink = label("",14)
	right.add_child(ink)
	var examples := HBoxContainer.new()
	right.add_child(examples)
	for kind in ["hammer","fish","pan"]:
		examples.add_child(button(kind.capitalize(),canvas.set_preset.bind(kind)))
	var saves := HBoxContainer.new()
	right.add_child(saves)
	slot = OptionButton.new()
	slot.add_theme_color_override("font_color",INK)
	for i in range(Library.SLOTS):
		slot.add_item("Slot %d" % (i+1),i)
	saves.add_child(slot)
	saves.add_child(button("SAVE",_save))
	saves.add_child(button("LOAD",_load))
	ready_button = button("READY — ENTER THE ROUND",game.accept_drawing)
	ready_button.add_theme_stylebox_override("normal",panel(Color("a0d8bd"),10))
	right.add_child(ready_button)
	right.add_child(label("No valid drawing at timeout? Your previous toy is kept.\nCrossed / complex loops stay as tubes, not invented shapes.",13))
	canvas.drawing_changed.connect(_preview_changed)
	canvas.set_data(data)

func _make_preview(box: VBoxContainer) -> void:
	var holder := SubViewportContainer.new()
	holder.custom_minimum_size = Vector2(470,240)
	holder.stretch = true
	box.add_child(holder)
	preview = SubViewport.new()
	preview.size = Vector2i(470,240)
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(preview)
	var stage := Node3D.new()
	preview.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = game.make_environment()
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-35,0)
	light.light_color = Color("ffe3b6")
	stage.add_child(light)
	preview_actor = Toy.avatar(Color("88d6b0"))
	stage.add_child(preview_actor)
	preview_grip = Node3D.new()
	preview_grip.position = Vector3(0.48,1.0,0.14)
	preview_grip.rotation = Vector3(-0.28,-0.7,0)
	preview_actor.add_child(preview_grip)
	var view := Camera3D.new()
	view.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.size = 3.8
	view.position = Vector3(3,4.5,6)
	stage.add_child(view)
	view.look_at(Vector3(0,0.95,0.25))
	view.current = true

func _preview_changed() -> void:
	if not is_instance_valid(canvas) or not is_instance_valid(preview_grip):
		return
	if is_instance_valid(preview_weapon):
		preview_grip.remove_child(preview_weapon)
		preview_weapon.queue_free()
	preview_weapon = Form.build(canvas.data)
	preview_grip.add_child(preview_weapon)
	ink.text = "INK %d%%   REACH %.2f m   FILLED LOOPS %d" % [int(canvas.data.ink_used()/4.0*100),canvas.data.reach(),Form.contours(canvas.data).size()]
	ready_button.disabled = not canvas.data.is_valid()

func _save() -> void:
	canvas.finish_stroke()
	var error := Library.save_slot(canvas.data,slot.selected)
	ink.text = "Saved to slot %d" % (slot.selected+1) if error == OK else "Save failed: " + error_string(error)

func _load() -> void:
	var data = Library.load_slot(slot.selected)
	if data == null:
		ink.text = "Empty slot or invalid drawing file."
	else:
		canvas.set_data(data)

func show_result(rules, complete: bool) -> void:
	var box := _card()
	box.add_child(label("MATCH COMPLETE" if complete else "ROUND COMPLETE",30))
	box.add_child(label(rules.result_text,17))
	var maximum: int = rules.scores.max()
	for i in range(4):
		box.add_child(label("%s     %d points%s" % [NAMES[i],rules.scores[i],"  ★" if complete and rules.scores[i] == maximum else ""],22))
	box.add_child(button("BACK TO TITLE" if complete else "CONTINUE  [ENTER]",game.return_to_menu if complete else game.next_round))

func notify(text: String, seconds: float = 1.7) -> void:
	toast.text = text
	message_seconds = seconds

func panel(color: Color, radius: int) -> StyleBoxFlat:
	var p := StyleBoxFlat.new()
	p.bg_color = color
	p.set_corner_radius_all(radius)
	p.content_margin_left = 20
	p.content_margin_right = 20
	p.content_margin_top = 12
	p.content_margin_bottom = 12
	return p

func label(text: String, font_size: int, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_color_override("font_color",color)
	item.add_theme_font_size_override("font_size",font_size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func button(text: String, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 38
	item.add_theme_font_size_override("font_size",16)
	item.add_theme_color_override("font_color",INK)
	item.add_theme_color_override("font_hover_color",INK)
	item.add_theme_color_override("font_pressed_color",INK)
	item.add_theme_stylebox_override("normal",panel(Color("e0e4d2"),9))
	item.add_theme_stylebox_override("hover",panel(Color("c6decb"),9))
	item.add_theme_stylebox_override("pressed",panel(Color("a9cdb8"),9))
	item.pressed.connect(action)
	return item
