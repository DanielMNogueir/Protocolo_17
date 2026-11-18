extends SceneTree
## Walks the real scene with the same movement, firing and interaction path
## as keyboard/mouse input. Only the clock and cinematic skips are accelerated.
const Scene = preload("res://scenes/core.tscn")
const Map = preload("res://scripts/core_map.gd")
const Progress = preload("res://scripts/campaign_progress.gd")
const PATH := "user://test_core_playthrough.json"
const DT := 1.0 / 60.0
const WATER := ["reserve_cell", "induction_coil", "living_circuit"]
var failures := 0
var game: Node2D
var pilot_target := Vector2.INF
var waypoint := Vector2.ZERO
var path_age := 0.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.remove_absolute(PATH)
	var saved := Progress.new()
	saved.path = PATH
	_check(saved.complete_water("story", WATER) == OK, "Seed a Water completion")
	_check(saved.complete_residues("story", "steady_hand") == OK, "Seed a Residues completion")
	_check(saved.complete_energy("story") == OK, "Seed an Energy completion")
	var levels := ["story", "operation", "veteran"]
	for i in levels.size():
		var side := "human" if i != 1 else "ai"
		if await _play(levels[i], side):
			print("%s → %s: %.1f s, %d drones, %d falls" % [levels[i], game.ending.result, game.elapsed, game.kills, game.deaths])
		game.queue_free()
		await process_frame
	var reloaded := Progress.new()
	reloaded.path = PATH
	reloaded.load_progress()
	_check(reloaded.core_completed and reloaded.endings_seen.size() == 2, "Both finales survive a reload")
	DirAccess.remove_absolute(PATH)
	print("CORE_OK" if failures == 0 else "CORE_FAILED")
	for frame in 3: await process_frame
	quit(0 if failures == 0 else 1)


func _play(level: String, side: String) -> bool:
	set_meta("p17_core_handoff", {"difficulty": level, "upgrades": WATER + ["steady_hand"], "save_path": PATH})
	game = Scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_muted(true)
	game.boss._rng.seed = 17
	await process_frame
	_dialogue()
	var ok := _travel(Map.TERMINAL, 64) and _check(game.near(Map.TERMINAL, 78), "Player reaches the command channel")
	if not ok:
		return false
	for i in 72:
		if game.state == "gallery": _step(Vector2.ZERO, Map.TERMINAL, true)
	_check(game.channel_read and game.state == "dialogue", "Hold E reads the terminal")
	_dialogue()
	if not _travel(Map.STAIRS.get_center(), 8.0, "gallery"):
		return false
	_check(game.state == "arrival", "Lia climbs the stairs")
	game._update_arrival(0.6)
	game._update_arrival(0.72)
	_dialogue()
	var cutoff: float = game.elapsed + 660.0
	while game.state in ["arena", "collapse", "dialogue", "defeat"] and game.elapsed < cutoff and game.deaths < 5:
		match game.state:
			"defeat":
				game._retry()
				game.boss._rng.seed = 17 + game.deaths
			"collapse":
				game._physics_process(0.05)
			"dialogue":
				_dialogue()
			"arena":
				_fight()
	if not _check(game.state == "choice", "%s pilot finishes phase %s alive (HP %s, falls %s)" %
			[level, game.boss.phase, game.hp, game.deaths]):
		return false
	if not _listen("human") or not _listen("ai"):
		return false
	_check(game.choice.can_decide() and game.choice.weighed, "Both arguments lead to Lia's reflection")
	if not _travel(Map.CONSOLES[0 if side == "human" else 1], 69.0):
		return false
	_step(Vector2.ZERO, game.pos, false)
	for frame in 160:
		if game.state != "choice": break
		_step(Vector2.ZERO, game.pos, true)
	_check(game.state == "ending" and game.choice.result == ("ai" if side == "ai" else "humanity"), "Holding selects the correct ending")
	game._advance_ending(false, 3.1)
	_dialogue()
	if side == "human":
		if not _travel(Map.OVERLOOK, 19.0, "overlook"):
			return false
		_dialogue()
	for i in 3:
		game._advance_ending(false, 8.6)
	game._advance_ending(false, 6.0)
	_check(game.state == "credits" and game.choice.result in game.campaign.endings_seen, "Epilogue hands off to credits and saves")
	game._action("skip_credits")
	_check(game.state == "complete", "Skipping credits reaches the campaign screen")
	game._action("again")
	return _check(game.state == "choice" and game.choice.can_decide(), "Complete screen returns to choice with both arguments")


func _fight() -> void:
	var boss: RefCounted = game.boss
	var movement := Vector2.ZERO
	var target: Vector2 = boss.core_position()
	var held := false
	var fire := true
	var burst: bool = game.secondary_cd <= 0.0
	var dash := false
	var enemy := _closest_spark()
	match boss.phase:
		1:
			var nearest: int = game._nearest_pillar(false)
			var point := Map.pillars()[nearest]
			target = enemy if enemy.is_finite() else point
			var pillar = boss.pillars[nearest]
			var distance: float = game.pos.distance_to(point)
			if distance <= 73.0 and pillar.available():
				held = not game._e_previous and (not pillar.running or pillar.in_window())
			elif distance > 65.0:
				movement = _steer(point)
			burst = burst and enemy.is_finite()
		2:
			if boss.burn > 0.0:
				movement = _orbit(240.0)
			else:
				var puzzle: Dictionary = game.objective_data()
				var mirror: Vector2 = puzzle.point
				var position := mirror + mirror.direction_to(Map.CENTER) * 107
				target = mirror
				var threat := enemy.is_finite() and Vector2(game.pos).distance_to(enemy) < 145.0
				if threat:
					target = enemy
				if Vector2(game.pos).distance_to(position) > 20.0:
					movement = _steer(position)
				burst = burst and threat
		3:
			movement = _orbit(250.0)
			dash = boss.attack == "aimed" and boss.fire_time > 0.0
	var danger := _dodge_projectile()
	if danger != Vector2.ZERO and (boss.phase > 1 or game.active_pillar < 0):
		movement = danger
		dash = true
	_step(movement, target, held, fire, dash, burst)


func _closest_spark() -> Vector2:
	var result := Vector2.INF
	var closest := INF
	for enemy: Dictionary in game.enemies:
		var at: Vector2 = enemy.pos
		var distance: float = game.pos.distance_squared_to(at)
		if enemy.warp <= 0.0 and distance < closest and Map.line_clear(game.pos, at, 2.0, game.map_phase()):
			result = at
			closest = distance
	return result


func _dodge_projectile() -> Vector2:
	for shot: Dictionary in game.shots:
		if not shot.hostile:
			continue
		var at: Vector2 = shot.pos
		var travel: Vector2 = shot.vel * 0.28
		var predicted := Geometry2D.get_closest_point_to_segment(game.pos, at, at + travel)
		if Vector2(game.pos).distance_to(predicted) > 22.0:
			continue
		var lateral := travel.normalized().orthogonal()
		var options := [lateral, -lateral]
		for direction: Vector2 in options:
			if Map.line_clear(game.pos, game.pos + direction * 76.0, 14.0, game.map_phase()):
				return direction
	return Vector2.ZERO


func _orbit(radius: float) -> Vector2:
	var radial := Map.CENTER.direction_to(game.pos)
	var drift := clampf((radius - Map.CENTER.distance_to(game.pos)) / 80.0, -1.3, 1.3)
	return (radial.orthogonal() + radial * drift).normalized()


func _listen(side: String) -> bool:
	if not _travel(Map.CONSOLES[0 if side == "human" else 1], 66.0):
		return false
	_step(Vector2.ZERO, game.pos, false)
	_step(Vector2.ZERO, game.pos, true)
	_step(Vector2.ZERO, game.pos, false)
	_check(game.state == "dialogue", "Tap E hears " + side)
	_dialogue()
	return true


func _step(movement: Vector2, target: Vector2, held: bool, fire: bool = false, dash: bool = false, burst: bool = false) -> void:
	game.clock += DT
	game.play_step(DT, movement, target, held, fire, dash, burst)


func _steer(target: Vector2) -> Vector2:
	path_age -= DT
	if path_age <= 0.0 or target != pilot_target:
		pilot_target = target
		waypoint = game.map.waypoint(game.pos, target, game.map_phase())
		path_age = 0.12
	return Vector2(game.pos).direction_to(waypoint)


func _travel(target: Vector2, radius: float, until_state: String = "") -> bool:
	for i in 3600:
		if until_state.is_empty() and game.near(target, radius):
			return true
		if not until_state.is_empty() and game.state != until_state:
			return true
		_step(_steer(target), target, false)
	return _check(false, "Route blocked to %s from %s (%s)" % [target, game.pos, game.state])


func _dialogue() -> void:
	while game.state == "dialogue":
		game._advance_dialogue()


func _check(ok: bool, label: String) -> bool:
	if not ok:
		failures += 1
		push_error(label)
	return ok
