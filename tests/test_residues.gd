extends SceneTree

const M = preload("res://scripts/residue_map.gd")
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node2D = load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	_check(M.walkable(M.START, 14.0, 0, game.cleared), "start walkable")
	for i in 4:
		_check(M.walkable(M.ITEMS[i], 14.0, 0, game.cleared), "item %d reachable" % i)
	_check(not M.walkable(M.GATES[0].get_center(), 14.0, 0, game.cleared), "first gate closed")
	_check(not M.walkable(M.GATES[1].get_center(), 14.0, 1, game.cleared), "second gate closed")
	_check(_path_to(M.START, M.ITEMS[3], 45.0, 0, game.cleared), "route from dock to sorting items")
	for i in 4:
		_check(_path_to(M.START, M.BINS[i] + Vector2(0, 65), 70.0, 0, game.cleared), "route from dock to bay %d" % i)
	_check(not game._terminal_ready(0), "sorting required")
	game.pos = M.ITEMS[0]
	game._interact(0.016, true, true)
	_check(game.carried == 0, "metal picked up")
	game.pos = M.BINS[1] + Vector2(0, 65)
	game._interact(0.016, true, true)
	_check(game.carried == -1 and not game.sorted[0], "wrong bin returns material")
	_check(game.bin_lock > 2.0, "wrong bin temporarily locks sorter")
	_check(game.enemies.size() == M.ENEMY_POSITIONS.size() + 1, "wrong bin alerts a collection drone")
	game.bin_lock = 0.0
	for i in 4:
		game.pos = M.ITEMS[i]
		game._interact(0.016, true, true)
		_check(game.carried == i, "picked %d" % i)
		game.pos = M.BINS[i] + Vector2(0, 65)
		game._interact(0.016, true, true)
		_check(game.sorted[i] and game.carried == -1, "sorted %d" % i)
	for enemy in game.enemies:
		if enemy.zone == 0: enemy.hp = 0
	_check(game._terminal_ready(0), "triage terminal ready")
	game.pos = M.TERMINALS[0]
	game._interact(1.5, true, false)
	_check(game.stage == 1 and game.terminal_on[0], "triage restored")
	_check(M.walkable(M.GATES[0].get_center(), 14.0, 1, game.cleared), "first gate open")
	_check(_path_to(M.START, M.BLOCKS[1], 85.0, 1, game.cleared), "route to Prisma blockages")
	for i in range(2, 4): game.enemies[i].hp = 0
	for i in 2:
		_check(not M.walkable(M.BLOCKS[i], 14.0, game.stage, game.cleared), "block %d solid" % i)
		game.pos = M.BLOCKS[i] + Vector2(0, 58)
		game._interact(0.9, true, false)
		_check(game.cleared[i], "block %d cleared" % i)
	_check(game._terminal_ready(1), "prisma terminal ready")
	game.pos = M.TERMINALS[1]
	game._interact(1.5, true, false)
	_check(game.stage == 2 and M.walkable(M.GATES[1].get_center(), 14.0, 2, game.cleared), "prisma restored")
	_check(_path_to(M.START, M.TERMINALS[2], 80.0, 2, game.cleared), "route to Iris terminal")
	for i in range(4, 7): game.enemies[i].hp = 0
	for i in range(2, 4):
		game.pos = M.BLOCKS[i] + Vector2(0, 58)
		game._interact(0.9, true, false)
		_check(game.cleared[i], "organic duct %d cleared" % i)
	_check(game._terminal_ready(2), "iris terminal ready")
	game.pos = M.TERMINALS[2]
	game._interact(1.5, true, false)
	_check(game.stage == 3 and game.state == "victory", "district victory")
	set_meta("p17_residue_handoff", {"difficulty": "veteran", "upgrades": ["reserve_cell", "induction_coil", "water_stride"]})
	var transferred: Node2D = load("res://scenes/residues.tscn").instantiate()
	root.add_child(transferred)
	await process_frame
	_check(transferred.max_hp == 7 and transferred.hp == 7, "difficulty and reserve cell transfer")
	_check(transferred.pulse_damage == 2, "induction coil transfers")
	_check(transferred.move_speed == 225.0 and is_equal_approx(transferred.dash_recharge, 1.05), "water stride transfers")
	transferred.queue_free()
	remove_meta("p17_residue_handoff")
	print("RESIDUES_TEST_OK: ", checks, " checks")
	game.queue_free()
	for frame in 3: await process_frame
	quit(0)

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error("RESIDUES_TEST_FAILED: " + message)
		quit(1)

func _path_to(from: Vector2, target: Vector2, reach: float, stage: int, cleared: Array) -> bool:
	var spacing := 28.0
	var origin := Vector2(14, 14)
	var first := Vector2i((from - origin) / spacing)
	var queue: Array[Vector2i] = [first]
	var seen := {first: true}
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		var point := origin + Vector2(cell) * spacing
		if point.distance_to(target) <= reach: return true
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + step
			if seen.has(next): continue
			var next_point := origin + Vector2(next) * spacing
			if not M.walkable(next_point, 14.0, stage, cleared): continue
			seen[next] = true
			queue.append(next)
	return false
