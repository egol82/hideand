@tool
extends EditorPlugin
## Opt-in real editor operation, never run in a game. No manually fabricated GI data.
const Build=preload("res://scripts/lighting15/build_room.gd")
var armed:=false
var busy:=false
var started:=false
var selected:=false
var elapsed:=0.0
var scene: Node
var gi: LightmapGI
func _enter_tree() -> void:
	if "--bake-manor15" in OS.get_cmdline_user_args():
		armed=true;call_deferred("open_scene")
func open_scene() -> void:EditorInterface.open_scene_from_path(Build.ScenePath)
func _process(delta: float) -> void:
	if not armed or busy:return
	elapsed+=delta
	if elapsed>600:finish(false,"editor bake deadline exceeded");return
	scene=EditorInterface.get_edited_scene_root()
	if scene==null or not scene.has_node("LightmapGI"):return
	gi=scene.get_node("LightmapGI")
	if not started:
		EditorInterface.edit_node(gi)
		var button:=find_button(EditorInterface.get_base_control())
		if button!=null and button.is_visible_in_tree():
			started=true;busy=true;print("LIGHTING15_BAKE_STARTED: actual editor toolbar")
			button.emit_signal("pressed");busy=false
	elif gi.light_data!=null and gi.light_data.get_user_count()>0:
		busy=true
		# Packing the edited scene directly avoids nested EditorInterface.save_scene progress dialogs.
		var packed:=PackedScene.new();var error:=packed.pack(scene)
		if error==OK:error=ResourceSaver.save(packed,Build.ScenePath,ResourceSaver.FLAG_COMPRESS)
		finish(error==OK,"saved populated LightmapGI native scene" if error==OK else error_string(error))
	elif not selected:
		var dialog=find_dialog(EditorInterface.get_base_control())
		if dialog!=null:
			selected=true;busy=true;dialog.current_path=Build.DataPath
			dialog.hide();dialog.emit_signal("file_selected",Build.DataPath);busy=false
func finish(ok: bool,reason: String) -> void:
	armed=false;set_process(false)
	var users:=gi.light_data.get_user_count() if is_instance_valid(gi) and gi.light_data!=null else 0
	var data: Dictionary={"baked":ok and users>0,"users":users,"reason":reason,"renderer":RenderingServer.get_current_rendering_method()}
	var f:=FileAccess.open("res://ci-artifacts/lighting15-bake.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "));f.close()
	print("LIGHTING15_BAKE_PASS: " if data.baked else "LIGHTING15_BAKE_FAIL: ",JSON.stringify(data))
	# Let renderer/editor save jobs settle; quit once, outside progress callbacks.
	get_tree().create_timer(1.0).timeout.connect(func():get_tree().quit(0 if data.baked else 1))
func find_button(n: Node) -> Button:
	if n is Button and n.text=="Bake Lightmaps":return n
	for c in n.get_children():
		var found:=find_button(c)
		if found!=null:return found
	return null
func find_dialog(n: Node):
	if n is EditorFileDialog and n.visible and "lightmap" in n.title.to_lower():return n
	for c in n.get_children():
		var found=find_dialog(c)
		if found!=null:return found
	return null
