extends SceneTree
## Produces an editable PackedScene; runtime uses the saved asset, not this builder.
const Bakery = preload("res://scripts/renderlab/patisserie.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var asset:=Bakery.create_island(); root.add_child(asset)
	own(asset,asset)
	var scene:=PackedScene.new(); var result:=scene.pack(asset)
	if result==OK: result=ResourceSaver.save(scene,"res://scenes/art/sugar_island.scn",ResourceSaver.FLAG_COMPRESS)
	if result!=OK: printerr("FAIL: studio asset ",error_string(result)); quit(1); return
	print("STUDIO_ASSET_SAVED"); asset.queue_free(); await process_frame; quit()
func own(node: Node, parent: Node) -> void:
	for child in node.get_children(): child.owner=parent; own(child,parent)
