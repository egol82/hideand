extends Node3D
## One additive, visual-only spring layer per actor. Never touches FacingRoot or weapon ancestry.
const Shapes = preload("res://scripts/smash/shapes.gd")
const Art = preload("res://scripts/phase4/art.gd")
var actor
var face: Node3D
var stars: Node3D
var eye_nodes: Array[Node3D] = []
var spiral_nodes: Array[Node3D] = []
var age := 1.0
var life := 0.0
var strength := 1.0
var side := 1.0
var local_direction := Vector3.BACK
var last_kind := ""
var immediate_impact := false
var base_arm_rotations: Array[Vector3] = []

func setup(subject) -> void:
	actor=subject; name="SmashReaction"
	# Root is between FacingRoot and art, not above the weapon pivot.
	var art: Node3D=actor.body_art
	actor.visual.remove_child(art); actor.visual.add_child(self); add_child(art)
	face=Node3D.new(); face.name="ComicExpression"; art.add_child(face)
	for sign_value in [-1,1]:
		var eye=Shapes.item(face,Shapes.spiral(),Vector3(sign_value*0.19,1.36,0.432),Vector3.ONE*0.145,Color("29444c"))
		spiral_nodes.append(eye)
		var squint:=Node3D.new(); face.add_child(squint); squint.position=eye.position
		for angle in [-0.72,0.72]:
			var line=Art.box(squint,Vector3.ZERO,Vector3(0.10,0.020,0.012),Color("29444c"),"ink",0.005)
			line.rotation.z=angle
		eye_nodes.append(squint)
	Art.ball(face,Vector3(0,1.18,0.423),Vector3(0.061,0.080,0.017),Color("29444c"),"ink")
	stars=Node3D.new(); stars.name="DizzyStars"; art.add_child(stars)
	for i in range(3):
		Shapes.item(stars,Shapes.star(),Vector3.ZERO,Vector3.ONE*0.21,[Color("ffe4a5"),Color("a5ddd4"),Color("f2b2bd")][i])
	base_arm_rotations=[art.get_node("LeftArm").rotation,art.get_node("RightArm").rotation]
	reset()

func start(direction: Vector3, handling: String, sequence: int, finish: bool = false) -> void:
	if not is_instance_valid(actor) or actor.hidden_in_box or not actor.visible: return
	local_direction=actor.visual.global_basis.orthonormalized().inverse()*direction.normalized()
	strength=1.0 if handling=="balanced" else (0.72 if handling=="quick" else 1.22)
	life=0.65 if finish else (0.56 if handling=="heavy" else 0.44)
	age=0; side=-1.0 if sequence%2 else 1.0
	last_kind="finish" if finish else handling
	face.visible=true; stars.visible=true

func advance(delta: float, reduced: bool, amount: float) -> void:
	if not is_instance_valid(actor): return
	if actor.hidden_in_box or not actor.visible or reduced or amount<=0:
		reset(); return
	if life<=0: return
	age=minf(life,age+maxf(0,delta))
	var t:=age/life
	if t>=1: reset(); return
	var decay:=exp(-t*4.5)*(1-t)
	var impact:=exp(-t*16.0) if immediate_impact else sin(minf(1,t*5.5)*PI)
	var spring:=sin(t*TAU*1.6)*decay
	var a:=strength*clampf(amount,0,1)
	scale=Vector3(1+0.20*impact*a,1-0.20*impact*a,1+0.12*impact*a)
	rotation=Vector3(local_direction.z*spring*0.50*a,side*spring*0.16*a,-local_direction.x*spring*0.55*a+side*spring*0.14*a)
	position=Vector3(0,0.085*sin(t*PI)*a,0)
	var art: Node3D=actor.body_art
	art.get_node("LeftArm").rotation=base_arm_rotations[0]+Vector3(spring*0.6*a,0,-0.65*impact*a)
	art.get_node("RightArm").rotation=base_arm_rotations[1]+Vector3(-spring*0.6*a,0,0.65*impact*a)
	for label in ["LeftEye","RightEye","LeftGlint","RightGlint","Mouth"]: art.get_node(label).visible=false
	for eye in spiral_nodes: eye.visible=last_kind in ["heavy","finish"] or t>0.40
	for eye in eye_nodes: eye.visible=last_kind not in ["heavy","finish"] and t<=0.40
	for i in range(3):
		var theta:=age*5.8+TAU*i/3
		var star: Node3D=stars.get_child(i)
		star.position=Vector3(cos(theta)*0.42,1.90+0.04*sin(theta*2),sin(theta)*0.21)
		star.rotation=Vector3(0,theta*0.22,theta*0.4)

func reset() -> void:
	life=0; age=0; transform=Transform3D.IDENTITY
	if is_instance_valid(face): face.visible=false
	if is_instance_valid(stars): stars.visible=false
	if is_instance_valid(actor) and is_instance_valid(actor.body_art):
		for label in ["LeftEye","RightEye","LeftGlint","RightGlint","Mouth"]: actor.body_art.get_node(label).visible=true
		if base_arm_rotations.size()==2:
			actor.body_art.get_node("LeftArm").rotation=base_arm_rotations[0]
			actor.body_art.get_node("RightArm").rotation=base_arm_rotations[1]
