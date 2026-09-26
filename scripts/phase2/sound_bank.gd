extends Node
## Small locally synthesized effects; no downloaded audio, music, or API requests.
var voices: Array[AudioStreamPlayer] = []
var bank: Dictionary = {}
var voice_index := 0
var volume := 0.7

func _ready() -> void:
	for i in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	bank["hit"] = _tone(210.0,70.0,0.16)
	bank["found"] = _tone(360.0,820.0,0.25)
	bank["ready"] = _tone(440.0,660.0,0.12)
	bank["escape"] = _tone(620.0,960.0,0.24)
	bank["capture"] = _tone(480.0,170.0,0.32)
	bank["taunt"] = _tone(760.0,480.0,0.20)

func play(key: String) -> void:
	if volume <= 0.0 or not bank.has(key):
		return
	var player := voices[voice_index]
	voice_index = (voice_index+1)%voices.size()
	player.stream = bank[key]
	player.volume_db = linear_to_db(volume*0.5)
	player.play()

func _tone(start: float, finish: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration*rate)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var phase := 0.0
	for i in range(count):
		var t := float(i)/count
		phase += TAU*lerpf(start,finish,t)/rate
		var envelope := minf(t*30.0,1.0)*pow(1.0-t,2.5)
		var value := int((sin(phase)+0.2*sin(phase*2.0))*envelope*15000)
		bytes[i*2] = value & 255
		bytes[i*2+1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
