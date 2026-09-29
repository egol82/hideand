extends "res://scripts/hideplay/game.gd"
## Explicit entry only: visual redesign and proportional view scale, unchanged game authority.
const PremiumUI=preload("res://scripts/premium/interface.gd")
func _ready() -> void:
	super._ready()
	var old=ui; remove_child(old); old.queue_free()
	ui=PremiumUI.new(); ui.game=self; add_child(ui)
	rig.drawn_size_view=true; rig.last_revision=-1
	for actor in fighters:
		actor.nameplate.font=ui.menu_font; actor.nameplate.outline_size=2; actor.nameplate.modulate=Color("f3eedf")
	ui.show_menu()
	call_deferred("_premium_studio_ui")
func _premium_studio_ui() -> void:
	var studio=get_node_or_null("ToyStudio")
	if is_instance_valid(studio) and is_instance_valid(studio.button):
		# The original tool is still available from styled menu buttons. No floating debug entry.
		studio.button.modulate.a=0; studio.button.mouse_filter=Control.MOUSE_FILTER_IGNORE; studio.button.focus_mode=Control.FOCUS_NONE
		studio.panel.theme=ui.root.theme

func _input(event: InputEvent) -> void:
	# Escape closes the field guide without creating an accidental settings/pause state.
	if is_instance_valid(ui) and ui.page=="help" and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE:
		if paused: ui.show_pause()
		else: ui.show_menu()
		get_viewport().set_input_as_handled(); return
	super._input(event)
