extends SceneTree
const Store = preload("res://scripts/quality/safe_store.gd")
const Controls = preload("res://scripts/quality/controls.gd")
const Workshop = preload("res://scripts/quality/workshop.gd")
const Practice = preload("res://scripts/quality/practice.gd")
const Prefs = preload("res://scripts/phase4/preferences.gd")
const Library = preload("res://scripts/phase4/weapon_library.gd")
const Data = preload("res://scripts/phase4/drawing_data.gd")
const Game = preload("res://scripts/phase4/game.gd")
const Copy = preload("res://scripts/quality/copy.gd")
var checks := 0
var failures := 0
var game
var capture := false
const DIR := "user://quality_tests/"

func _initialize() -> void: call_deferred("run")
func check(condition: bool, title: String) -> void:
	checks += 1
	if condition: print("PASS: "+title)
	else:
		failures += 1
		printerr("FAIL: "+title)

func write_bad(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func clear_path(path: String) -> void:
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func stores() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR+"store.json"
	clear_path(path)
	check(Store.save_value(path,{"value":1}) == OK,"first generation saved")
	check(Store.save_value(path,{"value":2}) == OK,"replacement generation saved")
	check(Store.load_value(path).data.value == 2,"newest valid generation read")
	write_bad(path,"{broken")
	var recovered := Store.load_value(path)
	check(recovered.ok and recovered.source == "backup" and recovered.data.value == 1,"truncated primary recovers previous valid generation")
	check(Store.save_value(path,{"value":3}) == OK,"save after corruption succeeds")
	write_bad(path,"{}")
	check(Store.load_value(path).data.value == 1,"corrupt primary never rotated over valid backup")
	write_bad(path+".bak","{}")
	check(not Store.load_value(path).ok,"both corrupt generations rejected")
	check(Store.save_value("res://escape.json",{"value":1}) == ERR_INVALID_PARAMETER,"resource folder writes rejected")
	check(Store.save_value("user://../escape.json",{"value":1}) == ERR_INVALID_PARAMETER,"path traversal rejected")
	check(Store.save_value(path,{"value":"x".repeat(Store.LIMIT)}) == ERR_INVALID_DATA,"oversized write rejected")
	clear_path(path)
	write_bad(path+".tmp",JSON.stringify({"schema":1,"payload":{"value":9},"digest":JSON.stringify({"value":9},"",true).sha256_text()}))
	check(not Store.load_value(path).ok,"uncommitted temp is never silently loaded")
	var data := Data.new()
	data.set_preset("fish")
	data.handling = "heavy"
	var toys := DIR+"toys"
	for i in range(8):
		clear_path(toys.path_join("%d.json" % i))
		check(Library.save_slot(data,i,toys) == OK,"toy slot %d saved" % i)
		var result := Library.read_slot(i,toys)
		check(result.data != null and result.data.to_dictionary() == data.to_dictionary(),"slot %d preserves vectors and handling" % i)
	check(Library.save_slot(data,-1,toys) == ERR_INVALID_PARAMETER,"negative toy slot rejected")
	check(Library.save_slot(data,8,toys) == ERR_INVALID_PARAMETER,"oversized toy slot rejected")
	check(Library.save_slot(Data.new(),0,toys) == ERR_INVALID_DATA,"blank toy cannot overwrite valid slot")
	data.set_preset("pan")
	check(Library.save_slot(data,0,toys) == OK,"toy overwrite creates recoverable previous version")
	write_bad(toys.path_join("0.json"),"{cutoff")
	var previous := Library.read_slot(0,toys)
	check(previous.source == "backup" and previous.data.handling == "heavy","toy backup recovery reports its source")
	var settings := Prefs.new()
	path = DIR+"settings.json"
	clear_path(path)
	settings.language = "ko"
	settings.volume = 0.25
	check(settings.save_local(path) == OK,"combined preferences saved")
	settings.volume = 0.75
	check(settings.save_local(path) == OK,"preferences replacement saved")
	write_bad(path,"{bad")
	var reload := Prefs.new()
	reload.load_local(path)
	check(reload.load_source == "backup" and reload.language == "ko" and is_equal_approx(reload.volume,0.25),"preferences recover coherent earlier settings")
	for key in settings.RANGES:
		var bad := settings.payload()
		bad[key] = NAN
		check(not Prefs.validate(bad),"NaN preference rejected: "+key)
	var bad := settings.payload(); bad.language = "unknown"
	check(not Prefs.validate(bad),"unsupported locale rejected")
	bad = settings.payload(); bad.recording = "yes"
	check(not Prefs.validate(bad),"diagnostic opt-in requires boolean")
	bad = settings.payload(); bad["script"] = "not-a-setting"
	check(not Prefs.validate(bad),"unexpected settings property rejected before apply")
	clear_path(path)
	clear_path(DIR+"store.json")
	for i in range(8): clear_path(toys.path_join("%d.json" % i))

func inputs() -> void:
	var c := Controls.new()
	for id in Controls.IDS:
		var e: InputEvent
		if int(c.bindings[id]) < 0:
			e = InputEventMouseButton.new(); e.button_index = -int(c.bindings[id])
		else:
			e = InputEventKey.new(); e.physical_keycode = int(c.bindings[id])
		e.pressed = true
		check(c.pressed(e,id),"default physical action matches "+id)
		e.pressed = false
		check(not c.pressed(e,id),"release cannot fire "+id)
	check(c.rebind("interact",KEY_Q) == "ok","alternate interact key accepted")
	check(c.rebind("attack",KEY_Q) == "interact","duplicate binding rejected without stealing")
	for code in [KEY_ESCAPE,KEY_ENTER,KEY_F11,KEY_F12,-MOUSE_BUTTON_WHEEL_UP,0,922337]:
		check(c.rebind("attack",code) == "reserved","reserved or invalid key rejected: %s" % code)
	var e := InputEventKey.new(); e.physical_keycode = KEY_Q; e.pressed = true
	check(c.pressed(e,"interact"),"remapped action uses new key")
	e.physical_keycode = KEY_E
	check(not c.pressed(e,"interact"),"old key no longer triggers action")
	var path := DIR+"keys.json"
	clear_path(path)
	check(c.save_local(path) == OK,"bindings saved")
	var restored := Controls.new()
	check(restored.load_local(path) and restored.hint("interact") == "Q","bindings restored")
	var b := {"version":1,"bindings":Controls.DEFAULTS.duplicate()}
	b.bindings.forward = b.bindings.back
	check(not Controls.validate(b),"duplicate codes in file rejected")
	b.bindings.forward = NAN
	check(not Controls.validate(b),"NaN binding rejected")
	restored.reset()
	e.physical_keycode = KEY_W; e.pressed = true
	Input.parse_input_event(e.duplicate())
	Input.flush_buffered_events()
	check(restored.held("forward") and restored.vector().y < -0.9,"engine input dispatch drives movement action")
	e.pressed = false
	Input.parse_input_event(e.duplicate())
	Input.flush_buffered_events()
	check(not restored.held("forward"),"engine release clears movement action")
	restored.release_all()
	clear_path(path)

func workshop_data() -> void:
	var w := Workshop.new()
	check(not w.allowed(true,0,3),"living player cannot open eliminated workshop")
	check(w.allowed(false,0,3),"captured player can prepare during search")
	check(w.allowed(false,2,5),"captured player can prepare during another duel")
	check(not w.allowed(false,3,3),"no next-round workshop in final round")
	check(not w.allowed(false,0,6),"result phase cannot reopen live workshop")
	var d := Data.new(); d.set_preset("fish"); d.handling = "heavy"
	check(w.keep(d),"valid future drawing accepted")
	d.handling = "quick"; d.strokes.clear()
	check(w.queued.is_valid() and w.queued.handling == "heavy","queued sketch is not aliased to editing data")
	check(not w.keep(d) and w.queued.is_valid(),"invalid edit cannot erase last valid future sketch")
	check(w.take() != null and w.take() == null,"queued sketch consumed only once")
	var p := Practice.new()
	p.record_move(9999); p.record_move(NAN)
	check(p.walked == 0,"teleports and NaN do not complete movement tutorial")
	p.equipped = true; p.dodged = true
	for n in range(5): p.record_move(0.45)
	for n in range(3): p.record_hit("hit")
	check(p.completed,"practice requires equip movement dodge and contacts")
	for key in Copy.TEXT:
		check(Copy.TEXT[key].size() == 2 and not Copy.TEXT[key][0].is_empty() and not Copy.TEXT[key][1].is_empty(),"paired UI copy: "+key)

func run() -> void:
	capture = "--capture-quality" in OS.get_cmdline_user_args()
	stores(); inputs(); workshop_data()
	game = Game.new()
	root.add_child(game)
	game.automated = true
	game.synthetic_run = true
	game.set_physics_process(false)
	game.set_process(false)
	await physics_frame
	await process_frame
	# Regression: cosmetic hurt/squash must never change authority geometry.
	var actor = game.fighters[0]
	for hz in [30,60,120]:
		actor.reset_fight(Vector3(0,0,1))
		actor.motion = Vector3.ZERO
		actor.use_view_aim = true
		actor.view_pitch = 0.6
		actor.flash = 0.14
		for n in range(hz/10):
			actor.step(1.0/float(hz),Vector3.ZERO,Vector3.BACK)
		check(actor.weapon.global_basis.get_scale().is_equal_approx(Vector3.ONE),"hurt animation cannot scale authority at %d Hz" % hz)
		check(actor.visual.scale.is_equal_approx(Vector3.ONE),"facing root is rotation-only at %d Hz" % hz)
	actor.reset_fight(Vector3(0,0,1))
	actor.flash = 0.14
	actor.step(1.0/60,Vector3.ZERO,Vector3.BACK)
	check(not actor.body_art.scale.is_equal_approx(Vector3.ONE),"body still expresses a hit while weapon scale is stable")
	game.ui.storage_directory = DIR+"ui_toys"
	clear_path(game.ui.storage_directory.path_join("0.json"))
	game.preferences.language = "ko"
	game.ui.show_menu()
	await screen("phase5_00_menu_ko")
	game.start_practice()
	var time_before: float = game.rules.time_left
	game.automated = false
	game._physics_process(0.5)
	game.automated = true
	check(game.practice_mode and game.rules.time_left == time_before,"practice drawing has no countdown")
	game.ui.canvas.set_preset("hammer")
	# Exercise the actual slot UI without touching a user's real toy slots.
	game.ui._save()
	var saved_toy: Dictionary = Library.read_slot(0,game.ui.storage_directory).data.to_dictionary()
	game.ui.canvas.set_preset("fish")
	game.ui._save()
	check(game.ui.slot_write_confirm == 0 and Library.read_slot(0,game.ui.storage_directory).data.to_dictionary() == saved_toy,"first overwrite press asks, does not overwrite")
	game.ui._save()
	check(game.ui.slot_write_confirm == -1 and Library.read_slot(0,game.ui.storage_directory).data.to_dictionary() != saved_toy,"second overwrite press commits validated drawing")
	write_bad(game.ui.storage_directory.path_join("0.json"),"{broken")
	game.ui._load()
	check(game.ui.canvas.data.to_dictionary() == saved_toy and game.ui.ink.text == game.ui.s("recovered"),"UI loads backup and tells player what happened")
	clear_path(game.ui.storage_directory.path_join("0.json"))
	game.ui._load()
	check(game.ui.canvas.data.to_dictionary() == saved_toy,"invalid or empty slot never erases current edit")
	await screen("phase5_01_workshop_ko")
	game.accept_drawing()
	check(not game.ui.modal.visible and game.practice.equipped,"practice equips real drawing into playable scene")
	check(game.fighters[0].weapon_data.to_dictionary() == game.draft.to_dictionary(),"practice preserves arbitrary original geometry")
	var score: Array = game.rules.scores.duplicate()
	Input.action_press("hs_forward")
	for n in range(34):
		game._physics_practice(1.0/60)
		await physics_frame
	Input.action_release("hs_forward")
	check(game.practice.walked > 1.0,"practice measures real movement, not claimed completion")
	var dash := InputEventKey.new(); dash.physical_keycode = KEY_SHIFT; dash.pressed = true
	game._unhandled_input(dash)
	check(game.practice.dodged,"dodge input progresses practice checklist")
	game.fighters[0].reset_fight(Vector3(0,0,1))
	game.fighters[1].reset_fight(Vector3(0,0,2.3))
	game.rig.face(Vector3.BACK)
	await physics_frame
	var hit := InputEventMouseButton.new(); hit.button_index = MOUSE_BUTTON_LEFT; hit.pressed = true
	game._unhandled_input(hit)
	for n in range(30):
		game._physics_practice(1.0/60)
		await physics_frame
	check(game.practice.hits > 0,"practice damage comes from real swept contact")
	check(game.rules.scores == score,"practice never awards match score")
	await screen("phase5_02_practice_ko")
	game.open_practice_drawing()
	check(game.rules.phase == game.Rules.Phase.DRAW and game.ui.canvas.data.is_valid(),"practice can reopen editor without losing toy")
	game.accept_drawing()
	check(game.practice.hits > 0,"re-equipping does not erase practice progress")
	game.return_to_menu()
	game.open_settings()
	game.ui.show_bindings()
	game.ui._select_binding("interact")
	var key := InputEventKey.new(); key.physical_keycode = KEY_Q; key.pressed = true
	game._input(key)
	check(game.controls.hint("interact") == "Q" and game.ui.binding_action.is_empty(),"live remap screen captures key and commits binding")
	await screen("phase5_03_controls_ko")
	game.controls.reset()
	game.toggle_pause()
	check(game.rules.phase == game.Rules.Phase.MENU and not game.paused,"settings opened from title returns to title")
	game.start_match(false)
	game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.1)
	game.rules.discover(0)
	game.rules.tick(game.rules.reveal_seconds()+0.01)
	var attackers: Array[int] = [game.rules.seeker]
	for n in range(3): game.rules.register_hits(attackers)
	check(not game.rules.alive[0],"captured test uses real authority hit resolution")
	var equipped: Dictionary = game.fighters[0].weapon_data.to_dictionary()
	game.open_workshop()
	check(game.workshop.opened and not game.paused and game.ui.modal.visible,"captured workshop opens without pausing game")
	game.ui.canvas.set_preset("pan")
	game.ui.handling_control.select(2)
	game.ui.handling_control.item_selected.emit(2)
	check(game.stash_workshop(),"future sketch kept")
	check(game.fighters[0].weapon_data.to_dictionary() == equipped,"future drawing never alters captured actor this round")
	time_before = game.rules.search_left
	game.automated = false
	game._physics_process(0.05)
	game.automated = true
	check(game.rules.search_left < time_before,"match clock continues behind workshop")
	check(game.workshop.opened and game.ui.canvas != null,"ongoing match update preserves drawing UI")
	await screen("phase5_04_next_round_ko")
	game.toggle_pause()
	game.toggle_pause()
	check(game.workshop.opened and game.ui.canvas.data.handling == "heavy","pause settings roundtrip preserves next-round sketch")
	game.rules._finish_round()
	check(not game.workshop.opened and game.workshop.queued != null,"round ending closes workshop but retains latest valid sketch")
	await screen("phase5_05_results_ko")
	game.next_round()
	check(game.ui.canvas.data.handling == "heavy" and game.workshop.queued == null,"queued toy becomes next-round draft exactly once")
	game.return_to_menu()
	game.preferences.language = "en"
	game.ui.show_menu()
	await screen("phase5_06_menu_en")
	game.ui.notify("CAUGHT!",5)
	game.effects.burst(Vector3.UP)
	game.hurt_feedback = 0.5
	game.start_practice(); game.accept_drawing()
	check(game.ui.toast.text.is_empty() and game.hurt_feedback == 0,"restarting practice clears stale capture/hurt notices")
	var expired := true
	for p in game.effects.particles: expired = expired and p.life == 0
	check(expired,"old contact particles never leak into a fresh practice session")
	await screen("phase5_07_practice_en")
	game.return_to_menu()
	game.open_settings()
	await screen("phase5_08_settings_en")
	game.toggle_pause()
	check(not game.settings_dirty,"synthetic runs never write user's real preferences")
	game.queue_free()
	await process_frame
	print("QUALITY_UNIT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func screen(name: String) -> void:
	if not capture: return
	game._process(1.0/60)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts")
	var error := root.get_texture().get_image().save_png("res://ci-artifacts/"+name+".png")
	check(error == OK,"actual rendered capture: "+name)
