extends SceneTree
## Regression for incorrect emitters, missed fixtures, dash tunnelling and stuck bots.
const M = preload("res://scripts/residue_map.gd")
const Pose = preload("res://scripts/lia_directional.gd")
var checks := 0
var failures := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("RESIDUE_COLLISION_FAILED: " + message)

func _run() -> void:
	var game = load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_muted(true)
	game.stage = 2
	# All 24 headings and eight gait phases use Water's actual emitter.
	game.pos = Vector2(900, 550) * M.SCALE
	for direction in 24:
		for frame in 8:
			game.aim = Vector2.RIGHT.rotated(direction * TAU / 24.0)
			game._animation.elapsed = (frame + 0.1) / 18.0
			game._animation.moving = true
			game.bullets.clear()
			var target: Vector2 = game.pos + game.aim * 300.0
			game._fire(target)
			var muzzle: Vector2 = game.pos + Pose.pose(game.aim, game._animation.elapsed, true).muzzle
			check(game.bullets.size() == 1 and game.bullets[0].pos.distance_to(muzzle) < 0.001, "held muzzle %d/%d" % [direction, frame])
			if not game.bullets.is_empty(): check(Vector2(game.bullets[0].vel).normalized().dot((target - muzzle).normalized()) > 0.99999, "aim corrected from the emitter")
	game.bullets.clear()
	game._fire(game.pos + Vector2(300, 0), true)
	check(game.bullets.size() == 5 and game.bullets[2].damage == game.pulse_damage + 1, "same five-pulse secondary as Water")
	for age in [0.0, 0.02, 0.05, 0.08, 0.12]:
		game.fire_cd = game.fire_interval - age
		check(is_equal_approx(game.shot_age(), age), "recoil time advances instead of freezing at 0.05")
	game.fire_cd = 0
	check(game.shot_age() == -1.0, "idle has no lingering muzzle flash")
	game.bullets.clear()
	# Every registered fixture rejects bodies. Approaches exercise the real
	# movement method with a displacement larger than an ordinary dash frame.
	for shape in M.collision_shapes(2, game.cleared):
		var rect: Rect2 = shape.rect
		check(not M.walkable(rect.get_center(), 0.5, 2, game.cleared), "solid centre: " + shape.name)
		for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var distance := absf(direction.x) * rect.size.x * 0.5 + absf(direction.y) * rect.size.y * 0.5
			var start := rect.get_center() + direction * (distance + 20.0)
			if not M.walkable(start, 14, 2, game.cleared): continue
			game.pos = start
			game._move_player(-direction * (distance * 2 + 45.0))
			check(M.walkable(game.pos, 14, 2, game.cleared) and (game.pos - rect.get_center()).dot(direction) > 0, "swept body cannot cross " + shape.name)
	check(not M.walkable(Vector2(675, 600) * M.SCALE, 14, 2, game.cleared), "reported traversable street pole")
	# Generous work aisles must fit even the largest robot, not just Lia.
	for aisle in [[Vector2(280, 315), Vector2(625, 315)], [Vector2(300, 405), Vector2(500, 405)], [Vector2(910, 325), Vector2(1175, 325)], [Vector2(1050, 740), Vector2(1050, 885)], [Vector2(900, 869), Vector2(1180, 869)]]:
		check(M.line_clear(aisle[0] * M.SCALE, aisle[1] * M.SCALE, 25, 2, game.cleared), "wide work aisle " + str(aisle))
	# A fast pulse crosses many pixels per tick; the pole must still stop it.
	game.enemies.clear()
	var origin := Vector2(220, 600) * M.SCALE
	game.bullets.append({"pos": origin, "source": origin, "vel": Vector2(650, 0), "hostile": false, "life": 1.7, "damage": 1})
	game._update_bullets(0.2)
	check(game.bullets.is_empty(), "pulse cannot tunnel through a street pole")
	# Reproduce the user's stuck bot through actual AI, without teleporting it.
	for case in [[Vector2(1000, 900), Vector2(1058, 720), false], [Vector2(1185, 894), Vector2(980, 690), true], [Vector2(1390, 315), Vector2(1135, 315), false], [Vector2(462, 315), Vector2(450, 540), false], [Vector2(620, 455), Vector2(450, 315), false], [Vector2(1390, 315), Vector2(1125, 540), false], [Vector2(982, 695), Vector2(950, 540), false], [Vector2(1185, 894), Vector2(1060, 540), true]]:
		game.enemies.clear()
		game.bullets.clear()
		game.pos = case[1] * M.SCALE
		game.enemies.append({"pos": case[0] * M.SCALE, "home": case[0] * M.SCALE, "hp": 9, "zone": 2, "shot_cd": 1000.0, "hit_cd": 0.0, "phase": 0.0, "id": 0, "boss": case[2]})
		var free := true
		var radius := 25.0 if case[2] else 18.0
		for tick in 1800:
			game._update_enemies(1.0 / 60.0)
			free = free and M.walkable(game.enemies[0].pos, radius, 2, game.cleared)
		check(free, "robot remains outside all fixtures during its complete route")
		check(game.enemies[0].pos.distance_to(game.pos) < (160 if case[2] else 140) and M.line_clear(game.enemies[0].pos, game.pos, 3, 2, game.cleared), "robot finds a firing position around machines: " + str(case))
	print("RESIDUE_COLLISION_", "OK" if failures == 0 else "FAILED", ": ", checks, " checks; ", failures, " failures")
	game.queue_free()
	for frame in 4: await process_frame
	await create_timer(0.12).timeout
	quit(1 if failures else 0)
