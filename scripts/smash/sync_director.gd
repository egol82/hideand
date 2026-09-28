extends "res://scripts/smash/director.gd"
## Atomic contact onset: no delayed queue, no reading an eliminated actor's new position.
var synced_contacts := 0
func initialize() -> void:
	super.initialize()
	game.rig.cute_sync = true
	game.rig.last_revision = -1
	for reaction in reactions: reaction.immediate_impact = true

func contact(event: Dictionary) -> void:
	var before := handled
	super.contact(event)
	if handled == before: return
	synced_contacts += 1
	# Populate real instance transforms / label positions on the contact frame,
	# instead of making labels visible at their previous pooled location.
	effects.advance(0.0,game.camera.global_basis.orthonormalized())
	if event.outcome == "hit":
		reactions[event.target_id].advance(0.0,game.preferences.reduced_motion,game.preferences.feedback_strength)
	game.rig.register_contact(event,game.fighters[event.attacker_id])

func reset() -> void:
	super.reset()
	if is_instance_valid(game) and is_instance_valid(game.rig): game.rig.clear_contact()
