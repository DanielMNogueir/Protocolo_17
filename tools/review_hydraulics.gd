extends SceneTree
## Actual district frames and a deterministic close-up of the clarifier animation.
const Props = preload("res://scripts/environment_props.gd")
const Objectives = preload("res://scripts/objective_visual.gd")
var output := "res://captures/agua-viva"
var game: Node2D

class Closeup extends Node2D:
	var time := 0.0
	var prop: Dictionary
	var objective := -1
	func _draw() -> void:
		draw_rect(Rect2(0,0,360,330),Color("102d36"))
		if objective>=0:
			Objectives.draw_foundation(self,Vector2(270,290),objective,true,time)
			Objectives.draw_body(self,Vector2(270,290),objective,true,time)
		else:
			Props.draw_foundation(self,prop)
			Props.draw(self,prop,time,true)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not OS.get_environment("P17_HYDRAULIC_OUTPUT").is_empty(): output = OS.get_environment("P17_HYDRAULIC_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output+"/frames")
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(1440,810)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.mode = "play"
	game.pointer = Vector2(-100,-100)
	var centers: Array[Vector2] = [Vector2(500,1320),Vector2(630,440),Vector2(1900,570),Vector2(1800,1400)]
	var player_positions: Array[Vector2] = [Vector2(690,1480),Vector2(770,610),Vector2(2110,610),Vector2(2040,1540)]
	for sector in range(4):
		for online in [false,true]:
			game.sim.start(sector)
			game.sim.enemies.clear()
			game.sim.restored = sector+1 if online else sector
			game.sim.pos = player_positions[sector]
			game.sim.aim = Vector2.UP
			game.camera_pos = centers[sector]
			game._clamp_camera()
			game.clock = 12.0
			game._update_energy_station(3.0)
			for warmup in range(12):
				game.queue_redraw()
				await process_frame
			await _capture("%02d_%s" % [sector+1,"ativo" if online else "avariado"])
	game.free()
	game = null
	root.content_scale_size = Vector2i(360,330)
	root.size = Vector2i(720,660)
	var closeup := Closeup.new()
	closeup.prop = Props.create("clarifier",Vector2(180,310),330)
	root.add_child(closeup)
	for frame in range(24):
		closeup.time = 12+frame/12.0
		closeup.queue_redraw()
		await _capture("frames/%03d" % frame)
	for index in [0,2,3]:
		closeup.objective = index
		closeup.time = 12.0
		closeup.queue_redraw()
		await _capture("objetivo_%02d" % [index+1])
	closeup.free()
	for cleanup in range(5): await process_frame
	print("HYDRAULIC_REVIEW_OK: 8 district views, 24 animation frames")
	quit(0)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output+"/"+label+".png") != OK:
		push_error("Cannot capture "+label)
		quit(1)
