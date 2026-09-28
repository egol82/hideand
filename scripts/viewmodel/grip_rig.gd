extends Node3D
## Cosmetic grip rig. No fighter, rules, data or collision writes; no per-frame geometry creation.
const Fit = preload("res://scripts/viewmodel/grip_fit.gd")
const Meshes = preload("res://scripts/viewmodel/hand_mesh.gd")
const Art = preload("res://scripts/phase4/art.gd")
var fit: Dictionary = {}
var right_hand: Node3D
var left_hand: Node3D
var right_arm: MeshInstance3D
var left_arm: MeshInstance3D
var right_wrist: MeshInstance3D
var left_wrist: MeshInstance3D
var right_cuff: Node3D
var left_cuff: Node3D
var main_anchor := Vector3.ZERO
var support_anchor := Vector3.ZERO
var right_socket := Vector3.ZERO
var left_socket := Vector3.ZERO
var frame := Basis.IDENTITY

func configure(data, drawing_basis: Basis, display_scale: float, color: Color) -> void:
	fit = Fit.solve(data,drawing_basis,display_scale)
	name = "NaturalGrip"
	if not fit.valid: visible = false; return
	frame = fit.basis
	main_anchor = fit.main
	right_hand = Meshes.curled_hand(self,fit.radius,color)
	right_hand.transform = Transform3D(frame,main_anchor)
	var grip_height := 0.60 if fit.mode == "pinch" else 1.0
	right_hand.scale.y = grip_height
	if fit.mode == "shaft":
		support_anchor = fit.support
		left_hand = Meshes.curled_hand(self,fit.radius,color,true)
		left_hand.transform = Transform3D(frame,support_anchor)
	else:
		# The drawing has no lower shaft. Cup the right wrist honestly, do not invent a handle.
		support_anchor = main_anchor+frame*Vector3(0.052,-0.123*grip_height,0.042)
		left_hand = Meshes.curled_hand(self,0.037,color,true)
		left_hand.transform = Transform3D(frame.rotated(frame.z,0.10),support_anchor)
		left_hand.scale = Vector3.ONE*0.83
	right_socket = main_anchor+frame*Vector3(fit.radius+0.070,-0.090*grip_height,0.042)
	left_socket = support_anchor+left_hand.basis*Vector3(-0.085,-0.080,0.038)
	right_arm = Meshes.sleeve(self,"RightSleeve")
	left_arm = Meshes.sleeve(self,"LeftSleeve")
	right_wrist = _wrist(color,"RightWrist")
	left_wrist = _wrist(color,"LeftWrist")
	right_cuff = _cuff("RightCuff")
	left_cuff = _cuff("LeftCuff")

func _wrist(color: Color, label: String) -> MeshInstance3D:
	var p := PackedVector3Array([Vector3.ZERO,Vector3(0,0.1,0),Vector3(0,0.8,0),Vector3.UP])
	return Meshes.instance(self,Meshes.tube(p,PackedFloat32Array([0.038,0.041,0.043,0.044]),false),label,color)

func _cuff(label: String) -> Node3D:
	var root := Node3D.new(); root.name = label; add_child(root)
	var p := PackedVector3Array([Vector3.ZERO,Vector3(0,0.009,0),Vector3(0,0.026,0),Vector3(0,0.035,0)])
	Meshes.instance(root,Meshes.tube(p,PackedFloat32Array([0.048,0.052,0.052,0.050]),false),"RibbedCuff",Color("dfd2b9"),"fabric")
	return root

func update_pose(view_root: Node3D, sweep: float) -> void:
	if not is_instance_valid(right_hand): return
	# Sleeves bridge actual grip sockets to two distinct lower-screen forearms.
	# The hands stay locked to their contacts throughout windup, strike and recovery.
	var right_elbow: Vector3 = view_root.transform.affine_inverse()*Vector3(0.42-clampf(sweep,-0.5,1)*0.025,-0.73,-0.08)
	var left_elbow := view_root.transform.affine_inverse()*Vector3(-0.22,-0.78,-0.06)
	_attach_arm(right_socket,right_elbow,right_wrist,right_arm,right_cuff)
	_attach_arm(left_socket,left_elbow,left_wrist,left_arm,left_cuff)

func _attach_arm(socket: Vector3, elbow: Vector3, wrist: Node3D, sleeve: Node3D, cuff: Node3D) -> void:
	var direction := (elbow-socket).normalized()
	var cuff_at := socket+direction*0.060
	Meshes.link(wrist,socket-direction*0.020,cuff_at+direction*0.012)
	Meshes.link(sleeve,cuff_at,elbow)
	# Unit-length frame for a real-thickness cuff; avoid stretching its decorative geometry.
	var helper := Vector3.FORWARD if absf(direction.z) < 0.95 else Vector3.RIGHT
	var x := direction.cross(helper).normalized()
	cuff.transform = Transform3D(Basis(x,direction,x.cross(direction).normalized()),cuff_at)
