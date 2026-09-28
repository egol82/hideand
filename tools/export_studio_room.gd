extends SceneTree
const Scene=preload("res://scenes/phase10.tscn")
const Exporter=preload("res://scripts/renderlab/bake_export.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Scene.instantiate(); root.add_child(game); game.automated=true
	await process_frame; await process_frame
	game.select_map("sugar_market")
	await process_frame; await process_frame
	game.get_node("ToyStudio").set_profile(1)
	var exporter=Exporter.new()
	var report: Dictionary=exporter.export_room(game.arena,"res://assets/renderlab/generated/sugar_static.scn")
	var file:=FileAccess.open("res://ci-artifacts/studio-export.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"  ")); file.close()
	print("STUDIO_EXPORT_RESULT: ",JSON.stringify(report))
	game.queue_free(); await process_frame
	if report.errors.is_empty() and report.meshes>0: print("STUDIO_UV2_EXPORT_PASS"); quit()
	else: printerr("FAIL: static export"); quit(1)
