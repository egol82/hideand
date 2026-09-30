extends "res://scripts/feel18/game.gd"
## Opt-in adapter: all original movement, inspection, capture and combat handlers are inherited.
const PineServices=preload("res://scripts/pine21/services.gd")
func _ready() -> void:
	super._ready()
	var old=hiding;remove_child(old);old.queue_free()
	hiding=PineServices.new();add_child(hiding);hiding.setup(self)

func _free_spot(id: int) -> int:
	var selected:=super._free_spot(id)
	if not hiding is PineServices or hiding.can_enter(id,selected):return selected
	for h in hiding.homes:
		if hiding.usable(h.id) and hiding.can_enter(id,h.id) and not _occupied(h.id,id):return h.id
	return -1

func _hide_bot(id: int,delta: float) -> Vector3:
	if hiding is PineServices and not hiding.can_enter(id,hide_assignments[id]):hide_assignments[id]=_free_spot(id)
	return super._hide_bot(id,delta)

func _process(delta: float) -> void:
	super._process(delta)
	if not hiding is PineServices or not hiding.pine_active or paused or not world_view_active() or ui.modal.visible:return
	if fighters[0].hidden_in_box and fighters[0].spot in PineServices.BUSH_IDS:
		ui.action_hint.text=("수풀 %.1f초 · %s / %s 나가기" if preferences.language=="ko" else "Thicket %.1fs · %s / %s exit")%[hiding.remaining[0],controls.hint("interact"),controls.hint("dash")]
