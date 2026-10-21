extends SceneTree
var failed := false
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if not FileAccess.file_exists("res://project.binary"):
		push_error("Smoke test must run against exported PCK")
		quit(1)
		return
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(960,540)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game._action("new")
	failed = game.mode!="difficulty"
	game._action("difficulty_operation")
	game._action("intro_skip")
	failed = failed or game.mode!="play" or game.sim.difficulty!="operation"
	game.sim.tick(0.05,Vector2.ZERO,game.sim.pos+Vector2.RIGHT*200,true,false,false)
	failed = failed or game.sim.shots!=1 or not game.has_save
	game.camera_pos=game.sim.pos
	for frame in 5:
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("P17_PACKAGE_CAPTURE")
	if not path.is_empty(): failed = failed or root.get_texture().get_image().save_png(path)!=OK
	game._action("pause")
	failed = failed or game.mode!="pause"
	game._action("resume")
	game._action("title")
	game._action("continue")
	failed = failed or game.mode!="play" or game.sim.stage!=0
	game.free()
	game=null
	for frame in 5: await process_frame
	print("BETA_PACKAGE_%s: exported resources, difficulty, prologue skip, combat, disk save, pause, title, continue and rendering" % ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
