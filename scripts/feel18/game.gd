extends "res://scripts/animation16/game.gd"
## The original event handler still owns swings/footsteps/hearing. Only the played waveform changes.
const Sound18=preload("res://scripts/feel18/sound_design.gd")
func _update_actor_events(id: int) -> void:
	var fx=get_node_or_null("SmashDirector")
	var actor=fighters[id]
	var use: bool=fx!=null and fx.active and fx.polished and actor.attack_sequence!=attack_seen[id]
	var original=audio.streams.get("swing")
	if use:
		var variants: Array=[]
		for i in range(3):variants.append(Sound18.stream("swing_"+actor.handling,i))
		audio.streams["swing"]=variants
		fx.note_swing(actor)
	super._update_actor_events(id)
	if use:audio.streams["swing"]=original
