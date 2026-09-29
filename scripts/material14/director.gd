extends "res://scripts/renderlab/director.gd"
## Materials only: reuses all previous scene/profile/lighting restoration and no authority writes.
const Materials14=preload("res://scripts/material14/materials.gd")
const MaterialSettings:="user://toy_material14.cfg"
var material_choice: OptionButton
var micro_choice: CheckButton
var weapon_revisions: Dictionary={}
func _ready() -> void:
	converter=Materials14.new()
	super._ready()
func _process(delta: float) -> void:
	super._process(delta)
	if not active:return
	# Equip replaces world meshes independently of the camera view. Refresh exactly on that revision.
	for actor in game.fighters:
		var stamp: Array=[actor.drawing_revision,actor.weapon.get_instance_id()]
		if weapon_revisions.get(actor.player_id,[])!=stamp:
			weapon_revisions[actor.player_id]=stamp;apply_materials(actor.weapon)
	if converter.cache.size()>2048:prune()
func apply_materials(node: Node) -> void:
	super.apply_materials(node)
	# The base traversal dispatches this override once per node. Do not recursively traverse twice.
	if profile!=2 or not node is MeshInstance3D:return
	var source=node.get_meta("studio_source",null)
	if not source is StandardMaterial3D:return
	var role:="body" if node.name=="ConnectedBody" else ("cutout" if node.name=="SafeFoamFill" else "surface")
	if role!="surface":node.material_override=converter.convert_role(source,true,(node.layers&(1<<19))!=0,role)
func make_ui() -> void:
	super.make_ui()
	panel.size=Vector2i(620,424)
	var column=copy_label.get_parent()
	material_choice=OptionButton.new();material_choice.custom_minimum_size.y=42
	material_choice.add_item("재질 1세대 / Materials I");material_choice.add_item("재질 2세대 / Materials II")
	column.add_child(material_choice);column.move_child(material_choice,2)
	micro_choice=CheckButton.new();micro_choice.text="미세 표면 / Surface microdetail";micro_choice.custom_minimum_size.y=34
	column.add_child(micro_choice);column.move_child(micro_choice,3)
	material_choice.item_selected.connect(func(i: int):set_material_generation(i+1,true))
	micro_choice.toggled.connect(func(v: bool):set_microdetail(v,true))
	if not game.synthetic_run:_load_material_setting()
	material_choice.select(converter.generation-1);micro_choice.set_pressed_no_signal(converter.detail)
	options.set_item_text(2,"C · SOFT TOY / 장난감 재질")
	update_copy()
func set_material_generation(value: int,persist: bool=false) -> void:
	if value not in [1,2]:return
	converter.generation=value
	if is_instance_valid(material_choice):material_choice.select(value-1)
	set_profile(profile,false)
	if persist and not game.synthetic_run:_save_material_setting()
func set_microdetail(value: bool,persist: bool=false) -> void:
	converter.detail=value
	if is_instance_valid(micro_choice):micro_choice.set_pressed_no_signal(value)
	set_profile(profile,false)
	if persist and not game.synthetic_run:_save_material_setting()
func update_copy() -> void:
	if not is_instance_valid(copy_label):return
	var ko: bool=game.preferences.language=="ko"
	copy_label.text=("C에서 재질 세대를 비교합니다. 조명·모델·판정은 동일합니다.\n비닐 반사 / 폼 단면 / 천 직조 / 도색 목재\n미세 표면은 끌 수 있습니다. 실제 GI는 다음 단계입니다." if ko else "Compare material generations in C, with the SAME light/model/rules.\nVinyl coat / foam cut face / cloth weave / painted wood.\nMicrodetail is optional. Baked GI is not part of this step.")
	if is_instance_valid(material_choice):material_choice.disabled=profile!=2
	if is_instance_valid(micro_choice):micro_choice.disabled=profile!=2 or converter.generation!=2
func _save_material_setting() -> void:
	var cfg:=ConfigFile.new();cfg.set_value("material","generation",converter.generation);cfg.set_value("material","detail",converter.detail)
	if cfg.save(MaterialSettings)!=OK:push_warning("Material preference could not be saved")
func _load_material_setting() -> void:
	if not FileAccess.file_exists(MaterialSettings):return
	var f:=FileAccess.open(MaterialSettings,FileAccess.READ)
	if f==null or f.get_length()>4096:return
	f.close()
	var cfg:=ConfigFile.new()
	if cfg.load(MaterialSettings)!=OK:return
	var g=cfg.get_value("material","generation",2);var d=cfg.get_value("material","detail",true)
	if g is int and g in [1,2]:converter.generation=g
	if d is bool:converter.detail=d
