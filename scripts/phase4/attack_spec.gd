extends RefCounted
## One attack clock feeds authority and the cosmetic view. Values are tuning hypotheses.
const IDS := ["quick", "balanced", "heavy"]
const BUFFER := 0.10

static func spec(id: String) -> Dictionary:
	match id:
		"quick": return {"id":id,"windup":0.09,"active":0.075,"recovery":0.19,"knock":4.5,"move":0.8}
		"heavy": return {"id":id,"windup":0.18,"active":0.11,"recovery":0.32,"knock":8.0,"move":0.48}
		_: return {"id":"balanced","windup":0.12,"active":0.09,"recovery":0.24,"knock":6.2,"move":0.65}

static func duration(id: String) -> float:
	var s := spec(id)
	return s.windup+s.active+s.recovery

static func progress(id: String, elapsed: float) -> float:
	var s := spec(id)
	return clampf((elapsed-s.windup)/s.active,0,1)

static func pose(id: String, elapsed: float) -> Vector3:
	if elapsed < 0:
		return Vector3(-0.22,-0.75,0)
	var s := spec(id)
	if elapsed < s.windup:
		var t := smoothstep(0,s.windup,elapsed)
		return Vector3(lerpf(-0.22,-0.32,t),lerpf(-0.75,-1.42,t),-0.1*t)
	if elapsed < s.windup+s.active:
		var t := progress(id,elapsed)
		return Vector3(lerpf(-0.32,-0.12,t),lerpf(-1.42,1.05,t),lerpf(-0.1,0.12,t))
	var t := smoothstep(0,s.recovery,elapsed-s.windup-s.active)
	return Vector3(lerpf(-0.12,-0.22,t),lerpf(1.05,-0.75,t),0.12*(1-t))

static func overlaps_active(id: String, before: float, after: float) -> bool:
	var s := spec(id)
	return after >= s.windup and before <= s.windup+s.active and after >= 0
