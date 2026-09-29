extends SceneTree
## Optional editable Godot library/rig export. Never runs during normal gameplay; no physics tracks.
const Clips=preload("res://scripts/animation16/clips.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var folder:="res://assets/animation16/generated"
	DirAccess.make_dir_recursive_absolute(folder)
	if ResourceSaver.save(Clips.library(),folder+"/toy_motion.tres")!=OK:
		push_error("Motion library save failed");quit(1);return
	var rig=load("res://assets/character13/buddy_rig.scn").instantiate()
	root.add_child(rig)
	var player:=AnimationPlayer.new();player.name="AnimationPlayer16";rig.add_child(player);player.owner=rig
	player.add_animation_library("",load(folder+"/toy_motion.tres"));player.root_node=NodePath("..")
	var packed:=PackedScene.new()
	if packed.pack(rig)!=OK or ResourceSaver.save(packed,folder+"/buddy_motion.scn",ResourceSaver.FLAG_COMPRESS)!=OK:
		push_error("Editable motion scene save failed");quit(1);return
	var reload=load(folder+"/buddy_motion.scn").instantiate();root.add_child(reload)
	var ap: AnimationPlayer=reload.get_node("AnimationPlayer16")
	ap.play("walk");ap.seek(0.25,true)
	if reload.get_node("Skeleton3D").get_bone_pose_rotation(10).is_equal_approx(Quaternion.IDENTITY):
		push_error("Reloaded clip did not move an actual bone");quit(1);return
	rig.queue_free();reload.queue_free();await process_frame
	print("ANIMATION16_EXPORT_PASS: editable library and rig saved and reloaded");quit()
