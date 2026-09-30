extends Node3D
## Bounded short segments from the rendered weapon's true movement, never a fabricated hit path.
const CAPACITY:=48
const Attack=preload("res://scripts/phase4/attack_spec.gd")
var draw: MultiMesh
var slots: Array[Dictionary]=[]
var history: Dictionary={}
var cursor:=0
var segments:=0
func _ready() -> void:
	var mesh:=SphereMesh.new();mesh.radial_segments=8;mesh.rings=4;mesh.radius=0.5;mesh.height=1
	draw=MultiMesh.new();draw.transform_format=MultiMesh.TRANSFORM_3D;draw.use_colors=true;draw.mesh=mesh;draw.instance_count=CAPACITY
	var n:=MultiMeshInstance3D.new();n.multimesh=draw
	n.material_override=preload("res://scripts/smash/shapes.gd").material(Color.WHITE,true)
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;n.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
	add_child(n)
	for i in range(CAPACITY):slots.append({"age":0.0,"life":0.0,"owner":-1,"from":Vector3.ZERO,"to":Vector3.ZERO,"width":0.0})
	reset()
func stop_actor(id: int, clear_existing: bool=false) -> void:
	history.erase(id)
	if clear_existing:
		for i in range(slots.size()):
			if slots[i].owner==id:slots[i].life=0.0;draw.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
func advance(delta: float,game,allowed: bool) -> void:
	if not allowed:reset();return
	for i in range(slots.size()):
		var s:=slots[i]
		if s.life<=0:continue
		s.age+=maxf(0,delta)
		var d: Vector3=s.to-s.from
		var scale_value: float=maxf(0,1-s.age/s.life)
		var b:=Basis(Quaternion(Vector3.UP,d.normalized())) if d.length()>0.00001 else Basis.IDENTITY
		draw.set_instance_transform(i,Transform3D(b.scaled(Vector3(s.width*scale_value,d.length(),s.width*scale_value)),(s.from+s.to)*0.5))
		if s.age>=s.life:s.life=0
	if delta<=0:return
	for actor in game.fighters:
		var id: int=actor.player_id
		if actor.hidden_in_box or not actor.visible or not actor.weapon.visible:
			stop_actor(id,true);continue
		var spec:=Attack.spec(actor.handling)
		if actor.elapsed<spec.windup or actor.elapsed>spec.windup+spec.active or actor.outcome!="pending":
			stop_actor(id);continue
		var mesh: Node3D=game.rig.view_weapon if id==game.view_target() else actor.weapon
		var point:=Vector3.ZERO
		for sample in actor.hit_samples:
			if sample.length_squared()>point.length_squared():point=sample
		var at: Vector3=mesh.to_global(point)
		if history.has(id) and history[id].attack==actor.attack_sequence:
			var previous: Vector3=history[id].at
			if at.distance_to(previous)>0.008 and at.distance_to(previous)<1.5:
				slots[cursor]={"age":0.0,"life":0.065,"owner":id,"from":previous,"to":at,"width":0.017 if actor.handling=="heavy" else 0.010}
				var d: Vector3=at-previous
				var b:=Basis(Quaternion(Vector3.UP,d.normalized()))
				draw.set_instance_transform(cursor,Transform3D(b.scaled(Vector3(slots[cursor].width,d.length(),slots[cursor].width)),(at+previous)*0.5))
				draw.set_instance_color(cursor,Color("efd9ad"));cursor=(cursor+1)%CAPACITY;segments+=1
		history[id]={"attack":actor.attack_sequence,"at":at}
func reset() -> void:
	history.clear();cursor=0
	if draw==null:return
	for i in range(slots.size()):slots[i].life=0.0;draw.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
