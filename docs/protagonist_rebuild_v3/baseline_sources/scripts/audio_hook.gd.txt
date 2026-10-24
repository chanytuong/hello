extends RefCounted
class_name NLBAudio
## Sound-hook placeholder. All call sites are wired; this is intentionally a
## no-op until real audio lands. Drop-in contract: NLBAudio.play(&"hit").
static func play(_sfx: StringName) -> void:
	pass
