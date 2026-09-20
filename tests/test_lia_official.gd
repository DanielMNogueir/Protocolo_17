extends SceneTree
const Visual := preload("res://scripts/lia_official.gd")
const Actors := preload("res://scripts/actors_art.gd")
var checks := 0
var failed := false

class ContactSheet extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 540), Color("112a33"))
		var directions := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
		var names := ["FRENTE", "ESQUERDA", "DIREITA", "COSTAS"]
		for column in 4:
			draw_string(ThemeDB.fallback_font, Vector2(135 + column * 210, 30), names[column], HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		for row in 4:
			draw_string(ThemeDB.fallback_font, Vector2(12, 85 + row * 125), ["REPOUSO", "CAMINHADA", "DISPARO", "MANUTENÇÃO"][row], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
			for column in 4:
				draw_set_transform(Vector2(175 + column * 210, 101 + row * 125), 0, Vector2.ONE * 1.8)
				Actors.draw_lia(self, Vector2.ZERO, directions[column], 0.24, row == 1, false, false, ["idle", "idle", "fire", "repair"][row])
				draw_set_transform(Vector2.ZERO)

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(message)

func _run() -> void:
	for sheet in ["walk", "actions"]:
		var texture: Texture2D = load("res://assets/lia_official/" + sheet + ".png")
		var img := texture.get_image()
		check(img.get_pixel(0, 0).a == 0, "Background transparent")
		for row in Visual.layout[sheet]:
			for f in row:
				var bounds := Rect2i(f[0], f[1], f[2], f[3])
				check(not img.get_region(bounds).is_empty(), "Frame exists")
				check(bounds.size.x > 50 and bounds.size.y > 120, "Whole character extracted")
	for dir in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		var frames: Array[Rect2] = []
		for i in 4:
			var frame := Visual.frame_for(dir, (i + 0.01) / 9, true)
			frames.append(frame.region)
			check(is_equal_approx(frame.rect.end.y, 18), "Foot anchor fixed")
		for i in range(1, 4):
			check(frames[i] != frames[i - 1], "Walking frames advance")
	check(Visual.frame_for(Vector2.LEFT, 0, false, "fire").column == 1, "Firing left uses actual left pose")
	check(Visual.frame_for(Vector2.LEFT, 0, false, "idle").column == 2, "Idle left uses actual left pose")
	check(Visual.frame_for(Vector2.RIGHT, 0, false, "repair").column == 1, "Repair right uses actual right pose")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1440, 810)
		var contact := ContactSheet.new()
		root.add_child(contact)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/lia_official_poses.png")
		contact.queue_free()
		await process_frame
		var game: Node2D = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.set_process(false)
		game.sound.set_muted(true)
		game.sim.start()
		game.sim.pos = Vector2(800, 1420)
		game.sim.aim = Vector2.DOWN
		game.mode = "play"
		game.camera_pos = game.sim.pos
		game._clamp_camera()
		var before := var_to_str([game.sim.pos, game.sim.hp, game.sim.velocity, game.sim.aim, game.sim.stage, game.sim.invuln, game.sim.shots, game.sim.dash_cd])
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/lia_official_game.png")
		check(before == var_to_str([game.sim.pos, game.sim.hp, game.sim.velocity, game.sim.aim, game.sim.stage, game.sim.invuln, game.sim.shots, game.sim.dash_cd]), "Rendering does not mutate gameplay")
		game.queue_free()
		await process_frame
	print("LIA_VISUAL_TEST_", "FAILED" if failed else "OK", ": ", checks, " checks")
	quit(1 if failed else 0)
