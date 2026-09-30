extends "res://scripts/pine21/game.gd"
## Same Pine adapter and original controllers; only the more specific service is installed.
const WetServices=preload("res://scripts/wetland21/services.gd")
func _ready() -> void:
	super._ready()
	var old=hiding;remove_child(old);old.queue_free()
	hiding=WetServices.new();add_child(hiding);hiding.setup(self)
