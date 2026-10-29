extends SceneTree
const M = preload("res://scripts/residue_map.gd")
var checks := 0
var traveled := 0.0
var peak_route_ms := 0.0
var failures := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var game: Node2D = load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	_check(M.walkable(M.START, 14.0, 0, game.cleared), "start stands on the avenue")
	_check(M.walkable(Vector2(1440, 550) * M.SCALE, 14.0, 0, game.cleared), "whole public avenue stays accessible")
	_check(not M.walkable(Vector2(410, 680) * M.SCALE, 14.0, 0, game.cleared), "warehouse roof is not traversable")
	_check(M.walkable(Vector2(335, 400) * M.SCALE, 14.0, 0, game.cleared), "human body fits the open loading dock")
	_check(not M.walkable(M.GATES[0].get_center(), 14.0, 0, game.cleared), "recycling entrance locked")
	_check(not M.walkable(M.GATES[1].get_center(), 14.0, 1, game.cleared), "compost entrance locked")
	_check(M.path_between(M.START, M.TERMINALS[1], 0, game.cleared, 65).is_empty(), "factory cannot be reached through walls or its locked dock")
	_check(not M.path_between(Vector2(1070, 750) * M.SCALE, M.BLOCKS[2], 2, game.cleared, 65).is_empty(), "guidance reaches aeration valve from central aisle")
	for i in 7:
		_check(M.walkable(M.ENEMY_POSITIONS[i], 25.0 if i == 6 else 18.0, 2, game.cleared), "enemy %d fits physical ground" % i)
	for i in 4:
		_check(_path_to(M.START, M.ITEMS[i], 35.0, 0, game.cleared), "independent street route to material %d" % i)
		_check(_path_to(M.START, M.BINS[i], 35.0, 0, game.cleared), "independent dock route to sorting bay %d" % i)
	if not _travel(game, M.ITEMS[0], 25): return
	game._interact(0.016, true, true)
	_check(game.carried == 0, "metal picked up")
	if not _travel(game, M.BINS[1], 25): return
	game._interact(0.016, true, true)
	_check(game.carried == -1 and not game.sorted[0], "wrong bay returns material")
	_check(game.bin_lock > 2.0 and game.enemies.size() == 8, "wrong bay locks sorting and alerts a drone")
	_check(M.walkable(game.enemies.back().pos, 18, 0, game.cleared), "alarm drone arrives on the loading apron")
	if not _travel(game, M.ITEMS[0], 25): return
	game._interact(0.016, true, true)
	if not _travel(game, M.BINS[0], 25): return
	game._interact(0.016, true, true)
	_check(not game.sorted[0] and game.carried == 0, "sorting lock prevents early delivery")
	game.bin_lock = 0.0
	game._interact(0.016, true, true)
	_check(game.sorted[0], "metal correctly sorted after reset")
	for i in range(1, 4):
		if not _travel(game, M.ITEMS[i], 25): return
		game._interact(0.016, true, true)
		_check(game.carried == i, "picked material %d" % i)
		if not _travel(game, M.BINS[i], 25): return
		game._interact(0.016, true, true)
		_check(game.sorted[i] and game.carried == -1, "sorted material %d" % i)
	for enemy in game.enemies:
		if enemy.zone == 0: enemy.hp = 0
	if not _travel(game, M.TERMINALS[0], 40): return
	game._interact(1.5, true, false)
	_check(game.stage == 1 and game.terminal_on[0], "sorting restored")
	_check(M.walkable(M.GATES[0].get_center(), 14.0, 1, game.cleared), "recycling dock opened")
	for i in 2:
		if not _travel(game, M.BLOCKS[i], 65): return
		game._interact(0.9, true, false)
		_check(game.cleared[i], "press obstruction %d cleared" % i)
	for enemy in game.enemies:
		if enemy.zone == 1: enemy.hp = 0
	if not _travel(game, M.TERMINALS[1], 40): return
	game._interact(1.5, true, false)
	_check(game.stage == 2 and game.terminal_on[1], "recycling restored")
	for i in range(2, 4):
		if not _travel(game, M.BLOCKS[i], 65): return
		game._interact(0.9, true, false)
		_check(game.cleared[i], "aeration valve %d restored" % i)
	for enemy in game.enemies:
		if enemy.zone == 2: enemy.hp = 0
	if not _travel(game, M.TERMINALS[2], 55): return
	game._interact(1.5, true, false)
	_check(game.stage == 3 and game.state == "victory", "physical street and dock traversal completes district")
	set_meta("p17_residue_handoff", {"difficulty": "veteran", "upgrades": ["reserve_cell", "induction_coil", "water_stride"]})
	var transferred: Node2D = load("res://scenes/residues.tscn").instantiate()
	root.add_child(transferred)
	transferred.set_physics_process(false)
	_check(transferred.max_hp == 7 and transferred.hp == 7, "difficulty and reserve cell transfer")
	_check(transferred.pulse_damage == 2, "induction coil transfer")
	_check(transferred.move_speed == 225 and is_equal_approx(transferred.dash_recharge, 1.05), "mobility upgrade transfer")
	transferred.queue_free()
	remove_meta("p17_residue_handoff")
	print("RESIDUES_TEST_", "OK" if failures == 0 else "FAILED", ": ", checks, " checks; physical route distance: ", int(traveled), "; peak route ms: ", snapped(peak_route_ms, 0.1))
	game.queue_free()
	for frame in 3: await process_frame
	await create_timer(0.12).timeout
	quit(1 if failures else 0)

func _travel(game: Node2D, target: Vector2, reach: float) -> bool:
	var started := Time.get_ticks_usec()
	var path := M.path_between(game.pos, target, game.stage, game.cleared, reach)
	peak_route_ms = maxf(peak_route_ms, (Time.get_ticks_usec() - started) / 1000.0)
	if path.is_empty():
		_check(false, "no street path to " + str(target / M.SCALE))
		quit(1)
		return false
	for point in path:
		for step in 1000:
			if game.pos.distance_to(point) < 0.5: break
			var before: Vector2 = game.pos
			game._move_player((point - before).limit_length(4.0))
			traveled += before.distance_to(game.pos)
			if before.distance_to(game.pos) < 0.01:
				_check(false, "physical route blocked at " + str(game.pos / M.SCALE) + " going to " + str(point / M.SCALE))
				quit(1)
				return false
	_check(game.pos.distance_to(target) <= reach + 1, "walked to " + str(target / M.SCALE))
	return true

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("RESIDUES_TEST_FAILED: " + message)

func _path_to(from: Vector2, target: Vector2, reach: float, stage: int, cleared: Array) -> bool:
	var spacing := 18.0
	var origin := Vector2(9, 9)
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
			if not M.walkable(origin + Vector2(next) * spacing, 14, stage, cleared): continue
			seen[next] = true
			queue.append(next)
	return false
