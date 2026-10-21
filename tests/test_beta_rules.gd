extends "res://tests/test_simulation.gd"

func _run() -> void:
	for level in S.DIFFICULTIES:
		var sim: P17Simulation = S.new()
		sim.start(0,level)
		check(sim.max_hp == {"story":9,"operation":6,"veteran":5}[level],"Difficulty changes starting resources: "+level)
		check(sim.fire_interval < 0.20,"Primary cadence increased")
		sim.pos = Vector2(740,1450)
		sim.tick(DT,Vector2.ZERO,Vector2(900,1450),false,false,false,0,false,true)
		check(sim.bullets.size() == 5 and sim.secondary_cd > 3.0,"Secondary creates five swept projectiles: "+level)
		var count := sim.secondary_shots
		sim.tick(DT,Vector2.ZERO,Vector2(900,1450),false,false,false,0,false,true)
		check(sim.secondary_shots == count,"Secondary cannot bypass cooldown")
		for bullet in sim.bullets:
			check(float(bullet.radius)==3 and not bullet.hostile,"Secondary uses original projectile size and correct ownership")
		var snapshot := sim.save_data()
		var restored: P17Simulation = S.new()
		check(restored.load_data(JSON.parse_string(JSON.stringify(snapshot))),"Version 2 JSON roundtrip")
		check(restored.difficulty==level and restored.secondary_shots==1 and is_equal_approx(restored.elapsed,sim.elapsed),"Difficulty and statistics persist")
		var stable := JSON.stringify(restored.save_data())
		for bad in [{"difficulty":true},{"elapsed":"oops"},{"kills":1.5},{"shots":-1},{"deaths":true},{"elapsed":INF}]:
			var corrupted := snapshot.duplicate(true)
			corrupted.merge(bad,true)
			check(not restored.load_data(corrupted) and JSON.stringify(restored.save_data())==stable,"Invalid metadata cannot mutate a running game")
		for stage in 4:
			sim.start(stage,level)
			for point in sim.operation.points:
				check(W.walkable(point,24,stage),"Field console stands on accessible ground")
			for wave in [1,2]:
				sim.enemies.clear()
				sim.wave = wave
				sim._spawn_reinforcements()
				var ids := {}
				for enemy in sim.enemies:
					check(W.walkable(enemy.pos,enemy.radius,stage),"Reinforcement body fits the stage: %s/%d/%d/%s" % [level,stage,wave,enemy.kind])
					check(not ids.has(enemy.id),"Reinforcements have unique animation IDs")
					ids[enemy.id]=true
					for other in sim.enemies:
						if other.id==enemy.id: continue
						check(enemy.pos.distance_to(other.pos)>=float(enemy.radius)+float(other.radius)+11,"Reinforcement bodies do not overlap on arrival")
				check(sim.enemies.size()==({"story":2,"operation":4,"veteran":6}[level]+wave-1+(1 if stage==3 and wave==2 else 0)),"Difficulty adjusts reinforcement count")
	_test_timing_and_treatment()
	_test_retry_and_legacy()
	_test_boss_phases()
	print("BETA_RULES_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _test_timing_and_treatment() -> void:
	var sim: P17Simulation = S.new()
	sim.start(1)
	sim.enemies.clear()
	sim.state = "activation"
	sim.pos = sim.operation.target()
	sim.operation.clock = 0
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
	check(sim.operation.completed==0 and sim.operation.cooldown>0,"Mistimed E cannot activate energy")
	for frame in 90: sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
	check(sim.operation.completed==0,"Holding E cannot repeatedly gamble on the timing window")
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,false)
	sim.operation.clock = 0.90
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
	check(sim.operation.completed==1 and sim.wave==1 and sim.state=="combat","Fresh E press inside the window completes the energy task once")
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,false)
	sim.enemies.clear()
	sim.state="activation"
	sim.pos=sim.operation.target()
	sim.operation.clock=0.90
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
	check(sim.operation.completed==2,"E release during combat does not leave a stale held input for the next task")
	sim.start(2)
	sim.enemies.clear()
	sim.state="activation"
	sim.operation.completed=1
	sim.pos=sim.operation.target()
	for frame in 180: sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
	check(sim.operation.completed==1,"Holding E cannot bypass treatment diagnosis")
	check(not sim.select_treatment(2) and not sim.operation.treatment_selected,"Pressure increase does not treat solids")
	for frame in 80: sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,false)
	check(sim.select_treatment(1),"Filtration matches suspended solids")

func _test_retry_and_legacy() -> void:
	var sim: P17Simulation = S.new()
	check(sim.load_data({"version":1,"stage":1,"chosen":["reserve_cell"]}),"Original alpha checkpoints migrate to operation difficulty")
	check(sim.max_hp==8 and sim.difficulty=="operation","Legacy upgrade and life are reconstructed")
	sim.operation.completed=1
	sim.wave=1
	sim.hp=1
	sim.invuln=0
	sim._hurt(1)
	sim.retry()
	check(sim.stage==1 and sim.restored==1 and sim.chosen==["reserve_cell"],"Retry preserves earlier sectors and upgrades")
	check(sim.operation.completed==0 and sim.wave==0 and sim.hp==8 and sim.deaths==1,"Retry resets tasks, combat and life in current sector")
	sim.state="upgrade"
	sim.hp=1
	sim.choose_upgrade(0)
	check(sim.hp==sim.max_hp,"Entering a new sector restores its full life budget")

func _test_boss_phases() -> void:
	var sim: P17Simulation=S.new()
	sim.start(3)
	sim.enemies.clear()
	sim.wave=2
	sim._spawn_reinforcements()
	var boss: Dictionary={}
	for enemy in sim.enemies:
		if enemy.kind=="boss": boss=enemy
	check(not boss.is_empty(),"Final reinforcement wave contains the guardian")
	boss.hp=50
	sim.invuln=999
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,false)
	check(boss.tier==1 and sim.events.has("boss_phase"),"Guardian changes pattern below two thirds health")
	boss.hp=20
	sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,false)
	check(boss.tier==2,"Guardian reaches overload phase below one third")
	for pattern in 3:
		sim.bullets.clear()
		boss.attack=pattern
		sim._enemy_attack(boss)
		check(not sim.bullets.is_empty(),"Every guardian pattern emits collidable projectiles")
