extends "res://tests/test_simulation.gd"
## Dano normal: não escreve invulnerabilidade, HP, posições ou dano para vencer.
var orbit_bias:=1.0
var combat_range:=280.0
func _run() -> void:
	var reports: Array = []
	for level in S.DIFFICULTIES:
		var sim: P17Simulation = S.new()
		sim.start(0,level)
		for stage in 4:
			var finished := false
			for attempt in 8:
				var clear := _fight(sim)
				if clear:
					for task in 2:
						if not _complete_field_task(sim):
							check(false,"Normal playthrough could not reach field task")
							break
						clear = _fight(sim)
						if not clear: break
				if clear and sim.state=="activation" and sim.operation.ready():
					if not _walk_to(sim,W.GOALS[stage]): break
					for frame in 120: sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
					finished = sim.restored==stage+1
					if finished: break
				if sim.state != "defeat": break
				print("RETRY level=",level," stage=",stage+1," attempt=",attempt+1)
				sim.retry()
			check(finished,"Normal-damage playthrough completes %s sector %d" % [level,stage+1])
			print("SECTOR level=",level," stage=",stage+1," done=",finished," hp=",sim.hp," kills=",sim.kills)
			if not finished: break
			if stage<3: sim.choose_upgrade([1,0,1][stage])
		var report := sim.save_data()
		report["victory"] = sim.state=="victory"
		report["hp"] = sim.hp
		report["max_hp"] = sim.max_hp
		reports.append(report)
		check(sim.state=="victory","Normal-damage campaign reaches victory: "+level)
		print("NORMAL_PLAYTHROUGH ",JSON.stringify(report))
	DirAccess.make_dir_recursive_absolute("res://.runtime")
	var file := FileAccess.open("res://.runtime/beta_playthrough.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(reports,"  "))
	print("BETA_PLAYTHROUGH_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _fight(sim: P17Simulation) -> bool:
	var path: PackedVector2Array = PackedVector2Array()
	var target := sim.pos
	var move := Vector2.ZERO
	var orbit_direction := orbit_bias
	for frame in 24000:
		if sim.state != "combat":
			return sim.state == "activation"
		var distance := INF
		for enemy in sim.enemies:
			var enemy_pos: Vector2 = enemy.pos
			if sim.pos.distance_to(enemy_pos) < distance:
				target = enemy_pos
				distance = sim.pos.distance_to(enemy_pos)
		var aim := (target - sim.pos).normalized()
		var muzzle: Vector2 = sim.pos + S.LIA_POSE.pose(aim, 0, false).muzzle
		var can_fire := sim._wall_fraction(sim.pos, muzzle, 3) == INF and sim._wall_fraction(muzzle, target, 3) == INF
		var need_move := distance > combat_range or not _clear_sight(sim.pos, target, sim.stage) or not can_fire
		if need_move:
			if frame % 12 == 0 or path.is_empty():
				path = _path(sim, target)
			while not path.is_empty() and sim.pos.distance_to(path[0]) < 7.0:
				path.remove_at(0)
			move = (path[0] - sim.pos).normalized() if not path.is_empty() else Vector2.ZERO
		else:
			if distance < 155.0:
				move = -aim
			else:
				move = aim.orthogonal() * orbit_direction
			if not W.walkable(sim.pos + move * 24.0, S.PLAYER_RADIUS + 1, sim.stage):
				orbit_direction = -orbit_direction
				move = aim.orthogonal() * orbit_direction
				if not W.walkable(sim.pos + move * 24.0, S.PLAYER_RADIUS + 1, sim.stage):
					move = -aim if W.walkable(sim.pos - aim * 24.0, S.PLAYER_RADIUS + 1, sim.stage) else Vector2.ZERO
		var danger := false
		for bullet in sim.bullets:
			if not bullet.hostile:
				continue
			var relative: Vector2 = bullet.pos - sim.pos
			var velocity: Vector2 = bullet.vel
			var near_time := clampf(-relative.dot(velocity) / velocity.length_squared(), 0.0, 0.45)
			if (relative + velocity * near_time).length() < 37.0 and near_time < 0.42:
				danger = true
				var evade := velocity.orthogonal().normalized()
				if evade.dot(move) < 0.0:
					evade = -evade
				if W.walkable(sim.pos + evade * 40.0, S.PLAYER_RADIUS + 1, sim.stage):
					move = evade
				elif W.walkable(sim.pos - evade * 40.0, S.PLAYER_RADIUS + 1, sim.stage):
					move = -evade
				break
		var dash := danger and sim.dash_cd <= 0.0 and move != Vector2.ZERO
		sim.tick(DT, move, target, true, dash, false, 0, false, sim.secondary_cd<=0 and distance<350 and can_fire)
		bot_frames += 1
		if sim.state == "defeat":
			return false
	print("BOT_STALL stage=", sim.stage, " pos=", sim.pos, " target=", target)
	return false
