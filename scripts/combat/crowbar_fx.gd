extends "res://scripts/combat/impact_fx.gd"
var marks: Array = []

func burst(pos: Vector2, direction: int, strike: int, metal: bool, defeated: bool) -> void:
	super.burst(pos,direction,strike,metal,defeated)
	marks.append({"pos":pos.round(),"direction":direction,"strike":strike,"life":.050,"metal":metal})
	while marks.size() > 8: marks.pop_front()

func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	for mark in marks: mark.life -= dt
	marks = marks.filter(func(m): return m.life > 0)

func _draw() -> void:
	super._draw()
	for mark in marks:
		var p: Vector2 = mark.pos
		var color := Color("ecce94") if mark.metal else Color("dcb199")
		var scale := 1.0 if mark.life > .025 else .6
		var vertical := 6.0 if mark.strike == 2 else 4.0
		var horizontal := 5.0 if mark.strike != 2 else 3.0
		var points := PackedVector2Array([p+Vector2(-horizontal,0)*scale,p+Vector2(-1,-1)*scale,p+Vector2(0,-vertical)*scale,p+Vector2(1,-1)*scale,p+Vector2(horizontal,0)*scale,p+Vector2(1,1)*scale,p+Vector2(0,vertical)*scale,p+Vector2(-1,1)*scale])
		for i in points.size(): points[i] = points[i].round()
		draw_colored_polygon(points,color)
		draw_rect(Rect2(p-Vector2.ONE,Vector2(2,2)),Color("f3e9c5"))
