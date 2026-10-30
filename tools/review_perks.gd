extends SceneTree
## Native rendering and input review. Never writes player settings or checkpoints.
class Shell extends "res://scripts/main.gd":
	func _save_checkpoint() -> void: pass
	func _read_checkpoint() -> Dictionary: return {}
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass
var game: Shell
var checks := 0
var out := OS.get_environment("P17_PERK_OUTPUT")
func _initialize() -> void: run.call_deferred()
func setup(stage: int) -> void:
	game.sim.start(stage)
	game.sim.restored = stage + 1
	game.sim.state = "upgrade"
	game.mode = "upgrade"
	game.dialogue.clear()
	game.pointer = Vector2(-100, -100)
	game.camera_pos = game.World.GOALS[stage]
	game._clamp_camera()
func render() -> void:
	game.queue_redraw()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	await render()
	assert(root.get_texture().get_image().save_png(out.path_join(label + ".png")) == OK)
func run() -> void:
	if out.is_empty(): out = ProjectSettings.globalize_path("user://perk-review")
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960, 540)
	game = Shell.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	for resolution in [Vector2i(960, 540), Vector2i(1440, 810)]:
		root.size = resolution
		for stage in 3:
			setup(stage)
			await capture("etapa-%d-%d" % [stage + 1, resolution.x])
			var cards: Array = game.buttons.filter(func(button): return button.id.begins_with("upgrade_"))
			assert(cards.size() == 3)
			for card in cards:
				assert(Rect2(Vector2.ZERO, game._size()).encloses(card.rect))
			for index in 3:
				for method in ["mouse", "keyboard"]:
					setup(stage)
					var expected: String = game.sim.upgrade_options()[index].id
					if method == "mouse":
						var click := InputEventMouseButton.new()
						click.button_index = MOUSE_BUTTON_LEFT
						click.pressed = true
						click.position = cards[index].rect.get_center()
						game._unhandled_input(click)
					else:
						var key := InputEventKey.new()
						key.physical_keycode = KEY_1 + index
						key.pressed = true
						game._unhandled_input(key)
					assert(game.sim.chosen.has(expected), "Selected perk matches its card")
					assert(game.mode == "play" and game.sim.stage == stage + 1, "Installation advances operation")
					game.ui_mouse_held = false
					checks += 1
		setup(1)
		await render()
		game.pointer = game.buttons[1].rect.get_center()
		await capture("destaque-%d" % resolution.x)
	game.free()
	for frame in 5: await process_frame
	print("PERK_REVIEW_OK: 8 captures; ", checks, " mouse/keyboard installations; all nine perks and both resolutions")
	quit()