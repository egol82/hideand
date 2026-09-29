extends RefCounted
## Original adventure-journal visual language. No Nintendo assets/fonts or gameplay state.
const PAPER := Color("f3eedf")
const MUTE := Color("b8c4bb")
const GOLD := Color("cfb77d")
const MINT := Color("9fcbbb")
const DEEP := Color("142827")
const PANEL := Color("203632")
const LINE := Color("627064")
static func box(color: Color = PANEL, radius: int = 9, margin: int = 16) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color=color; b.set_corner_radius_all(radius)
	b.border_color=Color(LINE,0.55); b.set_border_width_all(1)
	b.content_margin_left=margin; b.content_margin_right=margin; b.content_margin_top=8; b.content_margin_bottom=8
	return b
static func theme() -> Theme:
	var t := Theme.new(); t.default_font=preload("res://scripts/quality/copy.gd").font(); t.default_font_size=17
	for type_name in ["Label","Button","OptionButton","CheckBox","CheckButton","PopupMenu","LineEdit"]:
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]: t.set_color(state,type_name,PAPER)
		t.set_color("font_disabled_color",type_name,Color("7c8980"))
	for type_name in ["Button","OptionButton"]:
		t.set_stylebox("normal",type_name,box(Color(PANEL,0.92)))
		t.set_stylebox("hover",type_name,box(Color("354c41")))
		t.set_stylebox("pressed",type_name,box(Color("101f1e")))
		t.set_stylebox("disabled",type_name,box(Color("1d302c")))
		var focus:=box(Color.TRANSPARENT); focus.border_color=GOLD; focus.set_border_width_all(2)
		t.set_stylebox("focus",type_name,focus)
	t.set_stylebox("panel","PanelContainer",box())
	t.set_stylebox("panel","PopupPanel",box(DEEP,10,22))
	t.set_stylebox("panel","PopupMenu",box(DEEP,8,12))
	t.set_stylebox("hover","PopupMenu",box(Color("3a5145"),4,10))
	t.set_color("font_color","PopupMenu",PAPER); t.set_constant("v_separation","PopupMenu",14)
	t.set_stylebox("slider","HSlider",track(Color("465b4d")))
	t.set_stylebox("grabber_area","HSlider",track(GOLD))
	t.set_stylebox("grabber_area_highlight","HSlider",track(MINT))
	return t
static func style(node: Control) -> void:
	node.set_meta("phase6_styled",true)
	if node is BaseButton:
		node.focus_mode=Control.FOCUS_ALL
		for state in ["normal","hover","pressed","disabled","focus"]:
			if node.has_theme_stylebox_override(state): node.remove_theme_stylebox_override(state)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
			node.add_theme_color_override(state,PAPER)
	if node is CheckBox:
		for state in ["normal","hover","pressed","hover_pressed"]: node.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	if node is OptionButton: node.get_popup().theme=theme()

static func track(color: Color) -> StyleBoxFlat:
	var b:=box(color,2,0)
	b.content_margin_top=1; b.content_margin_bottom=1; b.border_color=color
	return b
