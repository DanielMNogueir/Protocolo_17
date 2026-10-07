extends SceneTree
## Actual game frames at repeatable cameras; no concept-image backgrounds.
var game: Node2D
var output := "res://captures/solo-integrado"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for path in ["res://scripts/ground_ecology.gd","res://scripts/wetlands.gd","res://scripts/world.gd","res://scripts/main.gd"]:
		var script: GDScript = load(path)
		if script==null or not script.can_instantiate():
			push_error("Review aborted: invalid scene dependency "+path)
			quit(1)
			return
	if not OS.get_environment("P17_WETLAND_OUTPUT").is_empty():
		output = OS.get_environment("P17_WETLAND_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(1440, 810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.mode = "play"
	game.pointer = Vector2(-100, -100)
	var cases := [
		["01_cais_terminal", 0, Vector2(870,1190), Vector2(870,1190), false],
		["02_cais_canal", 0, Vector2(690,1355), Vector2(615,1400), false],
		["03_cais_combate", 0, Vector2(690,1310), Vector2(730,1370), true],
		["04_energia", 1, Vector2(1030,450), Vector2(825,335), false],
		["05_filtros", 2, Vector2(1970,450), Vector2(1920,360), false],
		["06_distribuicao", 3, Vector2(1920,1170), Vector2(1840,1230), false],
		["07_cais_restaurado", 1, Vector2(690,1355), Vector2(615,1400), false],
		["08_jardim_filtragem", 2, Vector2(1925,620), Vector2(1910,630), false],
		["09_drenagem_energia", 1, Vector2(770,730), Vector2(460,640), false],
		["10_comportas_distribuicao", 3, Vector2(2110,1430), Vector2(2130,1430), false],
		["11_captacao_leste", 0, Vector2(930,1240), Vector2(900,1190), false],
	]
	var performance_samples: Array[Dictionary] = []
	for entry in cases:
		game.sim.start(entry[1])
		if not entry[4]: game.sim.enemies.clear()
		game.sim.pos = entry[2]
		game.sim.tick(0.001,Vector2.ZERO,game.sim.pos+Vector2.UP,false,false,false)
		game.camera_pos = entry[3]
		game._clamp_camera()
		game.clock = 12.0
		game._update_energy_station(3)
		game.enemy_presentation.advance(0.01, game.sim.enemies, game.sim.stage, game.sim.elapsed)
		for warmup in range(12):
			game.queue_redraw()
			await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(output + "/" + entry[0] + ".png")
		if error != OK:
			push_error("Capture failed: " + entry[0])
			quit(1)
			return
		print("Captured ", entry[0])
		if entry[4]:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			var started := Time.get_ticks_usec()
			var calls := 0.0
			for frame in range(120):
				game.clock = 12.0 + frame / 60.0
				game.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			performance_samples.append({"view":entry[0], "frame_ms":float(Time.get_ticks_usec()-started)/120000.0, "draw_calls":calls/120.0})
	var summary := FileAccess.open(output + "/review.json", FileAccess.WRITE)
	summary.store_string(JSON.stringify({"captures":cases.size(),"renderer":RenderingServer.get_video_adapter_name(),"performance":performance_samples}, "\t"))
	summary.close()
	game.free()
	game = null
	for cleanup in range(5): await process_frame
	print("WETLAND_REVIEW_OK: %d rendered game views" % cases.size())
	quit(0)
