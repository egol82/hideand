extends SceneTree
## Optional native scene export. No engine, fonts or gameplay-only objects in the editable art library.
const Kit=preload("res://scripts/environment17/kit.gd")
func _initialize() -> void:call_deferred("run")
func own(n: Node,ancestor: Node) -> void:
	for c in n.get_children():c.owner=ancestor;own(c,ancestor)
func run() -> void:
	var folder:="res://assets/environment17/generated"
	DirAccess.make_dir_recursive_absolute(folder)
	var kinds:=["sofa","bed","kitchen","wardrobe","play","bath","home_0","home_1","home_2","home_3","home_4","home_5","window","lamp","wall_art","architecture"]
	var count:=0
	for kind in kinds:
		var art:=Kit.make(kind);own(art,art)
		var packed:=PackedScene.new()
		if packed.pack(art)!=OK or ResourceSaver.save(packed,folder+"/"+kind+".scn",ResourceSaver.FLAG_COMPRESS)!=OK:
			push_error("Export failed "+kind);quit(1);return
		var scene=load(folder+"/"+kind+".scn").instantiate()
		if scene.get_child_count()!=art.get_child_count():push_error("Native reload lost meshes");quit(1);return
		for c in scene.get_children():
			if not c is MeshInstance3D or c.mesh==null or c.gi_mode!=GeometryInstance3D.GI_MODE_DYNAMIC:push_error("Native art invalid");quit(1);return
		scene.free();art.free();count+=1
	print("ENVIRONMENT17_EXPORT_PASS: ",count," native scenes saved and reloaded");quit()
