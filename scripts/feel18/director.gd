extends "res://scripts/smash/sync_director.gd"
## Extends the existing atomic contact path; every new onset consumes the same confirmed event.
const Impact18=preload("res://scripts/feel18/impact.gd")
const Audio18=preload("res://scripts/feel18/audio.gd")
const Trails18=preload("res://scripts/feel18/trails.gd")
var polished := true
var clock := 0.0
var trails
var toggle: CheckButton
var last_contact: Dictionary={}
var recoil_age := 1.0
var recoil_kind := ""
var recoil_actor := -1
var view_offset := Vector3.ZERO

func initialize() -> void:
	if active:return
	super.initialize()
	var old=effects;old.get_parent().remove_child(old);old.queue_free()
	effects=Impact18.new();game.add_child(effects)
	old=audio;old.get_parent().remove_child(old);old.queue_free()
	audio=Audio18.new();game.add_child(audio)
	trails=Trails18.new();game.add_child(trails)
	call_deferred("add_comparison")

func add_comparison() -> void:
	if is_instance_valid(toggle):return
	var scenery=game.get_node_or_null("Environment17")
	if scenery==null or not scenery.installed:call_deferred("add_comparison");return
	var existing: CheckButton=scenery.toggle
	var column=existing.get_parent();var index:=existing.get_index()
	var row:=HBoxContainer.new();column.add_child(row);column.move_child(row,index)
	existing.reparent(row);existing.text="가구 마감 / Scenery"
	toggle=CheckButton.new();toggle.text="타격 연출 / Smash polish";toggle.button_pressed=polished
	row.add_child(toggle);toggle.toggled.connect(set_polished)

func set_polished(value: bool) -> void:
	polished=value
	if is_instance_valid(toggle):toggle.set_pressed_no_signal(value)
	if is_instance_valid(effects):effects.polished=value
	if is_instance_valid(audio):audio.polished=value
	reset()
	if not value:
		for reaction in reactions:
			for star in reaction.stars.get_children():star.scale=Vector3.ONE*0.21

func _process(_delta: float) -> void:
	if not active or not is_instance_valid(audio):return
	# Pausing/hiding a Node3D does not automatically pause positional audio.
	audio.refresh_preferences(game.preferences.volume,game.paused)
	if game.preferences.reduced_motion or game.preferences.feedback_strength<=0:
		if is_instance_valid(trails):trails.reset()

func occluded(at: Vector3,normal: Vector3) -> bool:
	var eye: Vector3=game.camera.global_position
	var end:=at+normal.normalized()*0.08
	if eye.distance_to(end)<0.20:return false
	return not game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,end,1)).is_empty()

func contact(event: Dictionary) -> void:
	if not active or not is_instance_valid(audio) or game.paused:return
	if not event.get("world_point") is Vector3 or not event.get("normal") is Vector3:return
	if not event.world_point.is_finite() or not event.normal.is_finite():return
	var before:=handled
	audio.clock=clock;audio.next_muffled=polished and occluded(event.world_point,event.normal)
	audio.refresh_preferences(game.preferences.volume,game.paused)
	super.contact(event)
	if handled==before:return
	last_contact={"attack_id":event.attack_id,"attacker_id":event.attacker_id,"target_id":event.target_id,"time":clock,"at":event.world_point,"kind":last_kind}
	trails.stop_actor(event.attacker_id,true)
	if event.attacker_id==game.view_target() or event.target_id==game.view_target():
		recoil_age=0.0;recoil_kind=event.outcome;recoil_actor=game.view_target()
	if event.outcome=="hit":refine_reaction(event.target_id)

func refine_reaction(id: int) -> void:
	if not polished:return
	var r=reactions[id]
	if r.life<=0 or game.preferences.reduced_motion or game.preferences.feedback_strength<=0:return
	# Same reaction.age: a short directional settle, never a second hit clock or gameplay stun.
	var t: float=r.age/r.life
	var amount: float=clampf(game.preferences.feedback_strength,0,1)
	var displacement: float=sin(t*PI)*exp(-t*5.0)*0.055*amount
	r.position+=r.local_direction*displacement
	r.rotation*=0.90
	r.stars.visible=r.last_kind in ["heavy","finish"] or t<0.20
	for star in r.stars.get_children():star.scale=Vector3.ONE*(0.18 if r.last_kind in ["heavy","finish"] else 0.13)

func advance(delta: float) -> void:
	if not active or not is_instance_valid(trails) or not is_finite(delta) or delta<0:return
	if game.paused:delta=0.0
	clock+=delta;audio.clock=clock
	audio.refresh_preferences(game.preferences.volume,game.paused)
	super.advance(delta)
	var allowed: bool=polished and enabled and not game.preferences.reduced_motion and game.preferences.feedback_strength>0 and game.world_view_active() and not game.ui.modal.visible
	trails.advance(delta,game,allowed)
	for i in range(reactions.size()):refine_reaction(i)
	recoil_age=minf(1.0,recoil_age+delta)
	view_offset=Vector3.ZERO
	# Contact alignment has priority. Recovery recoil affects only hands, never camera yaw/pitch/FOV.
	if not allowed or recoil_actor!=game.view_target() or recoil_age<=0.065 or recoil_age>=0.25:return
	if game.rig.contact_age<game.rig.CONTACT_LIFE:return
	if not game.rig.hand_root.visible:return
	var t:=inverse_lerp(0.065,0.25,recoil_age)
	var ease: float=sin(t*PI)*(1-t)*game.preferences.feedback_strength
	view_offset=Vector3(0,-0.013*ease,(0.036 if recoil_kind=="blocked" else 0.020)*ease)
	game.rig.hand_root.position+=view_offset
	if is_instance_valid(game.rig.grip_rig):game.rig.grip_rig.update_pose(game.rig.hand_root,0)

func note_swing(actor) -> void:
	if not polished or not audio.recording or actor.hidden_in_box or not actor.visible:return
	if audio.recording_events.size()>=512:return
	audio.recording_events.append({"time":clock,"key":"swing_"+actor.handling,"variant":posmod(actor.attack_sequence,3),"muffled":false,"gain":game.preferences.volume*0.5})

func reset() -> void:
	super.reset();last_contact.clear();recoil_age=1.0;recoil_actor=-1;view_offset=Vector3.ZERO
	if is_instance_valid(trails):trails.reset()
