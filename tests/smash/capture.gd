extends SceneTree
## Real renderer evidence of deterministic staged contact/reaction, not a manual game session.
const Scene=preload("res://scenes/phase9.tscn")
const Contact=preload("res://scripts/phase4/combat.gd")
const Attack=preload("res://scripts/phase4/attack_spec.gd")
var game
var fx
var video:=false
var frame_number:=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	video="--video" in OS.get_cmdline_user_args()
	root.size=Vector2i(1280,720)
	game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await process_frame
	fx=game.get_node("SmashDirector")
	game.preferences.language="ko"; game.preferences.feedback_strength=1.0
	game.preferences.reduced_motion=false; game.preferences.head_bob=0; game.preferences.hand_sway=0
	for style in ["balanced","heavy"]:
		setup("sugar_market")
		await ticks(0.016,2)
		if style=="balanced": await shot("before")
		hit(style,false)
		await ticks(1.0/60,4)
		await shot(style+"_impact")
		await ticks(1.0/60,10)
		await shot(style+"_wobble")
	setup("starlight_arcade"); await ticks(0.016,2); hit("heavy",true)
	game.fighters[1].visible=false
	await ticks(1.0/60,9); await shot("finish")
	setup("pocket_station"); await ticks(0.016,2)
	game.fighters[0].attack_sequence+=1
	game._consume_event(Contact.event(game.fighters[0],null,Vector3(0.1,0.9,1.3),Vector3.BACK,"blocked","wood"))
	await ticks(1.0/60,6); await shot("blocked")
	setup("sugar_market"); await ticks(0.016,2)
	game.preferences.reduced_motion=true; hit("heavy",false)
	await ticks(1.0/60,4); await shot("reduced")
	if video:
		DirAccess.make_dir_recursive_absolute("res://ci-artifacts/smash_frames")
		for mode in ["balanced","heavy","finish"]:
			setup("sugar_market"); await ticks(0.016,2)
			for f in range(60):
				if f==12: hit("heavy" if mode!="balanced" else "balanced",mode=="finish")
				if mode=="finish" and f==13: game.fighters[1].visible=false
				if f>=12: game.fighters[0].elapsed=(f-12)/30.0
				if game.fighters[0].elapsed>=Attack.duration(game.fighters[0].handling): game.fighters[0].cancel_attack()
				await ticks(1.0/30,1)
				await RenderingServer.frame_post_draw
				var err:=root.get_texture().get_image().save_png("res://ci-artifacts/smash_frames/%04d.png"%frame_number)
				if err!=OK: printerr("FAIL: video frame"); quit(1); return
				frame_number+=1
	game.queue_free(); await process_frame
	print("SMASH_CAPTURE_PASS: rendered contact states; not manual playthrough"); quit()

func setup(id: String) -> void:
	game.return_to_menu(); game.select_map(id); game.start_match(true); game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds+0.1)
	game.fighters[0].reset_fight(Vector3(0.6,0,3.8)); game.fighters[0].show_weapon(true)
	game.fighters[1].reset_fight(Vector3(-0.55,0,1.7)); game.fighters[1].visual.rotation.y=0.08
	for i in [2,3]: game.fighters[i].set_hidden(true,i)
	game.rig.face(Vector3(-0.06,0,-1)); game.rig.pitch=-0.03
	game.rules.phase=game.Rules.Phase.DUEL; game.rules.seeker=0; game.rules.opponent=1
	game.ui.hide_modal(); game.ui.message_seconds=0; game.ui.toast.text=""
	game.preferences.reduced_motion=false
	fx.reset()

func hit(style: String, finish: bool) -> void:
	game.fighters[0].handling=style; game.fighters[0].attack_sequence+=1
	game.rules.hp[1]=1 if finish else 3
	game.fighters[0].elapsed=Attack.spec(style).windup
	game._consume_event(Contact.event(game.fighters[0],game.fighters[1],game.fighters[1].position+Vector3(0.23,1.15,0.31),Vector3.BACK,"hit"))

func ticks(delta: float, count: int) -> void:
	# Disable spontaneous render updates between deterministic samples, keep the renderer running.
	game.set_process(false)
	for i in range(count): game._process(delta); await process_frame

func shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var err:=root.get_texture().get_image().save_png("res://ci-artifacts/phase9_"+tag+".png")
	if err!=OK: printerr("FAIL: screenshot ",tag); quit(1)
	print("SMASH_CAPTURE ",tag)
