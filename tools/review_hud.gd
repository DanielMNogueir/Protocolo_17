extends SceneTree
var out := OS.get_environment("P17_HUD_OUTPUT")
var game: Node2D
var view_filter := OS.get_environment("P17_GUIDE_SCENE")
var large_text := OS.get_environment("P17_GUIDE_TEXT_125") == "1"
const FieldHUD = preload("res://scripts/field_hud.gd")
var captures := 0
var guide_failures := 0
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	if game.has_method("_update_objective_guides"): game._update_objective_guides(0.0)
	elif game.has_method("_update_objective_guide"): game._update_objective_guide(0.0)
	elif game.has_method("_present"): game._present(0.0)
	game.queue_redraw()
	if "_fx" in game: game._fx.queue_redraw()
	if "_hud" in game: game._hud.queue_redraw()
	for frame in 5: await process_frame
	RenderingServer.force_draw(true)
	assert(root.get_texture().get_image().save_png(out.path_join(label + ".png")) == OK)
	captures += 1
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
	if DisplayServer.get_name() == "headless":
		push_error("HUD review requires a rendering driver")
		quit(1)
		return
	if out.is_empty(): out = "res://captures/ui"
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(960,540)
	if not view_filter.is_empty():
		await _guide_views()
		_finish()
		return
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
	game._finish_dialogue()
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
	await _guide_views()
	_finish()


func _finish() -> void:
	print("HUD_REVIEW_%s: %d rendered scenarios" % ["OK" if guide_failures == 0 else "FAILED", captures])
	quit(0 if guide_failures == 0 else 1)

func _guide_views() -> void:
	for pair in [["main", "agua"], ["main", "prologo"], ["residues", "residuos"], ["power", "energia"], ["core", "nucleo"]]:
		if not view_filter.is_empty() and view_filter != pair[1]: continue
		game = load("res://scenes/%s.tscn" % pair[0]).instantiate()
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.sound.set_muted(true)
		if large_text: FieldHUD.text_scale_percent = 125
		for resolution in [Vector2i(960, 540), Vector2i(1440, 810)]:
			root.size = resolution
			await process_frame
			for on_screen in [true, false]:
				_configure_guide_view(pair[1], on_screen)
				var label := "%s-%dx%d-%s" % [pair[1], resolution.x, resolution.y, "visivel" if on_screen else "fora-da-tela"]
				if large_text: label += "-texto-125"
				await capture(label)
				var guides: Dictionary = {"agua": "water_guide", "prologo": "prologue_guide", "nucleo": "guide"}
				var guide: RefCounted = game.get(guides.get(pair[1], "objective_guide"))
				if guide.mode != ("arrow" if on_screen else "edge"):
					guide_failures += 1
					push_error("%s uses expected guide mode (got %s)" % [label, guide.mode])
		game.queue_free()
		await process_frame


func _configure_guide_view(scene: String, on_screen: bool) -> void:
	match scene:
		"agua":
			game.mode = "play"
			game.sim.start()
			game.sim.enemies.clear()
			game.sim.state = "activation"
			game.dialogue.clear()
			var target: Vector2 = game.WaterGuidance.objective(game.sim)
			game.sim.pos = target + Vector2(0, 130 if on_screen else 345)
			game.camera_pos = game.sim.pos
			game.guidance.update(game.sim, 1.0)
		"prologo":
			game._start_prologue(true)
			game.prologue.phase = "lab"
			game.prologue.step = 6
			var target: Vector2 = game.prologue.TARGETS[6]
			var candidate := target + Vector2(-102, 0)
			if not on_screen:
				var max_x := int(target.x - 495.0)
				for y in range(310, 435, 6):
					for x in range(124, max_x, 6):
						if game.Prologue.Lab.walkable(Vector2(x, y)):
							candidate = Vector2(x, y)
			game.prologue.pos = candidate
			game.prologue_camera = game.Prologue.Lab.SIZE * 0.5 if on_screen else game.prologue.pos
		"residuos":
			game.state = "play"
			var target: Vector2 = game.objective_point()
			game.pos = target + Vector2(0, 120 if on_screen else 344)
			game.camera = game.pos
			game._light.position = game.M.SIZE * 0.5 + game._offset()
			game._guide_timer = 0.0
			game._update_guidance()
		"energia":
			game.state = "play"
			game.pos = game.objective_point() + Vector2(0, 120) if on_screen else game.M.START
			game.camera = game.pos
			game._guide_timer = 0.0
			game._update_guidance()
			game._present(0.0)
		"nucleo":
			game.state = "gallery"
			game.channel_read = not on_screen
			game.pos = game.Map.TERMINAL + Vector2(140, 155) if on_screen else game.Map.GALLERY_START
			game._present(0.0)
