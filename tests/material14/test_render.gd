extends SceneTree
## Actual pixel checks of opaque occlusion, shadow response and absence of unlit emission.
const Mat=preload("res://scripts/material14/materials.gd")
const Surface=preload("res://scripts/graphics/surfaces.gd")
var converter=Mat.new()
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func picture() -> Image:
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func mean(image: Image,rect: Rect2i) -> float:
	var sum:=0.0;var count:=0
	for y in range(rect.position.y,rect.end.y,2):
		for x in range(rect.position.x,rect.end.x,2):
			var c:=image.get_pixel(x,y);sum+=(c.r+c.g+c.b)/3;count+=1
	return sum/maxi(1,count)
func difference(a: Image,b: Image) -> float:
	var sum:=0.0;var count:=0
	for y in range(0,a.get_height(),4):
		for x in range(0,a.get_width(),4):
			var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y)
			sum+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b);count+=3
	return sum/maxi(1,count)
func run() -> void:
	root.size=Vector2i(512,384)
	var stage:=Node3D.new();root.add_child(stage)
	var environment:=WorldEnvironment.new();var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR;e.background_color=Color.BLACK
	e.ambient_light_source=Environment.AMBIENT_SOURCE_DISABLED;e.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	environment.environment=e;stage.add_child(environment)
	var camera:=Camera3D.new();camera.position=Vector3(0,0,4);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.7;stage.add_child(camera);camera.current=true
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-20,-25,0);light.light_energy=0.75;light.shadow_enabled=true;stage.add_child(light)
	var sphere:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=0.68;mesh.height=1.36;mesh.radial_segments=48;mesh.rings=24
	sphere.mesh=mesh;stage.add_child(sphere)
	var crop:=Rect2i(220,165,60,55)
	var readings: Dictionary={}
	for kind in Mat.FAMILIES:
		sphere.material_override=converter.convert(Surface.make(Color("db7b65"),kind),true,false)
		light.light_energy=0.75
		var lit: Image=await picture();var bright:=mean(lit,crop)
		light.light_energy=0
		var dark: Image=await picture();var black:=mean(dark,crop)
		check(bright>0.06,kind+" actually renders under direct light")
		check(black<0.005,kind+" is dark with every light disabled")
		readings[kind]={"lit_mean":bright,"dark_mean":black}
	light.light_energy=0.75
	var block:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(2.0,2.0,0.15);block.mesh=box;block.position.z=1.1
	var m:=StandardMaterial3D.new();m.albedo_color=Color("3c6454");m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;block.material_override=m;stage.add_child(block)
	var covered: Image=await picture();sphere.hide();var empty: Image=await picture()
	var delta:=difference(covered,empty)
	check(delta<0.0001,"opaque wall completely occludes V2 mesh; no x-ray silhouette")
	# The same shader also receives an ordinary engine shadow: a camera-invisible caster is intentional here.
	block.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	block.position=Vector3(0.7,0.55,1.25);box.size=Vector3(2.8,2.8,0.15);sphere.show()
	sphere.material_override=converter.convert(Surface.make(Color("db7b65"),"vinyl"),true,false)
	var shadowed: Image=await picture();var shadow_lum:=mean(shadowed,crop)
	block.hide();var visible: Image=await picture();var clear_lum:=mean(visible,crop)
	check(shadow_lum<clear_lum*0.75,"world material retains actual shadow attenuation")
	readings["occlusion_difference"]=delta;readings["shadow_mean"]=shadow_lum;readings["unshadowed_mean"]=clear_lum
	var f:=FileAccess.open("res://ci-artifacts/material14-pixels.json",FileAccess.WRITE);f.store_string(JSON.stringify(readings,"  "));f.close()
	stage.queue_free();await process_frame
	print("MATERIAL_RENDER_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
