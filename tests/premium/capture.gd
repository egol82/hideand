extends SceneTree
const Scene=preload("res://scenes/phase12.tscn")
const Data=preload("res://scripts/phase4/drawing_data.gd")
var game
var baseline:=false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	baseline="--baseline" in OS.get_cmdline_user_args()
	var selected: PackedScene=load("res://scenes/phase11.tscn") if baseline else Scene
	game=selected.instantiate(); root.add_child(game); game.automated=true
	game.preferences.language="ko"; game.preferences.reduced_motion=true
	await process_frame; await process_frame
	game.ui.show_menu(); await shot("01_menu")
	game.start_practice(); await shot("02_workshop")
	game.accept_drawing(); game.rig.face(Vector3(0,0,-1)); game.fighters[0].reset_fight(Vector3(-3,0,6))
	await shot("03_hud")
	if baseline:
		game.queue_free(); await process_frame; print("PREMIUM_BASELINE_PASS"); quit(); return
	for v in [0.22,0.60]:
		var d=Data.new(); d.grip=Vector2(0.5,0.88); d.strokes.append(PackedVector2Array([d.grip,Vector2(0.5,0.88-v)]))
		game.fighters[0].equip(d); await shot("size_"+str(int(v*100)))
	game.open_settings(); await shot("04_settings")
	game.ui.show_map(); await shot("05_map")
	game.ui.show_bindings(); await shot("06_controls")
	game.rules.scores.assign([5,3,4,2]); game.ui.show_result(game.rules,true); await shot("07_results")
	game.ui.show_help(); await shot("08_help")
	game.preferences.language="en"; game.return_to_menu(); await shot("09_menu_en")
	game.start_match(false); game.accept_drawing(); game.rules.tick(game.rules.hiding_seconds+0.1)
	game.fighters[0].reset_fight(Vector3(-3,0,6)); game.rig.face(Vector3(0,0,-1)); await shot("10_live_hud")
	game.set_process(false); game.ui.hide_modal(); game.ui.notify("",0)
	game.queue_free(); await process_frame
	print("PREMIUM_CAPTURE_PASS"); quit()
func shot(tag: String) -> void:
	for i in range(6): game._process(0); await process_frame
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://ci-artifacts/"+("baseline_" if baseline else "")+"premium_"+tag+".png")
	if result!=OK: printerr("FAIL: capture ",tag); quit(1)
