extends Node3D
## Original synthetic toy thump + rubber squeak + wood knock. No sampled copyrighted sounds.
const VOICES:=6
const RATE:=22050
var voices: Array[AudioStreamPlayer3D]=[]
var streams: Dictionary={}
var cursor:=0
var volume:=0.7
var calls:=0

func _ready() -> void:
	for kind in ["bop","bonk","smash","blocked","squeak"]:
		var list: Array=[]
		for v in range(3): list.append(make_tone(kind,v))
		streams[kind]=list
	for i in range(VOICES):
		var p:=AudioStreamPlayer3D.new(); p.max_distance=22; p.unit_size=4; p.max_db=-2
		add_child(p); voices.append(p)

static func make_tone(kind: String, variation: int) -> AudioStreamWAV:
	var count:=int(RATE*(0.24 if kind!="squeak" else 0.18))
	var data:=PackedByteArray(); data.resize(count*2)
	var phase:=0.0; var low:=0.0
	var rng:=RandomNumberGenerator.new(); rng.seed=6901+kind.hash()+variation*67
	for i in range(count):
		var t:=float(i)/count
		var noise:=rng.randf_range(-1,1); low=lerpf(low,noise,0.17)
		var f: float={"bop":215.0,"bonk":150.0,"smash":90.0,"blocked":510.0,"squeak":850.0}.get(kind,150.0)
		f*=1.0+0.035*variation
		phase+=TAU*f*(1.0-0.58*t+0.06*sin(t*PI*5))/RATE
		var envelope:=minf(1,t*100)*pow(1-t,2.8)
		var value:=sin(phase)*0.63+low*0.26+noise*exp(-t*58)*0.09
		if kind=="blocked": value=sin(phase)*0.53+sin(phase*2.73)*0.22+low*0.11
		if kind=="squeak": value=(sin(phase)+sin(phase*2)*0.20)*sin(t*PI)*0.45
		var sample:=int(clampf(value*envelope,-0.9,0.9)*23000)
		data[i*2]=sample&255; data[i*2+1]=(sample>>8)&255
	var wav:=AudioStreamWAV.new(); wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=RATE; wav.data=data
	return wav

func play_contact(kind: String, at: Vector3, handling: String, sequence: int) -> void:
	if not at.is_finite(): return
	calls+=1
	if volume<=0 or DisplayServer.get_name()=="headless": return
	var key: String="smash" if kind=="finish" or handling=="heavy" else ("bop" if handling=="quick" else "bonk")
	if kind=="blocked": key="blocked"
	play_one(key,at,sequence,1.0)
	if kind!="blocked": play_one("squeak",at,sequence,0.37)

func play_one(key: String, at: Vector3, sequence: int, gain: float) -> void:
	var p:=voices[cursor]; cursor=(cursor+1)%VOICES
	p.stop(); p.stream=streams[key][posmod(sequence,3)]; p.global_position=at
	p.volume_db=linear_to_db(maxf(0.001,volume*gain))-7; p.play()

func reset() -> void:
	for p in voices: p.stop()

func _exit_tree() -> void:
	reset()
	for p in voices: p.stream=null
	streams.clear()
