extends Node2D
## A bounded, tiny CPU-drawn hit-juice pool. Coordinates are native world pixels.
## Six layers share one contact event: sparks/blood, a floating damage number,
## layered impact audio, and the caller's hitstop/shake/flash/knockback.
var motes: Array[Dictionary] = []
var blood: Array[Dictionary] = []
var numbers: Array[Dictionary] = []
var contacts := 0
var audio_events: Array[Dictionary] = []
var clock := 0.0
var banks: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
const BLOOD_COLORS: Array[Color] = [
	Color("8f1f1f"), Color("b52a2a"), Color("d13b32"), Color("6e1717")
]

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
	# A second, sharper layer: the short authored hit transients. Loaded through
	# the resource system because these files ship with .import metadata.
	for i in 3:
		var key := "hit_%d" % (i+1)
		var path := "res://art/iven/m1_combo/%s.wav" % key
		if ResourceLoader.exists(path):
			banks[key] = load(path)
	for i in 6:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -8
		add_child(voice)
		voices.append(voice)

func sound(key: String, gain_db: float = -8.0) -> void:
	if not banks.has(key):
		return
	var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = banks[key]
	voice.volume_db = gain_db
	# Tiny deterministic pitch variation keeps repeated hits from sounding canned.
	voice.pitch_scale = 0.96 + 0.02 * float(voice_index % 4)
	voice.play()
	audio_events.append({"sound":key,"frame":Engine.get_physics_frames(),"clock":clock,"gain_db":gain_db,"pitch":voice.pitch_scale})
	if audio_events.size() > 64:
		audio_events.pop_front()

func burst(pos: Vector2, direction: int, strike: int, metal: bool, defeated: bool, damage: int = 1) -> void:
	contacts += 1
	var total := 4+strike
	for i in total:
		var speed := Vector2(direction*(12+i*7),(-20+i*7))
		motes.append({"position":pos.round(),"velocity":speed,"life":0.065+0.009*i,"max":0.065+0.009*i,"color":Color("d5b378") if metal else Color("bd9279"),"size":2 if i == 0 else 1})
	while motes.size() > 40: motes.pop_front()
	if metal:
		# Armored targets throw a wider gold spark fan instead of blood.
		for i in 5:
			var t := float(i)/4.0
			motes.append({"position":pos.round(),"velocity":Vector2(direction*lerpf(70.0,220.0,t),lerpf(-150.0,-40.0,t)),"life":0.14+0.02*i,"max":0.14+0.02*i,"color":Color("f2d27a"),"size":2})
	else:
		_spawn_blood(pos,direction,strike)
	number(pos,damage,strike)
	sound("hit_%d" % clampi(strike,1,3), -4.0)
	sound("metal" if metal else "organic", -7.0)
	if defeated:
		sound("defeat", -5.0)

func _spawn_blood(pos: Vector2, direction: int, strike: int) -> void:
	var total := mini(10,5+strike*2)
	for i in total:
		var t := float(i)/float(maxi(1,total-1))
		var vx := float(direction)*lerpf(35.0,190.0,t) + (12.0 if i%2 == 0 else -12.0)
		var vy := lerpf(-190.0,-45.0,t) + float(i%3)*8.0
		var life := 0.30+0.03*float(i%4)
		blood.append({
			"position":pos.round()+Vector2(0,-4),
			"velocity":Vector2(vx,vy),
			"life":life,
			"max":life,
			"color":BLOOD_COLORS[i%BLOOD_COLORS.size()],
			"size":2 if i%3 == 0 else 1,
		})
	while blood.size() > 80: blood.pop_front()

func number(pos: Vector2, amount: int, strike: int) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("fff4cf") if strike < 3 else Color("ffd36b"))
	label.add_theme_color_override("font_outline_color", Color("2a1412"))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(36,18)
	label.pivot_offset = label.size*0.5
	label.position = pos.round()+Vector2(-18,-36)
	label.z_index = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	numbers.append({"label":label,"life":0.55,"max":0.55,"velocity":Vector2(0,-34.0)})

func _physics_process(dt: float) -> void:
	clock += dt
	for mote in motes:
		mote.life -= dt
		mote.position += mote.velocity*dt
		mote.velocity.y += 120*dt
	motes = motes.filter(func(m): return m.life > 0)
	for drop in blood:
		drop.life -= dt
		drop.position += drop.velocity*dt
		drop.velocity.y += 700*dt
	blood = blood.filter(func(b): return b.life > 0)
	queue_redraw()

func _process(dt: float) -> void:
	for i in range(numbers.size()-1,-1,-1):
		var n: Dictionary = numbers[i]
		n.life -= dt
		var label: Label = n.label
		if is_instance_valid(label):
			var age: float = float(n.max)-float(n.life)
			label.position.y += float(n.velocity.y)*dt
			var pop: float = 1.0+0.35*clampf(1.0-age/0.08,0.0,1.0)
			label.scale = Vector2(pop,pop)
			label.modulate.a = clampf(float(n.life)/0.25,0.0,1.0)
		if n.life <= 0.0:
			if is_instance_valid(label): label.queue_free()
			numbers.remove_at(i)

func _draw() -> void:
	for mote in motes:
		var color: Color = mote.color
		color.a = minf(1,mote.life/0.04)
		draw_rect(Rect2(mote.position.round(),Vector2.ONE*mote.size),color)
	for drop in blood:
		var color: Color = drop.color
		color.a = minf(1,drop.life/0.08)
		var size := int(drop.size)
		draw_rect(Rect2(drop.position.round(),Vector2(size,size)),color)
