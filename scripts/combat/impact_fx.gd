extends Node2D
## A bounded, tiny CPU-drawn pool. Coordinates are native world pixels.
var motes: Array[Dictionary] = []
var contacts := 0
var audio_events: Array[Dictionary] = []
var clock := 0.0
var banks: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0

func _ready() -> void:
	z_index = 9
	for key in ["whoosh_1","whoosh_2","whoosh_3","organic","metal","defeat","takedown","swap"]:
		var path: String = "res://art/iven/m1_crowbar/audio/"+key+".wav"
		if FileAccess.file_exists(path):
			var wav := AudioStreamWAV.new()
			var bytes := FileAccess.get_file_as_bytes(path)
			# These authored PCM files have a canonical 44-byte RIFF header.
			wav.format = AudioStreamWAV.FORMAT_16_BITS
			wav.mix_rate = 44100
			wav.stereo = false
			wav.data = bytes.slice(44)
			banks[key] = wav
	for i in 6:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -8
		add_child(voice)
		voices.append(voice)

func sound(key: String) -> void:
	if not banks.has(key): return
	var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = banks[key]
	voice.play()
	audio_events.append({"sound":key,"frame":Engine.get_physics_frames(),"clock":clock,"gain_db":-8})

func burst(pos: Vector2, direction: int, strike: int, metal: bool, defeated: bool) -> void:
	contacts += 1
	var total := 4+strike
	for i in total:
		var speed := Vector2(direction*(12+i*7),(-20+i*7))
		motes.append({"position":pos.round(),"velocity":speed,"life":0.065+0.009*i,"max":0.065+0.009*i,"color":Color("d5b378") if metal else Color("bd9279"),"size":2 if i == 0 else 1})
	while motes.size() > 40: motes.pop_front()
	sound("metal" if metal else "organic")
	if defeated: sound("defeat")

func _physics_process(dt: float) -> void:
	clock += dt
	for mote in motes:
		mote.life -= dt
		mote.position += mote.velocity*dt
		mote.velocity.y += 120*dt
	motes = motes.filter(func(m): return m.life > 0)
	queue_redraw()

func _draw() -> void:
	for mote in motes:
		var color: Color = mote.color
		color.a = minf(1,mote.life/0.04)
		draw_rect(Rect2(mote.position.round(),Vector2.ONE*mote.size),color)
