extends Node3D
## Phase 1 is a weapon laboratory, NOT the finished multiplayer game.
const Toy = preload("res://scripts/toy_factory.gd")
const Data = preload("res://scripts/weapon_data.gd")
const Actor = preload("res://scripts/actor.gd")
const CanvasScript = preload("res://scripts/drawing_canvas.gd")
const WeaponMesh = preload("res://scripts/weapon_mesh.gd")

var player
var targets: Array = []
var camera: Camera3D
var camera_home := Vector3(9.5,12.5,15.5)
var drawing := true
var frozen := 0.0
var shake := 0.0
var hits := 0
var knockouts := 0
var moving_targets := false
var clock := 0.0
var status: Label
var message: Label
var message_time := 0.0
var overlay: Control
var canvas
var ink_bar: ProgressBar
var ink_label: Label
var equip_button: Button
var preview_view: SubViewport
var preview_root: Node3D
var preview_grip: Node3D
var preview_weapon: MeshInstance3D
var audio: AudioStreamPlayer
var debug_visible := false
var debug_root: Node3D
var hide_spots := [Vector3(-4.8,0,2.15),Vector3(4.6,0,-1.25)]

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_min_size(Vector2i(1120,680))
	_setup_world()
	Toy.room(self)
	_spawn_actors()
	_setup_hud()
	_setup_drawing_ui()
	_setup_sound()
	canvas.set_data(player.weapon_data)
	_set_drawing(true)
	if "--smoke-test" in OS.get_cmdline_user_args():
		_smoke_finish()

func _setup_world() -> void:
	var world := WorldEnvironment.new()
	world.environment = _environment(Color("243840"))
	add_child(world)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-55,-35,0)
	sunlight.light_color = Color("ffe3b6")
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	add_child(sunlight)
	var fill := OmniLight3D.new()
	fill.position = Vector3(4,4,3)
	fill.omni_range = 15
	fill.light_energy = 0.45
	fill.light_color = Color("b8d8e6")
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.6
	camera.position = camera_home
	add_child(camera)
	camera.look_at(Vector3(0,0.6,-0.2))
	camera.current = true
	debug_root = Node3D.new()
	add_child(debug_root)

func _environment(background: Color) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = background
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e8eedc")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return env

func _spawn_actors() -> void:
	player = Actor.new()
	player.tint = Color("88d6b0")
	player.position = Vector3(0,0,1.9)
	add_child(player)
	var start = Data.new()
	start.set_preset("hammer")
	player.equip(start)
	var positions := [Vector3(0,0,-0.6),Vector3(2.7,0,0.5)]
	var colors := [Color("df92b2"),Color("edcd75")]
	for i in range(positions.size()):
		var target = Actor.new()
		target.tint = colors[i]
		target.position = positions[i]
		add_child(target)
		targets.append(target)

func _physics_process(delta: float) -> void:
	clock += delta
	if drawing:
		return
	if frozen > 0:
		frozen -= delta
		return
	var wish := _movement_vector()
	var aim := _aim_direction()
	player.step(delta,wish,aim)
	for i in range(targets.size()):
		var target = targets[i]
		var move := Vector3.ZERO
		if moving_targets:
			var destination: Vector3 = target.spawn_point + Vector3(sin(clock*0.8+i)*0.85,0,0)
			move = (destination-target.position)*0.8
			move.y = 0
		target.step(delta,move,player.position-target.position)
	if player.attack_active():
		_check_hits()
	_update_status()

func _process(delta: float) -> void:
	if drawing and is_instance_valid(preview_root):
		preview_root.rotation.y += delta * 0.38
	shake = move_toward(shake,0.0,delta*0.9)
	camera.position = camera_home + Vector3(sin(clock*111)*shake,sin(clock*79)*shake,0)
	if message_time > 0:
		message_time -= delta
		if message_time <= 0:
			message.text = ""
	if debug_visible and not drawing:
		_update_debug_points()

func _movement_vector() -> Vector3:
	var x := float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	var y := float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var right := camera.global_basis.x
	var down := camera.global_basis.z
	right.y = 0
	down.y = 0
	return (right.normalized()*x + down.normalized()*y).limit_length()

func _aim_direction() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var ray := camera.project_ray_normal(mouse)
	var plane := Plane(Vector3.UP,1.0)
	var point: Variant = plane.intersects_ray(origin,ray)
	if point is Vector3:
		var direction: Vector3 = point - player.global_position
		direction.y = 0.0
		return direction.normalized()
	return Vector3(0,0,1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB:
			_set_drawing(not drawing)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE and drawing:
			_set_drawing(false)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if drawing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player.begin_swing()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SHIFT:
				player.begin_dash(_movement_vector())
			KEY_R:
				_reset_room()
			KEY_E:
				_try_hide()
			KEY_F2:
				debug_visible = not debug_visible
				debug_root.visible = debug_visible
			KEY_F3:
				moving_targets = not moving_targets
				_notice("MOVING TARGETS" if moving_targets else "STATIONARY TARGETS")
			KEY_F12:
				_save_screenshot()

func _check_hits() -> void:
	var samples: PackedVector3Array = player.global_hit_samples()
	var old: PackedVector3Array = player.previous_samples
	if old.size() != samples.size():
		old = samples
	for target in targets:
		if target.down_time > 0 or player.hit_ids.has(target.get_instance_id()):
			continue
		var center: Vector3 = target.global_position + Vector3(0,1.0,0)
		for i in range(samples.size()):
			if Data.distance_to_segment(center,old[i],samples[i]) > 0.44 + Data.TUBE_RADIUS:
				continue
			var query := PhysicsRayQueryParameters3D.create(player.weapon_pivot.global_position,center,1)
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				continue
			var direction: Vector3 = center-player.global_position
			direction.y = 0
			if target.take_hit(direction):
				player.hit_ids[target.get_instance_id()] = true
				hits += 1
				if target.health <= 0:
					knockouts += 1
				frozen = 0.045
				shake = 0.13
				_spawn_impact(center)
				audio.play()
				_notice("SMASH!" if target.health <= 0 else "BONK!  %d / 3" % (3-target.health),0.75)
			break

func _spawn_impact(at: Vector3) -> void:
	for i in range(9):
		var angle := TAU*float(i)/9.0
		var p := Toy.ellipsoid(self,at,Vector3.ONE*0.055,Color("fff0af"))
		var direction := Vector3(cos(angle),0.7+sin(angle)*0.25,sin(angle))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(p,"position",at+direction*0.8,0.28)
		tween.tween_property(p,"scale",Vector3.ONE*0.005,0.28)
		tween.chain().tween_callback(p.queue_free)

func _try_hide() -> void:
	if player.hidden_in_box:
		player.toggle_hide()
		_notice("BACK OUT!  This is a manual hiding prototype.")
		return
	for spot in hide_spots:
		if player.position.distance_to(spot) < 1.45:
			player.toggle_hide()
			_notice("HIDDEN  /  E to come out",5.0)
			return
	_notice("Move behind a cardboard box, then press E.")

func _reset_room() -> void:
	player.reset_actor()
	for target in targets:
		target.reset_actor()
	hits = 0
	knockouts = 0
	_notice("ROOM RESET  /  Your equipped drawing is kept.")

func _update_status() -> void:
	status.text = "HITS %02d    KO %02d\nDRAWN REACH %.2f m\n%s" % [hits,knockouts,player.weapon_data.reach(),"HIDDEN" if player.hidden_in_box else "PRACTICE / OFFLINE"]

func _notice(text: String, duration: float = 2.2) -> void:
	message.text = text
	message_time = duration

func _set_drawing(value: bool) -> void:
	if not is_instance_valid(overlay):
		return
	if value and not drawing:
		canvas.set_data(player.weapon_data)
	drawing = value
	overlay.visible = value
	preview_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
	if value:
		_refresh_preview()
	else:
		canvas.finish_stroke()
		_update_status()

func _equip_drawing() -> void:
	canvas.finish_stroke()
	if not canvas.data.is_valid():
		return
	player.equip(canvas.data)
	_set_drawing(false)
	_notice("YOUR DRAWING IS NOW A TOY WEAPON.  Left click to swing!",4.0)

func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var title := _label("HIDE & SMASHING",26,Color("fff0d1"))
	title.position = Vector2(24,20)
	root.add_child(title)
	var subtitle := _label("PHASE 1  /  DRAWN-WEAPON LAB",14,Color("b5d4cd"))
	subtitle.position = Vector2(25,54)
	root.add_child(subtitle)
	status = _label("",17,Color("fff1d5"))
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.position = Vector2(-290,20)
	status.size = Vector2(265,90)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(status)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -62
	bottom.add_theme_stylebox_override("panel",_panel(Color(0.10,0.16,0.18,0.92),0))
	root.add_child(bottom)
	var hints := _label("WASD  Move    ·    Mouse  Aim    ·    LMB  Swing    ·    Shift  Dash    ·    Tab  Draw\nE  Hide near a box    ·    R  Reset    ·    F2  Hit samples    ·    F3  Moving targets    ·    F12  Screenshot",15,Color("ebead8"))
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(hints)
	message = _label("",25,Color("fff6cb"))
	message.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	message.offset_top = 96
	message.offset_bottom = 145
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(message)

func _setup_drawing_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	overlay = Control.new()
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.05,0.1,0.13,0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1080,630)
	card.add_theme_stylebox_override("panel",_panel(Color("eff0db"),22))
	center.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,18)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",9)
	margin.add_child(stack)
	stack.add_child(_label("DRAW YOUR WEAPON",30,Color("243840")))
	stack.add_child(_label("Your lines become a rounded toy. Pick a grip point, then test it in the room.",16,Color("587169")))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",18)
	stack.add_child(body)
	var left := VBoxContainer.new()
	body.add_child(left)
	canvas = CanvasScript.new()
	canvas.custom_minimum_size = Vector2(520,440)
	left.add_child(canvas)
	var palette := HBoxContainer.new()
	palette.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(palette)
	for i in range(Data.PALETTE.size()):
		var button := _button(" ",canvas.set_color_index.bind(i))
		button.custom_minimum_size = Vector2(50,34)
		button.add_theme_stylebox_override("normal",_panel(Color(Data.PALETTE[i]),10))
		palette.add_child(button)
	var controls := HBoxContainer.new()
	left.add_child(controls)
	controls.add_child(_button("Undo",canvas.undo))
	controls.add_child(_button("Clear",canvas.clear_drawing))
	controls.add_child(_button("Set grip",func():
		canvas.grip_mode = true
		ink_label.text = "Click on the canvas to choose where the hand holds it."
	))
	controls.add_child(_button("Save",_save_drawing))
	controls.add_child(_button("Load",_load_drawing))
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 460
	body.add_child(right)
	right.add_child(_label("LIVE 3D PREVIEW",17,Color("243840")))
	var holder := SubViewportContainer.new()
	holder.custom_minimum_size = Vector2(460,290)
	holder.stretch = true
	right.add_child(holder)
	preview_view = SubViewport.new()
	preview_view.size = Vector2i(460,290)
	preview_view.own_world_3d = true
	preview_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(preview_view)
	var stage := Node3D.new()
	preview_view.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = _environment(Color("30484b"))
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50,-35,0)
	light.light_color = Color("ffe3b6")
	stage.add_child(light)
	preview_root = Toy.avatar(Color("88d6b0"))
	stage.add_child(preview_root)
	preview_grip = Node3D.new()
	preview_grip.position = Vector3(0.48,1.0,0.14)
	preview_grip.rotation = Vector3(-0.28,-0.7,0)
	preview_root.add_child(preview_grip)
	var view_camera := Camera3D.new()
	view_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	view_camera.size = 3.7
	view_camera.position = Vector3(3,4.5,6)
	stage.add_child(view_camera)
	view_camera.look_at(Vector3(0,0.95,0.25))
	view_camera.current = true
	right.add_child(_label("SAME MATTE MATERIAL · SAME LIGHTING",14,Color("587169")))
	var presets := HBoxContainer.new()
	right.add_child(presets)
	for kind in ["hammer","fish","pan"]:
		presets.add_child(_button(kind.capitalize(),canvas.set_preset.bind(kind)))
	ink_bar = ProgressBar.new()
	ink_bar.custom_minimum_size = Vector2(400,18)
	ink_bar.show_percentage = false
	right.add_child(ink_bar)
	ink_label = _label("",14,Color("587169"))
	ink_label.custom_minimum_size = Vector2(440,40)
	ink_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(ink_label)
	equip_button = _button("EQUIP & PLAY",_equip_drawing)
	equip_button.custom_minimum_size.y = 48
	equip_button.add_theme_stylebox_override("normal",_panel(Color("88d6b0"),12))
	right.add_child(equip_button)
	right.add_child(_label("Tab / Esc: cancel changes and return to the room.\nPhase 1: open strokes only; no automatic filling.\nNo online play, accounts, or paid API calls.",13,Color("587169")))
	canvas.drawing_changed.connect(_refresh_preview)

func _refresh_preview() -> void:
	if not is_instance_valid(preview_grip):
		return
	if is_instance_valid(preview_weapon):
		preview_grip.remove_child(preview_weapon)
		preview_weapon.queue_free()
	preview_weapon = WeaponMesh.build(canvas.data)
	preview_grip.add_child(preview_weapon)
	ink_bar.value = 100.0*canvas.data.ink_used()/Data.MAX_INK
	ink_label.text = "INK %.0f%%  ·  %d / %d strokes  ·  reach %.2f m" % [ink_bar.value,canvas.data.strokes.size(),Data.MAX_STROKES,canvas.data.reach()]
	equip_button.disabled = not canvas.data.is_valid()

func _save_drawing() -> void:
	canvas.finish_stroke()
	var file := FileAccess.open("user://weapon.json",FileAccess.WRITE)
	if file == null:
		ink_label.text = "Save failed: %s" % error_string(FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(canvas.data.to_dictionary()))
	ink_label.text = "Saved locally to user://weapon.json"

func _load_drawing() -> void:
	if not FileAccess.file_exists("user://weapon.json"):
		ink_label.text = "No local drawing saved yet."
		return
	var file := FileAccess.open("user://weapon.json",FileAccess.READ)
	if file == null or file.get_length() > 65536:
		ink_label.text = "Cannot load: invalid file or more than 64 KiB."
		return
	var raw: Variant = JSON.parse_string(file.get_as_text())
	var data = Data.new()
	if not raw is Dictionary or not data.load_dictionary(raw):
		ink_label.text = "Cannot load: invalid or oversized drawing."
		return
	canvas.set_data(data)

func _panel(color: Color, radius: int) -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.set_corner_radius_all(radius)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	return panel

func _label(text: String, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",Color("243840"))
	button.add_theme_stylebox_override("normal",_panel(Color("dbe2d2"),9))
	button.add_theme_stylebox_override("hover",_panel(Color("c4ddcb"),9))
	button.add_theme_stylebox_override("pressed",_panel(Color("a7cbb5"),9))
	button.pressed.connect(action)
	return button

func _setup_sound() -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var bytes := PackedByteArray()
	var count := 4400
	bytes.resize(count*2)
	var phase := 0.0
	for i in range(count):
		var t := float(i)/float(count)
		phase += TAU*lerpf(190,65,t)/22050.0
		var envelope := sin(minf(t*20,1)*PI*0.5)*pow(1.0-t,3)
		var sample := int(sin(phase)*envelope*10000)
		bytes[i*2] = sample & 255
		bytes[i*2+1] = (sample >> 8) & 255
	stream.data = bytes
	audio = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = -8.0
	add_child(audio)

func _update_debug_points() -> void:
	for child in debug_root.get_children():
		debug_root.remove_child(child)
		child.queue_free()
	var points: PackedVector3Array = player.global_hit_samples()
	for i in range(0,points.size(),3):
		Toy.ellipsoid(debug_root,points[i],Vector3.ONE*0.035,Color("ed5460"))

func _save_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var filename := "user://phase1_%s.png" % str(Time.get_unix_time_from_system()).replace(".","_")
	var result := image.save_png(filename)
	_notice("Screenshot: " + ProjectSettings.globalize_path(filename) if result == OK else "Screenshot failed.",4.0)

func _smoke_finish() -> void:
	await get_tree().create_timer(0.5).timeout
	print("PHASE1_SMOKE_READY: scene and drawing UI initialized")
	get_tree().quit(0)
