extends SceneTree
## Identical framing for baseline/new water, actual frames and uncapped timings.
const W=preload("res://scripts/world.gd")
var game: Node2D
var output:="res://.runtime/water_review"
var stats: Array[Dictionary]=[]
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if not OS.get_environment("P17_WATER_OUTPUT").is_empty(): output=OS.get_environment("P17_WATER_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(1440,810)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	# Muting keeps the music stream running; this visual review needs no playback.
	for player in game.sound.get_children():
		if player is AudioStreamPlayer: player.stop()
	game.mode="play"
	game.pointer=Vector2(-100,-100)
	var cases: Array=[
		["01_ponte_vertical",1,Vector2(770,925),Vector2(770,925)],
		["02_canal_vertical",2,Vector2(1280,610),Vector2(1280,450)],
		["03_ponte_horizontal",2,Vector2(1280,610),Vector2(1280,610)],
		["04_encontro_canais",3,Vector2(770,925),Vector2(1280,925)],
		["05_pier_margem",0,Vector2(440,1740),Vector2(490,1540)],
		["06_distribuicao_reservatorio",3,Vector2(1920,1170),Vector2(1880,1240)],
	]
	for c in cases:
		game.sim.start(c[1])
		game.sim.enemies.clear()
		game.sim.pos=c[2]
		game.sim.velocity=Vector2.ZERO
		game.camera_pos=c[3]
		game._clamp_camera()
		game.clock=12
		game._update_energy_station(3)
		for frame in range(40):
			game.queue_redraw()
			await process_frame
		await _capture(c[0])
	# Three representative views: same draw, same machine, same settings, no vsync cap.
	for index in [0,2,3]:
		var c: Array=cases[index]
		game.camera_pos=c[3]
		game._clamp_camera()
		for warmup in range(60):
			game.queue_redraw()
			await process_frame
		var frames:=240
		var draw_sum:=0.0
		var start:=Time.get_ticks_usec()
		for frame in range(frames):
			game.clock=12+frame/60.0
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			draw_sum+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var ms:=float(Time.get_ticks_usec()-start)/1000.0/frames
		stats.append({"view":c[0],"frame_ms":ms,"fps":1000.0/ms,"draw_calls":draw_sum/frames})
	var water=game.get("water_surface")
	var summary: Dictionary={"views":stats,"renderer":RenderingServer.get_video_adapter_name(),"size":[root.size.x,root.size.y]}
	if water!=null: summary["field_setup_ms"]=water.setup_usec/1000.0
	var f:=FileAccess.open(output+"/performance.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(summary,"\t"))
	f.close()
	# Deterministic six-second sequence, exportable as an animated preview.
	if OS.get_environment("P17_WATER_ANIMATION")=="1":
		DirAccess.make_dir_recursive_absolute(output+"/frames")
		game.sim.start(3)
		game.sim.enemies.clear()
		game.sim.pos=Vector2(770,925)
		game.camera_pos=Vector2(770,925)
		for frame in range(60):
			game.clock=12+frame*0.1
			await _capture("frames/%03d"%frame)
	print("WATER_REVIEW_OK: 6 views, 720 benchmark frames", "; animation 60 frames" if OS.get_environment("P17_WATER_ANIMATION")=="1" else "")
	print(JSON.stringify(summary))
	game.free()
	game=null
	water=null
	for cleanup in range(5): await process_frame
	quit(0)
func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error:=root.get_texture().get_image().save_png(output+"/"+label+".png")
	if error!=OK: push_error("Cannot save water capture "+label); quit(1)
