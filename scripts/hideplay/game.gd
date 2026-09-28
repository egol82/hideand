extends "res://scripts/phase4/game.gd"
## Explicit adapter for the new hide/search rules. Historical entry scenes keep their old controller.
const Manor = preload("res://scripts/hideplay/manor.gd")
const Services = preload("res://scripts/hideplay/services.gd")
const HideUI = preload("res://scripts/hideplay/interface.gd")
var hiding
var paths3: Array = [PackedVector3Array(),PackedVector3Array(),PackedVector3Array(),PackedVector3Array()]
var skill_key: int=KEY_Q
var cycle_key: int=KEY_R
var peek_yaw:=0.0
var was_hidden:=false

func _ready() -> void:
	super._ready()
	var old=ui; remove_child(old); old.queue_free()
	ui=HideUI.new(); ui.game=self; add_child(ui)
	hiding=Services.new(); add_child(hiding); hiding.setup(self)
	for a in fighters:
		a.floor_snap_length=0.35
		a.floor_constant_speed=true
	var chosen:="toy_manor"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): chosen=arg.trim_prefix("--map=")
	select_map(chosen)
	ui.show_menu()

func select_map(id: String) -> void:
	if rules.phase!=Rules.Phase.MENU: return
	if id=="toy_manor":
		map_id=id
		remove_child(arena); arena.queue_free(); arena=Manor.new(); add_child(arena)
		rules.configure(arena.config)
		for i in range(4): fighters[i].original_spawn=arena.spawn_points[i]; fighters[i].reset_fight(arena.spawn_points[i]); fighters[i].show_weapon(false)
		rig.face(Vector3.FORWARD)
	else: super.select_map(id)
	if is_instance_valid(hiding): hiding.configure(0)
	paths3=[PackedVector3Array(),PackedVector3Array(),PackedVector3Array(),PackedVector3Array()]

func _prepare_round() -> void:
	if is_instance_valid(hiding): hiding.configure(int(rng.seed)+rules.round_index*991)
	super._prepare_round()
	if is_instance_valid(hiding):
		var available: Array[int]=[]
		for index in arena.active_spots: if hiding.usable(index): available.append(index)
		_shuffle(available)
		for i in range(4): hide_assignments[i]=available.pop_back() if i!=rules.seeker and not available.is_empty() else -1
	paths3=[PackedVector3Array(),PackedVector3Array(),PackedVector3Array(),PackedVector3Array()]
	call_deferred("_refresh_round_art")

func _refresh_round_art() -> void:
	if has_node("ToyStudio") and arena.has_method("set_layout"):
		get_node("ToyStudio").apply_materials(arena.furnishings)

func _phase_changed() -> void:
	super._phase_changed()
	if not is_instance_valid(hiding): return
	if rules.phase==Rules.Phase.DUEL and hiding.ambush_player>=0:
		var id: int=hiding.ambush_player; hiding.ambush_player=-1
		if id in [rules.seeker,rules.opponent] and rules.alive[id]: fighters[id].begin_swing()
	if rules.phase in [Rules.Phase.RESULT,Rules.Phase.COMPLETE]:
		hiding.reset()

func _free_spot(id: int) -> int:
	if not is_instance_valid(hiding): return super._free_spot(id)
	var list: Array[int]=[]
	for i in arena.active_spots: if hiding.usable(i) and not _occupied(i,id): list.append(i)
	_shuffle(list); return -1 if list.is_empty() else list[0]
func _hide_bot(id: int,delta: float) -> Vector3:
	if not is_instance_valid(hiding): return super._hide_bot(id,delta)
	var actor=fighters[id]
	if actor.hidden_in_box: return Vector3.ZERO
	var index: int=hide_assignments[id]
	if not hiding.usable(index) or _occupied(index,id): index=_free_spot(id); hide_assignments[id]=index
	if index<0: return Vector3.ZERO
	if actor.position.distance_to(arena.spots[index])<0.58:
		hiding.hide_actor(id,index); return Vector3.ZERO
	return _navigate(id,arena.spots[index],delta)

func _navigate(id: int,destination: Vector3,delta: float) -> Vector3:
	if not arena.has_method("route3"): return super._navigate(id,destination,delta)
	repath[id]-=delta
	if repath[id]<=0 or paths3[id].is_empty():
		paths3[id]=arena.route3(fighters[id].position,destination); repath[id]=0.6
	var path: PackedVector3Array=paths3[id]
	while not path.is_empty():
		var d: Vector3=path[0]-fighters[id].position
		if Vector2(d.x,d.z).length()<0.30 and absf(d.y)<0.5: path.remove_at(0)
		else:
			paths3[id]=path; d.y=0; return d.normalized()*0.88
	paths3[id]=path
	var final: Vector3=destination-fighters[id].position; final.y=0; return final.limit_length()*0.7

func _bot_move(id: int,delta: float) -> Vector3:
	if is_instance_valid(hiding) and (hiding.transit.has(id) or hiding.inspecting.has(id)): return Vector3.ZERO
	if rules.phase==Rules.Phase.DUEL and id in [rules.seeker,rules.opponent]:
		var other: int=rules.opponent if id==rules.seeker else rules.seeker
		if absf(fighters[id].position.y-fighters[other].position.y)>1.5: return _navigate(id,fighters[other].position,delta)
	return super._bot_move(id,delta)
func _move_input() -> Vector3:
	if is_instance_valid(hiding) and hiding.transit.has(0): return Vector3.ZERO
	return super._move_input()
func _update_actor_events(id: int) -> void:
	var prior_point:=heard_point; var prior_time:=heard_time
	super._update_actor_events(id)
	if is_instance_valid(hiding):
		# Preserve shared swing/audio bookkeeping, but replace its old flat-floor hearing route.
		heard_point=prior_point; heard_time=prior_time
		if local_notice=="FOOTSTEPS NEARBY": local_notice_time=0
		hiding.step_record(id)
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not automated and is_instance_valid(hiding): hiding.tick(delta)

func _focused_spot() -> int:
	if not is_instance_valid(hiding) or not _can_hide_now() or not rules.alive[0] or fighters[0].hidden_in_box: return -1
	var best:=0.5; var result:=-1
	for h in hiding.homes:
		if h.id not in arena.active_spots or fighters[0].position.distance_to(h.entry)>2.0: continue
		var p: Vector3=h.entry+Vector3.UP
		var direction: Vector3=(p-camera.global_position).normalized()
		var dot: float=(-camera.global_basis.z).dot(direction)
		if dot>best and arena.clear_ray(camera.global_position,p): best=dot; result=h.id
	return result
func _interact() -> void:
	if not is_instance_valid(hiding) or paused or not rules.alive[0] or is_spectating(): return
	if fighters[0].hidden_in_box: hiding.leave(0); return
	var port: Dictionary=hiding.passage(0)
	if not port.is_empty() and rules.phase in [Rules.Phase.HIDE,Rules.Phase.SEEK,Rules.Phase.DUEL]: hiding.travel(0,port); return
	if not _can_hide_now(): return
	var index:=_focused_spot()
	if index<0: return
	if rules.seeker==0:
		if rules.phase==Rules.Phase.SEEK and inspect_cooldown<=0: inspect_cooldown=0.65; _inspect(0,index)
	elif not hiding.usable(index): hiding.tell("여긴 물건이 가득해요. 다른 곳을 찾아보세요.","Packed with toys. Find another hiding place.")
	elif hiding.hide_actor(0,index):
		peek_yaw=PI; rig.yaw=peek_yaw; rig.pitch=0

func _inspect(id: int,index: int,immediate: bool=false) -> void:
	if not is_instance_valid(hiding): super._inspect(id,index); return
	if index<0 or index>=hiding.homes.size() or rules.phase!=Rules.Phase.SEEK: return
	if fighters[id].position.distance_to(hiding.homes[index].entry)>2.2: return
	if not arena.clear_ray(fighters[id].position+Vector3.UP,hiding.homes[index].entry+Vector3.UP): return
	if not immediate:
		if not hiding.inspecting.has(id):
			hiding.inspecting[id]={"index":index,"age":0.0,"start":fighters[id].position}
		return
	hiding.inspecting.erase(id)
	hiding.sound_at(fighters[id].position,id,10,"inspect")
	if not hiding.usable(index):
		if id==0: hiding.tell("장난감만 있네요!","Only toys in here!")
		return
	super._inspect(id,index)
func _taunt() -> void:
	if rules.phase!=Rules.Phase.SEEK or rules.seeker==0 or not rules.alive[0] or taunt_cooldown>0: return
	taunt_cooldown=6
	hiding.sound_at(fighters[0].position,0,16,"taunt"); audio.play_at("taunt",fighters[0].position)
	hiding.tell("여기지롱! 소리로 내 구역을 알렸어요.","Over here! You made a public sound clue.")

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(hiding): super._unhandled_input(event); return
	if paused or ui.modal.visible or not rules.alive[0]: return
	choose_extra_keys()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==cycle_key and rules.seeker==0:
			hiding.skill_index=(hiding.skill_index+1)%3; return
		if event.physical_keycode==skill_key:
			if rules.seeker==0: hiding.investigate()
			elif not hiding.deploy_decoy(0): hiding.tell("장난감이 없거나 앞쪽에 놓을 공간이 없어요.","No toy charge or no clear space ahead.")
			return
	if hiding.transit.has(0): return
	if fighters[0].hidden_in_box:
		if controls.pressed(event,"dash"): hiding.leave(0,true)
		elif controls.pressed(event,"attack"): hiding.ambush(0)
		elif controls.pressed(event,"interact"): _interact()
		elif controls.pressed(event,"taunt"): _taunt()
		return
	# New contextual passage action also works during field pursuit.
	if controls.pressed(event,"interact") and not hiding.passage(0).is_empty(): _interact(); return
	super._unhandled_input(event)

func choose_extra_keys() -> void:
	var unused: Array[int]=[]
	for code in [KEY_Q,KEY_R,KEY_F,KEY_V,KEY_B,KEY_N,KEY_1,KEY_2]:
		if code not in controls.bindings.values(): unused.append(code)
	if unused.size()>=2: skill_key=unused[0]; cycle_key=unused[1]
func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(hiding) or not is_instance_valid(ui): return
	choose_extra_keys()
	var hidden: bool=fighters[0].hidden_in_box and rules.alive[0] and not is_spectating() and world_view_active()
	if hidden:
		var index: int=fighters[0].spot
		if index>=0 and index<hiding.homes.size():
			rig.position=hiding.homes[index].peek
			if not was_hidden: peek_yaw=PI
			rig.yaw=peek_yaw+clampf(wrapf(rig.yaw-peek_yaw,-PI,PI),-0.80,0.80)
			rig.pitch=clampf(rig.pitch,-0.25,0.25); rig._apply_rotation()
	was_hidden=hidden
	ui.hide_view(hidden and not paused and not ui.modal.visible,hidden and hiding.peek_active[0])
	if hiding.transit.has(0) and not paused and not ui.modal.visible:
		ui.hide_view(true,false)
		ui.action_hint.text="통로 이동 중 / IN THE PASSAGE"
	for i in range(4): fighters[i]._set_layers(hiding.peek_eyes[i],(1<<18) if i==view_target() else 1)

func _begin_duel() -> void:
	super._begin_duel()
	if is_instance_valid(hiding):
		for i in [rules.seeker,rules.opponent]:
			if i>=0: hiding.peek_active[i]=false; hiding.peek_time[i]=0; hiding.peek_eyes[i].visible=false
func return_to_menu() -> void:
	if is_instance_valid(hiding): hiding.reset()
	super.return_to_menu()
