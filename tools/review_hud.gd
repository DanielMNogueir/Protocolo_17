extends SceneTree
var out := OS.get_environment("P17_HUD_OUTPUT")
var game: Node2D
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	game.queue_redraw()
	if "_hud" in game: game._hud.queue_redraw()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out.path_join(label + ".png")) == OK)
func verify_hud_clicks() -> void:
	for action in ["map", "pause"]:
		var candidates: Array = game.buttons.filter(func(button): return button.id == action)
		assert(candidates.size() == 1, "HUD action appears exactly once: " + action)
		var button: Dictionary = candidates[0]
		assert(Rect2(Vector2.ZERO, game._size()).encloses(button.rect), "HUD button fits viewport")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = button.rect.get_center()
		game._unhandled_input(click)
		assert(game.mode == action, "HUD click opens " + action)
		game._action("resume")
		assert(game.mode == "play", "HUD action resumes gameplay")
	game.ui_mouse_held = false

func run() -> void:
	if out.is_empty(): out = ProjectSettings.globalize_path("user://hud-review")
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(960,540)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.mode = "play"
	game.dialogue = []
	game.toast_time = 0
	game.sim.start()
	game.camera_pos = game.sim.pos
	await capture("01-aguas-960")
	verify_hud_clicks()
	game.sim.hp = 1
	game.sim.secondary_cd = 2.1
	game.sim.dash_cd = 0.6
	await capture("02-integridade-critica")
	game.sim.max_hp = 14
	game.sim.hp = 14
	await capture("12-integridade-maxima")
	for stage in 4:
		game.sim.start(stage)
		game.sim.enemies.clear()
		game.sim.state = "activation"
		game.sim.pos = game.sim.operation.target()
		game.camera_pos = game.sim.pos
		await capture("03-tarefa-%d" % stage)
		game.sim.start(2)
	game.sim.enemies.clear()
	game.sim.state = "activation"
	game.sim.operation.completed = 1
	game.sim.pos = game.sim.operation.target()
	game.camera_pos = game.sim.pos
	await capture("08-analise")
	game.sim.operation.completed = 2
	game.sim.pos = game.World.GOALS[2]
	game.camera_pos = game.sim.pos
	await capture("09-terminal")
	game.sim.start(3)
	game.sim.operation.completed = 2
	game.sim.enemies.clear()
	game.sim.wave = 2
	game.sim._spawn_reinforcements()
	for enemy in game.sim.enemies:
		if enemy.kind == "boss":
			game.sim.pos = enemy.pos + Vector2(0, 150)
	game.camera_pos = game.sim.pos
	await capture("10-chefe")
	root.size = Vector2i(1440,810)
	await capture("04-aguas-1440")
	verify_hud_clicks()
	game.free()
	root.size = Vector2i(960,540)
	game = load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.toast_time = 0
	for stage in 4:
		game.stage = stage
		for i in 3: game.terminal_on[i] = i < stage
		await capture("05-residuos-%d" % stage)
	game.stage = 0
	game.pos = game.M.ITEMS[0]
	game.camera = game.pos
	await capture("11-interacao-residuos")
	game.hp = 1
	game.secondary_cd = 2
	game.dash_cd = 0.4
	await capture("06-residuos-critica")
	root.size = Vector2i(1440,810)
	await capture("07-residuos-1440")
	game.free()
	for frame in 5: await process_frame
	print("HUD_REVIEW_OK: 18 rendered scenarios; map/pause mouse actions verified at both resolutions")
	quit()