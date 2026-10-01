extends SceneTree
## Render the four live districts and one restored totem without touching saves.
var game: Node2D
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/station_review")
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(1440,810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.clock = 4.0
	game.pointer = Vector2(-100,-100)
	var positions := [Vector2(755,1310),Vector2(830,420),Vector2(2150,580),Vector2(2110,1430)]
	for stage in range(4):
		game.sim.start(stage)
		game.sim.pos = positions[stage]
		game.mode = "play"
		game.camera_pos = game.sim.pos
		game._clamp_camera()
		game.enemy_presentation.advance(0.016,game.sim.enemies,game.sim.stage,game.sim.elapsed)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://.runtime/station_review/sector_%d.png" % (stage+1)
		var result := root.get_texture().get_image().save_png(path)
		assert(result == OK,"capture failed: " + path)
		print("Captured ",path)
	game.sim.start(0)
	game.sim.restored = 1
	game.sim.pos = Vector2(925,1180)
	game.mode = "play"
	game.camera_pos = Vector2(870,1190)
	game._clamp_camera()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var active_path := "res://.runtime/station_review/active_totem.png"
	assert(root.get_texture().get_image().save_png(active_path) == OK,"capture failed: " + active_path)
	print("Captured ",active_path)
	game.queue_free()
	await process_frame
	quit()
