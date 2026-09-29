extends "res://scripts/premium/game.gd"
## The Phase 13 opt-in adapter swaps only art. All prior input/rules/collision code stays.
const Buddy=preload("res://scripts/character13/avatar.gd")
var skin_ready:=false
var preview_revision:=0

func _ready() -> void:
	super._ready()
	for actor in fighters:
		var old: Node3D=actor.body_art
		var fresh:=Buddy.new();fresh.configure(actor.tint)
		old.get_parent().add_child(fresh);fresh.transform=old.transform
		old.get_parent().remove_child(old);old.queue_free();actor.body_art=fresh
	call_deferred("_finish_characters")

func _finish_characters() -> void:
	var smash=get_node("SmashDirector")
	if not smash.active:smash.initialize()
	for i in range(4):
		fighters[i].body_art.attach_reaction(smash.reactions[i])
		var ghost: Dictionary=smash.ghosts[i]
		var old: Node3D=ghost.toy
		var fresh:=Buddy.new();fresh.configure(fighters[i].tint)
		old.get_parent().add_child(fresh)
		# Keep existing KO stars/spiral overlays, remove the old primitive body completely.
		for child in old.get_children():
			if child is MeshInstance3D and child.mesh!=null and child.material_override is StandardMaterial3D and child.material_override.albedo_color==Color("29444c"):
				child.reparent(fresh.face,false);child.position-=Vector3(0,1.37,0.015)
		for label in ["LeftEye","RightEye","LeftGlint","RightGlint"]:fresh.controls[label].visible=false
		old.get_parent().remove_child(old);old.queue_free();ghost.toy=fresh
		smash.ghosts[i]=ghost
	skin_ready=true
	var studio=get_node_or_null("ToyStudio")
	if is_instance_valid(studio):
		for actor in fighters:studio.apply_materials(actor.body_art)
		for ghost in smash.ghosts:studio.apply_materials(ghost.toy)
	_sync_characters(0)

func _process(delta: float) -> void:
	super._process(delta)
	if autoplay and DisplayServer.get_name()=="headless":return
	if skin_ready:_sync_characters(0.0 if paused else delta)

func _consume_event(event: Dictionary) -> void:
	super._consume_event(event)
	if skin_ready:_sync_characters(0.0)

func _sync_characters(delta: float) -> void:
	var smash=get_node("SmashDirector")
	for actor in fighters:
		var reacting: bool=smash.reactions[actor.player_id].life>0 or actor.flash>0
		actor.body_art.pose_mode="weapon_ready" if actor.weapon.visible and not reacting else "idle"
		actor.body_art.grip_target=actor.body_art.global_transform.affine_inverse()*actor.weapon_pivot.global_position
		actor.body_art.sync_pose(delta,preferences.reduced_motion)
	for ghost in smash.ghosts:ghost.toy.sync_pose(delta,preferences.reduced_motion)
	if is_instance_valid(ui.preview_actor):
		if not ui.preview_actor is Buddy:
			var old: Node3D=ui.preview_actor;var parent:=old.get_parent()
			var fresh:=Buddy.new();fresh.configure(COLORS[0]);fresh.transform=old.transform
			parent.add_child(fresh)
			ui.preview_grip.reparent(fresh,false)
			parent.remove_child(old);old.queue_free();ui.preview_actor=fresh;preview_revision+=1
			fresh.pose_mode="weapon_ready"
			var studio=get_node_or_null("ToyStudio")
			if is_instance_valid(studio):studio.apply_materials(fresh)
		ui.preview_actor.sync_pose(delta,preferences.reduced_motion)
