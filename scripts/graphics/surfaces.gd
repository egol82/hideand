@tool
extends RefCounted
## Deterministic seamless microtextures; no external assets or gameplay random-state changes.
static var cache: Dictionary = {}
static var tiles: Dictionary = {}
static func make(color: Color, kind: String) -> StandardMaterial3D:
	var key := kind+color.to_html()
	if cache.has(key): return cache[key]
	var m := StandardMaterial3D.new()
	m.set_meta("toy_family",kind)
	m.albedo_color = color
	m.roughness = {"foam":0.78,"vinyl":0.40,"wood":0.61,"fabric":0.96,"ink":0.43,"plaster":0.91,"ceramic":0.30}.get(kind,0.7)
	m.metallic_specular = 0.25 if kind in ["foam","fabric","plaster"] else 0.36
	if kind in ["vinyl","ceramic"]:
		m.clearcoat_enabled = true
		m.clearcoat = 0.10
		m.clearcoat_roughness = 0.56
	if kind in ["foam","fabric","wood","plaster"]:
		var pair := textures(kind)
		m.albedo_texture = pair[0]
		m.normal_enabled = true
		m.normal_texture = pair[1]
		m.normal_scale = 0.22 if kind != "fabric" else 0.32
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 6
		m.uv1_scale = Vector3.ONE*({"foam":6.0,"fabric":3.0,"wood":0.65,"plaster":2.0}[kind])
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	cache[key] = m
	return m
static func height_at(x: float, y: float, kind: String) -> float:
	var a := TAU*x/128.0
	var b := TAU*y/128.0
	if kind == "fabric": return sin(a*16)*sin(b*16)*0.12+sin(a*32)*0.035
	if kind == "wood": return sin(b*12+sin(a*2)*0.6)*0.09+sin(b*29+sin(a)*0.4)*0.035
	return sin(a*19+b*11)*sin(b*23-a*13)*0.08+sin(a*7+b*9)*0.04
static func textures(kind: String) -> Array:
	if tiles.has(kind): return tiles[kind]
	var albedo := Image.create(128,128,false,Image.FORMAT_RGB8)
	var normal := Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):
			var v := 0.984+height_at(x,y,kind)*0.065
			albedo.set_pixel(x,y,Color(v,v,v))
			var dx := (height_at(x+1,y,kind)-height_at(x-1,y,kind))*1.9
			var dy := (height_at(x,y+1,kind)-height_at(x,y-1,kind))*1.9
			var n := Vector3(-dx,-dy,1).normalized()
			normal.set_pixel(x,y,Color(n.x*0.5+0.5,n.y*0.5+0.5))
	albedo.generate_mipmaps(); normal.generate_mipmaps()
	var result := [ImageTexture.create_from_image(albedo),ImageTexture.create_from_image(normal)]
	tiles[kind] = result
	return result
