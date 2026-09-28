extends "res://scripts/phase4/interface.gd"
const Board=preload("res://scripts/hideplay/map_board.gd")
var hide_top: ColorRect
var hide_bottom: ColorRect
var extra: Label
func _ready() -> void:
	super._ready()
	for index in range(2):
		var n:=ColorRect.new(); n.color=Color("253d40"); n.mouse_filter=Control.MOUSE_FILTER_IGNORE; n.visible=false
		root.add_child(n); root.move_child(n,0)
		if index==0: hide_top=n
		else: hide_bottom=n
	extra=_hud_label(Vector2(24,145),Vector2(470,130),14)
func map_name(id: String) -> String:
	if id=="toy_manor": return "숨바꼭질 대저택" if game.preferences.language=="ko" else "Hideaway Manor"
	return super.map_name(id)
func show_menu() -> void:
	var ko: bool=game.preferences.language=="ko"
	var box:=_card(840)
	box.add_child(label("HIDE & SMASHING",32))
	box.add_child(label("숨기 · 엿보기 · 속임수 · 반격" if ko else "Hide · Peek · Mislead · Smash",18))
	var choose:=OptionButton.new(); _control_ink(choose)
	var ids: Array=["toy_manor"]+Catalog4.IDS
	for id in ids: choose.add_item(map_name(id))
	choose.select(maxi(0,ids.find(game.map_id)))
	choose.item_selected.connect(func(i: int): game.select_map(ids[i]); show_menu()); box.add_child(choose)
	box.add_child(label("2층 + 두 계단 · 두 출구 · 빨래 슈트 · 비밀길" if game.map_id=="toy_manor" and ko else ("Two floors, two stairs, two exits, chute & secret passage" if game.map_id=="toy_manor" else ("기존 맵 + 새 은신/수색 도구" if ko else "Original map + new hiding/search tools")),16))
	var guide:=label(("은신: %s 엿보기 / %s 출구1 / %s 출구2 / %s 기습\n태엽 장난감·술래 능력은 화면에 표시되는 보조키를 사용합니다." if ko else "Hidden: %s peek / %s exit 1 / %s exit 2 / %s ambush\nExtra keys automatically avoid your saved key bindings.")%[game.controls.hint("quiet"),game.controls.hint("interact"),game.controls.hint("dash"),game.controls.hint("attack")],15)
	guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; guide.custom_minimum_size=Vector2(780,65); box.add_child(guide)
	if game.map_id!="toy_manor":
		var compact:=CheckBox.new(); compact.text="4인용 탐색 구역" if ko else "Compact four-player area"; compact.button_pressed=game.preferences.compact
		compact.toggled.connect(func(value: bool): game.set_compact(value); show_menu()); box.add_child(compact)
	var mode:=OptionButton.new(); _control_ink(mode); mode.add_item(s("field")); mode.add_item(s("classic")); mode.select(0 if game.rules.mode=="field" else 1)
	mode.item_selected.connect(func(i: int): game.set_mode("field" if i==0 else "classic")); box.add_child(mode)
	var row:=HBoxContainer.new(); box.add_child(row)
	for pair in [["seek_first",true],["hide_first",false]]:
		var b:=button(s(pair[0]),game.start_match.bind(pair[1])); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(b)
	box.add_child(button(s("practice"),game.start_practice))
	box.add_child(label(s("offline"),14)); box.add_child(label(s("points"),13))
	var bottom:=HBoxContainer.new(); box.add_child(bottom)
	bottom.add_child(button(s("settings"),game.open_settings)); bottom.add_child(button(s("quit"),game.get_tree().quit)); _language(bottom)
func hide_view(hidden: bool,peeking: bool) -> void:
	if not is_instance_valid(hide_top): return
	hide_top.visible=hidden; hide_bottom.visible=hidden
	var gap:=0.31 if peeking else 0.025
	var height: float=root.size.y*(0.5-gap*0.5)
	hide_top.position=Vector2.ZERO; hide_top.size=Vector2(root.size.x,height)
	hide_bottom.position=Vector2(0,root.size.y-height); hide_bottom.size=Vector2(root.size.x,height)
func refresh(state) -> void:
	super.refresh(state)
	if not is_instance_valid(extra) or not is_instance_valid(game.hiding): return
	extra.visible=game.world_view_active() and not modal.visible and not game.paused and not game.practice_mode
	var h=game.hiding; var ko: bool=game.preferences.language=="ko"
	var key:=OS.get_keycode_string(game.skill_key); var cycle:=OS.get_keycode_string(game.cycle_key)
	if state.seeker==0:
		var names: Array=["귀 기울이기 3초","최근 흔적 조사","소란스러운 빠른 검사"] if ko else ["Listen for 3s","Read fresh tracks","Loud quick inspection"]
		extra.text="%s · %s    %s · %s\n%s %02d"%[key,names[h.skill_index],cycle,"능력 변경" if ko else "Cycle tool","재사용" if ko else "Cooldown",ceili(h.skill_cooldown)]
	else:
		extra.text="%s · %s (%d)\n%s · %s"%[key,"가짜 소리 장난감" if ko else "Wind-up decoy",h.decoy_uses[0],game.controls.hint("taunt"),"도발 (구역 단서를 남깁니다)" if ko else "Taunt (leaves a clue)"]
	if game.fighters[0].hidden_in_box:
		extra.text+="\n%s · %s  /  %s · %s\n%s · %s"%[game.controls.hint("quiet"),"엿보기 (1.1초 뒤 눈이 보임)" if ko else "Peek (eyes exposed after 1.1s)",game.controls.hint("dash"),"두 번째 출구" if ko else "Exit 2",game.controls.hint("attack"),"근처 술래에 기습 도전" if ko else "Ambush nearby seeker"]
	if game.focus_spot>=0 and game.focus_spot<h.homes.size():
		action_hint.text=game.controls.hint("interact")+" · "+h.homes[game.focus_spot].get("title","Hiding place")
	var p: Dictionary=h.passage(0)
	if not p.is_empty(): action_hint.text=game.controls.hint("interact")+" · "+p.label+(" · 숨는 역할 전용" if p.hider_only and ko else "")
	if h.inspecting.has(0): action_hint.text=("확인 중… 움직이면 취소됩니다." if ko else "Inspecting… Moving cancels.")
	if h.listening: action_hint.text=("귀 기울이는 중… " if ko else "Listening… ")+str(snappedf(h.listen_age,0.1))+" / 3"
	if not h.pressure_zone.is_empty(): extra.text+="\n"+("종반 구역: " if ko else "Final area: ")+h.pressure_zone
func show_map() -> void:
	if game.map_id!="toy_manor": super.show_map(); return
	var box:=_card(820); box.add_child(label(map_name(game.map_id),25))
	box.add_child(label("공개 배치와 내 위치만 표시 · 두 계단은 양 끝에서 연결됩니다." if game.preferences.language=="ko" else "Public layout + your position only. Stairs link the two end landings.",14))
	var b:=Board.new(); b.arena=game.arena; b.player_position=game.fighters[0].position; b.custom_minimum_size=Vector2(760,370); box.add_child(b)
	box.add_child(button(s("resume"),game.toggle_pause))
