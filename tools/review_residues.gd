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
		["01-triagem", Vector2(740, 540), 0, Vector2(740, 515)],
		["02-baias", Vector2(463, 375), 0, Vector2(390, 288)],
		["03-prisma", Vector2(1130, 335), 1, Vector2(1168, 288)],
		["04-iris", Vector2(1060, 734), 2, Vector2(1180, 790)],
		["05-biodigestor", Vector2(1066, 876), 2, Vector2(1180, 815)],
		["10-patio", Vector2(610, 800), 1, Vector2(560, 780)],
	]
	for entry in views:
		game.stage = entry[2]
		game.cleared = [false, false, entry[0] == "05-biodigestor", entry[0] == "05-biodigestor"]
		for i in 3: game.terminal_on[i] = i < game.stage
		game.pos = entry[1] * game.M.SCALE
		assert(game.M.walkable(game.pos, 14.0, game.stage, game.cleared))
		game.camera = (entry[3] * game.M.SCALE).clamp(Vector2(480, 270), game.M.SIZE - Vector2(480, 270))
		game.pointer = Vector2(790, 450)
		game._guide_timer = 0.0
		game._update_guidance()
		game._light.position = game.M.SIZE * 0.5 + game._offset()
		game._light_material.set_shader_parameter("restored", float(game.stage))
		game._light_material.set_shader_parameter("ventilation", 2.0 if entry[0] == "05-biodigestor" else 0.0)
		game.queue_redraw()
		game._hud.queue_redraw()
		for frame in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(out + "/" + entry[0] + ".png") == OK)
	root.content_scale_size = Vector2i(game.M.SIZE)
	root.size = Vector2i(1536, 1024)
	game._hud.visible = false
	game.camera = game.M.SIZE * 0.5
	game._light.position = game.M.SIZE * 0.5
	game.queue_redraw()
	for frame in 5:
		await process_frame
		await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out + "/06-bairro-completo.png") == OK)
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	game._hud.visible = true
	game.state = "map"
	game._hud.queue_redraw()
	for frame in 5:
		await process_frame
		await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out + "/07-mapa-960.png") == OK)
	game.state = "play"
	game.stage = 0
	game.cleared = [false, false, false, false]
	game.terminal_on = [false, false, false]
	game.pos = Vector2(463, 375) * game.M.SCALE
	game.camera = Vector2(390, 288) * game.M.SCALE
	game._guide_timer = 0.0
	game._update_guidance()
	game._light.position = game.M.SIZE * 0.5 + game._offset()
	game._light_material.set_shader_parameter("restored", 0.0)
	game.queue_redraw()
	game._hud.queue_redraw()
	for frame in 5:
		await process_frame
		await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out + "/08-triagem-960.png") == OK)
	root.content_scale_size = Vector2i(game.M.SIZE)
	root.size = Vector2i(1536, 1024)
	game._hud.visible = false
	game.stage = 2
	game.collision_audit = true
	game.camera = game.M.SIZE * 0.5
	game._light.position = game.M.SIZE * 0.5
	game.queue_redraw()
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out + "/09-colisoes.png") == OK)
	print("RESIDUE_REVIEW_OK: ", views.size(), " gameplay views + overview + map + native 960")
	game.queue_free()
	for frame in 4: await process_frame
	await create_timer(0.12).timeout
	quit(0)
