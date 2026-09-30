extends "res://scripts/wetland21/game.gd"
const CanyonServices=preload("res://scripts/canyon21/services.gd")
func _ready() -> void:
	super._ready()
	var old=hiding;remove_child(old);old.queue_free()
	hiding=CanyonServices.new();add_child(hiding);hiding.setup(self)
func _process(delta: float) -> void:
	super._process(delta)
	if not hiding is CanyonServices or not hiding.canyon_active or paused or ui.modal.visible or not world_view_active():return
	if hiding.transit.has(0) and hiding.transit[0].get("canyon21",false):
		# This corridor is exposed, not the dark hidden-passage vignette inherited from the manor.
		ui.hide_view(false,false)
		ui.action_hint.visible=true
		ui.action_hint.text="노출 통과 중 · 공격에 맞을 수 있어요 / EXPOSED CROSSING"
	elif not fighters[0].hidden_in_box and not hiding.passage(0).is_empty():
		var wait: float=maxf(0,hiding.lane_ready[0]-hiding.elapsed)
		ui.action_hint.visible=true
		ui.action_hint.text=("통과로 %.1f초 후 재사용 / Cooldown"%wait) if wait>0 else (controls.hint("interact")+" · 빠른 통과 1.35초 · 큰 소리 / FAST · LOUD")
