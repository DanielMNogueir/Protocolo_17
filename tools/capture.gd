extends SceneTree
## Deterministic visual review only. Gameplay validation is in tests/.
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock = 4.0
	game.pointer = Vector2(-100, -100)
	game.has_save = false
	await _capture("01_title")
	game.mode = "briefing"
	game.briefing_page = 2
	game.briefing_clock = 10
	await _capture("02_story")
	game.sim.start()
	game.sim.pos = Vector2(730, 1375)
	game.mode = "play"
	game.camera_pos = game.sim.pos
	game._clamp_camera()
	await _capture("03_intake")
	game.mode = "map"
	await _capture("04_map")
	game.mode = "upgrade"
	game.sim.state = "upgrade"
	game.sim.restored = 1
	await _capture("05_upgrades")
	game.sim.start(1)
	game.sim.pos = Vector2(760, 465)
	game.camera_pos = game.sim.pos
	game._clamp_camera()
	game.mode = "play"
	await _capture("06_energy")
	game.sim.start(3)
	game.sim.pos = Vector2(2005, 1220)
	game.camera_pos = game.sim.pos
	game._clamp_camera()
	for enemy in game.sim.enemies:
		if enemy.kind == "boss":
			enemy.warning = 0.7
			enemy.aim = (game.sim.pos - enemy.pos).normalized()
	await _capture("07_boss")
	game.mode = "victory"
	game.sim.state = "victory"
	game.sim.restored = 4
	game.sim.kills = 17
	game.sim.elapsed = 533
	await _capture("08_ending")
	game.queue_free()
	await process_frame
	print("CAPTURES PASS: 8 rendered screens")
	quit(0)

func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://captures/" + label + ".png")
	if result != OK:
		push_error("Capture failed: " + label)
		quit(1)
	print("Captured ", label)
