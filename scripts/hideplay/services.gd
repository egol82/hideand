extends Node3D
## Rule-owned hide/search choices. Only recorded world events become clues; no live-target radar.
const Art = preload("res://scripts/phase4/art.gd")
const MAX_CLUES := 32
const MAX_TRACKS := 24
var game
var homes: Array[Dictionary]=[]
var sounds: Array[Dictionary]=[]
var tracks: Array[Dictionary]=[]
var props: Array[Node3D]=[]
var track_cursor:=0
var elapsed:=0.0
var seed_value:=0
var peek_time: Array[float]=[0,0,0,0]
var peek_active: Array[bool]=[false,false,false,false]
var peek_eyes: Array[Node3D]=[]
var decoys: Array[Dictionary]=[]
var decoy_uses: Array[int]=[1,1,1,1]
var travel_uses: Array[int]=[1,1,1,1]
var transit: Dictionary={}
var ambush_player:=-1
var bot_moves: Array[int]=[0,0,0,0]
var skill_index:=0
var skill_cooldown:=0.0
var inspecting: Dictionary={}
var listening:=false
var listen_age:=0.0
var pressure_stage:=0
var pressure_zone:=""
var quiet_distance: Array[float]=[0,0,0,0]
var actions: Dictionary={"decoy":0,"peek":0,"ambush":0,"travel":0,"investigate":0}

func setup(owner_game) -> void:
	game=owner_game; name="HidePlayServices"
	for i in range(MAX_TRACKS):
		var root:=Node3D.new(); add_child(root); root.visible=false
		for side in [-1,1]: Art.box(root,Vector3(side*0.09,0.018,0),Vector3(0.12,0.022,0.23),Color("deb772"),"foam",0.04)
		tracks.append({"node":root,"at":Vector3.ZERO,"time":-100.0,"source":-1})
	for i in range(4):
		var root:=Node3D.new(); add_child(root); root.visible=false
		for side in [-1,1]:
			Art.ball(root,Vector3(side*0.11,0,0),Vector3(0.066,0.066,0.04),Color("ede3bd"))
			Art.ball(root,Vector3(side*0.11,0,0.041),Vector3(0.024,0.03,0.018),Color("27444e"),"ink")
		peek_eyes.append(root)
		var toy:=Node3D.new(); add_child(toy); toy.visible=false
		Art.ball(toy,Vector3(0,0.2,0),Vector3(0.24,0.22,0.21),Color("efcc81"))
		Art.box(toy,Vector3(0.23,0.2,0),Vector3(0.13,0.05,0.10),Color("7baea1"),"wood",0.02)
		decoys.append({"node":toy,"due":-1.0,"expiry":0.0,"at":Vector3.ZERO,"source":i})
	configure(0)

func configure(round_seed: int) -> void:
	reset(); seed_value=round_seed; homes.clear()
	for n in props: if is_instance_valid(n): n.queue_free()
	props.clear()
	if game.arena.has_method("set_layout"):
		game.arena.set_layout(round_seed)
		for h in game.arena.homes: homes.append(h.duplicate())
	else:
		for i in range(game.arena.spots.size()):
			var p: Vector3=game.arena.spots[i]
			var exits: Array[Vector3]=[p]
			# Second exit is an actual reachable capsule-clear point, never across a blocker.
			for offset in [Vector3(1.5,0,0),Vector3(-1.5,0,0),Vector3(0,0,1.5),Vector3(0,0,-1.5)]:
				var q: Vector3=p+offset
				if free_point(q,-1) and game.arena.clear_ray(p+Vector3.UP*0.8,q+Vector3.UP*0.8): exits.append(q); break
			if exits.size()<2: exits.append(p) # Exposed as one-exit until geometry supports two.
			homes.append({"id":i,"at":p-Vector3(0,0,0.8),"entry":p,"exits":exits,"peek":p+Vector3.UP*1.0,"zone":zone(p),"fake":false,"title":game.arena.spot_names[i]})
	var r:=RandomNumberGenerator.new(); r.seed=round_seed+371
	var choices: Array[int]=game.arena.active_spots.duplicate()
	# Shuffle sealed cabinets only in a limited subset; at least three usable spaces remain.
	for n in range(mini(2,maxi(0,choices.size()-4))):
		var k:=r.randi_range(0,choices.size()-1); homes[choices[k]].fake=true; choices.remove_at(k)
	for h in homes:
		if h.has("root"):
			# Safe bounded parcel variations change visual silhouettes, not navigable footprint.
			var parcel:=Art.box(h.root,Vector3(0.35 if (round_seed+h.id)%2 else -0.35,1.49,0),Vector3(0.45,0.19,0.5),Color("eddbad"),"foam",0.06)
			parcel.name="RoundParcel"

func reset() -> void:
	elapsed=0; sounds.clear(); track_cursor=0; transit.clear(); inspecting.clear(); pressure_stage=0; pressure_zone=""
	listening=false; listen_age=0; skill_cooldown=0; ambush_player=-1; bot_moves.assign([0,0,0,0])
	peek_time.assign([0,0,0,0]); peek_active.assign([false,false,false,false]); decoy_uses.assign([1,1,1,1]); travel_uses.assign([1,1,1,1]); quiet_distance.assign([0,0,0,0])
	for eye in peek_eyes: eye.visible=false
	for t in tracks: t.node.visible=false; t.time=-100
	for d in decoys: d.node.visible=false; d.due=-1; d.expiry=0

func free_point(p: Vector3, actor_id: int) -> bool:
	if not p.is_finite() or not game.arena.inside(p): return false
	var shape:=CapsuleShape3D.new(); shape.radius=0.38; shape.height=1.48
	var q:=PhysicsShapeQueryParameters3D.new(); q.shape=shape; q.transform.origin=p+Vector3.UP*0.81; q.collision_mask=3
	if actor_id>=0: q.exclude=[game.fighters[actor_id].get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(): return false
	var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.25,p-Vector3.UP*0.45,1)
	return not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func usable(index: int) -> bool:
	return index>=0 and index<homes.size() and index in game.arena.active_spots and not homes[index].fake
func hide_actor(id: int,index: int) -> bool:
	if not usable(index) or game._occupied(index,id) or id==game.rules.seeker or not game.rules.alive[id]: return false
	var a=game.fighters[id]
	if a.position.distance_to(homes[index].entry)>1.85: return false
	a.position=homes[index].entry; a.old_position=a.position; a.cancel_attack(); a.dash_time=0; a.set_hidden(true,index)
	peek_time[id]=0; peek_active[id]=false
	game.audio.play_at("hide",a.position)
	return true
func leave(id: int,second: bool=false) -> bool:
	var a=game.fighters[id]
	if not a.hidden_in_box or a.spot<0 or a.spot>=homes.size(): return false
	var h:=homes[a.spot]; var selected: Vector3=h.exits[1 if second else 0]
	if not free_point(selected,id):
		if id==0: tell("출구가 막혔어요. 다른 쪽을 확인하세요.","Exit blocked. Try the other side.")
		return false
	var old_spot: int=a.spot
	a.set_hidden(false); a.position=selected; a.old_position=selected; a.motion=Vector3.ZERO
	peek_active[id]=false; peek_time[id]=0; peek_eyes[id].visible=false
	make_track(homes[old_spot].entry,id,"curtain")
	return true
func ambush(id: int) -> bool:
	if game.rules.mode!="field" or game.rules.phase!=game.Rules.Phase.SEEK or id==game.rules.seeker or game.rules.grace[id]>0: return false
	var actor=game.fighters[id]; var hunter=game.fighters[game.rules.seeker]
	if not actor.hidden_in_box or actor.position.distance_to(hunter.position)>3.2: return false
	if not game.arena.clear_ray(actor.position+Vector3.UP,hunter.position+Vector3.UP): return false
	if not leave(id): return false
	ambush_player=id
	var ok: bool=game.rules.discover(id)
	if ok:
		actions.ambush+=1
		# No free damage/attack while hidden. The shared reveal then actual collision decides the hit.
		if id==0: tell("튀어나왔다! 공개 연출 뒤 한 번 휘두릅니다.","Surprise! One swing is queued after the reveal.")
	return ok

func sound_at(p: Vector3, source: int, range_value: float, kind: String="step") -> void:
	if not p.is_finite(): return
	var packet: Dictionary={"at":Vector3(snappedf(p.x,2),p.y,snappedf(p.z,2)),"time":elapsed,"radius":range_value,"source":source,"kind":kind}
	sounds.append(packet); if sounds.size()>MAX_CLUES: sounds.pop_front()
	var hunter=game.fighters[game.rules.seeker]
	if source!=game.rules.seeker and hunter.position.distance_to(p)<=range_value:
		game.heard_point=packet.at; game.heard_time=2.0
		if game.rules.seeker==0 and game.preferences.sound_cues: tell("소리: "+direction(packet.at),"Sound: "+direction(packet.at))
	# Hiders also get the hunter's noisy inspection, never a current hidden-player coordinate.
	if source==game.rules.seeker and source!=0 and game.fighters[0].position.distance_to(p)<=range_value and game.preferences.sound_cues:
		tell("술래의 조사 소리: "+direction(packet.at),"Search sound: "+direction(packet.at))
func step_record(id: int) -> void:
	var a=game.fighters[id]
	if a.hidden_in_box or not a.visible or not a.is_on_floor(): return
	var moved: float=a.position.distance_to(a.old_position)
	if moved>0.7: return
	quiet_distance[id]+=moved
	if quiet_distance[id]<1.4: return
	quiet_distance[id]=0
	var quiet: bool=id==0 and game.controls.held("quiet") and not game.autoplay
	sound_at(a.position,id,game.footstep_radius(a.position,quiet))
	if not quiet: make_track(a.position,id,"step")
func make_track(p: Vector3,id: int,kind: String) -> void:
	var t:=tracks[track_cursor]; t.at=p; t.time=elapsed; t.source=id; t.kind=kind
	t.node.position=p; t.node.rotation.y=game.fighters[id].visual.rotation.y; t.node.visible=true
	track_cursor=(track_cursor+1)%MAX_TRACKS

func deploy_decoy(id: int) -> bool:
	if decoy_uses[id]<=0 or id==game.rules.seeker or not game.rules.alive[id] or not game._can_hide_now(): return false
	var actor=game.fighters[id]
	var dir: Vector3=game.rig.forward() if id==0 else actor.visual.global_basis.z
	var p: Vector3=actor.position+dir*3
	if not free_point(p,id) or not game.arena.clear_ray(actor.position+Vector3.UP,p+Vector3.UP): return false
	decoy_uses[id]-=1; var d:=decoys[id]; d.at=p; d.node.position=p; d.node.visible=true; d.due=elapsed+0.8; d.expiry=elapsed+6
	actions.decoy+=1
	if id==0: tell("태엽 장난감 설치! 잠시 뒤 소리가 납니다.","Wind-up toy set. It will squeak shortly.")
	return true
func investigate() -> bool:
	if game.rules.seeker!=0 or skill_cooldown>0 or game.rules.phase!=game.Rules.Phase.SEEK or game.fighters[0].hidden_in_box: return false
	if skill_index==0:
		listening=true; listen_age=0; skill_cooldown=15; tell("3초 동안 가만히 귀 기울이기…","Stand still and listen for 3 seconds…")
	elif skill_index==1:
		skill_cooldown=15; var found: Dictionary={}
		for t in tracks:
			if t.source==0 or elapsed-t.time>8 or t.at.distance_to(game.fighters[0].position)>8: continue
			if not game.arena.clear_ray(game.fighters[0].position+Vector3.UP,t.at+Vector3.UP*0.06): continue
			if found.is_empty() or t.time>found.time: found=t
		if found.is_empty(): tell("가까운 새 흔적이 없습니다.","No fresh nearby trail.")
		else:
			game.heard_point=found.at; game.heard_time=3
			tell("최근 흔적: "+direction(found.at),"Fresh trail: "+direction(found.at))
	else:
		var focus: int=game._focused_spot()
		if focus<0: tell("먼저 가까운 은신처를 바라보세요.","Face a nearby hiding place first."); return false
		skill_cooldown=15; sound_at(game.fighters[0].position,0,18,"inspect"); game.audio.play_at("blocked",game.fighters[0].position)
		game._inspect(0,focus,true)
	actions.investigate+=1; return true

func passage(id: int) -> Dictionary:
	if game.arena.has_method("route3"):
		for p in game.arena.passages:
			if game.fighters[id].position.distance_to(p.from)<1.2: return p
	return {}
func travel(id: int,p: Dictionary) -> bool:
	if game.paused or game.rules.phase not in [game.Rules.Phase.HIDE,game.Rules.Phase.SEEK,game.Rules.Phase.DUEL] or (game.rules.phase==game.Rules.Phase.HIDE and id==game.rules.seeker): return false
	if p.is_empty() or transit.has(id) or not game.rules.alive[id] or game.fighters[id].hidden_in_box: return false
	if game.fighters[id].position.distance_to(p.from)>1.25: return false
	if p.hider_only and (id==game.rules.seeker or travel_uses[id]<=0):
		if id==0: tell("숨는 역할 전용 · 라운드당 한 번","Hider passage · once per round")
		return false
	if not free_point(p.to,id): return false
	if p.hider_only: travel_uses[id]-=1
	transit[id]={"from":p.from,"to":p.to,"via":p.via,"age":0.0,"duration":p.duration,"noise":p.noise}
	game.fighters[id].cancel_attack(); game.fighters[id].dash_time=0; game.fighters[id].motion=Vector3.ZERO
	sound_at(p.from,id,p.noise,"hide"); game.audio.play_at("hide",p.from); actions.travel+=1
	return true

func tick(delta: float) -> void:
	if delta<=0 or game.paused or game.practice_mode or game.rules.phase not in [game.Rules.Phase.HIDE,game.Rules.Phase.SEEK,game.Rules.Phase.REVEAL,game.Rules.Phase.DUEL]: return
	elapsed+=delta; skill_cooldown=maxf(0,skill_cooldown-delta)
	for id in inspecting.keys():
		var job: Dictionary=inspecting[id]
		var who=game.fighters[id]
		if game.rules.phase!=game.Rules.Phase.SEEK or who.position.distance_to(job.start)>0.18 or who.position.distance_to(homes[job.index].entry)>2.2 or not game.arena.clear_ray(who.position+Vector3.UP,homes[job.index].entry+Vector3.UP):
			inspecting.erase(id); continue
		job.age+=delta
		if job.age>=0.65:
			inspecting.erase(id); game._inspect(id,job.index,true)
	for t in tracks: t.node.visible=elapsed-t.time<8
	for d in decoys:
		if d.due>=0 and elapsed>=d.due:
			d.due=-1; sound_at(d.at,d.source,14,"decoy"); game.audio.play_at("taunt",d.at)
		if elapsed>=d.expiry: d.node.visible=false
	for id in transit.keys():
		var t: Dictionary=transit[id]; t.age=minf(t.duration,t.age+delta)
		var q: float=smoothstep(0,1,t.age/t.duration)
		var p: Vector3=t.from*(1-q)*(1-q)+t.via*2*q*(1-q)+t.to*q*q
		var a=game.fighters[id]
		if not game.rules.alive[id] or a.hidden_in_box: transit.erase(id); continue
		a.position=p; a.old_position=p; a.velocity=Vector3.ZERO; a.motion=Vector3.ZERO
		if t.age>=t.duration:
			a.position=t.to; a.old_position=t.to; transit.erase(id); sound_at(t.to,id,t.noise,"landing"); game.audio.play_at("blocked",t.to)
	for id in range(4):
		var a=game.fighters[id]
		peek_active[id]=a.hidden_in_box and game.rules.alive[id] and (game.controls.held("quiet") if id==0 and not game.autoplay else fmod(elapsed+id*1.3,7)<1.4)
		if not peek_active[id]: peek_time[id]=0; peek_eyes[id].visible=false; continue
		peek_time[id]+=delta
		if a.spot<0 or a.spot>=homes.size(): continue
		var p: Vector3=homes[a.spot].peek
		peek_eyes[id].position=p; peek_eyes[id].visible=peek_time[id]>1.1
		# Only the exposed eyes count, and only through an actual clear ray and viewing cone.
		var hunter=game.fighters[game.rules.seeker]; var d: Vector3=p-(hunter.position+Vector3.UP*1.48)
		var forward: Vector3=game.rig.forward() if game.rules.seeker==0 and not game.autoplay else hunter.visual.global_basis.z
		if peek_time[id]>1.1 and d.length()<5.5 and forward.dot(d.normalized())>0.5 and game.arena.clear_ray(hunter.position+Vector3.UP*1.48,p):
			if game.rules.discover(id): peek_eyes[id].visible=false; actions.peek+=1
	if listening:
		if game._move_input().length()>0.05 or game.fighters[0].dash_time>0:
			listening=false; tell("움직여서 귀 기울이기가 끊겼어요.","Listening interrupted by movement.")
		else:
			listen_age+=delta
			if listen_age>=3:
				listening=false; var newest: Dictionary={}
				for s in sounds:
					if s.source!=0 and elapsed-s.time<=5 and s.at.distance_to(game.fighters[0].position)<16:
						if newest.is_empty() or s.time>newest.time: newest=s
				if newest.is_empty(): tell("최근 들린 소리가 없습니다.","No recent sound nearby.")
				else: game.heard_point=newest.at; game.heard_time=3; tell("들려요: "+direction(newest.at),"Heard: "+direction(newest.at))
	if game.rules.phase==game.Rules.Phase.SEEK:
		for id in range(1,4):
			if id==game.rules.seeker or not game.rules.alive[id] or not game.fighters[id].hidden_in_box or bot_moves[id]>=1: continue
			var heard:=false
			for sound in sounds:
				if sound.source==game.rules.seeker and elapsed-sound.time<0.4 and sound.at.distance_to(game.fighters[id].position)<6: heard=true
			if heard:
				deploy_decoy(id)
				var old: int=game.fighters[id].spot
				if leave(id,true):
					bot_moves[id]+=1
					var next: int=game._free_spot(id)
					if next==old:
						for h in homes:
							if h.id!=old and usable(h.id) and not game._occupied(h.id,id): next=h.id; break
					game.hide_assignments[id]=next
		var stage:=2 if game.rules.search_left<12 else (1 if game.rules.search_left<30 else 0)
		if stage>pressure_stage:
			pressure_stage=stage
			for id in range(4):
				if id!=game.rules.seeker and game.rules.alive[id]:
					pressure_zone=zone(game.fighters[id].position)
					# Deliberate endgame rule: public coarse room, never an exact hideout.
					tell("종반 구역 단서: "+pressure_zone,"Final area clue: "+pressure_zone,4)
					var candidates: Array=[]
					for h in homes: if h.zone==pressure_zone: candidates.append(h.id)
					if not candidates.is_empty(): game.search_route.assign(candidates); game.search_cursor=0
					break

func direction(point: Vector3) -> String:
	var d: Vector3=point-game.fighters[0].position
	var side: float=game.camera.global_basis.x.dot(d)
	var front: float=(-game.camera.global_basis.z).dot(d)
	var name: String=("오른쪽 / RIGHT" if side>0 else "왼쪽 / LEFT") if absf(side)>absf(front) else ("앞 / AHEAD" if front>=0 else "뒤 / BEHIND")
	return name+(" · 위층 / ABOVE" if d.y>2 else (" · 아래층 / BELOW" if d.y<-2 else ""))
func zone(point: Vector3) -> String:
	if game.arena.has_method("zone_name"): return game.arena.zone_name(point)
	return ("북쪽 / NORTH " if point.z<0 else "남쪽 / SOUTH ")+("서편 / WEST" if point.x<0 else "동편 / EAST")
func tell(ko: String,en: String,seconds: float=2.0) -> void:
	game.local_notice=ko if game.preferences.language=="ko" else en; game.local_notice_time=seconds
