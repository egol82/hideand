extends Node
## Pure visual extension with small-detail range culling; cover and clues never disappear.
const Recipes=preload("res://scripts/world19/recipes.gd")
const Batches=preload("res://scripts/world19/batches.gd")
var game
var studio
var installed:=false
var enabled:=true
var detail_distance:=28.0
var arena_id:=0
var finish_root: Node3D
var signature: Array=[]
var rebuilds:=0
var stats: Dictionary={}
var panel: PopupPanel
var status_label: Label
func _ready() -> void:
	game=get_parent();process_priority=120;call_deferred("initialize")
func initialize() -> void:
	studio=game.get_node("ToyStudio")
	var fx=game.get_node("SmashDirector")
	if not studio.active or not is_instance_valid(fx.toggle):call_deferred("initialize");return
	installed=true
	var button:=Button.new();button.text="맵 마감 / Maps";button.tooltip_text="장식·조명·거리별 표시 / Finish, lighting and detail range"
	fx.toggle.get_parent().add_child(button)
	panel=PopupPanel.new();panel.size=Vector2i(530,355);studio.ui_layer.add_child(panel)
	var margin:=MarginContainer.new();panel.add_child(margin)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,18)
	var column:=VBoxContainer.new();margin.add_child(column);column.add_theme_constant_override("separation",13)
	var heading:=Label.new();heading.text="WORLD FINISH  /  맵 마감";column.add_child(heading)
	var theme:=CheckButton.new();theme.text="테마별 세부 마감 / Themed finish";theme.button_pressed=true;column.add_child(theme);theme.toggled.connect(set_enabled)
	var lights:=CheckButton.new();lights.text="맵별 직접 조명 / Themed direct lighting";lights.button_pressed=true;column.add_child(lights)
	lights.toggled.connect(func(on: bool):studio.world_lighting=on;studio.set_profile(studio.profile,false))
	var range_option:=OptionButton.new();range_option.add_item("작은 장식 전체 / Full detail");range_option.add_item("작은 장식 18m / Near");range_option.add_item("작은 장식 28m / Balanced");range_option.select(2);column.add_child(range_option)
	range_option.item_selected.connect(func(i: int):set_distance([0.0,18.0,28.0][i]))
	status_label=Label.new();status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_label.custom_minimum_size=Vector2(470,70);column.add_child(status_label)
	var close:=Button.new();close.text="닫기 / Close";column.add_child(close);close.pressed.connect(panel.hide)
	button.pressed.connect(func():panel.theme=game.ui.root.theme;panel.popup_centered();update_label())
	refresh()
func _process(_delta: float) -> void:
	if installed:refresh()
func refresh() -> void:
	if not is_instance_valid(game.arena):return
	if arena_id!=game.arena.get_instance_id():
		arena_id=game.arena.get_instance_id();finish_root=null;signature=[];stats={}
		if game.arena.map_id in Recipes.IDS:
			var pieces:=Recipes.new().make(game.arena.map_id)
			finish_root=Batches.build(pieces);game.arena.add_child(finish_root);rebuilds+=1
			stats={"pieces":pieces.size(),"batches":finish_root.get_child_count(),"map":game.arena.map_id}
		update_label()
	if not is_instance_valid(finish_root):return
	var stamp: Array=[enabled,detail_distance,studio.profile,studio.converter.generation,studio.converter.detail]
	if stamp==signature:return
	signature=stamp;finish_root.visible=enabled;Batches.apply(finish_root,studio,detail_distance)
func set_enabled(value: bool) -> void:
	enabled=value;signature=[];refresh()
func set_distance(value: float) -> void:
	if value not in [0.0,18.0,28.0]:return
	detail_distance=value;signature=[];refresh()
func update_label() -> void:
	if not is_instance_valid(status_label):return
	status_label.text="대저택은 기존 GI와 가구 마감을 유지합니다.\nManor retains its native GI and crafted scenery." if stats.is_empty() else "장식 %d개 → 공간별 묶음 %d개\n거리 옵션은 작은 장식만 제어합니다. 엄폐·은신처는 유지합니다.\nOther maps use authored direct light, not a new GI bake."%[stats.pieces,stats.batches]
