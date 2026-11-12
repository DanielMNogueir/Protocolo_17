extends SceneTree
## Energy district collision and AI soak: every fixture rejects swept bodies
## (dash-sized moves included), every gate holds until its stage, pulses stop
## on fixtures, and live AI runs 1800 ticks per installation without any
## drone leaving the floor, tunnelling, or getting stuck far from Lia.
const M = preload("res://scripts/power_map.gd")
var checks := 0
var failures := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("POWER_COLLISION_FAILED: " + message)

func _run() -> void:
	var game: Node2D = load("res://scenes/power.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_muted(true)
	await process_frame
	game._finish_dialogue()
	for stage in 4:
		for shape in M.collision_shapes(stage):
			var rect: Rect2 = shape.rect
			check(not M.walkable(rect.get_center(), 0.5, stage), "solid centre at stage %d: %s" % [stage, shape.name])
			for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				var distance := absf(direction.x) * rect.size.x * 0.5 + absf(direction.y) * rect.size.y * 0.5
				var start := rect.get_center() + direction * (distance + 20.0)
				if not M.walkable(start, 14.0, stage): continue
				game.stage = stage
				game.pos = start
				game._move_player(-direction * (distance * 2.0 + 45.0))
				check(M.walkable(game.pos, 14.0, stage) and (game.pos - rect.get_center()).dot(direction) > 0, "swept body cannot cross %s (stage %d)" % [shape.name, stage])
	# A fast pulse crosses many pixels per tick; fixtures must still stop it.
	game.stage = 0
	var bank := M.world_rect(Rect2(380, 606, 200, 118))
	game.bullets.clear()
	game.bullets.append({"pos": bank.get_center() + Vector2(-bank.size.x, 0), "vel": Vector2(2400, 0), "hostile": false, "life": 1.0, "damage": 1})
	for frame in 10: game._update_bullets(0.016)
	check(game.bullets.is_empty(), "fast pulse stops on the workshop wall")
	# Wide aisles must fit the largest robot.
	for aisle in [[Vector2(80, 530), Vector2(1480, 530)], [Vector2(640, 240), Vector2(880, 240)], [Vector2(960, 900), Vector2(1400, 900)], [Vector2(240, 315), Vector2(440, 315)], [Vector2(1040, 290), Vector2(1240, 290)]]:
		check(M.line_clear(M.w(aisle[0]), M.w(aisle[1]), 25.0, 3), "wide aisle %s" % [aisle])
	# Live AI soak per installation: Lia strafes, enemies chase and fire.
	for stage in 3:
		game.stage = stage
		game.state = "play"
		game.hp = 999
		game.max_hp = 999
		var anchor: Vector2 = [M.w(Vector2(330, 330)), M.w(Vector2(1100, 330)), M.w(M.RING_CENTER)][stage]
		game.pos = anchor
		if stage == 2:
			game.battery.started = true
			for wave in 4: game._spawn_wave(wave)
		for enemy in game.enemies:
			if enemy.zone == stage: enemy.engaged = true
		var stuck := {}
		for tick in 1800:
			game.clock += 1.0 / 60.0
			var offset := Vector2(cos(tick * 0.02), sin(tick * 0.031)) * 70.0
			game._move_player((anchor + offset - game.pos).limit_length(3.4))
			game.invuln = 1.0
			game._update_arcs(1.0 / 60.0)
			game._update_enemies(1.0 / 60.0)
			game._update_bullets(1.0 / 60.0)
			game._update_trails(1.0 / 60.0)
			for enemy in game.enemies:
				if enemy.hp <= 0 or enemy.zone != stage: continue
				if not M.walkable(enemy.pos, enemy.radius - 1.0, stage):
					check(false, "%s %d left the floor at %s (stage %d)" % [enemy.kind, enemy.id, enemy.pos / M.SCALE, stage])
					enemy.hp = 0
				if tick == 1799 and enemy.kind in ["scout", "sentry", "spark"]:
					stuck[enemy.id] = enemy.pos.distance_to(game.pos)
		for id in stuck:
			check(stuck[id] < 620.0, "drone %d kept chasing (%.0f px from Lia, stage %d)" % [id, stuck[id], stage])
		check(game.state == "play", "soak stage %d ran without breaking state" % stage)
	print("POWER_COLLISION_", "OK" if failures == 0 else "FAILED", ": ", checks, " checks")
	game.queue_free()
	for frame in 3: await process_frame
	quit(1 if failures else 0)
