extends SceneTree
## Real scenes and input-independent snapshots of compact combat presentation.
const FieldHUD = preload("res://scripts/field_hud.gd")
var game: Node2D
var out := OS.get_environment("P17_POLISH_CAPTURE_DIR")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if out.is_empty(): out = "res://captures/polimento"
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960, 540)
	for preset in ["main", "main_timing", "residues", "power", "power_relays", "power_battery", "power_overload", "core", "core_overload"]:
		var scene: String = preset.get_slice("_", 0)
		game = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.sound.set_muted(true)
		for size in [Vector2i(960, 540), Vector2i(1440, 810)]:
			root.size = size
			await process_frame
			for large in [false, true]:
				FieldHUD.text_scale_percent = 125 if large else 100
				_setup(scene)
				_variant(preset)
				await _capture("%s-%dx%d-%d" % [preset, size.x, size.y, FieldHUD.text_scale_percent])
		game.queue_free()
		await process_frame
	print("COMBAT_POLISH_REVIEW_OK")
	quit()

func _setup(scene: String) -> void:
	match scene:
		"main":
			game.sim.start(1)
			game.mode = "play"
			game.dialogue.clear()
			game.sim.pos = Vector2(600, 430)
			game.camera_pos = game.sim.pos
			game.sim.aim = Vector2.RIGHT
			game.sim.enemies.resize(1)
			var enemy: Dictionary = game.sim.enemies[0]
			enemy.pos = Vector2(775, 480)
			enemy.hp = 3
			enemy.phase = "idle"
			game.enemy_presentation.advance(0.016, game.sim.enemies, 1, 0.016)
			game.sim.bullets.assign([{"pos": Vector2(710, 470), "vel": Vector2(-220, 0), "hostile": true}])
			game._update_objective_guides(0)
		"residues":
			game._finish_dialogue()
			game.pos = game.M.START
			game.camera = game.pos
			game.toast_time = 0
			var enemy: Dictionary = game.enemies[0]
			enemy.pos = game.pos + Vector2(160, -50)
			enemy.hp = 3
			enemy.look_dir = Vector2.LEFT
			game._drone_attack(enemy)
			game.bullets.assign([{"pos": game.pos + Vector2(100, -20), "vel": Vector2(-220, 0), "hostile": true}])
			game._update_objective_guide(0)
			game._light.position = game.M.SIZE * 0.5 + game._offset()
			game._guide_layer.queue_redraw()
			game._dialogue_layer.queue_redraw()
		"power":
			game._finish_dialogue()
			game.pos = game.M.START
			game.camera = game.pos
			game.toast_time = 0
			var enemy: Dictionary = game.enemies[0]
			enemy.pos = game.pos + Vector2(160, -50)
			enemy.hp = 3
			enemy.attack_age = 0.0
			enemy.facing = Vector2.LEFT
			game.bullets.assign([{"pos": game.pos + Vector2(100, -20), "vel": Vector2(-220, 0), "hostile": true, "kind": "bolt"}])
			game._present(0.0)
		"core":
			game.state = "arena"
			game.in_gallery = false
			game.pos = game.Map.ARRIVAL
			game.camera = game.pos
			game.boss.events.clear()
			game._present(0.0)

func _variant(preset: String) -> void:
	match preset:
		"main": game.water_guide.tip_remaining = 0.0
		"main_timing":
			game.sim.enemies.clear()
			game.sim.bullets.clear()
			game.sim.state = "activation"
			game.sim.operation.completed = 1
			game.sim.operation.clock = 0.84
			game.sim.pos = game.sim.operation.target() + Vector2(0, 35)
			game.camera_pos = game.sim.pos
			game._clamp_camera()
			game._update_energy_station(2.0)
			game._update_objective_guides(0)
			game.water_guide.tip_remaining = 0.0
		"residues": game.objective_guide.tip_remaining = 0.0
		"power_relays":
			game.stage = 1
			game.pos = game.M.w(game.M.RELAYS[0]) + Vector2(0, 80)
			game.relays.charge.assign([6.0, 4.0, 2.0])
		"power_battery":
			game.stage = 2
			game.pos = game.M.w(game.M.RING_CENTER)
			game.battery.started = true
			game.battery.charge = 0.57
			game.battery.cells.assign([0.92, 0.42, 0.55])
			game.toast = "Mantenha a carga e alivie as células críticas."
			game.toast_time = 3.0
		"power_overload":
			game.mirrors.solved = true
			for enemy in game.enemies:
				if enemy.zone == 0: enemy.hp = 0
			game.pos = game.M.w(game.M.TERMINALS[0]) + Vector2(0, 70)
			game.overloads[0].running = true
			game.overloads[0].hits = 1
			game.overloads[0].phase = 0.28
			game.toast = "Acerte a faixa verde para sincronizar a rede."
			game.toast_time = 3.0
		"core_overload":
			game.active_pillar = 2
			game.boss.pillars[2].running = true
			game.boss.pillars[2].hits = 1
			game.boss.pillars[2].phase = 0.28
			game.toast = "Acerte a faixa verde para sincronizar o pilar."
			game.toast_left = 3.0
	if preset.begins_with("power"):
		game.camera = game.pos
		game._present(0.0)
		game.objective_guide.tip_remaining = 0.0
	elif preset.begins_with("core"):
		game._present(0.0)

func _capture(label: String) -> void:
	game.queue_redraw()
	if "_hud" in game: game._hud.queue_redraw()
	if "_fx" in game: game._fx.queue_redraw()
	for i in 4: await process_frame
	RenderingServer.force_draw(true)
	var image := root.get_texture().get_image()
	assert(not image.is_empty())
	assert(image.save_png(out.path_join(label + ".png")) == OK)
