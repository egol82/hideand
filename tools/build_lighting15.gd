extends SceneTree
const Manor=preload("res://scripts/hideplay/manor.gd")
const Build=preload("res://scripts/lighting15/build_room.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var arena:=Manor.new();root.add_child(arena)
	await process_frame
	var build:=Build.new();var report: Dictionary=build.build(arena)
	var file:=FileAccess.open("res://ci-artifacts/lighting15-build.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	print("LIGHTING15_EXPORT: ",JSON.stringify(report))
	arena.queue_free();await process_frame
	if report.errors.is_empty() and report.meshes>0 and report.manual_probes>0:
		print("LIGHTING15_BUILD_PASS");quit()
	else:push_error("native lighting export failed");quit(1)
