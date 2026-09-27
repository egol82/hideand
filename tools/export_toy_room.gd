extends SceneTree
## An editable geometry snapshot, NOT a LightmapGI bake or UV2 unwrap.
## Run: godot --headless --path . --script res://tools/export_toy_room.gd
const Arena = preload("res://scripts/phase4/arena.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var arena := Arena.new()
	arena.map_id = "toy_home"
	root.add_child(arena)
	await process_frame
	var snapshot := Node3D.new()
	snapshot.name = "AuthoredToyRoom"
	root.add_child(snapshot)
	for child in arena.get_children():
		arena.remove_child(child)
		snapshot.add_child(child)
		own(child,snapshot)
	var packed := PackedScene.new()
	var error := packed.pack(snapshot)
	if error == OK: error = ResourceSaver.save(packed,"user://phase4_toy_room.tscn")
	print("ROOM_SNAPSHOT: "+ProjectSettings.globalize_path("user://phase4_toy_room.tscn") if error == OK else "FAIL: room snapshot "+error_string(error))
	arena.queue_free()
	snapshot.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
func own(node: Node, scene: Node) -> void:
	node.owner = scene
	for child in node.get_children(): own(child,scene)
