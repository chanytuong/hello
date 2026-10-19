extends "res://tests/test_roll_visual_transitions.gd"
## Same real-scene input replay for a preserved baseline and the V2 candidate.
func out_dir() -> String:
	return "res://artifacts/dodge_roll_v2/" + stage + "/"

func verify_results() -> void:
	check(rows.all(func(r): return r.anchor_error <= 0.708), "displayed neck attachment remains within pixel rounding")
	check(rows.all(func(r): return absf(r.visual_offset[0]) <= 0.501 and absf(r.visual_offset[1]) <= 0.501), "no duplicated presentation travel")
	check(rows.all(func(r): return r.clip.ends_with("right" if r.facing > 0 else "left")), "facing follows current input")
	for event in events:
		var row: Dictionary = rows[event.index]
		if event.kind in ["roll_entry", "air_entry"]:
			check(row.roll > 0.0 and absf(row.velocity[0]) > 333.0, event.case + ": immediate movement")
		elif event.kind == "cancel":
			check(row.roll == 0.0 and row.state != "DODGE_ROLL", event.case + ": immediate logical cancel")
		elif event.kind == "repeat":
			check(row.roll <= rows[event.index-1].roll, event.case + ": repeated press cannot extend roll")
		elif event.kind == "natural_exit":
			check(row.state == "RUN" and row.velocity[0]*row.facing == player.run_speed, event.case + ": no movement recovery lock")
