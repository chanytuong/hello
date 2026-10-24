extends SceneTree
## Phase B audit of the unchanged project. No production asset or gameplay edits.
const OUTPUT := "res://docs/protagonist_rebuild_v3/baseline_runtime/"
var _main: Node
var _records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_audit")

func _frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var p: NLBPlayer = _main.get_node("Player")
	var cam: Camera2D = _main.get_node("Camera2D")
	var record: Dictionary = {
		"label": label, "engine": Engine.get_version_info(),
		"window_size": [root.size.x, root.size.y],
		"player_position": [p.position.x, p.position.y],
		"velocity": [p.velocity.x, p.velocity.y], "on_floor": p.is_on_floor(),
		"facing": p.facing, "move_state": p.move_state, "attack_clock": p._atk_t,
		"hurt_clock": p._hurt_t, "hp": p.health.hp, "frozen": p.fight_frozen,
		"frame": p._frame_shown, "texture": p.sprite.texture.resource_path,
		"sprite_offset": [p.sprite.offset.x, p.sprite.offset.y],
		"sprite_scale": [p.sprite.scale.x, p.sprite.scale.y],
		"sprite_rotation": p.sprite.rotation,
		"texture_size": [p.sprite.texture.get_width(), p.sprite.texture.get_height()],
		"texture_filter": p.sprite.texture_filter,
		"camera_zoom": [cam.zoom.x, cam.zoom.y],
		"camera_position": [cam.position.x, cam.position.y],
		"canvas_transform": str(root.get_canvas_transform()),
		"body_visible": p.body_vis.visible,
		"base_cache": p._frame_cache.size(), "a2_cache": p._frame_cache_a2.size()
	}
	var err := root.get_texture().get_image().save_png(OUTPUT + label + ".png")
	record["capture_error"] = err
	_records.append(record)
	print("BASELINE " + JSON.stringify(record))

func _audit() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main
	await _frames(30)
	await _capture("01_idle")
	Input.action_press("move_right")
	await _frames(12)
	await _capture("02_run")
	Input.action_release("move_right")
	Input.action_press("jump")
	await _frames(8)
	await _capture("03_jump_rise")
	Input.action_release("jump")
	await _frames(17)
	await _capture("04_fall")
	await _frames(28)
	Input.action_press("dash")
	await _frames(3)
	await _capture("05_dash")
	Input.action_release("dash")
	await _frames(16)
	Input.action_press("attack")
	await _frames(5)
	await _capture("06_attack_active")
	Input.action_release("attack")
	await _frames(20)
	Input.action_press("blink")
	await _frames(3)
	await _capture("07_blink_transition")
	Input.action_release("blink")
	await _frames(24)
	await _capture("08_blink_arrival")
	var f := FileAccess.open(OUTPUT + "observations.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_records, "\t"))
	f.close()
	print("BASELINE_AUDIT_COMPLETE captures=" + str(_records.size()))
	quit(0)
