extends "res://scripts/hideplay/services.gd"
## Step 1 only: existing footstep/clue pools + two time-limited contextual thickets.
const PineArt=preload("res://scripts/pine21/art.gd")
const BUSH_IDS: Array[int]=[2,7]
const LEAF_RECTS: Array[Rect2]=[Rect2(-3,-10,6,2),Rect2(-4,-1,8,2)]
const BUSH_SECONDS:=4.0
const LEAF_SECONDS:=4.0
var pine_active:=false
var remaining: Array[float]=[4,4,4,4]
var leaf_visuals: Array[Node3D]=[]
var leaf_emitted:=false

func setup(owner_game) -> void:
	super.setup(owner_game)
	game.audio.streams["leaves21"]=PineArt.rustles()
	for t in tracks:
		var n:=Node3D.new();n.name="LeafPrint21";t.node.add_child(n);n.visible=false
		PineArt.leaf(n,Vector3(-0.09,0.031,0),Color("f0cb7a"),0.16)
		PineArt.leaf(n,Vector3(0.10,0.032,0.10),Color("ba7e44"),0.16)
		leaf_visuals.append(n)

func configure(round_seed: int) -> void:
	super.configure(round_seed)
	pine_active=game.arena.map_id=="pine_hollow"
	if not pine_active: return
	# Override only the two existing noisy trail strips. No new obstacles or routes.
	for i in range(game.arena.surface_zones.size()-1,-1,-1):
		if str(game.arena.surface_zones[i].id).begins_with("leaves21_"):game.arena.surface_zones.remove_at(i)
	for i in range(LEAF_RECTS.size()):
		game.arena.surface_zones.push_front({"id":"leaves21_"+str(i),"rect":LEAF_RECTS[i],"noise":1.8,"sound":"leaves21","loud":true})
	PineArt.build(game.arena,LEAF_RECTS,BUSH_IDS)
	for id in BUSH_IDS:
		homes[id].title="짧은 수풀 · 4초/라운드 / Thicket · 4s per round"
		game.arena.spot_names[id]=homes[id].title
		game.arena.markers[id].text="E · 4s"

func reset() -> void:
	super.reset();remaining.assign([4.0,4.0,4.0,4.0]);leaf_emitted=false

func on_leaves(p: Vector3) -> bool:
	if not pine_active or not p.is_finite():return false
	for r in LEAF_RECTS:
		if r.has_point(Vector2(p.x,p.z)):return true
	return false

func sound_at(p: Vector3,source: int,radius: float,kind: String="step") -> void:
	if kind=="step" and on_leaves(p):
		leaf_emitted=true;kind="leaves"
	super.sound_at(p,source,radius,kind)

func step_record(id: int) -> void:
	# Reuse the inherited 1.4m movement accumulator and hidden/ground/teleport guards.
	leaf_emitted=false;var before:=track_cursor
	super.step_record(id)
	# Quiet walking is quieter, not silent on dry leaves; it still leaves a short readable trace.
	if leaf_emitted and track_cursor==before:make_track(game.fighters[id].position,id,"leaves")

func make_track(p: Vector3,id: int,kind: String) -> void:
	if kind=="step" and on_leaves(p):kind="leaves"
	var slot:=track_cursor
	super.make_track(p,id,kind)
	if leaf_visuals.size()!=MAX_TRACKS:return
	for child in tracks[slot].node.get_children():child.visible=(child==leaf_visuals[slot]) if kind=="leaves" else (child!=leaf_visuals[slot])

func can_enter(id: int,index: int) -> bool:
	return not pine_active or index not in BUSH_IDS or remaining[id]>0.001

func hide_actor(id: int,index: int) -> bool:
	if id<0 or id>=4:return false
	var bush: bool=pine_active and index in BUSH_IDS
	if bush:
		var phase: int=game.rules.phase
		var allowed: bool=phase in [game.Rules.Phase.HIDE,game.Rules.Phase.SEEK] or (game.rules.mode=="field" and phase in [game.Rules.Phase.REVEAL,game.Rules.Phase.DUEL] and id not in [game.rules.seeker,game.rules.opponent])
		if not allowed or game.paused or game.practice_mode or not can_enter(id,index):
			if id==0:tell("이번 라운드의 수풀 시간을 다 썼어요.","Thicket time used. Try other cover.")
			return false
	var ok:=super.hide_actor(id,index)
	if ok and bush:
		sound_at(game.fighters[id].position,id,6.0,"bush_rustle")
		if id==0:tell("수풀은 수색으로 발견돼요. 남은 시간 %.1f초"%remaining[id],"Search can find you. Thicket time %.1fs"%remaining[id])
	return ok

func leave(id: int,second: bool=false) -> bool:
	var bush: bool=pine_active and game.fighters[id].spot in BUSH_IDS
	var ok:=super.leave(id,second)
	if ok and bush:sound_at(game.fighters[id].position,id,6.0,"bush_rustle")
	return ok

func tick(delta: float) -> void:
	if not is_finite(delta) or delta<=0:return
	var before:=elapsed
	super.tick(delta)
	var dt:=elapsed-before
	if not pine_active or dt<=0:return
	for t in tracks:
		if t.get("kind","")=="leaves" and elapsed-t.time>=LEAF_SECONDS:
			t.time=-100.0;t.node.visible=false # Also expire investigation eligibility, not just pixels.
	var phase: int=game.rules.phase
	if phase!=game.Rules.Phase.SEEK and not (game.rules.mode=="field" and phase in [game.Rules.Phase.REVEAL,game.Rules.Phase.DUEL]):return
	for id in range(4):
		var a=game.fighters[id]
		if not a.hidden_in_box or a.spot not in BUSH_IDS or not game.rules.alive[id]:continue
		remaining[id]=maxf(0,remaining[id]-dt)
		if remaining[id]>0.001:continue
		# Normal two-exit handler first; if both are occupied, expose at the existing entry
		# without teleporting into a new collider. Never extend concealment because of a blocked exit.
		if not leave(id) and not leave(id,true):
			a.set_hidden(false);peek_active[id]=false;peek_time[id]=0;peek_eyes[id].visible=false
			make_track(a.position,id,"curtain");sound_at(a.position,id,6.0,"bush_rustle")
		if id==0:tell("수풀 시간이 끝났어요. 다른 엄폐물로 이동하세요!","Thicket time is up. Move to other cover!")
