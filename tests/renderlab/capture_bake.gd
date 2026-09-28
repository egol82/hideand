extends SceneTree
## Standalone authoring preview; not the game and not an authority replacement.
var room
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var scene=load("res://assets/renderlab/generated/sugar_static.scn")
	if not scene is PackedScene: printerr("FAIL: no bake candidate"); quit(1); return
	room=scene.instantiate(); root.add_child(room)
	var gi: LightmapGI=room.get_node("LightmapGI")
	if gi.light_data==null or gi.light_data.get_user_count()<=0:
		printerr("FAIL: no editor-generated light data"); quit(1); return
	var saved=gi.light_data
	for baked in [false,true]:
		gi.light_data=saved if baked else null
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		var error:=root.get_texture().get_image().save_png("res://ci-artifacts/studio_gi_"+("on" if baked else "off")+".png")
		if error!=OK: printerr("FAIL: bake preview save"); quit(1); return
	print("STUDIO_GI_RENDER_PASS: paired actual static authoring-scene images")
	room.queue_free(); await process_frame; quit()
