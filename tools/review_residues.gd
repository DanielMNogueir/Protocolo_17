extends SceneTree

var game: Node2D
var out := OS.get_environment("P17_RESIDUE_CAPTURE_DIR")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if out.is_empty(): out = "res://captures/residuos"
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(1440, 810)
	game = load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.toast_time = 0.0
	var views := [
		["01-triagem", Vector2(440, 760), 0],
		["02-baias", Vector2(520, 430), 0],
		["03-prisma", Vector2(1200, 650), 1],
		["04-iris", Vector2(1970, 750), 2],
		["05-biodigestor", Vector2(1970, 650), 2],
	]
	for entry in views:
		game.stage = entry[2]
		for i in 3: game.terminal_on[i] = i < game.stage
		game.pos = entry[1]
		assert(game.M.walkable(game.pos, 14.0, game.stage, game.cleared))
		game.camera = entry[1]
		game._light.position = game.M.SIZE * 0.5 + game._offset()
		game._light_material.set_shader_parameter("restored", float(game.stage))
		game.queue_redraw()
		game._hud.queue_redraw()
		for frame in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(out + "/" + entry[0] + ".png") == OK)
	print("RESIDUE_REVIEW_OK: ", views.size(), " views")
	game.queue_free()
	for frame in 4: await process_frame
	quit(0)
