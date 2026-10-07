extends SceneTree
## Run with --headless --path . --script tests/test_simulation.gd.
## The campaign bot receives invulnerability only; weapons and enemy HP are real.

const S = preload("res://scripts/simulation.gd")
const W = preload("res://scripts/world.gd")
const DT: float = 1.0 / 60.0
const CELL: float = 20.0
var checks: int = 0
var failures: Array[String] = []
var grids: Dictionary = {}
var bot_frames: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_shots_and_walls()
	_test_damage_and_warnings()
	_test_dash_boundary()
	_test_activation_lock()
	_test_campaign()
	print("SIMULATION_TEST_%s: %d checks; %d bot frames; %d failures" % ["OK" if failures.is_empty() else "FAILED", checks, bot_frames, failures.size()])
	print("BOT_SCOPE: real movement, normal weapon damage, live enemy AI; invulnerability enabled only to isolate progression and route reachability.")
	quit(0 if failures.is_empty() else 1)


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _stationary_target(sim: P17Simulation, point: Vector2) -> Dictionary:
	var enemy: Dictionary = sim.enemies[0]
	sim.enemies.clear()
	enemy["pos"] = point
	enemy["phase"] = "windup"
	enemy["warning"] = 999.0
	enemy["cooldown"] = 999.0
	sim.enemies.append(enemy)
	return enemy


func _test_shots_and_walls() -> void:
	var sim: P17Simulation = S.new()
	sim.start()
	sim.pos = Vector2(740, 1450)
	var target: Dictionary = _stationary_target(sim, Vector2(900, 1450))
	var health: int = int(target["hp"])
	for frame in 25:
		sim.tick(DT, Vector2.ZERO, target["pos"], true, false, false)
	check(sim.shots >= 2 and int(target["hp"]) < health, "Normal player pulses damage a target through actual swept collision")
	check(sim.hp == sim.max_hp, "Player projectiles do not damage their own shooter")

	sim.start()
	sim.pos = Vector2(533, 1215)
	target = _stationary_target(sim, Vector2(533, 1328))
	health = int(target["hp"])
	check(W.walkable(sim.pos, S.PLAYER_RADIUS, 0) and W.walkable(target["pos"], 17.0, 0), "Wall regression fixture places both actors on legal ground")
	sim.pulse_speed = 12000.0
	for frame in 40:
		sim.tick(DT, Vector2.ZERO, target["pos"], true, false, false)
	check(sim.shots > 0 and int(target["hp"]) == health, "A 12,000 px/s projectile cannot tunnel through the pump between two valid actors")
	check(sim.bullets.is_empty(), "Blocked projectiles are consumed at the obstacle")

	# Closed gate is crossed by a whole projectile step, not just an endpoint sample.
	sim.start()
	sim.pos = Vector2(770, 975)
	target = _stationary_target(sim, Vector2(770, 875))
	health = int(target["hp"])
	sim.pulse_speed = 15000.0
	for frame in 20:
		sim.tick(DT, Vector2.ZERO, target["pos"], true, false, false)
	check(int(target["hp"]) == health, "Closed progression gate blocks swept projectiles in the bridge")


func _hostile_at_player(sim: P17Simulation) -> void:
	sim.bullets.append({"pos": sim.pos, "vel": Vector2.RIGHT * 190.0, "hostile": true,
		"damage": 1, "life": 1.0, "radius": 4.0})


func _test_damage_and_warnings() -> void:
	var sim: P17Simulation = S.new()
	sim.start()
	sim.invuln = 0.0
	sim.pos = Vector2(740, 1450)
	var enemy: Dictionary = sim.enemies[0]
	sim.enemies.clear()
	enemy["pos"] = Vector2(900, 1450)
	enemy["cooldown"] = 0.0
	sim.enemies.append(enemy)
	sim.tick(DT, Vector2.ZERO, enemy["pos"], false, false, false)
	check(float(enemy["warning"]) >= 0.5 and sim.bullets.is_empty(), "Enemy enters a visible warning before firing")
	for frame in 28:
		sim.tick(DT, Vector2.ZERO, enemy["pos"], false, false, false)
	check(sim.bullets.is_empty() and sim.hp == 6, "Enemy cannot fire or inflict ranged damage during the first half-second warning")
	for frame in 75:
		sim.tick(DT, Vector2.ZERO, enemy["pos"], false, false, false)
	check(sim.hp == 5, "A live scout fires a real hostile pulse that damages Lia")
	enemy["cooldown"] = 999.0
	sim.bullets.clear()
	var previous: int = sim.hp
	_hostile_at_player(sim)
	_hostile_at_player(sim)
	sim.tick(DT, Vector2.ZERO, enemy["pos"], false, false, false)
	check(sim.hp == previous, "Existing grace period rejects simultaneous new projectile impacts")
	for frame in 60:
		sim.tick(DT, Vector2.ZERO, enemy["pos"], false, false, false)
	_hostile_at_player(sim)
	_hostile_at_player(sim)
	sim.tick(DT, Vector2.ZERO, enemy["pos"], false, false, false)
	check(sim.hp == previous - 1, "After grace expires, simultaneous projectiles inflict exactly one integrity loss")
	check(sim.invuln > 0.7, "A damaging projectile renews the approximately 0.8-second grace period")


func _test_dash_boundary() -> void:
	var sim: P17Simulation = S.new()
	sim.start()
	sim.pos = Vector2(125, 1490)
	check(W.walkable(sim.pos, S.PLAYER_RADIUS, sim.stage), "Boundary dash fixture starts on safe ground beside the outer canal")
	_stationary_target(sim, Vector2(900, 1490))
	sim.invuln = 0.0
	_hostile_at_player(sim)
	sim.tick(DT, Vector2.LEFT, sim.pos + Vector2.LEFT * 100.0, false, true, false)
	check(sim.hp == 6 and sim.invuln > 0.1 and sim.events.has("dash"), "Starting a dash grants its temporary damage immunity")
	var legal: bool = true
	for frame in 24:
		sim.tick(DT, Vector2.LEFT, sim.pos + Vector2.LEFT * 100.0, false, false, false)
		legal = legal and W.walkable(sim.pos, S.PLAYER_RADIUS, sim.stage)
	check(legal and sim.pos.x >= 114.0, "Dash and subsequent movement stay out of the canal at every step")
	sim.tick(DT, Vector2.RIGHT, sim.pos + Vector2.RIGHT * 100.0, false, true, false)
	check(not sim.events.has("dash"), "Dash cannot restart while its cooldown is active")
	check(sim.dash_time == 0.0 and sim.velocity.length() <= sim.move_speed + 0.01, "Expired dash does not retain its high-speed momentum")


func _test_activation_lock() -> void:
	var sim: P17Simulation = S.new()
	sim.start()
	sim.pos = W.GOALS[0]
	sim.invuln = 999.0
	for frame in 150:
		sim.tick(DT, Vector2.ZERO, sim.pos + Vector2.UP, false, false, true)
	check(sim.state == "combat" and sim.repair == 0.0 and sim.restored == 0, "Holding E at the terminal cannot bypass the combat encounter")
	check(not sim.choose_upgrade(0), "An upgrade cannot be selected before a completed repair")
	check(not W.walkable(W.GATES[0].get_center(), 14.0, sim.stage), "First bridge remains physically gated before activation")


func _grid(stage: int) -> AStarGrid2D:
	if grids.has(stage):
		return grids[stage]
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, int(W.SIZE.x / CELL) + 1, int(W.SIZE.y / CELL) + 1)
	grid.cell_size = Vector2.ONE * CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			grid.set_point_solid(Vector2i(x, y), not W.walkable(Vector2(x, y) * CELL, S.PLAYER_RADIUS + 1.0, stage))
	grids[stage] = grid
	return grid


func _nearest_cell(grid: AStarGrid2D, point: Vector2) -> Vector2i:
	var center: Vector2i = Vector2i((point / CELL).round())
	for radius in 6:
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell: Vector2i = center + Vector2i(x, y)
				if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
					return cell
	return center


func _path(sim: P17Simulation, destination: Vector2) -> PackedVector2Array:
	var grid: AStarGrid2D = _grid(sim.stage)
	var path := grid.get_point_path(_nearest_cell(grid, sim.pos), _nearest_cell(grid, destination))
	# A replanned path starts at the nearest cell center, often behind the bot.
	# Returning to it every 12 frames can oscillate forever on entirely free floor.
	# Skip only that start node, and only after testing the actual body-sized edge.
	if path.size()>1 and sim.pos.distance_to(path[0])<CELL*0.75:
		var clear := true
		var samples := maxi(1,int(ceil(sim.pos.distance_to(path[1])/3.0)))
		for index in range(samples+1):
			if not W.walkable(sim.pos.lerp(path[1],float(index)/samples),S.PLAYER_RADIUS+1,sim.stage):
				clear=false
				break
		if clear: path.remove_at(0)
	return path


func _clear_sight(origin: Vector2, destination: Vector2, stage: int) -> bool:
	var count: int = maxi(1, int(ceil(origin.distance_to(destination) / 5.0)))
	for index in count + 1:
		if not W.walkable(origin.lerp(destination, float(index) / float(count)), 4.0, stage):
			return false
	return true


func _fight(sim: P17Simulation) -> bool:
	var path: PackedVector2Array = PackedVector2Array()
	var target: Vector2 = sim.pos
	var move: Vector2 = Vector2.ZERO
	for frame in 30000:
		if sim.state != "combat":
			return sim.state == "activation"
		sim.invuln = 999.0
		var distance: float = INF
		for enemy in sim.enemies:
			var enemy_pos: Vector2 = enemy["pos"]
			if sim.pos.distance_to(enemy_pos) < distance:
				target = enemy_pos
				distance = sim.pos.distance_to(enemy_pos)
		# A low terminal can clear Lia's center line but obstruct the actual rifle.
		# The bot must reposition as a player would; collision/damage remain unchanged.
		var aim: Vector2 = (target-sim.pos).normalized()
		var muzzle: Vector2 = sim.pos+S.LIA_POSE.pose(aim,0,false).muzzle
		var can_fire: bool = sim._wall_fraction(sim.pos,muzzle,3)==INF and sim._wall_fraction(muzzle,target,3)==INF
		var need_move: bool = distance > 240.0 or not _clear_sight(sim.pos, target, sim.stage) or not can_fire
		if need_move:
			if frame % 12 == 0 or path.is_empty():
				path = _path(sim, target)
			while not path.is_empty() and sim.pos.distance_to(path[0]) < 7.0:
				path.remove_at(0)
			move = (path[0] - sim.pos).normalized() if not path.is_empty() else Vector2.ZERO
		else:
			move = Vector2.ZERO
		sim.tick(DT, move, target, true, false, false)
		bot_frames += 1
	if not sim.enemies.is_empty():
		print("BOT_STALL stage=", sim.stage, " pos=", sim.pos, " target=", target, " enemies=", sim.enemies)
	return false


func _walk_to(sim: P17Simulation, destination: Vector2) -> bool:
	var path: PackedVector2Array = _path(sim, destination)
	if path.is_empty():
		return false
	for frame in 10000:
		if sim.pos.distance_to(destination) < 20.0:
			return true
		while not path.is_empty() and sim.pos.distance_to(path[0]) < 6.0:
			path.remove_at(0)
		var target: Vector2 = path[0] if not path.is_empty() else destination
		sim.tick(DT, (target - sim.pos).normalized(), destination, false, false, false)
		bot_frames += 1
	return false


func _test_saves_and_retry(snapshot: Dictionary) -> void:
	var sim: P17Simulation = S.new()
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	check(sim.load_data(decoded), "Checkpoint loads after a real JSON serialization round trip")
	check(sim.stage == 1 and sim.restored == 1 and sim.chosen == ["reserve_cell"] and sim.hp == 8 and sim.max_hp == 8, "Loaded checkpoint reconstructs completed stage and selected upgrade stats")
	check(sim.pos == W.CHECKPOINTS[1], "Loading places Lia at the stage's safe checkpoint")
	var malformed: Array = [
		{}, {"version": 2, "stage": 1, "chosen": ["reserve_cell"]},
		{"version": 1, "stage": 4, "chosen": []}, {"version": 1, "stage": 1.5, "chosen": []},
		{"version": 1, "stage": -1, "chosen": []}, {"version": 1, "stage": "1", "chosen": ["reserve_cell"]},
		{"version": 1, "stage": 1, "chosen": ["invented_upgrade"]},
		{"version": 1, "stage": 1, "chosen": ["water_stride"]},
		{"version": 1, "stage": 1, "chosen": []}, {"version": 1, "stage": 1, "chosen": "reserve_cell"},
		{"version": true, "stage": 0, "chosen": []},
	]
	var original: String = JSON.stringify(sim.save_data())
	for bad in malformed:
		check(not sim.load_data(bad) and JSON.stringify(sim.save_data()) == original, "Malformed save is rejected without mutating current progress: " + str(bad))
	decoded["pos"] = [-9000, -9000]
	decoded["hp"] = 500
	check(sim.load_data(decoded) and sim.pos == W.CHECKPOINTS[1] and sim.hp == 8, "Untrusted saved position and health fields cannot bypass checkpoint reconstruction")

	# Remove one defender using normal shots, then defeat Lia with collision impacts.
	sim.pos = Vector2(770, 730)
	sim.invuln = 999.0
	for enemy in sim.enemies:
		enemy["phase"] = "windup"
		enemy["warning"] = 999.0
	var first: Dictionary = sim.enemies[0]
	first["pos"] = Vector2(920, 730)
	for frame in 300:
		sim.tick(DT, Vector2.ZERO, Vector2(920, 730), true, false, false)
		if sim.enemies.size() < 4:
			break
	check(sim.enemies.size() == 3, "Retry fixture defeats one current-stage defender with normal projectiles")
	sim.bullets.clear()
	for impact in 8:
		sim.invuln = 0.0 # Isolate lethal collision behavior; grace timing has its own test.
		_hostile_at_player(sim)
		sim.tick(DT, Vector2.ZERO, sim.pos + Vector2.UP, false, false, false)
	check(sim.state == "defeat" and sim.hp == 0, "Eight hostile impacts defeat an upgraded eight-integrity player")
	sim.retry()
	check(sim.state == "combat" and sim.enemies.size() == 4 and sim.stage == 1, "Retry rebuilds only the complete current encounter")
	check(sim.restored == 1 and sim.chosen == ["reserve_cell"] and sim.hp == 8 and sim.max_hp == 8, "Retry preserves restored systems and chosen maximum-integrity upgrade")
	check(sim.pos == W.CHECKPOINTS[1] and W.walkable(W.GATES[0].get_center(), 14.0, sim.stage), "Retry uses a safe checkpoint and keeps the previously opened bridge accessible")


func _test_campaign() -> void:
	var sim: P17Simulation = S.new()
	sim.start()
	var expected_waves: Array[int] = [3, 4, 5, 5]
	for stage in 4:
		check(sim.stage == stage and sim.enemies.size() == expected_waves[stage], "Campaign stage %d creates its expected live encounter" % stage)
		if stage == 3:
			check(str(sim.enemies[4]["kind"]) == "boss" and int(sim.enemies[4]["hp"]) == 80, "Final encounter contains four defenders plus the full-health boss")
		var cleared: bool = _fight(sim)
		check(cleared, "Bot clears stage %d with real normal-damage projectiles" % stage)
		if not cleared:
			return
		check(sim.state == "activation" and sim.restored == stage, "Defeating stage %d alone does not activate its terminal" % stage)
		var reached: bool = _walk_to(sim, W.GOALS[stage])
		check(reached, "Bot physically reaches terminal %d without teleporting" % stage)
		if not reached:
			return
		for frame in 35:
			sim.tick(DT, Vector2.ZERO, W.GOALS[stage], false, false, true)
		check(sim.repair > 0.0 and sim.repair < 1.0, "Repair %d exposes partial normalized progress" % stage)
		sim.tick(DT, Vector2.ZERO, W.GOALS[stage], false, false, false)
		check(sim.repair == 0.0, "Releasing E interrupts repair %d" % stage)
		for frame in 112:
			sim.tick(DT, Vector2.ZERO, W.GOALS[stage], false, false, true)
		check(sim.restored == stage + 1 and is_equal_approx(sim.repair, 1.0), "Holding E completes restoration %d exactly once" % stage)
		if stage < 3:
			check(sim.state == "upgrade" and sim.upgrade_options().size() == 3, "Restoration %d presents three upgrade options" % stage)
			var prior: Vector2 = sim.pos
			var options: Array[Dictionary] = sim.upgrade_options()
			check(options[0]["id"] != options[1]["id"] and options[1]["id"] != options[2]["id"] and options[0]["id"] != options[2]["id"], "Upgrade cards for stage %d have three distinct choices" % stage)
			check(sim.choose_upgrade([1, 0, 2][stage]), "A valid upgrade choice advances stage %d" % stage)
			check(sim.pos == prior and sim.stage == stage + 1, "Choosing upgrade %d preserves Lia's exact world position" % stage)
			for gate in 3:
				check(W.walkable(W.GATES[gate].get_center(), 14.0, sim.stage) == (gate <= stage), "After stage %d, gate %d has the correct physical open state" % [stage, gate])
			if stage == 0:
				_test_saves_and_retry(sim.save_data())
		else:
			check(sim.state == "victory" and sim.restored == 4 and sim.kills == 17, "All four restorations and 17 real defeats produce victory")
			check(sim.chosen.size() == 3 and sim.enemies.is_empty() and sim.bullets.is_empty(), "Victory retains three chosen upgrades and clears combat hazards")
	print("CAMPAIGN: elapsed simulated seconds=", snappedf(sim.elapsed, 0.01), " kills=", sim.kills, " shots=", sim.shots, " chosen=", sim.chosen)
