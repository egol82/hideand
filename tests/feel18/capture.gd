extends SceneTree
## Real input/collision captures; optional soundtrack is an event-timed offline mono preview.
const Scene=preload("res://scenes/phase18.tscn")
const Design=preload("res://scripts/feel18/sound_design.gd")
const Art=preload("res://scripts/phase4/art.gd")
var game
var fx
var studio
var frames:=0
var video:=false
var blocker: StaticBody3D
func _initialize() -> void:call_deferred("run")
func shot(tag: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://ci-artifacts/feel18_"+tag+".png")!=OK:push_error("Capture failed "+tag);quit(1)
	print("FEEL18_CAPTURE ",tag)
func frame() -> void:
	await process_frame;await RenderingServer.frame_post_draw
	if video:
		if root.get_texture().get_image().save_png("res://ci-artifacts/feel18_frames/frame_%04d.png"%frames)!=OK:push_error("Frame save failed");quit(1)
	frames+=1
func fresh(style: String="balanced",hp: int=3,blocked: bool=false,miss: bool=false) -> void:
	if is_instance_valid(blocker):blocker.queue_free();await physics_frame;await process_frame
	game.return_to_menu();game.select_map("toy_home");game.start_practice();game.accept_drawing()
	game.fighters[0].reset_fight(Vector3(0,0,1));game.fighters[1].reset_fight(Vector3(0,0,2.3) if not miss else Vector3(8,0,8))
	game.fighters[0].handling=style;game.rules.hp[1]=hp;game.rig.face(Vector3.BACK)
	game.preferences.reduced_motion=false;game.preferences.feedback_strength=0.7;game.preferences.volume=0.7
	game.ui.toast.text="";game.ui.message_seconds=0;game.local_notice="";game.local_notice_time=0
	game._process(0);studio._process(0)
	if blocked:
		blocker=StaticBody3D.new();blocker.collision_layer=1;game.add_child(blocker)
		var cs:=CollisionShape3D.new();var s:=BoxShape3D.new();s.size=Vector3(2.2,2.2,0.12);cs.shape=s;blocker.add_child(cs)
		blocker.position=Vector3(0,1,1.72);Art.box(blocker,Vector3.ZERO,s.size,Color("c5a98b"),"wood",0.04)
	await physics_frame;await physics_frame
func click() -> void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;game._unhandled_input(e)
func contact_shot(tag: String,style: String,polished: bool=true,hp: int=3,blocked: bool=false) -> void:
	await fresh(style,hp,blocked);fx.set_polished(polished);fx.effects.serial=0
	var original: int=fx.handled;click()
	for step in range(60):
		game._physics_practice(1.0/60);game._process(1.0/60);studio._process(0)
		if fx.handled>original:
			await shot(tag);return
		await physics_frame
	push_error("Expected actual contact absent: "+tag);quit(1)
func run() -> void:
	root.size=Vector2i(1280,720);video="--video" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts/feel18_frames")
	DirAccess.make_dir_recursive_absolute("res://ci-artifacts/feel18-audio")
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	studio=game.get_node("ToyStudio");studio.set_process(false);fx=game.get_node("SmashDirector")
	game.preferences.language="ko"
	await contact_shot("before_contact","balanced",false)
	await contact_shot("after_contact","balanced",true)
	for style in ["quick","balanced","heavy"]:await contact_shot(style,style)
	await contact_shot("finish","heavy",true,1)
	await contact_shot("blocked","balanced",true,3,true)
	await fresh("balanced",3,false,true);click()
	for step in range(24):game._physics_practice(1.0/60);game._process(1.0/60);await physics_frame
	await shot("miss")
	game.return_to_menu();game.select_map("toy_manor");game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.1)
	game.fighters[0].reset_fight(Vector3(-1.5,0,0.5));game.fighters[1].reset_fight(Vector3(-3,0,-3.2));game.fighters[1].visual.rotation.y=0.12
	for i in [2,3]:game.fighters[i].set_hidden(true,i)
	game.rig.face(Vector3(-0.36,0,-1));game._process(0);studio._process(0);await shot("manor")
	game.return_to_menu();studio.panel.popup_centered();await shot("options");studio.panel.hide()
	# Six real attacks at 30 fixed physics steps per second. Start audio/event clock at first frame.
	fx.clock=0;fx.audio.clock=0;fx.audio.recording=true;fx.audio.recording_events.clear()
	for stage in ["quick","balanced","heavy","finish","blocked","miss"]:
		await fresh("heavy" if stage=="finish" else ("balanced" if stage in ["blocked","miss"] else stage),1 if stage=="finish" else 3,stage=="blocked",stage=="miss")
		var original: int=fx.handled;click()
		for i in range(36):
			game._physics_practice(1.0/30);game._process(1.0/30);studio._process(0);await frame()
		if (fx.handled==original)!=(stage=="miss"):push_error("Unexpected contact count in video stage "+stage);quit(1);return
	var manifest:={"fps":30,"frames":frames,"rate":Design.RATE,"note":"Offline mono mix from same PCM and confirmed event timestamps; not captured audio-device/spatial output.","events":fx.audio.recording_events}
	var f:=FileAccess.open("res://ci-artifacts/feel18-audio-events.json",FileAccess.WRITE);f.store_string(JSON.stringify(manifest,"  "));f.close()
	for e in fx.audio.recording_events:
		var tag: String=e.key+"_"+str(e.variant)+"_"+str(int(e.muffled))
		if Design.stream(e.key,e.variant,e.muffled).save_to_wav("res://ci-artifacts/feel18-audio/"+tag+".wav")!=OK:push_error("Audio export failed");quit(1);return
	fx.audio.recording=false
	game.queue_free();await process_frame
	print("FEEL18_CAPTURE_PASS: 10 screenshots / frames=",frames);quit()
