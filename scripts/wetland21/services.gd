extends "res://scripts/pine21/services.gd"
## Second increment: ONE inherited movement sampler and the existing investigation/sound pools.
const WetArt=preload("res://scripts/wetland21/art.gd")
const WATER_RECTS: Array[Rect2]=[Rect2(-3.2,-3.65,6.4,1.30),Rect2(-3.8,8.9,7.6,1.0)]
const REED_RECTS: Array[Rect2]=[Rect2(4.0,-8.8,1.8,3.6),Rect2(-5.8,-8.8,1.8,3.6),Rect2(5.0,4.6,1.8,2.8),Rect2(-6.8,4.6,1.8,2.8)]
const WATER_SECONDS:=3.0
const DRY_SECONDS:=2.5
const REED_SECONDS:=1.5
var wetland_active:=false
var wet_until: Array[float]=[-1,-1,-1,-1]
var wet_visuals: Array[Node3D]=[]
var reed_visuals: Array[Node3D]=[]
var tufts: Array[Node3D]=[]
var reed_events: Array[Dictionary]=[]
var sample_emitted:=false

func setup(owner_game) -> void:
	super.setup(owner_game)
	game.audio.streams["water21"]=WetArt.audio()
	game.audio.streams["reed21"]=PineArt.rustles() # Shared cached rustle, not a duplicate sound system.
	for t in tracks:
		wet_visuals.append(WetArt.wet_print(t.node));reed_visuals.append(WetArt.reed_print(t.node))

func configure(round_seed: int) -> void:
	super.configure(round_seed)
	wetland_active=game.arena.map_id=="reedwater_bend"
	tufts.clear();reed_events.clear()
	if not wetland_active:return
	for i in range(game.arena.surface_zones.size()-1,-1,-1):
		if str(game.arena.surface_zones[i].id).begins_with("wetland21_"):game.arena.surface_zones.remove_at(i)
	for i in range(WATER_RECTS.size()):
		game.arena.surface_zones.push_front({"id":"wetland21_water%d"%i,"rect":WATER_RECTS[i],"noise":1.25,"sound":"water21","loud":true})
	for i in range(REED_RECTS.size()):
		game.arena.surface_zones.push_front({"id":"wetland21_reed%d"%i,"rect":REED_RECTS[i],"noise":1.0,"sound":"reed21","loud":false})
	tufts=WetArt.build(game.arena,WATER_RECTS,REED_RECTS)
	for i in range(tufts.size()):
		tufts[i].rotation=Vector3.ZERO
		reed_events.append({"time":-100.0,"direction":Vector3.ZERO})

func reset() -> void:
	super.reset();wet_until.assign([-1.0,-1.0,-1.0,-1.0]);sample_emitted=false
	for visual in reed_visuals:WetArt.reset_reed_print(visual)
	for i in range(tufts.size()):
		if is_instance_valid(tufts[i]):tufts[i].rotation=Vector3.ZERO
	for event in reed_events:event.time=-100.0;event.direction=Vector3.ZERO

func zone_index(p: Vector3,zones: Array[Rect2]) -> int:
	if not wetland_active or not p.is_finite() or absf(p.y)>0.25:return -1
	for i in range(zones.size()):
		if zones[i].has_point(Vector2(p.x,p.z)):return i
	return -1

func sound_at(p: Vector3,source: int,radius: float,kind: String="step") -> void:
	if wetland_active and kind=="step" and source>=0 and source<4:
		sample_emitted=true
		if zone_index(p,WATER_RECTS)>=0:
			wet_until[source]=elapsed+DRY_SECONDS;kind="water21"
		var reed:=zone_index(p,REED_RECTS)
		if reed>=0:
			kind="reed21"
			var a=game.fighters[source]
			var d: Vector3=a.position-a.old_position;d.y=0
			reed_events[reed]={"time":elapsed,"direction":d.normalized()}
	super.sound_at(p,source,radius,kind)

func step_record(id: int) -> void:
	if id<0 or id>=4:return
	if not wetland_active:super.step_record(id);return
	if game.paused or game.practice_mode or game.rules.phase not in [game.Rules.Phase.HIDE,game.Rules.Phase.SEEK,game.Rules.Phase.REVEAL,game.Rules.Phase.DUEL]:return
	var a=game.fighters[id]
	if a.hidden_in_box or not a.visible or not a.is_on_floor() or not game.rules.alive[id] or transit.has(id) or a.position.distance_to(a.old_position)>0.7:
		wet_until[id]=-1.0;return
	# Wetness remembers only actual contact with shallow water. Standing/teleports cannot refresh it.
	if a.position.distance_to(a.old_position)>0.001 and zone_index(a.position,WATER_RECTS)>=0:wet_until[id]=elapsed+DRY_SECONDS
	sample_emitted=false;var before:=track_cursor
	super.step_record(id)
	# Quiet footsteps still disturb shallow water/reeds; one trace only per original step sample.
	if sample_emitted and track_cursor==before and (wet_until[id]>elapsed or zone_index(a.position,REED_RECTS)>=0):make_track(a.position,id,"step")

func make_track(p: Vector3,id: int,kind: String) -> void:
	if not p.is_finite() or id<0 or id>=4:return
	if wetland_active and kind=="step":
		if wet_until[id]>elapsed:kind="water21"
		elif zone_index(p,REED_RECTS)>=0:kind="reed21"
	var slot:=track_cursor
	super.make_track(p,id,kind)
	kind=tracks[slot].get("kind",kind) # Pine may canonicalize step -> leaves inside its override.
	if wet_visuals.size()!=MAX_TRACKS:return
	WetArt.reset_reed_print(reed_visuals[slot])
	if kind=="reed21" and wetland_active:WetArt.place_reed_print(reed_visuals[slot],tufts)
	# Restore each reused slot exactly; Pine leaves and ordinary footprints remain distinct.
	for child in tracks[slot].node.get_children():
		if kind=="water21":child.visible=child==wet_visuals[slot]
		elif kind=="reed21":child.visible=child==reed_visuals[slot]
		elif kind=="leaves":child.visible=child==leaf_visuals[slot]
		else:child.visible=child not in [wet_visuals[slot],reed_visuals[slot],leaf_visuals[slot]]

func short_clue_lifetime(kind: String) -> float:
	return WATER_SECONDS if kind=="water21" else (REED_SECONDS if kind=="reed21" else -1.0)

func advances_time(delta: float) -> bool:
	return is_finite(delta) and delta>0 and not game.paused and not game.practice_mode and game.rules.phase in [game.Rules.Phase.HIDE,game.Rules.Phase.SEEK,game.Rules.Phase.REVEAL,game.Rules.Phase.DUEL]

func expire_short_clues(at_time: float) -> void:
	for t in tracks:
		var ttl:=short_clue_lifetime(t.get("kind",""))
		if ttl>0 and at_time-t.time>=ttl:
			t.time=-100.0;t.node.visible=false
	for i in range(sounds.size()-1,-1,-1):
		var s:=sounds[i];var ttl:=short_clue_lifetime(s.kind)
		if ttl>0 and at_time-s.time>=ttl:sounds.remove_at(i)

func investigate() -> bool:
	expire_short_clues(elapsed)
	return super.investigate()

func tick(delta: float) -> void:
	if not advances_time(delta):return
	# The base tick increments elapsed BEFORE resolving a completed listen. Prune against
	# that upcoming time first, not afterwards, or expired water/reeds can renew HUD memory.
	expire_short_clues(elapsed+delta)
	var before:=elapsed
	super.tick(delta)
	if not wetland_active or elapsed==before:return
	for i in range(tufts.size()):
		if not is_instance_valid(tufts[i]):continue
		var age: float=elapsed-reed_events[i].time
		var bend:=0.0
		if age>=0 and age<REED_SECONDS and not game.preferences.reduced_motion:
			bend=sin(age*11.0)*0.18*pow(1-age/REED_SECONDS,2)
		var d: Vector3=reed_events[i].direction
		tufts[i].rotation=Vector3(d.z*bend,0,-d.x*bend)
	for i in range(tracks.size()):
		if tracks[i].node.visible and tracks[i].get("kind","")=="reed21":WetArt.update_reed_print(reed_visuals[i])
