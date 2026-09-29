extends SceneTree
const Scene=preload("res://scenes/phase14.tscn")
const Materials=preload("res://scripts/material14/materials.gd")
const Tiles=preload("res://scripts/material14/microtextures.gd")
const Surface=preload("res://scripts/graphics/surfaces.gd")
const Form=preload("res://scripts/phase4/weapon_form.gd")
const Data=preload("res://scripts/phase4/drawing_data.gd")
const Maps:=["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func count(n: Node) -> int:
	var total:=1
	for c in n.get_children():total+=count(c)
	return total
func physical(n: Node) -> Array:
	var out: Array=[]
	if n is CollisionObject3D:out.append([n.get_path(),n.global_transform,n.collision_layer,n.collision_mask])
	if n is CollisionShape3D:out.append([n.get_path(),n.global_transform,n.shape.get_rid(),n.disabled])
	for c in n.get_children():out.append_array(physical(c))
	return out
func snapshot(g) -> Dictionary:
	var out: Dictionary={"time":g.rules.time_left,"score":g.rules.scores.duplicate(),"hp":g.rules.hp.duplicate(),"phase":g.rules.phase,"physics":physical(g.arena),"spots":g.arena.spots.duplicate(),"camera":g.rig.transform}
	for i in range(4):
		var a=g.fighters[i]
		out[i]=[a.transform,a.weapon.global_transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.health,a.elapsed,a.body_art.body.mesh,a.body_art.body.skin,a.body_art.skeleton.get_bone_count()]
	return out
func source_state(m: StandardMaterial3D) -> Array:return [m.albedo_color,m.roughness,m.metallic_specular,m.normal_scale,m.disable_receive_shadows,m.cull_mode,m.shading_mode]
func run() -> void:
	var converter=Materials.new()
	for kind in Materials.FAMILIES:
		var source:=Surface.make(Color("d17868"),kind);var before:=source_state(source)
		var world:=converter.convert(source,true,false) as ShaderMaterial
		var view:=converter.convert(source,true,true) as ShaderMaterial
		check(world!=null and world.shader==Materials.V2,kind+" actual V2 shader")
		check(world.get_shader_parameter("family")==Materials.FAMILIES.find(kind),kind+" correct recipe")
		check(world!=view and not world.get_shader_parameter("view_only") and view.get_shader_parameter("view_only"),kind+" independent view/world material")
		check(converter.convert(source,true,false)==world,kind+" stable cache reuse")
		check(source_state(source)==before,kind+" source not mutated")
		check(world.get_shader_parameter("tint")==source.albedo_color,kind+" original hue preserved")
		var tile: ImageTexture=world.get_shader_parameter("micro_tile")
		check(tile!=null and tile.get_width()==128 and tile.get_image().has_mipmaps(),kind+" bounded mipmapped data texture")
		var image:=tile.get_image();var valid:=true
		for y in range(0,128,13):
			for x in range(0,128,11):
				var p:=image.get_pixel(x,y)
				if not is_finite(p.r+p.g+p.b) or minf(p.r,minf(p.g,p.b))<0 or maxf(p.r,maxf(p.g,p.b))>1:valid=false
		check(valid,kind+" sampled tile channels finite and normalized")
		converter.detail=false
		var low:=converter.convert(source,true,false) as ShaderMaterial
		check(low!=world and low.get_shader_parameter("detail_amount")==0.0,kind+" microdetail off independent cached resource")
		converter.detail=true;converter.generation=1
		check(converter.convert(source,true,false).shader!=Materials.V2,kind+" old shader comparison retained")
		converter.generation=2
		check(converter.convert(source,false,false) is StandardMaterial3D,kind+" B still uses standard material")
	check(Tiles.cache.size()==5,"six recipes share five static texture resources")
	var builds: int=Tiles.builds
	for i in range(30):Tiles.texture_for("foam");Tiles.texture_for("fabric")
	check(Tiles.builds==builds,"no texture rebuilding on reuse")
	var ink:=Surface.make(Color("19322f"),"ink")
	check(converter.convert(ink,true,false)==ink,"eyes and text ink remain exact")
	var clear:=StandardMaterial3D.new();clear.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	check(converter.convert(clear,true,false)==clear,"transparent materials not converted to opaque")
	var sign_material:=StandardMaterial3D.new();sign_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	check(converter.convert(sign_material,true,false)==sign_material,"unlit authored signs retain their material")
	var shader:=FileAccess.get_file_as_string("res://shaders/material14/toy_v2.gdshader")
	check(not "ALPHA =" in shader and not "EMISSION =" in shader and not "depth_test_disabled" in shader,"opaque depth retained without glow through walls")
	check(not "VERTEX +=" in shader and not "POSITION =" in shader and not "TIME" in shader,"no geometry or time-driven surface motion")
	check("ATTENUATION" in shader and "LIGHT_IS_DIRECTIONAL" in shader,"world shadows and local-light attenuation used")
	var game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	var studio=game.get_node("ToyStudio")
	check(studio.active and studio.converter.generation==2,"new scene starts with V2")
	check(game.skin_ready and game.fighters[1].body_art.skeleton.get_bone_count()==18,"Phase13 skeleton preserved")
	for id in Maps:
		game.return_to_menu();game.select_map(id);await process_frame;await process_frame
		studio.set_profile(2)
		var before:=snapshot(game)
		var env: Environment=game.environment_node.environment
		var light_state: Array=[env.ambient_light_energy,env.ambient_light_color,game.get_node("WarmKey").transform,game.get_node("WarmKey").light_energy]
		for gen in [1,2,1,2]:
			studio.set_material_generation(gen)
			check(snapshot(game)==before,id+" generation "+str(gen)+" preserves rules/geometry/skin")
		var current: Environment=game.environment_node.environment
		check(light_state==[current.ambient_light_energy,current.ambient_light_color,game.get_node("WarmKey").transform,game.get_node("WarmKey").light_energy],id+" same lights across material comparison")
		var body=game.fighters[1].body_art.body
		check(body.material_override.shader==Materials.V2 and body.material_override.get_shader_parameter("character_body"),id+" skinned body gets body recipe")
		var state:=snapshot(game);studio.set_microdetail(false);studio.set_microdetail(true)
		check(snapshot(game)==state,id+" surface switch cannot change information/physics")
		studio._process(0)
		var n:=count(game);var revision: int=game.rig.rebuild_count;var made: int=studio.converter.conversions
		for frame in range(30):studio._process(1.0/60)
		check(count(game)==n and revision==game.rig.rebuild_count and made==studio.converter.conversions,id+" steady frames create no meshes or materials")
		game.fighters[1].set_hidden(true,0);studio.set_material_generation(1);studio.set_material_generation(2)
		check(not body.is_visible_in_tree() and not game.fighters[1].body_art.face.is_visible_in_tree(),id+" no hidden body or face leak")
		game.fighters[1].set_hidden(false)
		studio.set_profile(0)
		check(body.material_override==body.get_meta("studio_source"),id+" A restores exact source")
		studio.set_profile(1)
		check(body.material_override is StandardMaterial3D,id+" B retained")
		studio.set_profile(2)
	game.start_practice();game._process(0);await process_frame;await process_frame;game._process(0);studio._process(0)
	check(game.ui.preview_actor.body.material_override.shader==Materials.V2,"workshop uses same skinned material")
	game.accept_drawing();game._process(0);studio._process(0)
	var actor=game.fighters[0]
	for kind in ["fish","hammer","pan"]:
		var data=Data.new();data.set_preset(kind);var original: Dictionary=data.to_dictionary()
		actor.equip(data);game._process(0);studio._process(0)
		var world: Material=actor.weapon.material_override;var view: Material=game.rig.view_weapon.material_override
		check(world is ShaderMaterial and view is ShaderMaterial and world!=view,kind+" equip gets isolated view/world materials")
		check(not world.get_shader_parameter("view_only") and view.get_shader_parameter("view_only"),kind+" shadow flags independent")
		check(actor.weapon_data.to_dictionary()==original and actor.hit_samples==Form.samples(data),kind+" original drawing and samples stay exact")
		check(game.rig.view_weapon.scale.is_equal_approx(Vector3.ONE*0.40),kind+" proportional fixed view scale retained")
		check(game.rig.grip_rig.right_hand.has_node("RoundPaw"),kind+" round hands preserved")
		var fill=actor.weapon.get_node_or_null("SafeFoamFill")
		check(fill==null or fill.material_override.get_shader_parameter("foam_cutout"),kind+" cut surface only tags existing fill")
	var clock: float=game.rules.time_left;var hp: Array=game.rules.hp.duplicate()
	game.paused=true;studio.set_material_generation(1);studio.set_material_generation(2);studio.set_microdetail(false);studio.set_microdetail(true)
	check(game.rules.time_left==clock and game.rules.hp==hp,"paused controls do not tick game time or damage")
	check(studio.material_choice.get_item_count()==2 and studio.material_choice.selected==1,"comparison control connected")
	check(studio.converter.cache.size()<2048 and Tiles.cache.size()==5,"bounded material/texture footprint in repeated map and equip fixture")
	game.queue_free();await process_frame;await process_frame
	print("MATERIAL_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
