extends SceneTree
## Exact-frame regression: real listener completion may not revive an already expired clue.
const Scene=preload("res://scenes/phase21.tscn")
var game
var checks:=0
var failures:=0
const SENTINEL:=Vector3(99,99,99)
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func fresh() -> void:
	game.return_to_menu();game.select_map("reedwater_bend");game.set_mode("field")
	game.start_match(true);game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-17+i*1.5,0,13))
	game.fighters[0].reset_fight(Vector3(-12,0,0));game.fighters[1].reset_fight(Vector3(-12,0,2))
	game.hiding.skill_index=0
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	var h=game.hiding
	var old_bug:=false
	for kind in ["water21","reed21"]:
		var ttl:=3.0 if kind=="water21" else 1.5
		for offset in [0.0,0.01,-0.01]:
			fresh();await physics_frame
			# Listen starts at t=4; sample at (7-ttl+offset); complete at t=7.
			# +/-10ms distinguishes still live from exactly/just expired without float ambiguity.
			h.tick(4.0)
			if 7.0-ttl+offset<4.0:
				h.elapsed=7.0-ttl+offset # Clock-only boundary fixture, no inserted damage/events.
				h.sound_at(Vector3(-12,0,2),1,10,kind);h.make_track(Vector3(-12,0,2),1,kind)
				h.tick(4.0-h.elapsed)
			check(h.investigate() and h.listening,kind+str(offset)+" actual three-second listener starts")
			if offset>=0 or ttl<3.0:
				if 7.0-ttl+offset>4.0:h.tick(7.0-ttl+offset-4.0)
				h.sound_at(Vector3(-12,0,2),1,10,kind);h.make_track(Vector3(-12,0,2),1,kind)
			h.tick(6.90-h.elapsed)
			game.heard_point=SENTINEL;game.heard_time=0
			h.tick(7.0-h.elapsed)
			var revived: bool=game.heard_point!=SENTINEL
			var alive: bool=offset>0
			check(not h.listening,kind+str(offset)+" listener completed on boundary frame")
			check(revived==alive,kind+str(offset)+" listener sees only unexpired sounds")
			check(h.tracks[0].node.visible==alive and (h.tracks[0].time>=0)==alive,kind+str(offset)+" track pixels and tracker eligibility share exact expiry")
			check((not h.sounds.is_empty())==alive,kind+str(offset)+" bounded sound record expires on the same clock")
			h.skill_index=1;h.skill_cooldown=0;game.heard_point=SENTINEL
			check(h.investigate() and (game.heard_point!=SENTINEL)==alive,kind+str(offset)+" original investigator obeys the same boundary")
			if alive:
				h.tick(0.011);h.skill_cooldown=0;game.heard_point=SENTINEL
				check(h.investigate() and game.heard_point==SENTINEL and not h.tracks[0].node.visible,kind+" formerly live sample vanishes next frame")
	fresh();h.sound_at(Vector3(-12,0,2),1,10,"water21");h.make_track(Vector3(-12,0,2),1,"water21")
	game.paused=true;h.tick(9)
	check(h.elapsed==0 and h.tracks[0].node.visible and h.sounds.size()==1,"paused service neither expires nor resurrects a clue")
	game.paused=false
	game.queue_free();await process_frame
	print("WETLAND21_EXPIRY_RESULT: %d checks, %d failures; old_bug=%s"%[checks,failures,old_bug])
	quit(0 if failures==0 else 1)
