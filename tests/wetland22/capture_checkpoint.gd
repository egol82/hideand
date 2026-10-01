extends SceneTree
const ResetReady=preload("res://tests/seed21/round_ready.gd")
const Scene=preload("res://scenes/phase21.tscn")
const Plans=preload("res://scripts/seed21/layouts.gd")
const Rig=preload("res://scripts/phase3/first_person.gd")
const EXPECTED_ROUND:=0
var game
var prefix: String="after"
var match_seed: int=0
var seed_supplied:=false
var views: Dictionary={}
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="):prefix=arg.trim_prefix("--prefix=")
		if arg.begins_with("--match-seed="):
			var value: String=arg.trim_prefix("--match-seed=")
			if value.is_valid_int():match_seed=int(value);seed_supplied=true
	call_deferred("run")
func require(ok: bool,label: String) -> bool:
	if not ok:push_error(label);quit(1)
	return ok
func vector_data(v: Vector3) -> Array:
	return [v.x,v.y,v.z]
func transform_data(t: Transform3D) -> Array:
	return [vector_data(t.basis.x),vector_data(t.basis.y),vector_data(t.basis.z),vector_data(t.origin)]
func layout_ready() -> bool:
	if not require(not game.layout_reset_pending and game.round_layout.applied,"Original seed placement must finish"):return false
	if not require(game.round_layout.last_rejection.is_empty(),"Original occupancy validation must accept this fixture"):return false
	if not require(int(game.rng.seed)==match_seed and game.rules.round_index==EXPECTED_ROUND,"Unexpected match seed or round"):return false
	var expected: Dictionary=Plans.serial(Plans.plan("reedwater_bend",match_seed,EXPECTED_ROUND))
	var actual: Dictionary=game.round_layout.descriptor
	for key in expected:
		if not require(actual.get(key)==expected[key],"Actual layout differs from requested fixture: "+str(key)):return false
	return require(actual.get("round_seed")==game.hiding.seed_value,"Layout manifest must retain the actual service seed")
func shot(tag: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	if not layout_ready():return
	var camera: Camera3D=game.camera
	if tag=="gameplay":
		var expected_eye: Vector3=game.fighters[0].global_position+Vector3.UP*Rig.EYE_HEIGHT
		if not require(camera.position.is_zero_approx(),"Diagnostic camera translation leaked into gameplay"):return
		if not require(camera.global_position.distance_to(expected_eye)<0.0001,"Gameplay camera is not at the player's real eye"):return
		if not require(game.arena.inside(camera.global_position),"Gameplay camera is outside the playable map"):return
	var actors: Array=[]
	for actor in game.fighters:actors.append(transform_data(actor.global_transform))
	views[tag]={"map":game.arena.map_id,"mode":game.rules.mode,"match_seed":int(game.rng.seed),"round_index":game.rules.round_index,"phase":game.rules.phase,"time_left":game.rules.time_left,"layout":game.round_layout.descriptor.duplicate(true),"camera_global_transform":transform_data(camera.global_transform),"camera_local_transform":transform_data(camera.transform),"fov":camera.fov,"projection":camera.projection,"near":camera.near,"far":camera.far,"viewport":[root.size.x,root.size.y],"actors":actors}
	print("PHASE22_CAPTURE_MANIFEST: ",prefix," ",tag," ",JSON.stringify(views[tag]))
	var image:=root.get_texture().get_image()
	var path: String="res://ci-artifacts/%s_%s.png"%[prefix,tag]
	if not require(image.save_png(path)==OK,"Cannot save "+path):return
	print("PHASE22_CAPTURE ",prefix," ",tag)
func stage_match() -> void:
	game.return_to_menu();game.select_map("reedwater_bend");game.set_mode("field")
	# Reuse Wetland21 fresh(): finish map/menu rendering before starting the round.
	await process_frame;await RenderingServer.frame_post_draw
	# Reset only this capture fixture's RNG, not gameplay/seed validation code.
	game.rng.seed=match_seed;game.start_match(true)
	await ResetReady.wait(game)
	if not layout_ready():return
	game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.4,0,14))
	game._process(0);game.get_node("ToyStudio")._process(0)
	await ResetReady.positions(game)
func run() -> void:
	if not require("--quality-test" in OS.get_cmdline_user_args() and seed_supplied,"Capture requires --quality-test and explicit --match-seed before _ready"):return
	if not require(prefix in ["before","after"],"Invalid capture prefix"):return
	root.size=Vector2i(1280,720)
	# _ready reads the command-line flags; automated only freezes the staged simulation.
	game=Scene.instantiate();root.add_child(game);game.automated=true
	if not require(game.synthetic_run and int(game.rng.seed)==match_seed,"_ready did not use the requested deterministic setup"):return
	await process_frame;await process_frame;await physics_frame
	game.set_process(false);game.get_node("ToyStudio").set_process(false)
	game.preferences.language="en";game.preferences.reduced_motion=false
	await stage_match()
	for actor in game.fighters:actor.visible=false
	game.ui.visible=false;game.rig.hand_root.visible=false
	game.camera.global_position=Vector3(-1.55,2.65,-1.45);game.camera.look_at(Vector3(-0.55,0.55,-6.7))
	await shot("close")
	game.camera.global_position=Vector3(6.6,3.35,0.2);game.camera.look_at(Vector3(0.2,0.95,-5.0))
	await shot("mid")
	await stage_match()
	game.ui.visible=true;game.rig.hand_root.visible=true
	# Restore the local view transform before the original rig follows the player.
	game.camera.transform=Transform3D.IDENTITY
	game.fighters[0].reset_fight(Vector3(5.9,0,-2.5));game.fighters[1].reset_fight(Vector3(5.1,0,-6.3))
	# Other actors retain the clear staging positions, not positions inside solid islands.
	await ResetReady.positions(game)
	game.rig.face(Vector3(-0.25,0,-1));game.rig.pitch=-0.09
	game._process(0);game.get_node("ToyStudio")._process(0)
	for i in range(4):
		if not require(game.hiding.free_point(game.fighters[i].position,i),"Gameplay actor must occupy a real navigable position: "+str(i)):return
	await shot("gameplay")
	if not require(views.size()==3,"All three capture manifests are required"):return
	var file:=FileAccess.open("res://ci-artifacts/%s_manifest.json"%prefix,FileAccess.WRITE)
	if not require(file!=null,"Cannot save capture manifest"):return
	file.store_string(JSON.stringify({"schema":1,"prefix":prefix,"views":views},"  "));file.close()
	game.queue_free();await process_frame
	print("PHASE22_CAPTURE_PASS: ",prefix)
	quit()
