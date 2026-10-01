extends SceneTree
## Captures the live proof of concept from the real game scene.

var game: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/energy_station_review")
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(1440, 810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock = 4.0
	game.pointer = Vector2(-100, -100)
	game.sim.start(1)
	game.sim.enemies.clear()
	game.sim.state = "activation"
	game.sim.pos = Vector2(1010, 470)
	game.mode = "play"
	game.camera_pos = Vector2(850, 370)
	game._clamp_camera()
	game.energy_station.set_online(false, false)
	await _capture("offline_front")
	game.sim.pos = Vector2(795, 300)
	await _capture("offline_occlusion")
	game.sim.restored = 2
	game.sim.stage = 2
	game.sim.state = "combat"
	game.energy_station.set_online(true, false)
	game.clock = 7.0
	game.sim.pos = Vector2(1010, 470)
	await _capture("online_front")
	game.queue_free()
	await process_frame
	print("ENERGY_STATION_REVIEW_OK: 3 captures")
	quit(0)


func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.runtime/energy_station_review/" + label + ".png"
	var result := root.get_texture().get_image().save_png(path)
	assert(result == OK, "capture failed: " + path)
	print("Captured ", path)
