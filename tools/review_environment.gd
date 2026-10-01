extends SceneTree
## Focused render review for water, bridges, props and PNG integration.

var game: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/environment_review")
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(1440, 810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock = 7.0
	game.pointer = Vector2(-100, -100)
	game.mode = "play"
	game.sim.enemies.clear()
	var reviews := [
		["vertical_bridge", 0, Vector2(770, 925)],
		["horizontal_bridge", 1, Vector2(1280, 610)],
		["industrial_props", 0, Vector2(300, 1500)],
		["solar_props", 1, Vector2(460, 550)],
		["structure_edges", 1, Vector2(1755, 320)],
	]
	for review in reviews:
		game.sim.start(review[1])
		game.sim.enemies.clear()
		game.sim.pos = review[2]
		game.camera_pos = review[2]
		game._clamp_camera()
		await _capture(review[0])
	game.queue_free()
	await process_frame
	print("ENVIRONMENT_REVIEW_OK: 5 captures")
	quit(0)


func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.runtime/environment_review/" + label + ".png"
	assert(root.get_texture().get_image().save_png(path) == OK, "capture failed: " + path)
	print("Captured ", path)
