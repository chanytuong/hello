extends Node
class_name NLBHealth
## Reusable hit-point container with invulnerability windows.
## Owned by a fighter; damaged only through NLBHurtBox.

signal changed(current: int, maximum: int)
signal died

@export var max_hp: int = 3
@export var iframes: float = 0.5

var hp: int = -1  # -1 = unprimed; primed lazily (see _ensure)
var _primed: bool = false

func _ready() -> void:
	_ensure()

func _ensure() -> void:
	if _primed:
		return
	_primed = true
	hp = max_hp

func _process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)

var _invuln: float = 0.0

## Returns true if damage was applied.
func damage(amount: int) -> bool:
	_ensure()
	if _invuln > 0.0 or hp <= 0:
		return false
	hp = maxi(hp - amount, 0)
	if hp <= 0:
		died.emit()
	else:
		_invuln = iframes
		changed.emit(hp, max_hp)
	return true

func grant_iframes(t: float) -> void:
	_invuln = maxf(_invuln, t)

func reset() -> void:
	_primed = true
	hp = max_hp
	_invuln = 0.0
	changed.emit(hp, max_hp)
