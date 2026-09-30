extends Node
## Manor-only art dressing. Shader/GI/rules/controllers stay owned by their existing systems.
const Kit=preload("res://scripts/environment17/kit.gd")
var game
var studio
var enabled:=true
var detail_root: Node3D
var home_records: Array[Dictionary]=[]
var arena_id:=0
var furniture_id:=0
var rebuilds:=0
var toggle: CheckButton
var installed:=false

func _ready() -> void:
	game=get_parent();process_priority=100
	call_deferred("initialize")
func initialize() -> void:
	studio=game.get_node("ToyStudio")
	if not studio.active:call_deferred("initialize");return
	if not installed:
		installed=true
		toggle=CheckButton.new();toggle.text="가구·실내 마감 / Crafted scenery";toggle.button_pressed=enabled
		var column=studio.copy_label.get_parent();column.add_child(toggle);column.move_child(toggle,7)
		studio.copy_label.custom_minimum_size.y=65;studio.panel.size=Vector2i(650,650)
		toggle.toggled.connect(set_enabled)
	refresh()
func _process(_delta: float) -> void:
	if not installed or not is_instance_valid(game.arena):return
	refresh()
func refresh() -> void:
	if not is_instance_valid(game.arena):return
	if game.arena.get_instance_id()!=arena_id:
		restore();detail_root=null;home_records.clear();furniture_id=0
		arena_id=game.arena.get_instance_id()
		if game.arena.map_id=="toy_manor":build_fixed()
	if game.arena.map_id=="toy_manor" and game.arena.furnishings.get_instance_id()!=furniture_id:
		build_homes()
	if is_instance_valid(toggle):toggle.disabled=game.arena.map_id!="toy_manor"
func put(parent: Node3D,kind: String,at: Vector3,rotation: Vector3=Vector3.ZERO) -> Node3D:
	var n:=Kit.make(kind);n.position=at;n.rotation=rotation;parent.add_child(n);return n
func build_fixed() -> void:
	detail_root=Node3D.new();detail_root.name="CraftedManor17";game.arena.add_child(detail_root)
	for level in [0,1]:
		var y:=float(level)*4
		put(detail_root,"sofa" if level==0 else "bed",Vector3(-4,y,-6))
		put(detail_root,"kitchen" if level==0 else "wardrobe",Vector3(4,y,-6))
		put(detail_root,"play" if level==0 else "bath",Vector3(0,y,7))
		for x in [-10.0,-5.0,5.0,10.0]:put(detail_root,"window",Vector3(x,y+2.05,-12.64))
		# Frames on the opaque far wall; not in front of cover openings or room labels.
		for x in [-8.0,8.0]:put(detail_root,"wall_art",Vector3(x,y+2.0,-12.78))
	put(detail_root,"architecture",Vector3.ZERO)
	for at in [Vector3(-5.8,3.19,-3),Vector3(4.8,3.14,5.5),Vector3(-4,6.90,-5),Vector3(4,6.90,6)]:
		put(detail_root,"lamp",at)
	detail_root.visible=enabled;studio.apply_materials(detail_root);rebuilds+=1
func build_homes() -> void:
	# Restore only old art that we own. RoundParcel and gameplay reveal/trace nodes remain untouched.
	for record in home_records:
		for old in record.originals:
			var node=old.ref.get_ref()
			if is_instance_valid(node):node.visible=old.visible
		var prior=record.root.get_ref()
		if is_instance_valid(prior):prior.get_parent().remove_child(prior);prior.queue_free()
	home_records.clear();furniture_id=game.arena.furnishings.get_instance_id()
	for home in game.arena.homes:
		var originals: Array[Dictionary]=[]
		for child in home.root.get_children():
			if child is MeshInstance3D and child.name!="RoundParcel" and not child.name.begins_with("Grounding15"):
				originals.append({"ref":weakref(child),"visible":child.visible});child.visible=not enabled
		var n:=put(home.root,"home_"+str(home.id%6),Vector3.ZERO)
		n.name="CraftedHome17";n.visible=enabled
		home_records.append({"root":weakref(n),"originals":originals,"id":home.id})
		studio.apply_materials(n)
	rebuilds+=1
func set_enabled(value: bool) -> void:
	enabled=value
	if is_instance_valid(toggle):toggle.set_pressed_no_signal(value)
	if is_instance_valid(detail_root):detail_root.visible=value
	for record in home_records:
		var root=record.root.get_ref()
		if is_instance_valid(root):root.visible=value
		for old in record.originals:
			var n=old.ref.get_ref()
			if is_instance_valid(n):n.visible=bool(old.visible) and not value
func restore() -> void:
	for record in home_records:
		for old in record.originals:
			var n=old.ref.get_ref()
			if is_instance_valid(n):n.visible=old.visible
func _exit_tree() -> void:
	restore();home_records.clear()
