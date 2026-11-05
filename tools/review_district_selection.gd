extends SceneTree
var game: Node2D
var out := OS.get_environment("P17_SELECTION_OUTPUT")
var captures := 0
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	game.queue_redraw()
	if "_hud" in game: game._hud.queue_redraw()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	var viewport := Rect2(Vector2.ZERO, game.get_viewport_rect().size)
	for button in game.buttons: assert(viewport.encloses(button.rect), "Control inside viewport: " + button.id)
	assert(root.get_texture().get_image().save_png(out.path_join(label + ".png")) == OK)
	captures += 1
func click(id: String) -> void:
	var found: Array = game.buttons.filter(func(button): return button.id == id)
	assert(found.size() == 1, "Exactly one clickable control: " + id)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = found[0].rect.get_center()
	game._unhandled_input(event)
func run() -> void:
	if out.is_empty(): out = "user://selection-review"
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.sound.set_muted(true)
	game.campaign.water_completed = false
	game._action("new")
	await capture("01-distritos-bloqueado-960")
	assert(game.buttons.filter(func(button): return button.id == "district_residues").is_empty())
	game.sim.load_data({"version": 2, "stage": 3, "difficulty": "operation", "chosen": ["reserve_cell", "induction_coil", "water_stride"]})
	game.sim.state = "victory"
	game._state_changed()
	game._action("districts")
	await capture("02-distritos-desbloqueado-960")
	root.size = Vector2i(1440, 810)
	await capture("03-distritos-desbloqueado-1440")
	click("district_residues")
	await capture("04-dificuldade-residuos")
	click("difficulty_operation")
	for frame in 5: await process_frame
	game = current_scene
	assert(game.scene_file_path == "res://scenes/residues.tscn")
	game.set_physics_process(false)
	game.sound.set_muted(true)
	game.stage = 2
	game.toast_time = 0
	game.pos = Vector2(1066, 876) * game.M.SCALE
	game.camera = Vector2(1180, 815) * game.M.SCALE
	game.enemies.back().hp = 40
	game.enemies[5].hp = 6
	game.queue_redraw()
	await capture("05-residuos-vida-real")
	click("map")
	assert(game.state == "map", "HUD map works in Residues")
	game._action("resume")
	await capture("06-retorno-mapa")
	click("pause")
	assert(game.state == "pause", "HUD pause works in Residues")
	await capture("07-pausa-residuos")
	click("districts")
	for frame in 5: await process_frame
	game = current_scene
	game.set_process(false)
	game.sound.set_muted(true)
	assert(game.mode == "districts" and game.campaign.water_completed, "Return to the selector keeps saved access")
	await capture("08-retorno-selecao")
	print("DISTRICT_SELECTION_REVIEW_OK: ", captures, " captures; locked/unlocked, mouse navigation, actual scene transition and return verified")
	quit()
