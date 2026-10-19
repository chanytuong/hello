extends "res://scripts/previews/m1a_v2_preview.gd"
## Isolated roll review; existing M1-A V2 driver and assets remain unmodified.
func _ready() -> void:
	super()
	case_label = "DODGE ROLL V2 / human review candidate"
	var wall := StaticBody2D.new()
	wall.position = Vector2(780, 360)
	var collider := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(2, 400)
	collider.shape = box
	wall.add_child(collider)
	add_child(wall)

func _physics_process(dt: float) -> void:
	super(dt)
	detail.text = "A/D move | Shift roll | Space jump | J/LMB existing M1-A V2 | R reset\nRoll %s / %.2fs | RUN and JUMP stay live during cooldown" % ["READY" if player.can_movement_roll() else "ACTIVE" if player.roll_remaining > 0 else "COOLDOWN",player.roll_cooldown_remaining]

func _draw() -> void:
	super()
	draw_line(Vector2(780,160),Vector2(780,560),Color("929d95"),2.0)
