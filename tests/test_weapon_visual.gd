extends SceneTree
const Weapon := preload("res://scripts/weapon_visual.gd")
const Actors := preload("res://scripts/actors_art.gd")
const Visual := preload("res://scripts/lia_official.gd")
const DIRECTIONS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
const IDLE_TIMES := [0.01, 0.56, 1.11, 3.90]
var failures := 0
var checks := 0

class Review extends Node2D:
	var action := "idle"
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("112a33"))
		if action in ["steps", "idleposes"]:
			var walking := action == "steps"
			var count := 8 if walking else 4
			var title := "CAMINHADA ARMADA / OITO FASES POR DIREÇÃO" if walking else "REPOUSO ARMADO / RESPIRAÇÃO E PISCADA"
			draw_string(ThemeDB.fallback_font, Vector2(24, 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
			for row in 4:
				for step in count:
					var aim: Vector2 = DIRECTIONS[row]
					var x := 92.0 + float(step) * 179.0 if walking else 185.0 + float(step) * 355.0
					var point := Vector2(x, 143 + row * 185)
					var sample_time: float = (step + .01) / Visual.WALK_FPS if walking else IDLE_TIMES[step]
					draw_set_transform(point, 0, Vector2.ONE * 2.4)
					draw_line(Vector2(-22, 18), Vector2(22, 18), Color("44636b"), .5)
					Actors.draw_lia(self, Vector2.ZERO, aim, sample_time, walking, false, false)
					draw_set_transform(Vector2.ZERO)
					draw_string(ThemeDB.fallback_font, point + Vector2(-16, 68), "%d" % step, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
			return
		draw_string(ThemeDB.fallback_font, Vector2(26, 32), "LIA / PULSO OFICIAL — " + action.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		for i in 8:
			var aim := Vector2.RIGHT.rotated(i * PI / 4)
			var point := Vector2(175 + (i % 4) * 355, 218 + (i / 4) * 380)
			draw_set_transform(point, 0, Vector2.ONE * 3.4)
			Actors.draw_lia(self, Vector2.ZERO, aim, 1.2, action == "walk", false, false, "fire" if action == "fire" else "idle", .02 if action == "fire" else -1.0)
			if action == "fire":
				Actors.WEAPON.draw_pulse(self, {"pos": aim * 39, "vel": aim * 640}, .04)
			draw_set_transform(Vector2.ZERO)
			draw_string(ThemeDB.fallback_font, point + Vector2(-22, 92), "%d°" % (i * 45), HORIZONTAL_ALIGNMENT_LEFT, -1, 15)

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _image_hash(image: Image) -> String:
	# Padding or relocation alone must not make an unchanged pose count as new art.
	var content := image.get_region(image.get_used_rect())
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(content.get_data())
	return digest.finish().hex_encode()

func _emitter_near(image: Image, point: Vector2i, radius: int) -> bool:
	for y in range(maxi(0, point.y - radius), mini(image.get_height(), point.y + radius + 1)):
		for x in range(maxi(0, point.x - radius), mini(image.get_width(), point.x + radius + 1)):
			var color := image.get_pixel(x, y)
			if color.a > .5 and color.g > .35 and color.b > .32 and minf(color.g, color.b) - color.r > .055:
				return true
	return false

func _validate_atlases() -> void:
	check(Visual.expanded.directions == ["down", "left", "right", "up"], "Atlas direction order stays explicit")
	for sheet: String in ["walk", "idle"]:
		var texture: Texture2D = Visual.ARMED_WALK if sheet == "walk" else Visual.ARMED_IDLE
		var image := texture.get_image()
		var expected := 8 if sheet == "walk" else 4
		check(not image.is_empty() and image.detect_alpha() != Image.ALPHA_NONE, sheet + " has actual alpha")
		check(image.get_pixel(0, 0).a == 0.0, sheet + " atlas background is transparent")
		check(Visual.expanded[sheet].size() == 4, sheet + " has four directions")
		var total := 0
		var hashes: Dictionary = {}
		for direction in 4:
			var row: Array = Visual.expanded[sheet][direction]
			check(row.size() == expected, "%s direction %d has %d complete poses" % [sheet, direction, expected])
			for step in row.size():
				var metadata: Dictionary = row[step]
				var values: Array = metadata.region
				var bounds := Rect2i(values[0], values[1], values[2], values[3])
				var label := "%s/%d/%d" % [sheet, direction, step]
				var valid := bounds.size.x > 0 and bounds.size.y > 0 and Rect2i(Vector2i.ZERO, image.get_size()).encloses(bounds)
				check(valid, label + " region lies wholly inside its atlas")
				if not valid:
					continue
				var frame_image := image.get_region(bounds)
				check(frame_image.get_used_rect().has_area(), label + " contains visible character pixels")
				if not frame_image.get_used_rect().has_area():
					continue
				var digest := _image_hash(frame_image)
				check(not hashes.has(digest), label + " has unique trimmed image bytes")
				hashes[digest] = true
				var sample_time: float = (step + .01) / Visual.WALK_FPS if sheet == "walk" else IDLE_TIMES[step]
				var pose := Visual.held_pose(DIRECTIONS[direction], sample_time, sheet == "walk")
				check(pose.frame == step and pose.direction == direction and pose.sheet == sheet, label + " resolves the intended pose")
				check(pose.parts.size() == 1, label + " is one full armed image, without body/weapon cuts")
				var part: Dictionary = pose.parts[0]
				check(part.texture == texture and part.region == Rect2(bounds), label + " uses its complete source frame")
				check(not part.upper, label + " is not a detached upper-body layer")
				check(is_equal_approx(pose.scale, Visual.expanded.scales[sheet]), label + " uses constant animation scale")
				var rect: Rect2 = part.rect
				var anchor := Vector2(metadata.anchor[0], metadata.anchor[1])
				var transformed_anchor: Vector2 = rect.position + (anchor - Vector2(bounds.position)) * float(pose.scale)
				check(transformed_anchor.is_equal_approx(Vector2(0, 18)), label + " anatomical anchor maps to the fixed ground point")
				check(is_equal_approx(rect.end.y, 18), label + " feet stay on the established baseline")
				var muzzle_source := Vector2(metadata.muzzle[0], metadata.muzzle[1])
				var expected_muzzle := rect.position + (muzzle_source - Vector2(bounds.position)) * float(pose.scale)
				var muzzle: Vector2 = pose.muzzle
				check(muzzle.is_finite() and muzzle.length() < 60 and muzzle.is_equal_approx(expected_muzzle), label + " muzzle uses the exact sprite transform")
				check(Rect2(bounds).grow(1).has_point(muzzle_source), label + " muzzle marker belongs to the source sprite")
				check(_emitter_near(image, Vector2i(muzzle_source), maxi(4, int(ceil(2.0 / float(pose.scale))))), label + " muzzle is near a cyan emitter within two display pixels")
				total += 1
		check(total == expected * 4 and hashes.size() == expected * 4, sheet + " provides the complete unique atlas")

func _validate_animation() -> void:
	var cycle := 8.0 / Visual.WALK_FPS
	check(is_equal_approx(cycle, 4.0 / 9.0), "Eight walking frames preserve the prior 0.444-second stride")
	for direction: Vector2 in DIRECTIONS:
		for step in 8:
			var time := (step + .01) / Visual.WALK_FPS
			check(Visual.held_pose(direction, time, true).frame == step, "All eight walk phases are reachable in order")
			check(Visual.held_pose(direction, time + cycle, true).frame == step, "Walk cycle repeats without an extra or missing phase")
			check(Visual.held_pose(direction.rotated(PI / 2), time, true).frame == step, "Turning preserves the walking phase")
	for index in 4:
		check(Visual.idle_frame(index * .55 + .01) == [0, 1, 2, 1][index], "Idle breathing uses the intended slower cadence")
	var blink_samples := 0
	for sample in 400:
		var frame := Visual.idle_frame(sample * .01 + .001)
		check(frame >= 0 and frame < 4, "Idle always selects a valid pose")
		if frame == 3:
			blink_samples += 1
	check(blink_samples == 16, "Blink occupies only 0.16 seconds of a four-second interval")
	check(Visual.idle_frame(3.839) != 3 and Visual.idle_frame(3.841) == 3 and Visual.idle_frame(3.999) == 3 and Visual.idle_frame(4.001) != 3, "Blink opens and closes at its exact boundaries")
	for time: float in IDLE_TIMES:
		for direction: Vector2 in DIRECTIONS:
			check(Visual.held_pose(direction, time, false).frame == Visual.idle_frame(time), "Every direction reaches all breathing/blink frames")
	check(Weapon.recoil_at(-1) == 0 and Weapon.recoil_at(.1) == 0 and Weapon.recoil_at(.2) == 0, "Recoil stops after the shot interval")
	check(Weapon.recoil_at(.01) > Weapon.recoil_at(.06), "Recoil settles independently of walking phase")
	for index in 32:
		var aim := Vector2.RIGHT.rotated(index * TAU / 32)
		for shot_age: float in [-1.0, 0.0, .05, .075, .1, .2]:
			var recoil := Weapon.recoil_at(shot_age)
			for foot_x: float in [-12.0, 0.0, 12.0]:
				var foot := Vector2(foot_x, 18)
				check(Visual.recoil_point(foot, aim, recoil).is_equal_approx(foot), "Affine recoil keeps the entire foot baseline fixed")
			var pose := Visual.held_pose(aim, .13, true)
			var muzzle: Vector2 = pose.muzzle
			var leaned := Visual.recoil_point(muzzle, aim, recoil)
			check(leaned.is_finite() and leaned.distance_to(muzzle) <= 2.5, "Muzzle recoil remains finite and restrained at every aim angle")
			var a := Vector2(-18, -32)
			var b := Vector2(18, 18)
			check(Visual.recoil_point(a.lerp(b, .37), aim, recoil).is_equal_approx(Visual.recoil_point(a, aim, recoil).lerp(Visual.recoil_point(b, aim, recoil), .37)), "Affine recoil keeps hands, gun and muzzle attached")

func _simulation_snapshot(sim: RefCounted) -> String:
	return var_to_str([sim.pos, sim.velocity, sim.aim, sim.bullets, sim.enemies, sim.particles, sim.events,
		sim.hp, sim.max_hp, sim._fire_cd, sim.fire_interval, sim.shots, sim.pulse_damage, sim.pulse_speed,
		sim.dash_cd, sim.dash_time, sim.invuln, sim.repair, sim.stage, sim.restored, sim.state, sim.chosen, sim.kills, sim.elapsed])

func _run() -> void:
	_validate_atlases()
	_validate_animation()
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1440, 810)
		var review := Review.new()
		root.add_child(review)
		for action in ["idle", "walk", "fire", "steps", "idleposes"]:
			review.action = action
			review.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://captures/weapon_" + action + ".png") == OK, "Visual capture saved: " + action)
		review.queue_free()
		await process_frame
		var game: Node2D = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.set_process(false)
		game.sound.set_muted(true)
		game.sim.start()
		game.sim.pos = Vector2(800, 1420)
		game.mode = "play"
		game.sim.tick(.02, Vector2.RIGHT, Vector2(1000, 1390), true, false, false)
		game.lia_animation.advance(.02, game.sim.velocity, game.sim.dash_time > 0)
		game.camera_pos = game.sim.pos
		game._clamp_camera()
		for phase_time: float in [0.01, .17, .40, 1.11, 3.90]:
			game.clock = phase_time
			game.lia_animation.elapsed = phase_time
			var before := _simulation_snapshot(game.sim)
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			check(before == _simulation_snapshot(game.sim), "Actual scene rendering leaves all combat/progression state untouched")
		check(root.get_texture().get_image().save_png("res://captures/weapon_game.png") == OK, "Real gameplay capture saved")
		game.queue_free()
		await process_frame
	else:
		print("WEAPON_VISUAL: headless asset/animation checks only; run graphically for captures and scene draw validation")
	print("WEAPON_VISUAL_", "OK" if failures == 0 else "FAILED", ": ", checks, " checks")
	quit(0 if failures == 0 else 1)
