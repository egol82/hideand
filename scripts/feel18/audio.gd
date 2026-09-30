extends "res://scripts/smash/audio.gd"
## One precomposed stream per impact; bounded voices, no delayed squeak timer or global bus writes.
const Design = preload("res://scripts/feel18/sound_design.gd")
var polished := true
var next_muffled := false
var clock := 0.0
var gain_records: Array[float] = []
var recording := false
var recording_events: Array[Dictionary] = []
var last_key := ""
var last_sequence := -1
var onset_clock := 0.0
var paused_state := false

func _ready() -> void:
	super._ready(); Design.warm()
	gain_records.resize(VOICES); gain_records.fill(-1.0)
	for voice in voices: voice.max_db=-7; voice.panning_strength=0.8

func play_contact(kind: String, at: Vector3, handling: String, sequence: int) -> void:
	if not polished:
		super.play_contact(kind,at,handling,sequence); return
	if not at.is_finite() or paused_state: return
	calls+=1
	var key := "finish" if kind=="finish" else ("blocked" if kind=="blocked" else handling)
	if key not in Design.KEYS: key="balanced"
	last_key=key; last_sequence=sequence; onset_clock=clock
	var wav := Design.stream(key,sequence,next_muffled)
	var gain := 0.80 if kind=="finish" else (0.55 if kind=="blocked" else 0.68)
	if recording and recording_events.size()<512:
		recording_events.append({"time":clock,"key":key,"variant":posmod(sequence,3),"muffled":next_muffled,"gain":gain*volume})
	if volume<=0 or DisplayServer.get_name()=="headless": return
	var slot := cursor; cursor=(cursor+1)%VOICES
	var voice := voices[slot]; voice.stop(); voice.stream=wav; voice.global_position=at
	gain_records[slot]=gain
	voice.volume_db=linear_to_db(maxf(0.0001,volume*gain))-10.0
	voice.stream_paused=false; voice.play()

func refresh_preferences(value: float, paused: bool) -> void:
	volume=clampf(value,0,1); paused_state=paused
	for i in range(voices.size()):
		voices[i].stream_paused=paused
		if volume<=0: voices[i].stop()
		elif polished and gain_records[i]>=0: voices[i].volume_db=linear_to_db(maxf(0.0001,volume*gain_records[i]))-10.0

func reset() -> void:
	super.reset(); next_muffled=false
	for i in range(gain_records.size()): gain_records[i]=-1.0
