extends RefCounted
## Physical keyboard / mouse remapping. System/menu escapes cannot be rebound.
const Store = preload("res://scripts/quality/safe_store.gd")
const PATH := "user://phase5/controls.json"
const DEFAULTS := {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"attack":-MOUSE_BUTTON_LEFT,"interact":KEY_E,"dash":KEY_SHIFT,"quiet":KEY_CTRL,"taunt":KEY_C,"map":KEY_M,"workshop":KEY_TAB}
const IDS := ["forward","back","left","right","attack","interact","dash","quiet","taunt","map","workshop"]
const RESERVED := [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_F11,KEY_F12,KEY_META]
var bindings: Dictionary = DEFAULTS.duplicate()
var load_source := "default"

func _init() -> void:
	apply()

static func valid_code(code: Variant) -> bool:
	if not (code is int or code is float) or not is_finite(float(code)) or float(code) != floor(float(code)): return false
	var key := int(code)
	if key in RESERVED: return false
	return key in [-1,-2,-3,KEY_SPACE,KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_TAB,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT] or (key >= KEY_A and key <= KEY_Z) or (key >= KEY_0 and key <= KEY_9)

static func validate(data: Dictionary) -> bool:
	if data.get("version") != 1 or not data.get("bindings") is Dictionary or data.bindings.size() != IDS.size(): return false
	var used: Dictionary = {}
	for id in IDS:
		var code: Variant = data.bindings.get(id)
		if not valid_code(code) or used.has(int(code)): return false
		used[int(code)] = true
	return true

func apply() -> void:
	for id in IDS:
		var action: String = "hs_"+id
		if not InputMap.has_action(action): InputMap.add_action(action)
		Input.action_release(action)
		InputMap.action_erase_events(action)
		var code := int(bindings[id])
		var event: InputEvent
		if code < 0:
			event = InputEventMouseButton.new()
			event.button_index = -code
		else:
			event = InputEventKey.new()
			event.physical_keycode = code
		InputMap.action_add_event(action,event)

func rebind(id: String, code: int) -> String:
	if id not in IDS or not valid_code(code): return "reserved"
	for other in IDS:
		if other != id and int(bindings[other]) == code: return other
	bindings[id] = code
	apply()
	return "ok"

func reset() -> void:
	bindings = DEFAULTS.duplicate()
	apply()

func held(id: String) -> bool:
	return id in IDS and Input.is_action_pressed("hs_"+id)

func pressed(event: InputEvent, id: String) -> bool:
	return id in IDS and event.is_action_pressed("hs_"+id,false,true)

func vector() -> Vector2:
	return Input.get_vector("hs_left","hs_right","hs_forward","hs_back")

func hint(id: String) -> String:
	if id not in IDS: return "?"
	var code := int(bindings[id])
	if code < 0: return ["LMB","RMB","MMB"][-code-1]
	return OS.get_keycode_string(code)

func load_local(path: String = PATH) -> bool:
	var result := Store.load_value(path,validate)
	if not result.ok: return false
	bindings = result.data.bindings.duplicate()
	load_source = result.source
	apply()
	return true

func save_local(path: String = PATH) -> Error:
	return Store.save_value(path,{"version":1,"bindings":bindings},validate)

func release_all() -> void:
	for id in IDS: Input.action_release("hs_"+id)

static func event_code(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo and not event.meta_pressed:
		return event.physical_keycode if event.physical_keycode else event.keycode
	if event is InputEventMouseButton and event.pressed: return -event.button_index
	return 0
