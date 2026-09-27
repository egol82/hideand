@tool
extends Node3D
## Editor-placeable decorative modules; never add colliders or hidden-player information.
const Art = preload("res://scripts/phase4/art.gd")
const Studio = preload("res://scripts/graphics/studio.gd")
const WindowShader = preload("res://shaders/window_sky.gdshader")
@export_enum("window","postcard","books","lamp") var kind := "window"
@export var accent := Color("9abfc0")

func _ready() -> void:
	build()
func build() -> void:
	if has_node("Generated"): return
	var r := Node3D.new(); r.name = "Generated"; add_child(r)
	if kind == "window":
		Art.box(r,Vector3.ZERO,Vector3(3.35,1.98,0.16),Color("f4e8ce"),"wood",0.045)
		var glass := Art.box(r,Vector3(0,0,0.09),Vector3(3.08,1.72,0.018),accent,"vinyl",0.006)
		var mat := ShaderMaterial.new(); mat.shader = WindowShader; glass.material_override = mat
		for x in [-0.54,0.54]: Art.box(r,Vector3(x,0,0.125),Vector3(0.052,1.75,0.038),Color("f1e6d0"),"wood",0.012)
		Art.box(r,Vector3(0,0,0.13),Vector3(3.1,0.065,0.04),Color("f1e6d0"),"wood",0.013)
		Art.box(r,Vector3(0,-1.04,0.13),Vector3(3.63,0.15,0.35),Color("f2e5cf"),"wood",0.05)
		Art.box(r,Vector3(0,1.21,0.03),Vector3(4.30,0.065,0.065),Color("c4a572"),"wood",0.025)
		for side in [-1,1]:
			for j in range(5):
				var x: float = side*(1.44+j*0.115)
				Art.ball(r,Vector3(x,-0.06,0.19+sin(j*1.1)*0.015),Vector3(0.095,1.19,0.075),accent,"fabric")
			Art.box(r,Vector3(side*1.66,-0.46,0.29),Vector3(0.50,0.075,0.052),Color("ebd39f"),"fabric",0.023)
	elif kind == "postcard":
		Art.box(r,Vector3.ZERO,Vector3(2.25,1.30,0.09),Color("d1b286"),"wood",0.045)
		Art.box(r,Vector3(0,0,0.055),Vector3(2.06,1.11,0.027),Color("f2e4c7"),"fabric",0.025)
		Art.ball(r,Vector3(0.58,0.22,0.088),Vector3(0.19,0.19,0.013),Color("e5b46d"))
		for i in range(3):
			Art.box(r,Vector3(-0.46+i*0.40,-0.25,0.085+i*0.008),Vector3(0.58,0.24+i*0.09,0.025),accent.darkened(i*0.06),"foam",0.07).rotation.z = -0.13+i*0.15
	elif kind == "books":
		for i in range(3):
			var node := Node3D.new(); r.add_child(node)
			node.position.y = i*0.12; node.rotation.y = i*0.15-0.1
			Art.box(node,Vector3(0,0.048,0),Vector3(0.65,0.10,0.45),[accent,Color("dc9b81"),Color("dcbf7e")][i],"fabric",0.018)
			Art.box(node,Vector3(0.022,0.052,0.005),Vector3(0.59,0.059,0.433),Color("f4e9d1"),"wood",0.012)
	elif kind == "lamp":
		Art.ball(r,Vector3(0,0.11,0),Vector3(0.25,0.10,0.25),Color("e3bf87"),"ceramic")
		Art.box(r,Vector3(0,0.37,0),Vector3(0.055,0.52,0.055),Color("c79b64"),"wood",0.025)
		var shade := MeshInstance3D.new()
		var cone := CylinderMesh.new(); cone.top_radius = 0.22; cone.bottom_radius = 0.40; cone.height = 0.43; cone.radial_segments = 48
		shade.mesh = cone; shade.position.y = 0.69
		var mat := Art.material(Color("f1dfb2"),"fabric").duplicate() as StandardMaterial3D
		mat.emission_enabled = true; mat.emission = Color("c39c60"); mat.emission_energy_multiplier = 0.18
		shade.material_override = mat; r.add_child(shade)
		var lamp := OmniLight3D.new(); lamp.position = Vector3(0,0.70,0)
		lamp.omni_range = 4.5; lamp.light_color = Color("ffe2ab"); lamp.light_energy = 0.26
		r.add_child(lamp)
