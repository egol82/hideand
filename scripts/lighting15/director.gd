extends "res://scripts/material14/director.gd"
## Live-map GI coordinator. No input, collision, capsule, skeleton or weapon-transform writes.
const Build15=preload("res://scripts/lighting15/build_room.gd")
const ContactShader=preload("res://shaders/contact_shadow.gdshader")
var lighting_mode:=2 # 0 Phase14; 1 new direct light only; 2 identical direct lights + real baked GI
var contact_support:=true
var bundle: Node3D
var baked_data: LightmapGIData
var gi: LightmapGI
var attached_arena:=0
var originals: Array[Dictionary]=[]
var light_records: Array[Dictionary]=[]
var dynamic_records: Array[Dictionary]=[]
var groundings: Array[Dictionary]=[]
var last_dynamic: Array=[]
var lighting_choice: OptionButton
var contact_choice: CheckButton
var status_label: Label
var missing_reason:=""
var applications:=0

func make_ui() -> void:
	super.make_ui()
	panel.size=Vector2i(650,582)
	var column=copy_label.get_parent()
	lighting_choice=OptionButton.new();lighting_choice.custom_minimum_size.y=42
	for text in ["조명 A · 이전 조명 / Previous","조명 B · 창빛 + 실내등 / Direct only","조명 C · LightmapGI + Probes / Baked GI"]:lighting_choice.add_item(text)
	column.add_child(lighting_choice);column.move_child(lighting_choice,4)
	lighting_choice.item_selected.connect(set_lighting)
	contact_choice=CheckButton.new();contact_choice.text="발밑 접촉 보강 / Ground-contact support";contact_choice.button_pressed=true
	column.add_child(contact_choice);column.move_child(contact_choice,5)
	contact_choice.toggled.connect(func(v: bool):contact_support=v;apply_lighting())
	status_label=Label.new();status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_label.custom_minimum_size=Vector2(560,40)
	column.add_child(status_label);column.move_child(status_label,6)
	lighting_choice.select(lighting_mode)

func update_copy() -> void:
	super.update_copy()
	if not is_instance_valid(copy_label):return
	copy_label.text=("재질 I/II는 유지합니다. 조명 B/C는 같은 직접광입니다.\nC만 실제 정적 LightmapGI와 동적 프로브를 사용합니다.\n원본 지형·은신·무기 크기·접촉 판정은 바꾸지 않습니다." if game.preferences.language=="ko" else "Material I/II remain. B/C share identical direct lights.\nOnly C adds baked static GI and dynamic probes.\nGeometry, hiding, weapon sizes and hit timing are unchanged.")
	if is_instance_valid(lighting_choice):lighting_choice.disabled=game.arena.map_id!="toy_manor"
	if is_instance_valid(status_label):
		status_label.text=("대저택 전용 / Manor only" if game.arena.map_id!="toy_manor" else ("실제 베이크 연결 / Baked users: %d"%baked_data.get_user_count() if baked_data!=null else "GI 미준비 — 직접광만 사용 / "+missing_reason))

func set_profile(value: int,persist: bool=false) -> void:
	super.set_profile(value,persist)
	if not active:return
	ensure_world()
	apply_lighting()

func set_lighting(value: int) -> void:
	if value not in [0,1,2]:return
	lighting_mode=value
	if is_instance_valid(lighting_choice):lighting_choice.select(value)
	# Restore the inherited graphics profile before applying the light-only overlay.
	set_profile(profile,false)

func ensure_world() -> void:
	var id: int=game.arena.get_instance_id()
	if id==attached_arena:return
	restore_originals()
	if is_instance_valid(bundle):bundle.get_parent().remove_child(bundle);bundle.queue_free()
	bundle=null;gi=null;baked_data=null;originals.clear();light_records.clear()
	attached_arena=id;last_dynamic=[];missing_reason="baked asset missing"
	if game.arena.map_id!="toy_manor":return
	var sources:=Build15.fixed_meshes(game.arena)
	for n in sources:originals.append({"node":weakref(n),"visible":n.visible})
	for n in game.arena.get_children():
		if n is Light3D:light_records.append({"node":weakref(n),"energy":n.light_energy})
	if ResourceLoader.exists(Build15.ScenePath):
		var candidate=load(Build15.ScenePath).instantiate()
		if candidate.get_meta("fixed_signature","")==Build15.signature(sources):
			bundle=candidate;game.arena.add_child(bundle)
			gi=bundle.get_node("LightmapGI");baked_data=gi.light_data
			for n in bundle.get_children():
				if n is MeshInstance3D:
					var index: int=n.get_meta("source_index",-1)
					if index>=0 and index<sources.size():
						var source=sources[index].get_meta("studio_source",sources[index].material_override)
						n.material_override=source;n.set_meta("bake_static15",true)
						n.set_meta("studio_source",source)
						# Track for the inherited A/B/C material restoration loop.
						records.append({"node":weakref(n),"source":source,"cast":n.cast_shadow})
			apply_materials(bundle)
			missing_reason="LightmapGI data not yet baked" if baked_data==null else ""
		else:candidate.free();missing_reason="fixed-geometry signature changed; rebake required"
	if bundle==null:
		bundle=Node3D.new();bundle.name="UnbakedLighting15";game.arena.add_child(bundle)
		bundle.add_child(Build15.light_rig())
	update_copy()

func apply_lighting() -> void:
	if not active or not is_instance_valid(game.arena):return
	applications+=1
	var manor: bool=game.arena.map_id=="toy_manor"
	var use: bool=manor and lighting_mode>0
	if is_instance_valid(bundle):
		bundle.visible=use
		if is_instance_valid(gi):gi.light_data=baked_data if use and lighting_mode==2 else null
		# Only replace fixed visuals after a verified matching UV2 scene has been loaded.
		var replacement: bool=bundle.has_meta("fixed_signature")
		for record in originals:
			var n=record.node.get_ref()
			if is_instance_valid(n):n.visible=bool(record.visible) and not (use and replacement)
	for record in light_records:
		var n=record.node.get_ref()
		if is_instance_valid(n):n.light_energy=0.0 if use else record.energy
	if use:
		game.get_node("WarmKey").light_energy=0.0
		game.get_node("CoolSoftFill").light_energy=0.0
		var env: Environment=game.environment_node.environment
		env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color=Color("dce4e2");env.ambient_light_energy=0.13
		env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
		env.tonemap_white=4.0;env.tonemap_exposure=1.0
	refresh_dynamic(true)
	update_copy()

func _process(delta: float) -> void:
	super._process(delta)
	if not active:return
	refresh_dynamic(false)
	update_contacts()

func apply_materials(n: Node) -> void:
	super.apply_materials(n)
	# Material comparison does not change lightmapping mode or replace the baked UV2 meshes.

func dynamic_tree(n: Node) -> void:
	if n is MeshInstance3D and n.name!="ArtContactShadow" and not n.name.begins_with("Grounding15"):
		if not n.has_meta("gi_original15"):
			n.set_meta("gi_original15",n.gi_mode);dynamic_records.append({"node":weakref(n),"mode":n.gi_mode})
		n.gi_mode=GeometryInstance3D.GI_MODE_DYNAMIC
	for child in n.get_children():dynamic_tree(child)

func refresh_dynamic(force: bool) -> void:
	var use: bool=game.arena.map_id=="toy_manor" and lighting_mode>0
	if not use:
		for record in dynamic_records:
			var n=record.node.get_ref()
			if is_instance_valid(n):n.gi_mode=record.mode
		for g in groundings:
			if is_instance_valid(g.node.get_ref()):g.node.get_ref().visible=false
		for actor in game.fighters:
			var old=actor.visual.get_node_or_null("ArtContactShadow")
			if old!=null:old.visible=true
		return
	var stamp: Array=[game.rig.rebuild_count,game.arena.furnishings.get_instance_id()]
	for actor in game.fighters:stamp.append(actor.weapon.get_instance_id());stamp.append(actor.body_art.get_instance_id())
	if not force and stamp==last_dynamic:return
	last_dynamic=stamp
	var living: Array[Dictionary]=[]
	for record in dynamic_records:
		if is_instance_valid(record.node.get_ref()):living.append(record)
	dynamic_records=living
	for actor in game.fighters:
		dynamic_tree(actor.visual)
		for side in ["L","R"]:
			if not actor.visual.has_node("Grounding15"+side):
				var node:=make_contact("Grounding15"+side,Vector2(0.46,0.40))
				actor.visual.add_child(node)
				groundings.append({"node":weakref(node),"actor":weakref(actor),"side":side})
		var old=actor.visual.get_node_or_null("ArtContactShadow")
		if old!=null:old.visible=false
	dynamic_tree(game.rig.hand_root)
	dynamic_tree(game.arena.furnishings)
	for home in game.arena.homes:
		if not home.root.has_node("Grounding15Furniture"):
			var plane:=make_contact("Grounding15Furniture",Vector2(2.02,1.57));plane.position=Vector3(0,0.040,0)
			home.root.add_child(plane)
			groundings.append({"node":weakref(plane),"actor":null,"side":""})
	var smash=game.get_node_or_null("SmashDirector")
	if smash!=null:
		for ghost in smash.ghosts:dynamic_tree(ghost.root)

func make_contact(label: String,size2: Vector2) -> MeshInstance3D:
	var mesh:=PlaneMesh.new();mesh.size=size2
	var n:=MeshInstance3D.new();n.name=label;n.mesh=mesh
	var mat:=ShaderMaterial.new();mat.shader=ContactShader;mat.set_shader_parameter("strength",0.13)
	n.material_override=mat;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.gi_mode=GeometryInstance3D.GI_MODE_DISABLED;n.set_meta("cosmetic_only",true)
	return n

func update_contacts() -> void:
	var use: bool=game.arena.map_id=="toy_manor" and lighting_mode>0 and contact_support
	var kept: Array[Dictionary]=[]
	for record in groundings:
		var n=record.node.get_ref()
		if not is_instance_valid(n):continue
		kept.append(record);n.visible=use
		if not use or record.actor==null:continue
		var actor=record.actor.get_ref()
		if not is_instance_valid(actor):n.visible=false;continue
		# Parent visibility already handles hiding; keep the layer in step with local-body suppression.
		n.layers=actor.body_art.body.layers
		var sk: Skeleton3D=actor.body_art.skeleton
		var bone:=sk.find_bone("foot_"+record.side)
		var point: Vector3=sk.global_transform*sk.get_bone_global_pose(bone).origin
		var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.15,point-Vector3.UP*0.9,1)
		var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():n.visible=false;continue
		var gap: float=maxf(0.0,point.y-hit.position.y-0.18)
		n.visible=not actor.hidden_in_box and actor.visible and gap<0.65
		var normal: Vector3=hit.normal
		var x:=normal.cross(Vector3.FORWARD).normalized()
		n.global_transform=Transform3D(Basis(x,normal,x.cross(normal).normalized()),hit.position+normal*0.018)
		n.material_override.set_shader_parameter("strength",0.15*clampf(1.0-gap/0.65,0,1))
	groundings=kept

func restore_originals() -> void:
	for record in originals:
		var n=record.node.get_ref()
		if is_instance_valid(n):n.visible=record.visible
	for record in light_records:
		var n=record.node.get_ref()
		if is_instance_valid(n):n.light_energy=record.energy

func _exit_tree() -> void:
	restore_originals()
	originals.clear();light_records.clear();dynamic_records.clear();groundings.clear();baked_data=null
	super._exit_tree()
