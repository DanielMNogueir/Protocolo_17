extends SceneTree
## Renders review captures of the Energy district into captures/energia (or
## $P17_POWER_CAPTURE_DIR). Needs a rendering driver: run without --headless.
##   Godot --path . --script tools/review_power.gd

var game: Node2D
var out := OS.get_environment("P17_POWER_CAPTURE_DIR")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if out.is_empty(): out = "res://captures/energia"
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(1440, 810)
	game = load("res://scenes/power.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game._finish_dialogue()
	var M = game.M
	# [name, Lia (source), stage, camera (source), setup]
	var views := [
		["01-patio-apagao", Vector2(250, 790), 0, Vector2(300, 700), "none"],
		["02-espelhos", Vector2(560, 330), 0, Vector2(400, 240), "mirrors"],
		["03-sobrecarga", Vector2(232, 412), 0, Vector2(300, 330), "overload"],
		["04-corredor", Vector2(650, 240), 1, Vector2(760, 250), "arcs"],
		["05-torre", Vector2(960, 300), 1, Vector2(1100, 230), "tower"],
		["06-baterias", Vector2(1195, 862), 2, Vector2(1200, 800), "battery"],
		["07-elevador", Vector2(1420, 795), 3, Vector2(1330, 800), "none"],
	]
	for entry in views:
		_reset(entry[2])
		game.pos = M.w(entry[1])
		assert(M.walkable(game.pos, 14.0, game.stage))
		game.camera = M.w(entry[3]).clamp(Vector2(480, 270), M.SIZE - Vector2(480, 270))
		game.aim = Vector2.RIGHT
		_setup(entry[4])
		await _capture(entry[0])
	# Whole district, dark and fully restored.
	root.content_scale_size = Vector2i(M.SIZE)
	root.size = Vector2i(1536, 1024)
	game._hud.visible = false
	for powered in [false, true]:
		_reset(3 if powered else 0)
		game.pos = M.START
		game.camera = M.SIZE * 0.5
		await _capture("08-distrito-" + ("aceso" if powered else "apagado"))
	game.collision_audit = true
	_reset(0)
	game.camera = M.SIZE * 0.5
	game._light.visible = false
	await _capture("09-colisoes")
	game._light.visible = true
	game.collision_audit = false
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	game._hud.visible = true
	_reset(1)
	game.pos = M.w(Vector2(760, 240))
	game.camera = game.pos
	game._guide_timer = 0.0
	game._update_guidance()
	game.state = "map"
	await _capture("10-mapa-960")
	game.state = "play"
	game._start_dialogue(game.Story.SOLAR, "play")
	game.dialogue_chars = 9999.0
	await _capture("11-registro-beatrix")
	game._start_dialogue(game.Story.INTRO.slice(3), "play")
	game.dialogue_chars = 9999.0
	await _capture("12-ia")
	game._finish_dialogue()
	game.state = "victory"
	game.elapsed = 512.0
	game.kills = 31
	game.victory_notice = "OPERAÇÃO CORRENTE REGISTRADA  /  PROGRESSO SALVO"
	await _capture("13-vitoria")
	await _reference_plates()
	print("POWER_REVIEW_OK: ", views.size(), " gameplay views + overviews + audit + map + dialogue + victory + reference plates")
	game.queue_free()
	for frame in 4: await process_frame
	await create_timer(0.12).timeout
	quit(0)

## Framed layout references for assets/power/PROMPTS.md: static background only
## (no actors, interactive props, gates, darkness or HUD). Each sector covers a
## quarter of the district and is rendered at the painted size, 1536×1024.
func _reference_plates() -> void:
	var M = game.M
	var folder := "res://assets/power/reference"
	DirAccess.make_dir_recursive_absolute(folder)
	game.state = "play"
	game.plate_mode = true
	game._hud.visible = false
	game._light.visible = false
	game._fx.visible = false
	var half: Vector2 = M.SIZE * 0.5
	for powered in [false, true]:
		_reset(3 if powered else 0)
		game.plate_mode = true
		var suffix := "on" if powered else "off"
		root.content_scale_size = Vector2i(M.SIZE)
		root.size = Vector2i(1536, 1024)
		game.camera = half
		await _capture_to(folder + "/district_" + suffix + ".png")
		root.content_scale_size = Vector2i(half)
		root.size = Vector2i(1536, 1024)
		var names := ["northwest", "northeast", "southwest", "southeast"]
		for i in 4:
			game.camera = Vector2(i % 2, i / 2) * half + half * 0.5
			await _capture_to(folder + "/sector_" + names[i] + "_" + suffix + ".png")
	game.plate_mode = false
	game._light.visible = true
	game._fx.visible = true

func _capture_to(path: String) -> void:
	game._present(0.0)
	game.queue_redraw()
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)

func _reset(stage: int) -> void:
	game.stage = stage
	game.state = "play"
	game.restored_light = float(stage)
	game.toast_time = 0.0
	game.clock = 0.4
	if stage > 0:
		game.mirrors.orientation.assign([2, 4, 6])
		game.mirrors.solved = true
		game.overloads[0].done = true
	if stage > 1:
		game.relays.solved = true
		game.overloads[1].done = true
	for enemy in game.enemies:
		if enemy.zone < stage: enemy.hp = 0
		enemy.death_age = 5.0 if enemy.zone < stage else -1.0

func _setup(kind: String) -> void:
	match kind:
		"mirrors":
			game.mirrors.orientation.assign([2, 1, 3])
			game.fire_cd = game.fire_interval * 0.8
			game.aim = Vector2.LEFT
			game.bullets.append({"pos": game.pos + Vector2(-60, -22), "source": game.pos, "vel": Vector2(-640, 0), "hostile": false, "life": 1.0, "damage": 1})
		"overload":
			game.mirrors.orientation.assign([2, 4, 6])
			game.mirrors.solved = true
			for enemy in game.enemies:
				if enemy.zone == 0: enemy.hp = 0
			var overload = game.overloads[0]
			overload.running = true
			overload.hits = 1
			overload.phase = 0.31
			game.aim = Vector2.UP
		"arcs":
			game.clock = 2.3
			game.toast = "IA: O corredor segue um ritmo. Você também seguirá."
			game.toast_ai = true
			game.toast_time = 3.0
		"tower":
			for step in 60:
				if game.coil_links()[0].active: break
				game.clock += 0.05
			game.relays.charge[0] = 5.0
			game.relays.charge[1] = 2.0
			for enemy in game.enemies:
				if enemy.zone == 1 and enemy.kind == "sentry": enemy.phase = "windup"
		"battery":
			game.battery.started = true
			game.battery.charge = 0.46
			game.battery.cells.assign([0.5, 0.86, 0.6])
			game.battery.surging = 1
	game._guide_timer = 0.0
	game._update_guidance()

func _capture(name: String) -> void:
	game._present(0.0)
	game.queue_redraw()
	game._hud.queue_redraw()
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out + "/" + name + ".png") == OK)
