extends Node3D
## Bounded, depth-tested world effects. Every burst is an observed contact, not a damage source.
const Shapes = preload("res://scripts/smash/shapes.gd")
const CAPACITY := 96
const LABEL_CAPACITY := 6
const PALETTE := [Color("ffe0a0"),Color("f6a3b5"),Color("99decb"),Color("aecbe9")]
var draws: Array[MultiMesh] = []
var particles: Array[Dictionary] = []
var words: Array[Dictionary] = []
var cursor := 0
var word_cursor := 0
var enabled := true
var serial := 0
var language := "en"

func _ready() -> void:
	var chip := BoxMesh.new(); chip.size = Vector3(1,0.20,0.55)
	for mesh in [Shapes.star(),chip,Shapes.ring()]:
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true; mm.mesh = mesh; mm.instance_count = CAPACITY
		var draw := MultiMeshInstance3D.new(); draw.multimesh = mm
		draw.material_override = Shapes.material(Color.WHITE,true)
		draw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(draw); draws.append(mm)
	for i in range(CAPACITY): particles.append({"age":1.0,"life":0.0,"kind":0,"at":Vector3.ZERO,"v":Vector3.ZERO,"size":0.0,"spin":0.0})
	for i in range(LABEL_CAPACITY):
		var label := Label3D.new(); label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 60; label.pixel_size = 0.0065; label.outline_size = 10
		label.outline_modulate = Color("30404b"); label.no_depth_test = false
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var font := SystemFont.new(); font.font_names = PackedStringArray(["Noto Sans CJK KR","Malgun Gothic","sans-serif"])
		label.font = font; label.visible = false; add_child(label)
		words.append({"node":label,"life":0.0,"age":0.0,"at":Vector3.ZERO})
	reset()

func emit_contact(at: Vector3, normal: Vector3, kind: String, handling: String, strength: float = 1.0) -> void:
	if not enabled or strength <= 0 or not at.is_finite(): return
	serial += 1
	var heavy := handling == "heavy"
	var count := 18 if kind == "finish" else (10 if heavy else 7)
	if kind == "blocked": count = 4
	if kind == "miss": return
	var n := normal.normalized() if normal.length_squared() > 0.01 else Vector3.BACK
	for i in range(count):
		var angle := TAU*float(i)/count+float(serial%7)*0.23
		var v := Vector3(cos(angle),0.5+float(i%3)*0.30,sin(angle))*1.5+n*0.65
		var size_value := (0.17 if i%3==0 else 0.10)*(1.3 if kind == "finish" else 1.0)*strength
		put(i%2,at+n*0.05,v,size_value,0.40+float(i%3)*0.07,PALETTE[(i+serial)%4])
	if kind != "blocked": put(2,at+n*0.10,Vector3.ZERO,(1.0 if heavy else 0.75)*strength,0.22,Color("ffe9b8"))
	word(at+Vector3.UP*0.30+n*0.12,kind,handling)

func put(kind: int, at: Vector3, velocity: Vector3, size_value: float, life: float, color: Color) -> void:
	for mm in draws: mm.set_instance_transform(cursor,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	particles[cursor] = {"age":0.0,"life":life,"kind":kind,"at":at,"v":velocity,"size":size_value,"spin":float((serial+cursor)%13)*0.63}
	draws[kind].set_instance_color(cursor,color)
	cursor = (cursor+1)%CAPACITY

func word(at: Vector3, kind: String, handling: String) -> void:
	var message := "SMASH!" if kind=="finish" else ("CLONK!" if kind=="blocked" else ("BONK!" if handling!="quick" else "BOP!"))
	if language == "ko": message = "스매시!" if kind=="finish" else ("팅!" if kind=="blocked" else ("쾅!" if handling=="heavy" else "퍽!"))
	var w := words[word_cursor]; w.node.text = message; w.node.modulate = Color("fff0bd") if kind!="blocked" else Color("a9d2eb")
	w.at = at; w.age = 0.0; w.life = 0.48 if kind=="finish" else 0.32; w.node.visible = true
	word_cursor = (word_cursor+1)%LABEL_CAPACITY

func advance(delta: float, camera_basis: Basis) -> void:
	if not is_finite(delta) or delta < 0: return
	for i in range(CAPACITY):
		var p := particles[i]
		if p.life <= 0: continue
		p.age = minf(p.life,p.age+delta)
		var t: float = p.age/p.life
		if t >= 1:
			draws[p.kind].set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO)); p.life=0.0; continue
		var pos: Vector3 = p.at+p.v*p.age+Vector3.DOWN*1.8*p.age*p.age
		var s: float = p.size*(1-t*t)
		var b := Basis.from_euler(Vector3(p.spin,t*7,p.spin+t*4))
		if p.kind==2:
			b=camera_basis; s=p.size*(0.35+1.5*t)*(1-t); pos=p.at
		elif p.kind==0: b=camera_basis.rotated(camera_basis.z,p.spin+t*4)
		draws[p.kind].set_instance_transform(i,Transform3D(b.scaled(Vector3.ONE*s),pos))
	for w in words:
		if w.life <= 0: continue
		w.age=minf(w.life,w.age+delta)
		var t: float=w.age/w.life
		w.node.position=w.at+Vector3.UP*(0.12*t)
		w.node.scale=Vector3.ONE*(0.80+0.20*sin(minf(1,t*5)*PI*0.5))
		w.node.modulate.a=1-smoothstep(0.65,1.0,t)
		if t>=1: w.life=0; w.node.visible=false

func active_count() -> int:
	var n:=0
	for p in particles:
		if p.life>0: n+=1
	return n

func reset() -> void:
	cursor=0; word_cursor=0
	for i in range(particles.size()):
		particles[i].life=0.0
		for mm in draws: mm.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	for w in words: w.life=0.0; w.node.visible=false
