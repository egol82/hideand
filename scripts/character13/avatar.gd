extends Node3D
## Skinned world character, independent from first-person paws and authoritative weapon.
## Legacy presentation controls below are empty nodes; one surface supplies the entire body.
const Builder=preload("res://scripts/character13/mesh_builder.gd")
const Art=preload("res://scripts/phase4/art.gd")
var skeleton: Skeleton3D
var body: MeshInstance3D
var face: BoneAttachment3D
var controls: Dictionary={}
var features: Dictionary={}
var attachments: Dictionary={}
var tint:=Color("88d6b0")
var phase:=0.0
var pose_mode:="idle"
var configured:=false
var sync_count:=0
var grip_target:=Vector3(0.48,1.0,0.14)

func configure(color: Color) -> void:
	if configured:return
	configured=true;tint=color;name="SkinnedBuddy"
	skeleton=Skeleton3D.new();skeleton.name="Skeleton3D";add_child(skeleton)
	for i in range(Builder.NAMES.size()):
		skeleton.add_bone(Builder.NAMES[i])
		var parent: int=Builder.PARENTS[i]
		if parent>=0:skeleton.set_bone_parent(i,parent)
		var at: Vector3=Builder.JOINTS[i]-(Builder.JOINTS[parent] if parent>=0 else Vector3.ZERO)
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,at))
	skeleton.reset_bone_poses()
	body=MeshInstance3D.new();body.name="ConnectedBody"
	body.mesh=load("res://assets/character13/buddy_body.res") if ResourceLoader.exists("res://assets/character13/buddy_body.res") else Builder.mesh()
	body.skin=skeleton.create_skin_from_rest_transforms();body.skeleton=NodePath("../Skeleton3D")
	body.custom_aabb=AABB(Vector3(-1.3,-0.4,-0.9),Vector3(2.6,2.7,1.8))
	body.material_override=Art.material(color,"vinyl");add_child(body)
	# Read-only socket targets for later IK. Never parent the world weapon to these bones.
	for side in ["L","R"]:
		var socket:=BoneAttachment3D.new();socket.name="HandSocket"+side;socket.bone_name="hand_"+side
		skeleton.add_child(socket);attachments[side]=socket
		var marker:=Marker3D.new();marker.name="Grip";marker.position=Vector3.ZERO;socket.add_child(marker)
	face=BoneAttachment3D.new();face.name="FaceAttachment";face.bone_name="head";skeleton.add_child(face)
	for label in ["LeftArm","RightArm","LeftFoot","RightFoot","LeftEye","RightEye","LeftGlint","RightGlint","Mouth"]:
		var c:=Node3D.new();c.name=label;add_child(c);controls[label]=c
	controls.LeftFoot.position=Vector3(-0.22,0.18,0.10);controls.RightFoot.position=Vector3(0.22,0.18,0.10)
	controls.LeftEye.scale=Vector3(0.043,0.064,0.026);controls.RightEye.scale=controls.LeftEye.scale
	controls.Mouth.scale=Vector3(0.072,0.042,0.018)
	for side in [-1,1]:
		var prefix: String="Left" if side<0 else "Right"
		var x: float=side*0.175
		var z:=Builder.front(x,1.365)
		features[prefix+"Eye"]=_face_ball(Vector3(x,1.365,z+0.007),Vector3(0.038,0.063,0.025),Color("243b40"),"ink")
		features[prefix+"Glint"]=_face_ball(Vector3(x-0.010,1.389,z+0.030),Vector3(0.011,0.014,0.007),Color("fff2d6"))
		_face_ball(Vector3(side*0.293,1.22,Builder.front(side*0.293,1.22)+0.003),Vector3(0.062,0.028,0.015),color.lerp(Color("eda6a0"),0.52))
		var ear:=BoneAttachment3D.new();ear.name="EarInset"+prefix;ear.bone_name="ear_L" if side<0 else "ear_R";skeleton.add_child(ear)
		var point: Vector3=Vector3(side*0.29,1.80,Builder.front(side*0.29,1.80)+0.004)-Builder.JOINTS[16 if side<0 else 17]
		Art.ball(ear,point,Vector3(0.070,0.10,0.018),color.lightened(0.19))
	features.Mouth=_face_ball(Vector3(0,1.205,Builder.front(0,1.205)+0.011),Vector3(0.047,0.023,0.016),Color("293f44"),"ink")
	_face_ball(Vector3(0,1.281,Builder.front(0,1.281)+0.008),Vector3(0.029,0.019,0.016),color.darkened(0.18))
	# Quiet belly marking sits flush against the body; it is not another torso volume.
	var badge:=BoneAttachment3D.new();badge.name="ChestBadge";badge.bone_name="spine";skeleton.add_child(badge)
	var pin:=Art.ball(badge,Vector3(0,0.865,Builder.front(0,0.865)+0.002)-Builder.JOINTS[1],Vector3(0.052,0.052,0.016),color.lightened(0.30))
	pin.name="ToyButton"
	sync_pose(0,false)

func _face_ball(at: Vector3,size3: Vector3,color: Color,kind: String="vinyl") -> MeshInstance3D:
	return Art.ball(face,at-Builder.JOINTS[3],size3,color,kind)

func _rotation(id: int,angles: Vector3) -> void:
	skeleton.set_bone_pose_rotation(id,Quaternion.from_euler(angles))

func sync_pose(delta: float,reduced: bool) -> void:
	if not configured:return
	sync_count+=1
	# The owner passes zero while paused: poses cannot drift on a settings screen.
	if is_finite(delta) and delta>0 and not reduced:phase=fmod(phase+delta,TAU*10)
	skeleton.reset_bone_poses()
	if pose_mode=="rest":_copy_face();return
	var breath:=0.0 if reduced else sin(phase*1.75)*0.008
	_rotation(1,Vector3(breath,0,0))
	_rotation(3,Vector3(-breath*0.45,0,breath*0.5))
	# Only a restrained compatibility bridge for existing movement/reaction controls.
	# This is not the later full locomotion/IK animation project.
	for pair in [["Left",4,5,6,10,11,12],["Right",7,8,9,13,14,15]]:
		var prefix: String=pair[0]
		var arm: Vector3=controls[prefix+"Arm"].rotation
		_rotation(pair[1],Vector3(clampf(arm.x,-0.7,0.7),arm.y,clampf(arm.z,-0.7,0.7)))
		_rotation(pair[2],Vector3(-0.04,0,0))
		var foot: Node3D=controls[prefix+"Foot"]
		var swing:=clampf((foot.position.z-0.10)*3.0,-0.33,0.33)
		_rotation(pair[4],Vector3(swing,0,0))
		_rotation(pair[5],Vector3(-maxf(0,swing)*0.30,0,0))
		_rotation(pair[6],Vector3(-swing*0.65+foot.rotation.x,0,0))
	if pose_mode=="a_pose":
		_rotation(4,Vector3(0,0,-0.48));_rotation(7,Vector3(0,0,0.48))
	elif pose_mode=="weapon_ready":
		_ready_arm(7,8,9,grip_target)
		_rotation(4,Vector3(-0.25,0.10,-0.06));_rotation(5,Vector3(-0.48,0,0))
	_copy_face()

func _copy_face() -> void:
	for prefix in ["Left","Right"]:
		var eye: Node3D=features[prefix+"Eye"]
		eye.scale.y=maxf(0.001,controls[prefix+"Eye"].scale.y/0.064*0.063)
		eye.visible=controls[prefix+"Eye"].visible
		features[prefix+"Glint"].visible=controls[prefix+"Glint"].visible and eye.visible
	features.Mouth.visible=controls.Mouth.visible
	features.Mouth.scale.y=0.023*clampf(controls.Mouth.scale.y/0.042,0.5,2.2)

func attach_reaction(reaction) -> void:
	# Comic overlays must move with the head, not float at the old unskinned coordinates.
	if not is_instance_valid(reaction.face):return
	if reaction.face.get_parent()!=face:
		reaction.face.reparent(face,false);reaction.face.position=-Builder.JOINTS[3]
	if reaction.stars.get_parent()!=face:
		reaction.stars.reparent(face,false);reaction.stars.position=-Builder.JOINTS[3]

func set_layer(mask: int) -> void:
	_layer_recursive(self,mask)
func _layer_recursive(node: Node,mask: int) -> void:
	if node is VisualInstance3D:node.layers=mask
	for child in node.get_children():_layer_recursive(child,mask)

func _ready_arm(upper: int,lower: int,hand: int,target: Vector3) -> void:
	# A single ready-pose fitting aid for the existing grip, not collision ownership/full body IK.
	var shoulder: Vector3=Builder.JOINTS[upper]
	var rest_a: Vector3=Builder.JOINTS[lower]-shoulder
	var rest_b: Vector3=Builder.JOINTS[hand]-Builder.JOINTS[lower]
	var offset:=target-shoulder
	var reach:=clampf(offset.length(),0.06,rest_a.length()+rest_b.length()-0.005)
	var direction:=offset.normalized()
	var pole:=Vector3(0.9,-1.0,-0.1)
	var bend: Vector3=(pole-direction*pole.dot(direction)).normalized()
	var along: float=(rest_a.length_squared()-rest_b.length_squared()+reach*reach)/(2*reach)
	var height:=sqrt(maxf(0.00001,rest_a.length_squared()-along*along))
	var a: Vector3=direction*along+bend*height
	var b: Vector3=direction*reach-a
	var qa:=Quaternion(rest_a.normalized(),a.normalized())
	var qb:=Quaternion(rest_b.normalized(),qa.inverse()*b.normalized())
	skeleton.set_bone_pose_rotation(upper,qa)
	skeleton.set_bone_pose_rotation(lower,qb)
	skeleton.set_bone_pose_rotation(hand,Quaternion.IDENTITY)
