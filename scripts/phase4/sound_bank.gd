extends Node3D
## Bounded pool, authored procedural layers; never reads hidden occupancy or sends network traffic.
const MAX_VOICES := 12
var volume := 0.65
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var cursor := 0
var sequence := 0

func _ready() -> void:
	for kind in ["hit","hurt","blocked","swing","step","hide","ready","found","escape","miss","taunt","chime_step","soft_step"]:
		var variants: Array = []
		for variant in range(3): variants.append(_make(kind,variant))
		streams[kind] = variants
	for i in range(MAX_VOICES):
		var voice := AudioStreamPlayer3D.new()
		voice.max_distance = 22
		voice.unit_size = 4
		voice.max_db = 0
		add_child(voice)
		voices.append(voice)

func play(kind: String) -> void:
	var camera := get_viewport().get_camera_3d()
	play_at(kind,camera.global_position if camera != null else Vector3.ZERO)

func play_at(kind: String, at: Vector3, gain: float = 1) -> void:
	if volume <= 0 or DisplayServer.get_name() == "headless" or voices.is_empty(): return
	if not streams.has(kind): return
	var voice := voices[cursor]
	cursor = (cursor+1)%MAX_VOICES
	voice.stop()
	voice.stream = streams[kind][sequence%3]
	sequence += 1
	voice.global_position = at
	voice.volume_db = linear_to_db(maxf(0.001,volume*gain))-9
	voice.play()

func _make(kind: String, variation: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 530+kind.hash()+variation*37
	var length := 0.14 if kind in ["step","miss"] else 0.24
	var count := int(22050*length)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var phase := 0.0
	var low := 0.0
	for i in range(count):
		var t := float(i)/count
		var noise := rng.randf_range(-1,1)
		low = lerpf(low,noise,0.2)
		var frequency: float = {"blocked":380.0,"hit":155.0,"hurt":180.0,"step":90.0,"chime_step":730.0,"soft_step":65.0,"hide":320.0,"found":620.0,"ready":430.0,"escape":540.0}.get(kind,110.0)
		frequency *= 1.0+variation*0.045
		phase += TAU*frequency*(1-t*0.5)/22050
		var envelope := minf(t*60,1)*pow(1-t,3)
		var value := sin(phase)*0.6+low*0.2+noise*exp(-t*45)*0.18
		if kind=="chime_step": value = sin(phase)*0.58+sin(phase*2.01)*0.21
		elif kind=="soft_step": value = low*0.4+sin(phase)*0.15
		if kind in ["swing","miss"]: value = low*1.7*sin(t*PI)
		var sample := int(clampf(value*envelope,-1,1)*18000)
		bytes[i*2] = sample & 255
		bytes[i*2+1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream

func _exit_tree() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	streams.clear()
