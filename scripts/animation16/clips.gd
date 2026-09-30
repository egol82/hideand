extends RefCounted
## Project-authored, in-place skeletal clips. No method/audio/visibility/authority tracks.
const Rig = preload("res://scripts/character13/mesh_builder.gd")
const STATES := ["idle","walk","run","hide","peek","weapon_ready","windup","attack","hit","recover","ko","air"]
static var cached: AnimationLibrary

static func library() -> AnimationLibrary:
	if cached != null: return cached
	cached = AnimationLibrary.new()
	for state in STATES:
		var clip := Animation.new()
		clip.resource_name = state
		clip.length = 1.0
		clip.loop_mode = Animation.LOOP_LINEAR if state in ["idle","walk","run","hide","peek","weapon_ready"] else Animation.LOOP_NONE
		for bone in range(Rig.NAMES.size()):
			var track := clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(track,NodePath("Skeleton3D:"+Rig.NAMES[bone]))
			for key in range(17):
				var t := float(key)/16
				clip.rotation_track_insert_key(track,t,Quaternion.from_euler(angles(state,t,bone)))
		var pos := clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(pos,NodePath("Skeleton3D:pelvis"))
		for key in range(17):
			var t := float(key)/16
			clip.position_track_insert_key(pos,t,Rig.JOINTS[0]+pelvis_offset(state,t))
		cached.add_animation(state,clip)
	return cached

static func pelvis_offset(state: String,t: float) -> Vector3:
	match state:
		"idle","weapon_ready": return Vector3(0,sin(t*TAU)*0.005,0)
		"walk": return Vector3(0,0.009*(1-cos(t*TAU*2)),0)
		"run": return Vector3(0,0.017*(1-cos(t*TAU*2)),0)
		"hide": return Vector3(0,-0.065,0)
		"peek": return Vector3(0.025,-0.045,0.008)
		"windup": return Vector3(0,-0.018*smoothstep(0,1,t),0)
		"attack": return Vector3(0,lerpf(-0.018,0.01,t),0)
		"hit": return Vector3(0,-0.028*(1-t),0)
		"recover": return Vector3(0,0.01*(1-t),0)
		"ko": return Vector3(0,-0.09*smoothstep(0,1,t),0)
	return Vector3.ZERO

static func angles(state: String,t: float,bone: int) -> Vector3:
	var a := Vector3.ZERO
	var s := sin(t*TAU)
	var side := -1.0 if bone in [4,5,6,10,11,12,16] else 1.0
	match state:
		"idle","weapon_ready":
			if bone == 1: a.x = s*0.012
			if bone == 3: a.z = s*0.018; a.x = -s*0.007
			if bone in [4,7]: a.z = side*0.025; a.x = -0.08
			if bone in [5,8]: a.x = -0.12
		"walk","run":
			var amplitude := 0.43 if state == "run" else 0.25
			if bone == 1: a.x = 0.13 if state == "run" else 0.035; a.y = s*0.05
			if bone == 3: a.x = -0.07 if state == "run" else -0.025; a.z = s*0.035
			if bone in [4,7]: a.x = -side*s*amplitude*0.65-0.08; a.z = side*0.07
			if bone in [5,8]: a.x = -0.32 if state == "run" else -0.16
			if bone in [10,13]: a.x = side*s*amplitude
			if bone in [11,14]: a.x = -maxf(0,side*s)*amplitude*0.65
			if bone in [12,15]: a.x = -side*s*amplitude*0.40
		"hide","peek":
			if bone == 1: a.x = 0.16; a.z = -0.08 if state == "peek" else 0.0
			if bone == 3: a.x = -0.14; a.y = 0.26 if state == "peek" else s*0.025
			if bone in [4,7]: a.x = -0.28; a.z = -side*0.14
			if bone in [5,8]: a.x = -0.42
			if bone in [10,13]: a.x = 0.18
			if bone in [11,14]: a.x = -0.38
		"windup":
			var w := smoothstep(0,1,t)
			if bone == 1: a.y = -0.16*w; a.x = 0.045*w
			if bone == 3: a.y = 0.08*w
			if bone in [4,7]: a.x = -0.26*w; a.z = side*0.12*w
			if bone in [5,8]: a.x = -0.28
		"attack":
			if bone == 1: a.y = lerpf(-0.16,0.20,t); a.x = 0.09*sin(t*PI)
			if bone == 3: a.y = -lerpf(-0.08,0.10,t)
			if bone in [4,7]: a.x = -0.26; a.z = side*0.12
			if bone in [5,8]: a.x = -0.22
		"recover":
			if bone == 1: a.y = 0.20*(1-smoothstep(0,1,t))
			if bone == 3: a.y = -0.10*(1-t)
			if bone in [4,7]: a.x = -0.12; a.z = side*0.07
			if bone in [5,8]: a.x = -0.14
		"hit":
			var j := exp(-t*4.0)*(1-t)
			if bone == 1: a.x = -0.14*j
			if bone == 3: a.x = -0.19*j; a.z = 0.08*j
			if bone in [4,7]: a.z = side*0.44*j; a.x = -0.18*j
			if bone in [5,8]: a.x = -0.25*j
		"ko":
			var k := sin(minf(t*1.5,1.0)*PI*0.5)
			if bone == 1: a.z = 0.20*k
			if bone == 3: a.z = 0.18*k; a.x = -0.12*k
			if bone in [4,7]: a.z = side*0.65*k
			if bone in [11,14]: a.x = -0.40*k
		"air":
			if bone in [4,7]: a.z = side*0.20
			if bone in [10,13]: a.x = 0.13
			if bone in [11,14]: a.x = -0.27
	return a
