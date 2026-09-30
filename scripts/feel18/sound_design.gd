extends RefCounted
## Project-authored PCM recipes. Body thump, short felt transient and elastic tail are one clock.
const RATE := 22050
const Attack = preload("res://scripts/phase4/attack_spec.gd")
const KEYS := ["quick","balanced","heavy","finish","blocked","swing_quick","swing_balanced","swing_heavy"]
static var cache: Dictionary = {}

static func stream(key: String, variant: int = 0, muffled: bool = false) -> AudioStreamWAV:
	variant=posmod(variant,3)
	var tag := key+str(posmod(variant,3))+str(muffled)
	if cache.has(tag): return cache[tag]
	var swinging := key.begins_with("swing_")
	var duration := 0.38 if key=="finish" else (0.30 if key=="heavy" else 0.24)
	var peak := 0.028
	if swinging:
		var timing := Attack.spec(key.trim_prefix("swing_"))
		duration = timing.windup+timing.active+0.07
		peak = timing.windup+timing.active*0.32
	var count := int(RATE*duration)
	var bytes := PackedByteArray(); bytes.resize(count*2)
	var random := RandomNumberGenerator.new(); random.seed = 18180+key.hash()+posmod(variant,3)*197
	var low := 0.0; var filtered := 0.0; var phase := 0.0; var elastic := 0.0
	for i in range(count):
		var seconds := float(i)/RATE
		var t := seconds/duration
		var noise := random.randf_range(-1.0,1.0)
		low = lerpf(low,noise,0.10)
		var f: float = {"quick":205.0,"balanced":140.0,"heavy":94.0,"finish":78.0,"blocked":560.0}.get(key,125.0)
		f *= 1.0+posmod(variant,3)*0.028
		phase += TAU*f*(1.0-0.62*t)/RATE
		elastic += TAU*(420.0+110.0*sin(t*PI*1.4))*(1.0+variant*0.019)/RATE
		var onset := minf(1.0,seconds/0.0015)
		var end := smoothstep(duration,duration-0.022,seconds)
		var body := sin(phase)*exp(-seconds*(18.0 if key=="quick" else 13.0))
		var tap := (noise-low)*exp(-seconds*145.0)
		var tail := sin(elastic)*exp(-seconds*17.0)*smoothstep(0.013,0.048,seconds)
		var value := (0.48*body+0.21*low*exp(-seconds*18.0)+0.12*tap+0.13*tail)*onset*end
		if key=="blocked":
			value = (0.35*sin(phase)+0.17*sin(phase*2.37)+0.12*tap)*exp(-seconds*24.0)*onset*end
		if key=="finish": value += 0.07*sin(elastic*1.49)*sin(t*PI)*exp(-seconds*10.0)*onset*end
		if swinging:
			var width := 0.042 if key=="swing_quick" else 0.06
			var whoosh := exp(-pow((seconds-peak)/width,2.0))
			value = (low*1.35+(noise-low)*0.06)*whoosh*onset*end
		filtered = lerpf(filtered,value,0.10)
		if muffled: value=filtered*0.55
		var sample := int(clampf(value,-0.82,0.82)*32767.0)
		bytes[i*2]=sample&255; bytes[i*2+1]=(sample>>8)&255
	var wav := AudioStreamWAV.new(); wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=RATE; wav.data=bytes; cache[tag]=wav
	return wav

static func warm() -> void:
	for key in KEYS:
		for v in range(3):
			stream(key,v,false)
			if not key.begins_with("swing_"): stream(key,v,true)
