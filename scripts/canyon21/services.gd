extends "res://scripts/wetland21/services.gd"
## Canyon increment. Reuses passage transit and finite public sound/track pools, never invulnerability.
const CanyonArt=preload("res://scripts/canyon21/art.gd")
const LANE_ENDS: Array[Vector3]=[Vector3(0,0,-1.0),Vector3(0,0,8.0)]
const WIND_CENTERS: Array[Vector3]=[Vector3(-12,0,2),Vector3(12,0,7)]
const LANE_SECONDS:=1.35
const LANE_COOLDOWN:=8.0
const CANYON_CLUE_SECONDS:=2.0
const WIND_PERIOD:=17.0
const WIND_WARNING:=0.8
const WIND_ACTIVE:=2.0
const WIND_SETTLE:=0.5
var canyon_active:=false
var canyon_art: Node3D
var lane_ready: Array[float]=[0,0,0,0]
var wind_cycles: Array[int]=[-1,-1]
var lane_uses:=0
var lane_aborts:=0
var wind_emissions:=0
var sweep_shape: CapsuleShape3D

func setup(owner_game) -> void:
	sweep_shape=CapsuleShape3D.new();sweep_shape.radius=0.38;sweep_shape.height=1.48
	super.setup(owner_game)
	game.audio.streams["wind21"]=CanyonArt.wind_audio()

func configure(round_seed: int) -> void:
	super.configure(round_seed)
	canyon_active=game.arena.map_id=="amber_canyon"
	canyon_art=null
	if canyon_active:canyon_art=CanyonArt.build(game.arena,LANE_ENDS,WIND_CENTERS)

func reset() -> void:
	super.reset();lane_ready.assign([0.0,0.0,0.0,0.0]);wind_cycles.assign([-1,-1])
	lane_uses=0;lane_aborts=0;wind_emissions=0
	if is_instance_valid(canyon_art):pose_wind(0)

func short_clue_lifetime(kind: String) -> float:
	if kind in ["lane21","wind21"]:return CANYON_CLUE_SECONDS
	return super.short_clue_lifetime(kind)

func lane(index: int) -> Dictionary:
	return {"canyon21":true,"id":"canyon21_lane%d"%index,"label":"노출 통과로 / Exposed crossing","index":index,"from":LANE_ENDS[index],"to":LANE_ENDS[1-index],"via":(LANE_ENDS[0]+LANE_ENDS[1])*0.5,"duration":LANE_SECONDS,"noise":18.0,"hider_only":false}

func passage(id: int) -> Dictionary:
	if not canyon_active:return super.passage(id)
	if id<0 or id>=game.fighters.size():return {}
	for i in range(2):
		if game.fighters[id].position.distance_to(LANE_ENDS[i])<1.0:return lane(i)
	return {}

func actor_can_travel(id: int) -> bool:
	if id<0 or id>=4 or game.paused or game.practice_mode:return false
	var a=game.fighters[id];var phase: int=game.rules.phase
	if not a.visible or a.hidden_in_box or not game.rules.alive[id]:return false
	if a.flash>0 or a.knock_velocity.length()>0.01:return false
	if phase==game.Rules.Phase.HIDE:return id!=game.rules.seeker
	if phase==game.Rules.Phase.SEEK:return true
	return phase==game.Rules.Phase.DUEL and (game.rules.mode=="field" or id in [game.rules.seeker,game.rules.opponent])

func clear_sweep(a: Vector3,b: Vector3,id: int) -> bool:
	if not a.is_finite() or not b.is_finite() or not free_point(b,id):return false
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=sweep_shape;q.transform.origin=a+Vector3.UP*0.81
	q.motion=b-a;q.collision_mask=3;q.exclude=[game.fighters[id].get_rid()]
	var space=game.get_world_3d().direct_space_state
	if not space.intersect_shape(q,1).is_empty():return false
	var result: PackedFloat32Array=space.cast_motion(q)
	return result.size()==2 and result[0]>=0.9999

func travel(id: int,p: Dictionary) -> bool:
	if not p.get("canyon21",false):return super.travel(id,p)
	if not canyon_active or not actor_can_travel(id):return false
	var index: int=p.get("index",-1)
	if index not in [0,1] or p!=lane(index):return false # Only the actual exposed corridor.
	if lane_ready[id]>elapsed or transit.has(id) or not game.fighters[id].is_on_floor():return false
	for t in transit.values():
		if t.get("canyon21",false):return false # Never launch head-on riders.
	if not clear_sweep(game.fighters[id].position,p.from,id) or not clear_sweep(p.from,p.to,id):
		if id==0:tell("통과로가 막혔어요. 옆길로 돌아가세요.","Lane occupied. Use the open side routes.")
		return false
	if not super.travel(id,p):return false
	transit[id].canyon21=true;lane_ready[id]=elapsed+LANE_COOLDOWN;lane_uses+=1
	# The superclass emitted the one launch sound. Give only that event a finite lane lifetime.
	if not sounds.is_empty():sounds.back().kind="lane21"
	make_track(p.from,id,"lane21")
	return true

func sound_at(p: Vector3,source: int,radius: float,kind: String="step") -> void:
	if canyon_active and kind=="landing":kind="lane21"
	super.sound_at(p,source,radius,kind)

func validate_riders(delta: float) -> void:
	for id in transit.keys():
		var t: Dictionary=transit[id]
		if not t.get("canyon21",false):continue
		var a=game.fighters[id]
		var age: float=minf(t.duration,t.age+delta)
		var q: float=smoothstep(0,1,age/t.duration)
		var next: Vector3=t.from*(1-q)*(1-q)+t.via*2*q*(1-q)+t.to*q*q
		# No closing door: an occupied segment, damage or phase change simply cancels propulsion.
		if not actor_can_travel(id) or not clear_sweep(a.position,next,id):
			transit.erase(id);lane_aborts+=1
			if id==0:tell("통과 중단 · 이제 직접 움직이세요.","Lane released. You can move normally.")

func tick(delta: float) -> void:
	if not advances_time(delta):return
	if canyon_active:validate_riders(delta)
	var riders: Array=transit.keys()
	super.tick(delta)
	if not canyon_active:return
	for id in riders:
		if not transit.has(id) and (game.fighters[id].position.distance_to(LANE_ENDS[0])<0.05 or game.fighters[id].position.distance_to(LANE_ENDS[1])<0.05):
			make_track(game.fighters[id].position,id,"lane21")
	# Environmental gusts are scheduled public events, never driven by occupancy or enemy state.
	for i in range(WIND_CENTERS.size()):
		var phase:=wind_phase(elapsed,i)
		var cycle:=int(floor((elapsed-4.0-i*8.5)/WIND_PERIOD))
		if phase>=WIND_WARNING and phase<WIND_WARNING+WIND_ACTIVE and cycle!=wind_cycles[i]:
			wind_cycles[i]=cycle;wind_emissions+=1
			sound_at(WIND_CENTERS[i],-1,14.0,"wind21");game.audio.play_at("wind21",WIND_CENTERS[i])
	pose_wind(elapsed)

func wind_phase(at: float,index: int) -> float:
	var relative:=at-4.0-index*8.5
	return -1.0 if relative<0 else fposmod(relative,WIND_PERIOD)

func pose_wind(at: float) -> void:
	if not is_instance_valid(canyon_art):return
	for i in range(2):
		var group: Node3D=canyon_art.get_node("WindPad%d"%i)
		var phase:=wind_phase(at,i)
		var warning: bool=phase>=0 and phase<WIND_WARNING
		var moving: bool=phase>=WIND_WARNING and phase<WIND_WARNING+WIND_ACTIVE+WIND_SETTLE
		var t:=clampf((phase-WIND_WARNING)/(WIND_ACTIVE+WIND_SETTLE),0,1)
		var pulse:=sin(t*PI) if moving else 0.0
		var comfort: bool=game.preferences.reduced_motion
		group.get_node("WindFlag").rotation.z=0.25 if warning else (-0.20 if moving else 0.0)
		for j in range(4):
			var toy: Node3D=group.get_node("WindToy%d"%j);var rest: Vector3=toy.get_meta("rest")
			toy.position=rest;toy.rotation=Vector3.ZERO
			if moving and not comfort:
				toy.position=rest+Vector3(pulse*0.65,absf(sin(t*TAU*2+j))*pulse*0.16,pulse*sin(j+0.4)*0.22)
				toy.rotation=Vector3(t*TAU*2*pulse,0,-t*TAU*pulse)
