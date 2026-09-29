extends SceneTree
const Builder=preload("res://scripts/character13/mesh_builder.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var start:=Time.get_ticks_msec()
	var mesh:=Builder.mesh()
	var error:=ResourceSaver.save(mesh,"res://assets/character13/buddy_body.res",ResourceSaver.FLAG_COMPRESS)
	if error!=OK:push_error("Character resource save failed");quit(1);return
	var avatar=load("res://scripts/character13/avatar.gd").new()
	avatar.configure(Color("88d6b0"));root.add_child(avatar);avatar.pose_mode="rest";avatar.sync_pose(0,true)
	own(avatar,avatar)
	# Standalone editable rig with baked rest/skin. Runtime uses the same mesh and rig definition.
	avatar.set_script(null)
	var packed:=PackedScene.new()
	if packed.pack(avatar)!=OK or ResourceSaver.save(packed,"res://assets/character13/buddy_rig.scn",ResourceSaver.FLAG_COMPRESS)!=OK:
		push_error("Character rig export failed");quit(1);return
	avatar.queue_free();await process_frame
	print("CHARACTER_BUILD_PASS: vertices=",mesh.get_meta("vertices")," triangles=",mesh.get_meta("triangles")," milliseconds=",Time.get_ticks_msec()-start)
	quit()

func own(node: Node,owner_node: Node) -> void:
	for child in node.get_children():child.owner=owner_node;own(child,owner_node)
