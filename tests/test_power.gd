extends SceneTree
## Energy district, full mission without teleporting: Lia walks every route in
## 4 px steps, solves the mirrors by shooting them, survives one botched
## Sobrecarga (damage + lockout), crosses the arc corridor, breaks the
## transformer shield, chains the relays inside their window, holds the battery
## ring while venting cells on foot, and rides the elevator. Module effects for
## Isolamento, Sobrecarga controlada and Pulso condutor are checked separately.
const M = preload("res://scripts/power_map.gd")
const Story = preload("res://scripts/power_story.gd")
const TEST_PATH := "user://power_campaign_test.json"
const WATER := ["reserve_cell", "induction_coil", "water_stride"]
var checks := 0
var failures := 0
var traveled := 0.0
var tick_relays := false
var tick_battery := false
var vents := 0
var overload_events := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	set_meta("p17_power_handoff", {"difficulty": "operation", "upgrades": WATER.duplicate()})
	var game: Node2D = load("res://scenes/power.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	_check(game.state == "dialogue" and game.dialogue.size() == Story.INTRO.size(), "district opens on the blackout briefing")
	_check(game.max_hp == 8 and game.hp == 8 and game.pulse_damage == 2, "Water modules carry into Energy")
	game._finish_dialogue()
	_check(game.state == "play", "briefing hands control to the player")
	_geometry(game)
	if _solar(game) and _tower(game) and _battery(game): _elevator(game)
	await _finish(game)

func _finish(game: Node2D) -> void:
	game.queue_free()
	if has_meta("p17_power_handoff"): remove_meta("p17_power_handoff")
	await _modules()
	if FileAccess.file_exists(TEST_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("POWER_TEST_", "OK" if failures == 0 else "FAILED", ": ", checks, " checks; walked ", int(traveled), " px; vents ", vents)
	for frame in 3: await process_frame
	quit(1 if failures else 0)

# ---------------------------------------------------------------- geometry

func _geometry(game: Node2D) -> void:
	_check(M.walkable(M.START, 14.0, 0), "start stands in the maintenance yard")
	for i in M.GATES.size():
		var center: Vector2 = M.world_rect(M.GATES[i][1]).get_center()
		var opens: int = M.GATES[i][2]
		_check(not M.walkable(center, 14.0, opens - 1), "%s closed before stage %d" % [M.GATES[i][0], opens])
		_check(M.walkable(center, 14.0, opens), "%s opens at stage %d" % [M.GATES[i][0], opens])
	for entry in M.ENEMIES + M.EXTRA_ENEMIES:
		_check(M.walkable(M.w(entry[1]), game.ENEMY_RADIUS[entry[0]], 3), "%s at %s fits the floor" % [entry[0], entry[1]])
	for spawn in M.WAVE_SPAWNS: _check(M.walkable(M.w(spawn), 20.0, 2), "battery wave spawn %s is open floor" % spawn)
	_check(M.path_between(M.START, M.w(M.TERMINALS[1]), 0, 60.0).is_empty(), "tower is sealed while the district is dark")
	_check(M.path_between(M.START, M.w(M.RING_CENTER), 1, 30.0).is_empty(), "battery bank sealed until the tower is restored")
	_check(not M.path_between(M.START, M.w(M.ELEVATOR), 3, 60.0).is_empty(), "elevator reachable once the grid is up")

# ---------------------------------------------------------------- Central Solar

func _solar(game: Node2D) -> bool:
	_check(not game.terminal_ready(0), "solar terminal waits for the beam")
	var turns := [2, 3, 3]
	var stands := [Vector2(0, 95), Vector2(0, 95), Vector2(115, -10)]
	for m in 3:
		if not _travel(game, M.w(M.MIRRORS[m]) + stands[m], 40.0): return false
		var before: int = game.mirrors.orientation[m]
		var hits := 0
		for shot in 12:
			if game.mirrors.aligned(m): break
			var previous: int = game.mirrors.orientation[m]
			_shoot(game, M.w(M.MIRRORS[m]) + Vector2(0, -30), 0.4)
			if game.mirrors.orientation[m] != previous: hits += 1
		_check(game.mirrors.aligned(m) and hits == turns[m], "mirror %d turned %d× by pulses from %d to target" % [m, hits, before])
		_check(game.mirrors.lit_count() == m + 2, "beam now reaches node %d" % (m + 2))
	for enemy in game.enemies:
		if enemy.zone == 0:
			for hit in 30:
				if enemy.hp <= 0: break
				game._hit_enemy(enemy, 1)
	game.tick_world(0.016)
	_check(game.mirrors.solved and game.toast.begins_with("FEIXE"), "collector lit, beam locked")
	_check(game.zone_alive(0) == 0 and game.terminal_ready(0), "solar terminal ready once drones are down")
	if not _travel(game, M.w(M.TERMINALS[0]), 60.0, "terminal 0"): return false
	var candidate: Dictionary = game.interaction_candidate()
	_check(candidate.get("kind", "") == "terminal", "terminal prompt reachable on foot")
	var hp: int = game.hp
	game._interact(0.016, true, true)
	var overload = game.overloads[0]
	_check(overload.running, "E starts the Sobrecarga")
	overload.phase = 0.0
	game._interact(0.016, true, true)
	_check(game.hp == hp - 1 and overload.cooldown >= 2.9 and not overload.running, "press outside the window discharges and locks the console")
	_check(game.effects.any(func(e: Dictionary) -> bool: return e.kind == "bolt"), "discharge arcs from the console to Lia")
	game.invuln = 0.0
	game._interact(0.016, true, true)
	_check(game.hp == hp - 1 and overload.cooldown > 0.0 and not overload.running, "locked console ignores presses")
	overload.tick(3.1)
	game._interact(0.016, true, true)
	for center in [0.5, 0.28, 0.71]:
		overload.phase = center
		game._interact(0.016, true, true)
	_check(game.stage == 1 and overload.done, "three pulses in the moving window restore the Central Solar")
	_check(game.state == "dialogue" and game.dialogue[0].speaker == "beatrix_record", "first Beatrix record plays")
	game._finish_dialogue()
	return true

# ---------------------------------------------------------------- Torre Norte

func _tower(game: Node2D) -> bool:
	var arc = game.arcs[0]
	var idle_time := -1.0
	var active_time := -1.0
	for step in 400:
		var t := step * 0.01
		if idle_time < 0.0 and arc.state(t) == "idle": idle_time = t
		if active_time < 0.0 and arc.state(t) == "active": active_time = t
	if not _travel(game, (arc.a + arc.b) * 0.5, 12.0): return false
	game.hp = game.max_hp
	game.invuln = 0.0
	game.clock = idle_time
	game._update_arcs(0.016)
	_check(game.hp == game.max_hp, "idle pylons let Lia through")
	game.clock = active_time
	game.dash_time = 0.1
	game._update_arcs(0.016)
	_check(game.hp == game.max_hp, "dashing through a live arc is safe")
	game.dash_time = 0.0
	game._update_arcs(0.016)
	_check(game.hp == game.max_hp - 1, "standing in a live arc shocks Lia")
	var scout: Dictionary = {}
	for enemy in game.enemies:
		if enemy.zone == 1 and enemy.kind == "scout": scout = enemy
	var scout_home: Vector2 = scout.pos
	scout.pos = (arc.a + arc.b) * 0.5 + Vector2(0, 10)
	var scout_hp: int = scout.hp
	game._update_arcs(0.016)
	_check(scout.hp == scout_hp - 2, "arcs damage drones lured into them")
	scout.pos = scout_home
	game.hp = game.max_hp
	game.invuln = 0.0
	game.clock = idle_time
	# Corrupted transformer: shields every drone of its installation in range.
	var transformer: Dictionary = {}
	for enemy in game.enemies:
		if enemy.zone == 1 and enemy.kind == "transformer": transformer = enemy
	_check(game.shielded(scout) and not game.shielded(transformer), "drones near the transformer are shielded")
	scout_hp = scout.hp
	game.bullets.append({"pos": scout.pos + Vector2(-60, -8), "vel": Vector2(640, 0), "hostile": false, "life": 1.0, "damage": 2})
	for frame in 20: game._update_bullets(0.016)
	_check(scout.hp == scout_hp and game.effects.any(func(e: Dictionary) -> bool: return e.kind == "shield"), "shielded drone deflects pulses")
	for hit in 30:
		if transformer.hp <= 0: break
		game._hit_enemy(transformer, 1)
	_check(not game.shielded(scout) and game.toast.begins_with("TRANSFORMADOR"), "destroying the transformer drops the shields")
	# Coils project a live arc between them that eats pulses.
	var links: Array[Dictionary] = game.coil_links()
	_check(links.size() == 1, "coil pair is linked")
	for step in 100:
		if game.coil_links()[0].active: break
		game.clock += 0.05
	links = game.coil_links()
	var middle: Vector2 = (links[0].a + links[0].b) * 0.5
	var bullets_before: int = game.bullets.size()
	game.bullets.append({"pos": middle + Vector2(-40, 0), "vel": Vector2(640, 0), "hostile": false, "life": 1.0, "damage": 1})
	for frame in 10: game._update_bullets(0.016)
	_check(game.bullets.size() == bullets_before, "live coil arc blocks pulses")
	game.clock = idle_time
	# Relays: all three must hold charge at once; Lia walks between them.
	var stands := [Vector2(0, 95), Vector2(-110, 30), Vector2(-110, 0)]
	tick_relays = true
	for r in 3:
		if not _travel(game, M.w(M.RELAYS[r]) + stands[r], 45.0): return false
		for shot in 6:
			if game.relays.lit(r): break
			_shoot(game, M.w(M.RELAYS[r]) + Vector2(0, -30), 0.2)
		_check(game.relays.lit(r), "relay %d energized by a pulse" % r)
	tick_relays = false
	_check(game.relays.solved and game.toast.begins_with("RELÉS"), "relay chain synchronized within the window (%.1f s left on the first)" % game.relays.charge[0])
	for enemy in game.enemies:
		if enemy.zone == 1:
			for hit in 30:
				if enemy.hp <= 0: break
				game._hit_enemy(enemy, 1)
	_check(game.terminal_ready(1), "tower terminal ready")
	if not _travel(game, M.w(M.TERMINALS[1]), 60.0, "terminal 1"): return false
	var overload = game.overloads[1]
	game._interact(0.016, true, true)
	for pulse in 3:
		for frame in 4000:
			overload.tick(0.008)
			if overload.in_window(): break
		game._interact(0.016, true, true)
	_check(game.stage == 2 and overload.done, "surging Sobrecarga timed by watching the needle restores the tower")
	_check(game.state == "dialogue" and game.dialogue[0].speaker == "beatrix_record", "second Beatrix record plays")
	game._finish_dialogue()
	return true

# ---------------------------------------------------------------- Banco de Baterias

func _battery(game: Node2D) -> bool:
	var ring: Vector2 = M.w(M.RING_CENTER)
	if not _travel(game, ring, 12.0): return false
	var before: int = game.enemies.size()
	tick_battery = true
	var elapsed := 0.0
	while not game.battery.done and elapsed < 160.0:
		_battery_tick(game, 0.05)
		elapsed += 0.05
		for i in 3:
			if game.battery.started and not game.battery.done and game.battery.danger(i):
				if not _travel(game, M.w(M.CELL_CONSOLES[i]), 50.0, "console %d" % i): return false
				var candidate: Dictionary = game.interaction_candidate()
				_check(candidate.get("kind", "") == "console" and candidate.index == i, "console %d reachable" % i)
				game._interact(0.016, true, true)
				vents += 1
				if not _travel(game, ring, 12.0): return false
	tick_battery = false
	_check(game.battery.done and game.stage == 3, "reserve fully charged on foot (%.0f s)" % elapsed)
	_check(overload_events == 0, "no cell overloaded while Lia kept venting")
	_check(game.enemies.size() - before == 9, "four drone waves arrived during the charge")
	_check(game.zone_alive(2) == 0, "restored grid reclaims the battery drones")
	_check(game.effects.any(func(e: Dictionary) -> bool: return e.kind == "emp"), "EMP ring plays")
	_check(game.state == "dialogue" and game.dialogue[0].speaker == "beatrix_record", "third Beatrix record plays")
	game._finish_dialogue()
	return true

func _battery_tick(game: Node2D, dt: float) -> void:
	var charge: float = game.battery.charge
	var surging: int = game.battery.surging
	game._update_battery(dt)
	if game.battery.charge < charge - 0.05 and game.battery.surging != surging: overload_events += 1

# ---------------------------------------------------------------- Elevator

func _elevator(game: Node2D) -> bool:
	if not _travel(game, M.w(M.ELEVATOR), 60.0, "porta do elevador"): return false
	_check(game.interaction_candidate().get("kind", "") == "elevator", "elevator prompt reachable")
	game._interact(0.5, true, false)
	game._interact(0.016, false, false)
	_check(game.hold_progress == 0.0 and game.state == "play", "releasing E cancels the elevator")
	game.campaign = game.CampaignProgress.new()
	game.campaign.path = TEST_PATH
	_check(game.campaign.complete_water("operation", WATER) == OK and game.campaign.complete_residues("operation", "steady_hand") == OK, "test profile prepared")
	game._interact(1.2, true, false)
	_check(game.state == "dialogue" and game.after_dialogue == "victory", "holding E rides the elevator")
	game._finish_dialogue()
	_check(game.state == "victory" and game.victory_notice.ends_with("PROGRESSO SALVO"), "victory saves Energy")
	var reloaded = game.CampaignProgress.new()
	reloaded.path = TEST_PATH
	reloaded.load_progress()
	_check(reloaded.energy_completed and reloaded.residue_upgrade == "steady_hand", "Energy completion survives a reload")
	return true

# ---------------------------------------------------------------- modules

func _modules() -> void:
	set_meta("p17_power_handoff", {"difficulty": "operation", "upgrades": ["grounded_suit", "steady_hand", "conductive_pulse"]})
	var game: Node2D = load("res://scenes/power.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game._finish_dialogue()
	var hp: int = game.hp
	for shock in 2:
		game.invuln = 0.0
		game._damage(true)
	_check(game.hp == hp - 1, "Isolamento halves electrical damage")
	game.invuln = 0.0
	game._damage(false)
	_check(game.hp == hp - 2, "Isolamento does not affect bolts")
	_check(is_equal_approx(game.overloads[0].half_width, 0.125 * 1.3) and is_equal_approx(game.relays.window, 7.0 * 1.3), "Sobrecarga controlada widens windows")
	var first: Dictionary = {}
	var second: Dictionary = {}
	for enemy in game.enemies:
		if enemy.zone == 0 and enemy.kind == "scout":
			if first.is_empty(): first = enemy
			elif second.is_empty(): second = enemy
	second.pos = first.pos + Vector2(90, 0)
	var second_hp: int = second.hp
	game.bullets.append({"pos": first.pos + Vector2(-60, -8), "vel": Vector2(640, 0), "hostile": false, "life": 1.0, "damage": 1})
	for frame in 20: game._update_bullets(0.016)
	_check(second.hp == second_hp - 1, "Pulso condutor arcs to a nearby drone")
	# Spark dash leaves a live trail on the floor.
	var spark: Dictionary = {}
	for enemy in game.enemies:
		if enemy.kind == "spark" and enemy.zone == 0: spark = enemy
	spark.engaged = true
	spark.aim = Vector2.LEFT
	game._enemy_attack(spark, 1.65, 1.0)
	_check(spark.phase == "dash", "spark winds up into a dash")
	game.pos = spark.pos + Vector2(-500, 0)
	for frame in 6: game._update_enemies(0.05)
	_check(game.trails.size() > 0, "dash leaves an electric trail")
	game.hp = game.max_hp
	game.shock_debt = 0.0
	game.invuln = 0.0
	game.pos = (game.trails[0].a + game.trails[0].b) * 0.5
	game._update_trails(0.01)
	game.invuln = 0.0
	game._update_trails(0.01)
	_check(game.hp == game.max_hp - 1, "trail shocks Lia (halved by Isolamento)")
	game.hp = 1
	game.shock_debt = 0.0
	game.invuln = 0.0
	game._damage(false)
	_check(game.state == "defeat", "zero integrity ends the attempt")
	game.queue_free()
	remove_meta("p17_power_handoff")
	await process_frame

# ---------------------------------------------------------------- helpers

func _shoot(game: Node2D, target: Vector2, settle: float) -> void:
	var direction: Vector2 = (target - game.pos).normalized()
	game.aim = direction
	game.fire_cd = 0.0
	game._fire(target)
	for frame in int(settle / 0.016) + 20:
		game._update_bullets(0.016)
		game.mirrors.tick(0.016)
		if tick_relays: game.relays.tick(0.016)

func _travel(game: Node2D, target: Vector2, reach: float, body: String = "") -> bool:
	var path: PackedVector2Array = M.path_between(game.pos, target, game.stage, reach, 14.0, not body.is_empty(), body)
	if path.is_empty():
		_check(false, "no route from %s to %s" % [game.pos / M.SCALE, target / M.SCALE])
		return false
	for point in path:
		for step in 2000:
			if game.pos.distance_to(point) < 0.5: break
			var before: Vector2 = game.pos
			game._move_player((point - before).limit_length(4.0))
			var moved: float = before.distance_to(game.pos)
			traveled += moved
			var dt: float = moved / game.move_speed
			if tick_relays: game.relays.tick(dt)
			if tick_battery: _battery_tick(game, dt)
			if moved < 0.01:
				_check(false, "route blocked at %s towards %s" % [game.pos / M.SCALE, point / M.SCALE])
				return false
	_check(game.pos.distance_to(target) <= reach + 1.0, "walked to %s" % (target / M.SCALE))
	return true

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("POWER_TEST_FAILED: " + message)
