extends "res://scripts/hideplay/interface.gd"
## Rebuilds presentation with original adventure-journal styling, preserving actual handlers.
const S=preload("res://scripts/premium/skin.gd")
const Backdrop=preload("res://scripts/premium/backdrop.gd")
const HUD=preload("res://scripts/premium/hud.gd")
const Stamp=preload("res://scripts/premium/map_stamp.gd")
var premium_hud: Control
var page_panel: PanelContainer
var page_width:=1080.0
var page:="menu"
var drawing_note: Label
var canvas_header: Label
var footer_note: Label
var selected_tab:="play"
var board_view: Control
var size_readout: Label

func bi(ko: String,en: String) -> String: return ko if game.preferences.language=="ko" else en
func _ready() -> void:
	super._ready()
	root.theme=S.theme()
	premium_hud=HUD.new(); root.add_child(premium_hud); root.move_child(premium_hud,2)
	premium_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for n in [role_label,timer,standings,objective,detail,extra]: n.visible=false
	action_hint.add_theme_font_size_override("font_size",15)
	action_hint.add_theme_stylebox_override("normal",S.box(Color(0.05,0.11,0.10,0.88),8,16))
	action_hint.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	toast.add_theme_font_size_override("font_size",23)
	toast.add_theme_color_override("font_color",S.PAPER)
	root.resized.connect(_layout_page)
	_layout_page()
func label(text: String,pixels: int,color: Color=S.PAPER) -> Label:
	var n:=Label.new(); n.text=text; n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.add_theme_font_size_override("font_size",pixels); n.add_theme_color_override("font_color",color)
	return n
func panel(color: Color,radius: int) -> StyleBoxFlat: return S.box(color,mini(12,radius))
func button(text: String,action: Callable) -> Button:
	var n:=Button.new(); n.text=text; n.custom_minimum_size.y=42
	n.add_theme_font_size_override("font_size",16); S.style(n)
	n.pressed.connect(action); return n
func primary(n: Button) -> void:
	for state in ["normal","hover","pressed"]: n.add_theme_stylebox_override(state,S.box(S.GOLD.lightened(0.1) if state=="hover" else S.GOLD,7))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: n.add_theme_color_override(state,S.DEEP)
	n.custom_minimum_size.y=48
func _control_ink(n: Control) -> void: S.style(n)
func _clear() -> void:
	drawing_note=null; canvas_header=null; size_readout=null; footer_note=null; page_panel=null; board_view=null
	super._clear()
func _card(width: float=980.0) -> VBoxContainer:
	_clear(); modal.show(); page_width=width
	var shade:=ColorRect.new(); shade.color=Color(0.05,0.1,0.085,0.24); modal.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash:=Backdrop.new(); wash.journal=page!="menu"; modal.add_child(wash); wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_panel=PanelContainer.new(); page_panel.set_meta("phase6_styled",true)
	page_panel.add_theme_stylebox_override("panel",S.box(Color(0.06,0.13,0.115,0.88),13,26)); modal.add_child(page_panel)
	var scroll:=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; page_panel.add_child(scroll)
	var box:=VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",12); scroll.add_child(box)
	_layout_page()
	if not game.preferences.reduced_motion:
		page_panel.modulate.a=0.0; page_panel.create_tween().tween_property(page_panel,"modulate:a",1.0,0.14)
	return box
func _layout_page() -> void:
	if is_instance_valid(page_panel):
		page_panel.size=Vector2(minf(page_width,root.size.x-92),root.size.y-100)
		page_panel.position=(root.size-page_panel.size)*0.5
	if is_instance_valid(action_hint):
		action_hint.position=Vector2(root.size.x*0.5-255,root.size.y*0.77)
		action_hint.size=Vector2(510,42)
	if is_instance_valid(toast): toast.position=Vector2(root.size.x*0.5-330,124); toast.size=Vector2(660,40)
func _heading(box: VBoxContainer,kicker: String,title: String,note: String="") -> void:
	box.add_child(label(kicker,12,S.GOLD)); box.add_child(label(title,30))
	if not note.is_empty():
		var n:=label(note,14,S.MUTE); n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(n)
	var line:=HSeparator.new(); var thin:=StyleBoxLine.new(); thin.color=Color(S.GOLD,0.3); thin.thickness=1; line.add_theme_stylebox_override("separator",thin); box.add_child(line)
func _choice(items: Array,selected: int,action: Callable) -> OptionButton:
	var n:=OptionButton.new(); n.custom_minimum_size.y=42; S.style(n)
	for item in items: n.add_item(item)
	n.select(maxi(0,selected)); n.item_selected.connect(action); return n
func show_menu() -> void:
	page="menu"; var box:=_card(1140)
	var top:=HBoxContainer.new(); box.add_child(top)
	var brand:=label("HIDE & SMASHING  /  THE TOY JOURNAL",12,S.GOLD); brand.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(brand)
	top.add_child(button(bi("도움말","How to play"),show_help)); top.add_child(button(s("settings"),game.open_settings))
	var spacer:=Control.new(); spacer.custom_minimum_size.y=8; box.add_child(spacer)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",40); box.add_child(row)
	var left:=VBoxContainer.new(); left.custom_minimum_size.x=365; left.add_theme_constant_override("separation",15); row.add_child(left)
	left.add_child(label("HIDE &\nSMASHING",48))
	left.add_child(label(bi("그림 하나로 시작되는 숨바꼭질","A little drawing. A grand escape."),19,S.MINT))
	var desc:=label(bi("나만의 무기를 그리고, 숨고,\n들키면 멋지게 반격하세요.","Draw your own toy. Find your cover.\nGet found? Make your escape."),15,S.MUTE); left.add_child(desc)
	var go:=button(bi("숨는 역할로 시작","Play as a hider"),game.start_match.bind(false)); primary(go); left.add_child(go)
	left.add_child(button(bi("술래로 시작","Play as the seeker"),game.start_match.bind(true)))
	left.add_child(button(bi("무기 공방 · 자유 연습","Toy workshop · free practice"),game.start_practice))
	var right:=VBoxContainer.new(); right.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(right)
	right.add_child(label(bi("오늘의 놀이터","YOUR PLAYGROUND"),12,S.GOLD))
	var ids: Array=["toy_manor"]+Catalog4.IDS
	right.add_child(_choice(ids.map(func(id): return map_name(id)),ids.find(game.map_id),func(i: int): game.select_map(ids[i]); show_menu()))
	board_view=Stamp.new(); board_view.arena=game.arena; board_view.custom_minimum_size=Vector2(420,220); right.add_child(board_view)
	var note:=bi("두 계단으로 이어진 비밀스러운 장난감 집","Two stairways. A house full of little secrets.") if game.map_id=="toy_manor" else bi("엄폐물과 돌아가는 길을 먼저 눈여겨보세요.","Look for cover, quiet paths and a way back out.")
	right.add_child(label(note,13,S.MUTE))
	right.add_child(_choice([bi("현장 반격 · 발견된 곳에서 싸우기","Field · fight where you are found"),bi("클래식 · 중앙 결투장","Classic · central arena")],0 if game.rules.mode=="field" else 1,func(i: int): game.set_mode("field" if i==0 else "classic")))
	if game.map_id!="toy_manor": _check(right,bi("4인용 탐색 구역","Compact four-player area"),game.preferences.compact,func(v: bool): game.set_compact(v); show_menu())
	var bottom:=HBoxContainer.new(); bottom.add_theme_constant_override("separation",12); box.add_child(bottom)
	var info:=label(bi("오프라인   ·   나 + 봇 3명   ·   4라운드","OFFLINE   /   YOU + 3 BOTS   /   4 ROUNDS"),12,S.MUTE); info.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bottom.add_child(info)
	_language(bottom); bottom.add_child(button(bi("그래픽 보기","Art settings"),show_art)); bottom.add_child(button(s("quit"),game.get_tree().quit))
	if game.preferences.load_source=="backup" or game.controls.load_source=="backup": box.add_child(label(s("settings_recovered"),13,S.GOLD))
func show_art() -> void:
	var studio=game.get_node_or_null("ToyStudio")
	if not is_instance_valid(studio): return
	studio.panel.theme=root.theme
	studio.update_copy(); studio.panel.popup_centered()
func show_drawing(data) -> void:
	page="drawing"; var box:=_card(1140)
	var head:=HBoxContainer.new(); box.add_child(head)
	draw_heading=label(bi("나만의 무기 공방","YOUR TOY WORKSHOP"),28); draw_heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; head.add_child(draw_heading)
	if game.practice_mode: head.add_child(button(s("title"),game.return_to_menu))
	elif game.workshop.opened: head.add_child(button(s("spectate"),game.close_workshop))
	box.add_child(label(bi("그린 크기 그대로. 작은 장난감부터 커다란 한 방까지.","Your size, your silhouette. Small toy or big statement."),14,S.MUTE))
	if game.workshop.opened: box.add_child(label(s("live_round"),13,S.GOLD))
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",26); box.add_child(columns)
	var left:=VBoxContainer.new(); left.size_flags_horizontal=Control.SIZE_EXPAND_FILL; columns.add_child(left)
	left.add_child(label(bi("01  /  모양을 그리세요","01  /  DRAW YOUR SHAPE"),12,S.GOLD))
	canvas=Canvas4.new(); canvas.custom_minimum_size=Vector2(474,306); left.add_child(canvas); canvas.custom_minimum_size=Vector2(474,344)
	var actions:=HBoxContainer.new(); left.add_child(actions)
	for pair in [["undo",canvas.undo],["clear",canvas.clear_drawing],["grip",func(): canvas.grip_mode=true; drawing_note.text=bi("그림 위에서 손으로 잡을 위치를 누르세요.","Click the part of your drawing you want to hold.")]]:
		actions.add_child(button(s(pair[0]),pair[1]))
	var palette:=HBoxContainer.new(); palette.add_theme_constant_override("separation",10); left.add_child(palette)
	for i in range(5):
		var b:=button("",canvas.set_color_index.bind(i)); b.tooltip_text=bi("무기 색상 ","Toy color ")+str(i+1); b.custom_minimum_size=Vector2(48,34)
		b.add_theme_stylebox_override("normal",S.box(Color(data.PALETTE[i]),15,0)); palette.add_child(b)
	drawing_note=label(bi("최대 사거리 2.20m · 원본 모양과 크기를 보존합니다.","Reach limit 2.20m · Original shape and size are preserved."),12,S.MUTE)
	drawing_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; left.add_child(drawing_note)
	var right:=VBoxContainer.new(); right.custom_minimum_size.x=435; columns.add_child(right)
	right.add_child(label(bi("02  /  장난감으로 태어나는 순간","02  /  YOUR DRAWING COMES TO LIFE"),12,S.GOLD))
	_make_preview(right)
	var holder:=preview.get_parent() as SubViewportContainer; holder.custom_minimum_size=Vector2(435,190)
	size_readout=label("",16,S.MINT); right.add_child(size_readout)
	handling_control=_choice(Attack4.IDS.map(func(id): return s(id)),Attack4.IDS.find(data.handling),func(i: int): canvas.data.handling=Attack4.IDS[i]; _preview_changed()); right.add_child(handling_control)
	fill_control=CheckBox.new(); S.style(fill_control); fill_control.text=s("fill"); fill_control.button_pressed=data.fill_closed
	fill_control.toggled.connect(func(v: bool): canvas.data.fill_closed=v; _preview_changed()); right.add_child(fill_control)
	ink=label("",12,S.MUTE); right.add_child(ink)
	var extras:=HBoxContainer.new(); right.add_child(extras)
	var names: Array=[bi("망치","Hammer"),bi("물고기","Fish"),bi("프라이팬","Pan")]
	for i in range(3): extras.add_child(button(names[i],canvas.set_preset.bind(["hammer","fish","pan"][i])))
	var saves:=HBoxContainer.new(); right.add_child(saves)
	slot=OptionButton.new(); S.style(slot); slot.custom_minimum_size.y=38
	for i in range(8):
		var record:=Library4.read_slot(i,storage_directory); slot.add_item(s("slot")%(i+1)+(bi(" · 저장됨"," · saved") if record.data!=null else ""))
	slot.item_selected.connect(func(_i: int): slot_write_confirm=-1); saves.add_child(slot)
	saves.add_child(button(s("save"),_save)); saves.add_child(button(s("load"),_load))
	ready_button=button(s("queue" if game.workshop.opened else ("test_toy" if game.practice_mode else "ready")),game.accept_drawing); primary(ready_button); right.add_child(ready_button)
	canvas.drawing_changed.connect(_preview_changed); canvas.set_data(data)
func _preview_changed() -> void:
	super._preview_changed()
	if not is_instance_valid(size_readout) or not is_instance_valid(canvas): return
	var bounds:=Rect2(); var first:=true
	for stroke in canvas.data.strokes:
		for p in stroke:
			if first: bounds=Rect2(p,Vector2.ZERO); first=false
			else: bounds=bounds.expand(p)
	var world: Vector2=bounds.size*canvas.data.world_scale()
	size_readout.text=bi("가로 %.2fm  ×  세로 %.2fm","Width %.2fm  ×  height %.2fm")%[world.x,world.y]
	ink.text=bi("잉크 %d%%   ·   사거리 %.2fm","Ink %d%%   ·   reach %.2fm")%[roundi(canvas.data.ink_used()/4*100),canvas.data.reach()]
	if canvas.data.world_scale()<2.399:
		drawing_note.text=bi("사거리·면적 한도에 도달해 크기 상한이 적용됩니다.","Reach/area limit reached. The shared size cap now applies.")
	else: drawing_note.text=bi("크기는 자동으로 같아지지 않습니다. 작게 그리면 작아져요.","No automatic equal-sizing. A smaller drawing stays smaller.")
func show_pause() -> void:
	page="settings"; var box:=_card(1000)
	_heading(box,"THE TOY JOURNAL",s("settings") if game.settings_from_menu else s("paused"),bi("편안한 시선, 선명한 소리. 플레이에 맞춰 조절하세요.","Find a comfortable view and your preferred feel."))
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",42); box.add_child(row)
	var a:=VBoxContainer.new(); a.custom_minimum_size.x=420; row.add_child(a)
	var b:=VBoxContainer.new(); b.custom_minimum_size.x=420; row.add_child(b)
	a.add_child(label(bi("시점과 소리","VIEW & SOUND"),12,S.GOLD))
	_slider(a,s("sensitivity"),game.preferences.mouse_sensitivity,0.0005,0.008,0.0001,game.set_sensitivity)
	_slider(a,s("fov"),game.preferences.vertical_fov,55,90,1,game.set_fov)
	_slider(a,s("volume"),game.preferences.volume,0,1,0.05,game.set_volume)
	_check(a,s("invert"),game.preferences.invert_y,game.set_invert_y); _language(a)
	b.add_child(label(bi("움직임과 접근성","MOTION & COMFORT"),12,S.GOLD))
	_check(b,s("reduced"),game.preferences.reduced_motion,game.set_reduced_motion)
	_slider(b,s("sway"),game.preferences.hand_sway,0,1,0.05,game.set_comfort.bind("hand_sway"))
	_slider(b,s("bob"),game.preferences.head_bob,0,1,0.05,game.set_comfort.bind("head_bob"))
	_slider(b,s("contact"),game.preferences.feedback_strength,0,1,0.05,game.set_comfort.bind("feedback_strength"))
	_check(b,s("cues"),game.preferences.sound_cues,game.set_sound_cues)
	_check(b,s("metrics"),game.preferences.recording,game.set_recording)
	var nav:=HBoxContainer.new(); nav.add_theme_constant_override("separation",10); box.add_child(nav)
	nav.add_child(button(s("remap"),show_bindings)); nav.add_child(button(bi("그래픽 보기","Art settings"),show_art)); nav.add_child(button(bi("도움말","Field guide"),show_help))
	var resume:=button(s("back" if game.settings_from_menu else "resume"),game.toggle_pause); primary(resume); box.add_child(resume)
	if not game.settings_from_menu: box.add_child(button(s("title"),game.return_to_menu))
func show_help() -> void:
	page="help"; var box:=_card(950)
	_heading(box,bi("모험 수첩","FIELD GUIDE"),bi("숨고, 속이고, 반격하기","Hide. Mislead. Smash."))
	var sections:= [
		[bi("01  /  나만의 무기","01  /  YOUR OWN TOY"),bi("공방에서 그린 크기가 그대로 반영됩니다. 사거리와 잉크 한도는 모두에게 같습니다.","Draw small or large. Everyone shares the same reach and ink limits.")],
		[bi("02  /  들키지 않는 선택","02  /  FIND YOUR COVER"),bi("카펫은 조용합니다. 은신처에서는 출구를 고르고, 오래 엿보면 눈이 드러납니다.","Carpets are quiet. Choose your hiding exit; peek too long and your eyes show.")],
		[bi("03  /  한 번의 속임수","03  /  A LITTLE MISDIRECTION"),bi("태엽 장난감을 놓아 소리를 남기세요. 술래의 조사는 최근 흔적과 소리를 사용합니다.","Leave a wind-up toy behind. Seeker tools read recent sounds and traces, not live radar.")],
		[bi("04  /  스매시","04  /  SMASH YOUR WAY OUT"),bi("발견되면 직접 그린 무기로 반격합니다. 현장 반격과 클래식은 서로 다른 경기 방식입니다.","When discovered, fight with your drawing. Field and Classic use different encounter rules.")]]
	for section in sections:
		box.add_child(label(section[0],14,S.GOLD)); var n:=label(section[1],16); n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(n)
	box.add_child(button(bi("조작키 확인 / 변경","View / change controls"),_guide_bindings))
	box.add_child(button(s("back"),show_pause if game.paused else show_menu))
func show_bindings() -> void:
	page="bindings"; super.show_bindings()
func show_map() -> void:
	page="map"; var box:=_card(1030)
	_heading(box,bi("놀이터 지도","PLAYGROUND ATLAS"),map_name(game.map_id),bi("공개된 가구와 내 위치만 표시합니다. 숨은 상대는 보이지 않습니다.","Public furniture and your position only. No hidden-player markers."))
	board_view=Stamp.new(); board_view.arena=game.arena; board_view.player_position=game.fighters[0].position; board_view.show_player=true
	board_view.custom_minimum_size=Vector2(880,365); box.add_child(board_view)
	box.add_child(label(bi("민트 · 은신처 후보    /    황금선 · 계단    /    밝은 점 · 나","MINT · hiding candidates   /   GOLD · stairs   /   LIGHT DOT · you"),13,S.MUTE))
	box.add_child(button(s("resume"),game.toggle_pause))
func show_wait() -> void:
	page="wait"; var box:=_card(850)
	modal.get_child(0).color=Color("102321")
	_heading(box,bi("곧 시작됩니다","READY WHEN YOU ARE"),bi("눈을 감고, 잠시 기다려요","Give them a moment."),bi("친구들이 자신만의 은신처를 찾는 중입니다.","The hiders are finding their own little corner."))
	wait_clock=label("",64,S.GOLD); box.add_child(wait_clock)
	box.add_child(label(bi("소리와 흔적에 귀 기울여 보세요.","Listen for the little things they leave behind."),17,S.MUTE))
func show_result(state,complete: bool) -> void:
	page="result"; var box:=_card(1010)
	_heading(box,bi("이번 모험의 기록","THE STORY SO FAR"),s("complete" if complete else "result"),s("points"))
	var order: Array[int]=[0,1,2,3]; order.sort_custom(func(a: int,b: int): return state.scores[a]>state.scores[b])
	for rank in range(4):
		var id: int=order[rank]; var panel_node:=PanelContainer.new(); panel_node.set_meta("phase6_styled",true)
		panel_node.add_theme_stylebox_override("panel",S.box(Color("34483a") if id==0 else Color("20362f"),8,18)); box.add_child(panel_node)
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",24); panel_node.add_child(row)
		row.add_child(label("%02d"%(rank+1),24,S.GOLD)); var name_label:=label(bi("나","YOU") if id==0 else NAMES[id],21); name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(name_label)
		var badge:=""
		if id==state.seeker and state.remaining()==0: badge=s("sweep")
		elif id!=state.seeker and state.alive[id]: badge=s("never_found" if state.discoveries[id]==0 else ("escaped" if state.escapes[id]>0 else "survivor"))
		row.add_child(label(badge,13,S.MINT))
		row.add_child(label("+%d"%(state.scores[id]-state.round_start_scores[id]),14,S.MUTE)); row.add_child(label("%d"%state.scores[id],28))
	var next:=button(s("title" if complete else "continue"),game.return_to_menu if complete else game.next_round); primary(next); box.add_child(next)
func refresh(state) -> void:
	super.refresh(state)
	for n in [role_label,timer,standings,objective,detail,extra]: n.visible=false
	var in_play: bool=game.world_view_active() and not modal.visible and not game.paused
	premium_hud.visible=in_play
	overlay4.visible=in_play
	toast.visible=in_play and not toast.text.is_empty() and message_seconds>0
	if not is_instance_valid(game.hiding): return
	var h=game.hiding; var actor=game.fighters[0]; var spectator: bool=game.is_spectating()
	var secs:=maxi(0,ceili(state.time_left))
	var phase_names: Array=[bi("준비","Ready"),bi("그리기","Draw"),bi("숨을 시간","Find cover"),bi("수색 중","The search"),bi("발견","Discovered"),bi("반격","Smash"),bi("기록","Results"),bi("마무리","Complete")]
	var tool_names: Array=[bi("귀 기울이기","Listen"),bi("흔적 조사","Read tracks"),bi("빠른 검사","Quick inspection")]
	var info: Dictionary={"role":bi("술래","SEEKER") if state.seeker==0 else bi("숨는 사람","HIDER"),"hp":state.hp[0],"map":map_name(game.map_id),"time":"%02d:%02d"%[secs/60,secs%60],"phase":phase_names[state.phase],"round":mini(3,state.round_index),"status":bi("생존 %d명","%d hiders remain")%state.remaining(),"score":bi("내 점수 %d","Your score %d")%state.scores[0],"key":OS.get_keycode_string(game.skill_key),"tool":tool_names[h.skill_index] if state.seeker==0 else bi("소리 장난감","Wind-up decoy"),"tool_note":"","ready":1.0,"footer":game.controls.hint("map")+bi("  지도    ·    Esc  메뉴","  Map    ·    Esc  Menu")}
	if state.seeker==0:
		info.ready=1.0-clampf(h.skill_cooldown/15.0,0,1)
		info.tool_note=bi("%s  도구 변경","%s  Change tool")%OS.get_keycode_string(game.cycle_key) if h.skill_cooldown<=0 else bi("%d초 뒤 사용 가능","Ready in %ds")%ceili(h.skill_cooldown)
	else:
		info.ready=1.0 if h.decoy_uses[0]>0 else 0.0; info.tool_note=bi("이번 라운드 %d개 남음","%d left this round")%h.decoy_uses[0]
	if not h.pressure_zone.is_empty(): info.phase=bi("구역 단서 · ","Area clue · ")+h.pressure_zone
	if actor.hidden_in_box:
		info.role=bi("숨어 있어요","IN COVER"); info.tool_note=bi("Ctrl을 오래 누르면 눈이 드러나요.","Long peeks can expose your eyes.").replace("Ctrl",game.controls.hint("quiet"))
		action_hint.text=game.controls.hint("interact")+bi(" 출구 1   ·   "," Exit 1   ·   ")+game.controls.hint("dash")+bi(" 출구 2   ·   "," Exit 2   ·   ")+game.controls.hint("quiet")+bi(" 엿보기"," Peek")
	if spectator:
		info.role=bi("관전 중","SPECTATING"); info.tool=bi("다음 무기 준비","Prepare your next toy"); info.key=game.controls.hint("workshop"); info.tool_note=bi("다음 라운드에 사용할 그림을 준비해요.","Your next drawing will wait for the next round.")
	if game.practice_mode:
		info.role=bi("자유 연습","FREE PRACTICE"); info.time="∞"; info.phase=bi("시간 제한 없음","No time limit"); info.status=bi("명중 %d회","%d hits")%game.practice.hits; info.score=bi("점수 없는 연습","Unscored practice")
		info.key=game.controls.hint("workshop"); info.tool=bi("무기 다시 그리기","Redraw your toy"); info.tool_note=bi("움직이고, 대시하고, 세 번 맞혀보세요.","Move, dash and land three hits."); info.ready=1.0
		info.footer=game.controls.hint("attack")+bi(" 공격   ·   "," Attack   ·   ")+game.controls.hint("dash")+bi(" 대시"," Dash")
	premium_hud.info=info; premium_hud.queue_redraw()
	action_hint.visible=in_play and not action_hint.text.is_empty()
	if is_instance_valid(draw_heading): draw_heading.text=bi("다음 무기 준비","Your next toy") if game.workshop.opened else bi("나만의 무기 공방","Your toy workshop")+("" if game.practice_mode else "   %02d"%ceili(state.time_left))
	if is_instance_valid(wait_clock): wait_clock.text="%02d"%ceili(state.time_left)
	_layout_page()
func notify(text: String,seconds: float=1.7) -> void:
	var alias: Dictionary={"SMASH!":bi("반격할 순간","Make your move"),"CAUGHT!":bi("이번엔 잡혔어요","Caught this time"),"IN THE PASSAGE":bi("통로를 지나가는 중","Taking the shortcut")}
	super.notify(alias.get(text,text),clampf(seconds,0.7,2.8))
func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(toast): toast.modulate.a=clampf(message_seconds/0.15,0,1)

func _guide_bindings() -> void:
	if game.rules.phase==Rules.Phase.MENU and not game.paused: game.open_settings()
	show_bindings()
