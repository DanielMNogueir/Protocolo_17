extends SceneTree
## Same camera and real scene for baseline and new objectives.
var game: Node2D
var output := "res://captures/objetivos"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not OS.get_environment("P17_OBJECTIVE_OUTPUT").is_empty():
		output = OS.get_environment("P17_OBJECTIVE_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(1440,810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.pointer = Vector2(-100,-100)
	for sector in range(4):
		for state in ["avariado","disponivel","reparando","restaurado"]:
			game.sim.start(sector)
			game.sim.pos = game.World.GOALS[sector]
			game.sim.aim = Vector2.UP
			if state != "avariado":
				game.sim.enemies.clear()
				game.sim.tick(0.001,Vector2.ZERO,game.sim.pos+Vector2.UP,false,false,false)
			if state == "reparando": game.sim.repair = 0.62
			if state == "restaurado": game.sim._activate()
			game.mode = "play"
			game.clock = 12.0
			game.camera_pos = game.sim.pos+Vector2(-45,-65)
			game._clamp_camera()
			game._update_energy_station(3.0)
			game.enemy_presentation.reset()
			for warmup in range(12):
				game.queue_redraw()
				await process_frame
			await RenderingServer.frame_post_draw
			var path := output+"/%02d_%s.png" % [sector+1,state]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Capture failed: "+path)
				quit(1)
				return
			print("Captured ",sector+1," / ",state)
	game.free()
	game = null
	for cleanup in range(5): await process_frame
	print("OBJECTIVE_REVIEW_OK: 16 real game frames")
	quit(0)
