extends "res://scripts/smash/impact_pool.gd"
## Directional foam chips, compact rings and a short soft puff. No screen-wide flash or light.
var polished := true
var puff_draw: MultiMesh
var puffs: Array[Dictionary]=[]
var puff_cursor := 0
var last_origin := Vector3.ZERO
var onset_serial := 0
const PUFF_CAPACITY := 24

func _ready() -> void:
	super._ready()
	var mesh := SphereMesh.new(); mesh.radial_segments=12; mesh.rings=6; mesh.radius=0.5; mesh.height=1.0
	puff_draw=MultiMesh.new();puff_draw.transform_format=MultiMesh.TRANSFORM_3D
	puff_draw.use_colors=true; puff_draw.mesh=mesh; puff_draw.instance_count=PUFF_CAPACITY
	var node:=MultiMeshInstance3D.new();node.multimesh=puff_draw
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.95
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=mat
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
	add_child(node)
	for i in range(PUFF_CAPACITY): puffs.append({"age":0.0,"life":0.0,"at":Vector3.ZERO,"v":Vector3.ZERO,"size":0.0})
	reset()

func emit_contact(at: Vector3, normal: Vector3, kind: String, handling: String, strength: float=1.0) -> void:
	if not polished:
		super.emit_contact(at,normal,kind,handling,strength);return
	if not enabled or strength<=0 or not at.is_finite() or kind not in ["hit","finish","blocked"]:return
	serial+=1;onset_serial=serial;last_origin=at
	var n:=normal.normalized() if normal.length_squared()>0.001 else Vector3.BACK
	var x:=n.cross(Vector3.UP).normalized()
	if x.length_squared()<0.1:x=Vector3.RIGHT
	var y:=n.cross(x).normalized()
	var power := 1.3 if kind=="finish" else (1.15 if handling=="heavy" else (0.75 if handling=="quick" else 1.0))
	var count := 14 if kind=="finish" else (10 if handling=="heavy" else 6)
	if kind=="blocked":count=4;power=0.65
	for i in range(count):
		var angle:=TAU*i/count+posmod(serial,5)*0.23
		var radial:=x*cos(angle)+y*sin(angle)
		var color: Color=PALETTE[posmod(serial+i,PALETTE.size())]
		if kind=="blocked":color=Color("cbb797")
		put(0 if i%3==0 and kind!="blocked" else 1,at+n*0.04,radial*(1.1+0.1*(i%3))*power+n*0.7+Vector3.UP*0.45,(0.14 if i%3==0 else 0.075)*power*strength,0.25+0.04*(i%3),color)
	put(2,at+n*0.065,Vector3.ZERO,0.50*power*strength,0.13 if kind=="blocked" else 0.18,Color("aad1e2") if kind=="blocked" else Color("ffe4b0"))
	if kind!="blocked":
		for i in range(4 if handling=="heavy" or kind=="finish" else 3):
			var angle:=TAU*i/4+serial*0.2
			var dir:=x*cos(angle)+y*sin(angle)
			puffs[puff_cursor]={"age":0.0,"life":0.17,"at":at+n*0.08+dir*0.055,"v":dir*0.90+n*0.35,"size":0.17*power*strength}
			puff_draw.set_instance_color(puff_cursor,Color("fff0d5"));puff_cursor=(puff_cursor+1)%PUFF_CAPACITY
	word(at+Vector3.UP*0.25+n*0.08,kind,handling)

func word(at: Vector3, kind: String, handling: String) -> void:
	super.word(at,kind,handling)
	var w:=words[posmod(word_cursor-1,LABEL_CAPACITY)]
	w.node.font_size=46 if polished and kind=="finish" else (38 if polished else 60)
	w.node.pixel_size=0.0046 if polished else 0.0065
	w.node.outline_size=6 if polished else 10
	if polished:w.life=0.36 if kind=="finish" else 0.24

func advance(delta: float,camera_basis: Basis) -> void:
	if not is_finite(delta) or delta<0:return
	super.advance(delta,camera_basis)
	if puff_draw==null:return
	for i in range(puffs.size()):
		var p:=puffs[i]
		if p.life<=0:continue
		p.age=minf(p.life,p.age+delta)
		var t: float=p.age/p.life
		var scale_value: float=p.size*(0.45+0.7*minf(1,t*4))*pow(1-t,1.4)
		puff_draw.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value),p.at+p.v*p.age))
		if t>=1:p.life=0

func reset() -> void:
	super.reset();puff_cursor=0
	if puff_draw!=null:
		for i in range(puffs.size()):
			puffs[i].life=0.0
			puff_draw.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
