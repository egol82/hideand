extends "res://scripts/character13/game.gd"
## Opt-in animation adapter. No authority changes; old scenes still use their original pose bridge.
const Animator = preload("res://scripts/animation16/animator.gd")
var motion_entries: Dictionary={}
var animation_enabled:=true
var motion_revision:=0

func _motion(avatar):
	var id: int=avatar.get_instance_id()
	if motion_entries.has(id) and is_instance_valid(motion_entries[id]):return motion_entries[id]
	# Remove stale references as workshop previews are replaced.
	for key in motion_entries.keys():
		if not is_instance_valid(motion_entries[key]):motion_entries.erase(key)
	var node:=Animator.new();avatar.add_child(node);node.setup(avatar)
	motion_entries[id]=node;motion_revision+=1
	return node

func _sync_characters(delta: float) -> void:
	# Pause preserves final bones, not a freshly reapplied legacy pose.
	if paused and skin_ready and not motion_entries.is_empty():return
	super._sync_characters(0.0)
	if not skin_ready or not animation_enabled:return
	var fx=get_node("SmashDirector")
	for actor in fighters:
		var peek: bool=hiding.peek_active[actor.player_id] if is_instance_valid(hiding) else false
		var transit: bool=hiding.transit.has(actor.player_id) if is_instance_valid(hiding) else false
		_motion(actor.body_art).update_actor(actor,fx.reactions[actor.player_id],delta,preferences.reduced_motion,peek,transit)
	for ghost in fx.ghosts:
		var ghost_motion=_motion(ghost.toy)
		if ghost.root.visible and ghost.life>0:
			ghost_motion.evaluate("ko",ghost.age/maxf(0.001,ghost.life),delta,preferences.reduced_motion)
	if is_instance_valid(ui.preview_actor) and ui.preview_actor is Buddy:
		var preview=_motion(ui.preview_actor)
		if not preferences.reduced_motion:preview.local_clock+=delta
		preview.evaluate("weapon_ready",fposmod(preview.local_clock/3,1),delta,preferences.reduced_motion)
		# Preview uses the existing selected point, never moves the user's actual drawing.
		ui.preview_actor._ready_arm(7,8,9,ui.preview_actor.to_local(ui.preview_grip.global_position))
		ui.preview_actor._copy_face()

func _ready() -> void:
	super._ready()
	smash_reset.connect(_reset_motion)

func _reset_motion() -> void:
	for node in motion_entries.values():
		if is_instance_valid(node):node.reset()
