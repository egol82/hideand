@tool
extends EditorPlugin
## Opt-in editor automation of the real Bake Lightmaps command; never runs in the game.
var armed:=false
var started:=false
var selected_file:=false
var waited:=0.0
var lightmap: LightmapGI
func _enter_tree() -> void:
	if "--studio-bake" in OS.get_cmdline_user_args():
		armed=true; call_deferred("open_room")
func open_room() -> void:
	EditorInterface.open_scene_from_path("res://assets/renderlab/generated/sugar_static.scn")
func finish(ok: bool, reason: String) -> void:
	armed=false
	var data: Dictionary={"baked":ok,"reason":reason,"renderer":RenderingServer.get_current_rendering_method(),"users":lightmap.light_data.get_user_count() if is_instance_valid(lightmap) and lightmap.light_data!=null else 0}
	var f:=FileAccess.open("res://ci-artifacts/studio-bake.json",FileAccess.WRITE)
	if f!=null: f.store_string(JSON.stringify(data,"  ")); f.close()
	if ok: print("STUDIO_GI_BAKE_PASS: ",JSON.stringify(data))
	else: printerr("STUDIO_GI_BAKE_FAILED: ",reason)
	get_tree().quit(0 if ok else 1)
func _process(delta: float) -> void:
	if not armed: return
	waited+=delta
	if waited>360: finish(false,"editor did not produce populated LightmapGIData within timeout"); return
	var root:=EditorInterface.get_edited_scene_root()
	if root==null or not root.has_node("LightmapGI"): return
	lightmap=root.get_node("LightmapGI")
	if not started:
		EditorInterface.edit_node(lightmap)
		var button=find_bake_button(EditorInterface.get_base_control())
		if button!=null and button.is_visible_in_tree():
			started=true; print("STUDIO_GI_BAKE_STARTED: real editor toolbar action"); button.emit_signal("pressed")
	elif lightmap.light_data!=null and lightmap.light_data.get_user_count()>0:
		var error:=EditorInterface.save_scene()
		if error!=OK: finish(false,"cannot save baked scene: "+error_string(error)); return
		finish(true,"editor-created lightmap textures, users and data saved")
	elif not selected_file:
		var dialog=find_save_dialog(EditorInterface.get_base_control())
		if dialog!=null:
			selected_file=true
			dialog.current_path="res://assets/renderlab/generated/sugar_static.lmbake"
			dialog.hide(); dialog.emit_signal("file_selected",dialog.current_path)
func find_bake_button(node: Node) -> Button:
	if node is Button and node.text=="Bake Lightmaps": return node
	for child in node.get_children():
		var found:=find_bake_button(child)
		if found!=null: return found
	return null
func find_save_dialog(node: Node):
	if node is EditorFileDialog and node.visible and "lightmap" in node.title.to_lower(): return node
	for child in node.get_children():
		var found=find_save_dialog(child)
		if found!=null: return found
	return null
