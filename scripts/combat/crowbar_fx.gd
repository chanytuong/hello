extends "res://scripts/combat/impact_fx.gd"
## Crowbar-specific contact punctuation: a short, opaque cross at the exact
## weapon/body intersection. Blood, damage numbers, and sound live in the shared
## impact pool so every crowbar strike gets the same six-layer hit package.
var marks: Array = []

func burst(pos: Vector2, direction: int, strike: int, metal: bool, defeated: bool, damage: int = 1) -> void:
	super.burst(pos,direction,strike,metal,defeated,damage)
	marks.append({"pos":pos.round(),"direction":direction,"strike":strike,"life":.055,"metal":metal})
	while marks.size() > 8: marks.pop_front()

func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	for mark in marks: mark.life -= dt
	marks = marks.filter(func(m): return m.life > 0)

func _draw() -> void:
	super._draw()
	for mark in marks:
		var p: Vector2 = mark.pos
		var color := Color("f2d27a") if mark.metal else Color("ff6a57")
		var scale := 1.0 if mark.life > .025 else .6
		var vertical := 7.0 if mark.strike == 2 else 5.0
		var horizontal := 6.0 if mark.strike != 2 else 4.0
		var points := PackedVector2Array([p+Vector2(-horizontal,0)*scale,p+Vector2(-1,-1)*scale,p+Vector2(0,-vertical)*scale,p+Vector2(1,-1)*scale,p+Vector2(horizontal,0)*scale,p+Vector2(1,1)*scale,p+Vector2(0,vertical)*scale,p+Vector2(-1,1)*scale])
		for i in points.size(): points[i] = points[i].round()
		draw_colored_polygon(points,color)
		draw_rect(Rect2(p-Vector2.ONE,Vector2(2,2)),Color.WHITE)
