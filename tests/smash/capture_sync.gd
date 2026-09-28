extends SceneTree
## Real input -> physical contact -> presentation. No injected hit or manually hidden finisher.
const Scene = preload("res://scenes/phase9_followup.tscn")
var game
var frame_number := 0
var video := false
var metrics: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	video = "--video" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts/sync_frames")
	var selected: PackedScene = load("res://scenes/phase10.tscn") if "--studio" in OS.get_cmdline_user_args() else Scene
	game = selected.instantiate(); root.add_child(game); game.automated = true
	await process_frame; await process_frame
	game.set_process(false)
	for id in ["sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu(); game.select_map(id); game.start_match(true); game.accept_drawing()
		game.rules.tick(game.rules.hiding_seconds+0.1)
		game.rules.phase = game.Rules.Phase.DUEL; game.rules.seeker = 0; game.rules.opponent = 1
		game.practice_mode = true
		game.fighters[0].reset_fight(Vector3(0.6,0,4.5))
		game.fighters[1].reset_fight(Vector3(0.6,0,3.2))
		game.fighters[0].handling = "balanced" if id == "sugar_market" else "heavy"
		game.rules.hp[1] = 1 if id == "pocket_station" else 3
		for i in [2,3]: game.fighters[i].set_hidden(true,i)
		game.fighters[0].show_weapon(true)
		game.rig.face(Vector3.FORWARD)
		game.preferences.language = "ko"; game.preferences.feedback_strength = 1.0
		game.preferences.reduced_motion = false; game.preferences.hand_sway = 0.0; game.preferences.head_bob = 0.0
		game.ui.hide_modal(); game.ui.message_seconds = 0.0; game.ui.toast.text = ""
		game._clear_feedback()
		var hit_frame := -1
		var fx = game.get_node("SmashDirector")
		var before: int = fx.handled
		for f in range(60):
			if f == 12:
				var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
				game._unhandled_input(click)
			for tick in range(2): game._physics_practice(1.0/60)
			game._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if f == 8: save(image,"sync_"+id+"_idle.png")
			if fx.handled > before and hit_frame < 0:
				hit_frame = f
				save(image,"sync_"+id+"_impact.png")
				metrics.append({"map":id,"first_hit_frame":f,"hp":game.rules.hp[1],"contact_rendered":game.rig.contact_rendered,"source":"InputEventMouseButton + _physics_practice + real swept collision"})
			if hit_frame >= 0 and f == hit_frame+4: save(image,"sync_"+id+"_reaction.png")
			if video: save(image,"sync_frames/%04d.png"%frame_number)
			frame_number += 1
		if hit_frame < 0: printerr("FAIL: actual swing did not hit in ",id); quit(1); return
		game.practice_mode = false
	var file := FileAccess.open("res://ci-artifacts/sync-capture-metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"  ")); file.close()
	game.queue_free(); await process_frame
	print("SYNC_CAPTURE_PASS: actual input and collision, no synthetic hit fixture")
	quit()
func save(image: Image, path: String) -> void:
	if image.save_png("res://ci-artifacts/"+path) != OK:
		printerr("FAIL: cannot save ",path); quit(1)
