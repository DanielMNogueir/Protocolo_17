extends SceneTree
## Render actual game art to a review gallery without changing player saves.
const Art = preload("res://scripts/enemy_art.gd")
const Actors = preload("res://scripts/actors_art.gd")

class Board extends Node2D:
	var time := 0.0
	var direction := 1
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 900), Color("10232b"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(24, 28), "PROTOCOLO 17  /  UNIDADES CORROMPIDAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("7be4ce"))
		for col in 4:
			draw_string(font, Vector2(24 + col * 240, 58), ["EXPLORADOR", "SENTINELA", "INVESTIDA", "CONTENÇÃO"][col], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8bd74"))
		for row in 5:
			var y := 90 + row * 162
			draw_line(Vector2(24, y), Vector2(936, y), Color("2c4249"))
			draw_string(font, Vector2(24, y + 18), ["MOVIMENTO", "PREPARAÇÃO", "ATAQUE", "DANO", "DESTRUIÇÃO"][row], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("91abae"))
			for col in 4:
				var kind: String = ["scout", "sentry", "rammer", "boss"][col]
				var enemy := {"kind": kind, "pos": Vector2.ZERO, "id": col, "aim": Vector2.from_angle(direction * PI / 4), "hp": 2, "max_hp": 8,
					"moving": true, "anim_time": time, "phase": "windup" if row == 1 else ("charge" if row == 2 and kind == "rammer" else "idle"),
					"warning": .4 if row == 1 else 0.0, "hurt": .1 if row == 3 else 0.0, "attack_age": fmod(time, .3) if row == 2 else 99.0, "death_age": fmod(time, 1.05)}
				draw_set_transform(Vector2(120 + col * 240, y + 100), 0, Vector2.ONE * (1.05 if kind == "boss" else 1.8))
				if row == 4:
					Art.draw_destroyed(self, enemy)
				else:
					Art.draw(self, enemy, time)
				draw_set_transform(Vector2.ZERO)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/enemy_review")
	root.content_scale_size = Vector2i(960, 900)
	root.size = Vector2i(960, 900)
	var board := Board.new()
	root.add_child(board)
	for index in 32:
		board.time = index / 8.0
		board.direction = index / 4
		board.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/enemy_review/frame_%02d.png" % index)
	board.queue_free()
	await process_frame
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(1440, 810)
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.sim.start(3)
	game.sim.pos = Vector2(2110, 1430)
	game.mode = "play"
	game.camera_pos = game.sim.pos
	game._clamp_camera()
	game.enemy_presentation.advance(.016, game.sim.enemies, game.sim.stage, game.sim.elapsed)
	var before := var_to_str([game.sim.enemies, game.sim.bullets, game.sim.pos, game.sim.hp, game.sim.state])
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(before == var_to_str([game.sim.enemies, game.sim.bullets, game.sim.pos, game.sim.hp, game.sim.state]), "Rendering must not modify combat")
	root.get_texture().get_image().save_png("res://.runtime/enemy_review/game.png")
	FileAccess.open("res://.runtime/enemy_review/preview.html", FileAccess.WRITE).store_string(FileAccess.get_file_as_string("res://tools/enemy_review.html"))
	print("ENEMY_REVIEW_OK: 32 animation captures and real scene; drawing preserves simulation")
	quit()
