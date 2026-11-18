extends SceneTree
## Captures every major Core presentation state using a rendering driver.
## P17_CORE_CAPTURE_DIR can redirect the output outside the project.
const Scene = preload("res://scenes/core.tscn")
const Map = preload("res://scripts/core_map.gd")
const Boss = preload("res://scripts/core_boss.gd")
const Story = preload("res://scripts/core_story.gd")
const TEST_PATH := "user://review_core_campaign.json"

var game: Node2D
var out := OS.get_environment("P17_CORE_CAPTURE_DIR")
var capture_size := ""
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Core review requires a rendering driver")
		quit(1)
		return
	if out.is_empty(): out = "res://captures/nucleo"
	DirAccess.make_dir_recursive_absolute(out)
	set_meta("p17_core_handoff", {"save_path": TEST_PATH})
	game = Scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_muted(true)
	root.content_scale_size = Vector2i(960, 540)
	for size: Vector2i in [Vector2i(960, 540), Vector2i(1440, 810)]:
		root.size = size
		capture_size = "%dx%d" % [size.x, size.y]
		await _views()
	game.queue_free()
	await process_frame
	print("CORE_REVIEW_OK" if failures == 0 else "CORE_REVIEW_FAILED")
	quit(0 if failures == 0 else 1)


func _views() -> void:
	game.clock = 2.0
	game.guide.tip_remaining = 0.0
	game.choice.reopen()
	game.choice.heard_ai = 0
	game.choice.heard_human = 0
	game.ending.sequence = ""
	game.in_gallery = true
	game.channel_read = false
	game.state = "gallery"
	game.pos = Map.GALLERY_START
	await _capture("01-galeria")
	game.pos = Map.TERMINAL + Vector2(0, 58)
	game._talk(Story.COMMAND_CHANNEL, "gallery")
	game.dialogue_chars = 9999.0
	await _capture("02-canal")
	game.in_gallery = false
	game.pos = Map.pillars()[2] + Vector2(0, 63)
	game.state = "arena"
	game.boss = Boss.new("operation", 1.0, 1)
	game.active_pillar = 2
	game.boss.press_pillar(2)
	game.boss.pillars[2].phase = 0.47
	await _capture("03-sobrecarga")
	game.boss = Boss.new("operation", 1.0, 2)
	game.boss.phase_time = 3.0
	game.active_pillar = -1
	game.pos = Map.ring(0.72, 185)
	await _capture("04-apagao")
	game.boss.phase_time = 12.0
	game.boss.dawn_amount = 0.8
	game.boss.burn = 4.0
	game.pos = Map.CENTER + Vector2(-218, 104)
	await _capture("05-feixe")
	game.boss = Boss.new("operation", 1.0, 3)
	game.pos = Map.CENTER + Vector2(199, 130)
	game.boss.integrity = 0.35
	game.boss.attack = "spiral"
	for i in 20:
		game.shots.append({"pos": Map.CENTER + Vector2.from_angle(i * 0.62) * (58 + i * 12), "vel": Vector2.RIGHT, "hostile": true})
	await _capture("06-espiral")
	game.shots.clear()
	game.boss.phase = 4
	game.boss.integrity = 0.0
	for i in 2:
		game.state = "choice"
		game.pos = Map.CONSOLES[i] + Vector2(32, 48)
		await _capture("07-beatrix" if i == 0 else "08-ia")
		game.evidence = {"side": "human" if i == 0 else "ai", "number": 1, "kills": 86}
		game._talk([Story.HUMAN_CASE[0] if i == 0 else Story.AI_CASE[0]], "choice")
		game.dialogue_chars = 9999.0
		await _capture("09-projecao-beatrix" if i == 0 else "10-projecao-ia")
		game.evidence.clear()
	for result in ["humanity", "ai"]:
		game.choice.result = result
		game.ending.start(result)
		game.ending.show_cards()
		game.state = "ending"
		var card_index := 0
		for card in game.ending.cards():
			game.ending.index = card_index
			game.ending.age = 3.2
			await _capture("11-" + card[0])
			card_index += 1
		game.ending.sequence = "signal"
		await _capture("12-laboratorio" if result == "humanity" else "13-cais")
		game.state = "complete"
		await _capture("14-campanha-" + result)
		game.state = "credits"
		game.ending.credits_time = 8.4
		await _capture("15-creditos-" + result)


func _capture(label: String) -> void:
	game._present(0.0)
	await process_frame
	RenderingServer.force_draw(true)
	var image := root.get_texture().get_image()
	if image.is_empty() or image.save_png(out.path_join("%s-%s.png" % [capture_size, label])) != OK:
		failures += 1
