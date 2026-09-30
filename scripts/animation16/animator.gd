extends Node
## Single visual pose owner after the legacy bridge: clip -> crossfade -> ground/hand IK -> ears.
const Clips = preload("res://scripts/animation16/clips.gd")
const IK = preload("res://scripts/animation16/two_bone.gd")
const Grip = preload("res://scripts/viewmodel/grip_fit.gd")
const Attack = preload("res://scripts/phase4/attack_spec.gd")
var avatar
var player: AnimationPlayer
var state := "idle"
var local_clock := 0.0
var locomotion_phase := 0.0
var blend_age := 1.0
var blend_from: Array[Quaternion]=[]
var blend_from_pos := Vector3.ZERO
var last_position := Vector3.ZERO
var have_position := false
var grip_revision := -1
var grip_fit: Dictionary={}
var grip_mode := "none"
var right_error := 0.0
var left_error := 0.0
var hand_clamped := false
var ground_hits := 0
var grounded_feet: Array[Vector3]=[]
var foot_targets: Array[Vector3]=[Vector3.ZERO,Vector3.ZERO]
var plants: Array[Dictionary]=[{},{}]
var ear_angle := 0.0
var sample_time := 0.0
var updates := 0
var ik_enabled := true
var current_direction := Vector3.BACK
var prior_rotations: Array[Quaternion]=[]
var prior_position := Vector3.ZERO

func setup(subject) -> void:
	avatar=subject;name="Motion16"
	player=AnimationPlayer.new();player.name="AnimationPlayer16"
	# Animation paths are local to the existing skinned body, not the actor/weapon.
	avatar.add_child(player);player.root_node=NodePath("..")
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.add_animation_library("",Clips.library())
	player.play("idle");player.seek(0,true)

func reset() -> void:
	have_position=false;plants=[{},{}];state="idle";local_clock=0;locomotion_phase=0;blend_age=1
	ear_angle=0;grip_mode="none";ground_hits=0;sample_time=0;blend_from.clear();prior_rotations.clear()

func select_state(actor,reaction,peek: bool,transit: bool) -> String:
	if actor.hidden_in_box: return "peek" if peek else "hide"
	if not actor.visible: return "ko"
	if reaction!=null and reaction.life>0: return "hit"
	if actor.elapsed>=0:
		var s:=Attack.spec(actor.handling)
		if actor.elapsed<s.windup:return "windup"
		if actor.elapsed<s.windup+s.active:return "attack"
		return "recover"
	if transit:return "hide"
	if not actor.is_on_floor() and absf(actor.velocity.y)>0.4:return "air"
	var speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
	if speed>5.0 or actor.dash_time>0:return "run"
	if speed>0.12:return "walk"
	return "weapon_ready" if actor.weapon.visible else "idle"

func update_actor(actor,reaction,delta: float,reduced: bool,peek: bool=false,transit: bool=false,freeze: bool=false) -> void:
	if freeze or not is_finite(delta) or delta<0:return
	var distance:=0.0
	if have_position:distance=Vector2(actor.global_position.x-last_position.x,actor.global_position.z-last_position.z).length()
	if distance>1.5 or (have_position and absf(actor.global_position.y-last_position.y)>1.0):
		plants=[{},{}];distance=0;locomotion_phase=0
	last_position=actor.global_position;have_position=true
	var chosen:=select_state(actor,reaction,peek,transit)
	var speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
	var velocity_local: Vector3=actor.visual.global_basis.orthonormalized().inverse()*Vector3(actor.velocity.x,0,actor.velocity.z)
	if velocity_local.length()>0.1:current_direction=velocity_local.normalized()
	# Distance, not frame rate or held keys, advances the walking cycle.
	locomotion_phase=fposmod(locomotion_phase+distance/(0.72 if chosen=="run" else 0.56),1.0)
	if not reduced:local_clock+=delta
	var t:=fposmod(local_clock/3.0,1.0) if not reduced else 0.0
	if chosen in ["walk","run"]:t=locomotion_phase
	elif chosen in ["windup","attack","recover"]:
		var s:=Attack.spec(actor.handling)
		if chosen=="windup":t=actor.elapsed/s.windup
		elif chosen=="attack":t=(actor.elapsed-s.windup)/s.active
		else:t=(actor.elapsed-s.windup-s.active)/s.recovery
	elif chosen=="hit":t=reaction.age/maxf(0.001,reaction.life)
	evaluate(chosen,t,delta,reduced)
	if chosen=="hit" and reaction!=null:
		var impulse: float=exp(-t*6.0)*0.10*reaction.strength
		avatar.skeleton.set_bone_pose_rotation(1,(avatar.skeleton.get_bone_pose_rotation(1)*Quaternion.from_euler(Vector3(-reaction.local_direction.z*impulse,0,reaction.local_direction.x*impulse))).normalized())
	ground_hits=0;grounded_feet.clear()
	if ik_enabled and chosen not in ["hide","peek","ko","air","hit"] and actor.visible and not transit and actor.is_on_floor():
		feet(actor,chosen,t,speed,delta)
	else:plants=[{},{}]
	grip_mode="none";right_error=0;left_error=0;hand_clamped=false
	if ik_enabled and actor.weapon.visible and actor.visible and not actor.hidden_in_box and chosen not in ["hit","ko","hide","peek"]:
		hands(actor)
	avatar._copy_face()
	remember_pose()
	updates+=1

func evaluate(chosen: String,t: float,delta: float,reduced: bool=false) -> void:
	if chosen not in Clips.STATES:return
	var sk: Skeleton3D=avatar.skeleton
	if chosen!=state or player.assigned_animation!=chosen:
		blend_from.clear()
		for i in range(sk.get_bone_count()):blend_from.append(prior_rotations[i] if prior_rotations.size()==sk.get_bone_count() else sk.get_bone_pose_rotation(i))
		blend_from_pos=prior_position if not prior_rotations.is_empty() else sk.get_bone_pose_position(0)
		blend_age=0.0 if chosen in ["idle","walk","run","weapon_ready"] and state in ["idle","walk","run","weapon_ready","recover","hit","air"] else 1.0
		state=chosen;player.play(chosen)
	# All non-animated bone fields reset; no incremental drift or stale previous pose.
	sk.reset_bone_poses()
	sample_time=clampf(t,0,0.999999)
	player.seek(sample_time,true)
	blend_age=minf(1,blend_age+maxf(0,delta)/0.10)
	if blend_age<1 and blend_from.size()==sk.get_bone_count():
		var w:=smoothstep(0,1,blend_age)
		for i in range(sk.get_bone_count()):sk.set_bone_pose_rotation(i,blend_from[i].slerp(sk.get_bone_pose_rotation(i),w))
		sk.set_bone_pose_position(0,blend_from_pos.lerp(sk.get_bone_pose_position(0),w))
	# Stable, bounded secondary motion; essential walk/attack remains in comfort mode.
	var wanted:=0.0 if reduced else (sin(t*TAU)*0.07 if chosen in ["walk","run"] else (exp(-t*8)*0.10 if chosen=="hit" else sin(local_clock*2)*0.018))
	if reduced:ear_angle=0
	else:ear_angle=lerpf(ear_angle,wanted,1-exp(-maxf(0,delta)*14))
	sk.set_bone_pose_rotation(16,Quaternion.from_euler(Vector3(ear_angle,0,-ear_angle*0.3)))
	sk.set_bone_pose_rotation(17,Quaternion.from_euler(Vector3(-ear_angle*0.7,0,ear_angle*0.3)))

func hands(actor) -> void:
	if grip_revision!=actor.drawing_revision:
		grip_fit=Grip.solve(actor.weapon_data,Basis.IDENTITY,1.0);grip_revision=actor.drawing_revision
	if not grip_fit.get("valid",false):return
	var sk: Skeleton3D=avatar.skeleton
	var to_skeleton:=sk.global_transform.affine_inverse()
	var anchor: Vector3=grip_fit.anchor
	# Primary hand stays by the selected real stroke, not a far end of a large drawing.
	var main: Vector3=anchor+grip_fit.axis*minf(grip_fit.run*0.10,0.025)
	var target: Vector3=to_skeleton*(actor.weapon.global_transform*main)
	var report:=IK.solve(sk,7,8,9,target,Vector3(0.8,-1,-0.2))
	if not report.valid:return
	right_error=report.endpoint.distance_to(target);hand_clamped=report.clamped
	# A round paw has no anatomical finger requirement; keep wrist tilt bounded.
	var aim: Basis=(to_skeleton.basis*actor.weapon.global_basis*grip_fit.basis).orthonormalized()
	var parent_basis:=sk.get_bone_global_pose(8).basis.orthonormalized()
	var wrist:=parent_basis.get_rotation_quaternion().inverse()*aim.get_rotation_quaternion()
	var angle:=wrist.get_angle()
	if angle>0.9:wrist=Quaternion.IDENTITY.slerp(wrist,0.9/maxf(angle,0.001))
	sk.set_bone_pose_rotation(9,wrist.normalized())
	grip_mode="one_hand"
	# Only a long connected shaft justifies a second shaft grip; unreachable support releases.
	if grip_fit.run<0.31:return
	var shoulder:=sk.get_bone_global_pose(4).origin
	var max_reach:=sk.get_bone_pose_position(5).length()+sk.get_bone_pose_position(6).length()
	var support:=Vector3.ZERO
	var found:=false
	# Search only the connected real shaft. A support hand releases when it cannot reach.
	for offset in [0.22,0.32,0.42,0.52,0.62]:
		if offset>grip_fit.run-0.035:continue
		var candidate: Vector3=to_skeleton*(actor.weapon.global_transform*(anchor+grip_fit.axis*offset))
		if shoulder.distance_to(candidate)<max_reach-0.002:
			support=candidate;found=true;break
	if not found:return
	var left:=IK.solve(sk,4,5,6,support,Vector3(-0.8,-1,-0.2))
	if left.valid:
		grip_mode="two_hand";left_error=left.endpoint.distance_to(support)

func feet(actor,chosen: String,t: float,speed: float,delta: float) -> void:
	var sk: Skeleton3D=avatar.skeleton
	var moving:=chosen in ["walk","run"] and speed>0.12
	for i in range(2):
		var upper:=10 if i==0 else 13;var lower:=upper+1;var tip:=upper+2
		var phase_value:=fposmod(t+0.5*i,1.0)
		var swing:=moving and phase_value<0.42
		var rest: Vector3=Clips.Rig.JOINTS[tip]
		var stride:=0.13 if chosen=="run" else 0.10
		var along:=lerpf(-stride,stride,phase_value/0.42) if swing else lerpf(stride,-stride,(phase_value-0.42)/0.58)
		var base_local:=rest+current_direction*(along if moving else 0.0)
		var base: Vector3=actor.visual.global_transform*base_local
		var query:=PhysicsRayQueryParameters3D.create(base+Vector3.UP*0.38,base-Vector3.UP*0.65,1)
		var hit: Dictionary=actor.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.normal.dot(Vector3.UP)<0.64:plants[i]={};continue
		var target: Vector3=hit.position+Vector3.UP*0.16
		if absf(hit.position.y-actor.global_position.y)>0.31:plants[i]={};continue
		if swing:
			plants[i]={};target.y+=sin(phase_value/0.42*PI)*(0.08 if chosen=="run" else 0.055)
		else:
			if plants[i].is_empty() or plants[i].point.distance_to(target)>0.21:
				plants[i]={"point":target,"normal":hit.normal}
			target=plants[i].point
		foot_targets[i]=target;ground_hits+=1;grounded_feet.append(hit.position)
		var result:=IK.solve(sk,upper,lower,tip,sk.to_local(target),Vector3(0,0,1))
		if not result.valid:continue
		var forward: Vector3=actor.visual.global_basis.z
		var up: Vector3=hit.normal
		var right:=up.cross(forward).normalized()
		if right.length_squared()<0.1:continue
		var basis:=Basis(right,up,right.cross(up).normalized())
		IK.orient(sk,tip,sk.global_basis.inverse()*basis)

func remember_pose() -> void:
	prior_rotations.clear()
	for i in range(avatar.skeleton.get_bone_count()):prior_rotations.append(avatar.skeleton.get_bone_pose_rotation(i))
	prior_position=avatar.skeleton.get_bone_pose_position(0)
