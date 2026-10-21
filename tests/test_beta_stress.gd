extends "res://tests/test_simulation.gd"
const Energy=preload("res://scripts/energy_station.gd")
var frames_tested:=0
var deaths_observed:=0
func _run() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=170021
	for level in S.DIFFICULTIES:
		for stage in 4:
			var sim: P17Simulation=S.new()
			sim.start(stage,level)
			var initial_count: int=S.WAVE_KINDS[stage].size()-(1 if stage==3 else 0)+int(S.INITIAL_EXTRAS[level])
			check(sim.enemies.size()==initial_count,"Difficulty affects the first wave as well: %s/%d" % [level,stage])
			for task in sim.operation.points:
				var grid:=_grid(stage)
				check(not grid.get_point_path(_nearest_cell(grid,sim.pos),_nearest_cell(grid,task)).is_empty(),"Field task has a route from checkpoint")
				if stage==1:
					var pad:=Rect2(task-Vector2(20,20),Vector2(40,40))
					check(not Energy.GENERATOR_VISUAL.grow(8).intersects(pad) and not Energy.CONTROL_VISUAL.grow(8).intersects(pad),"Energy field task is not hidden by machine artwork")
			var enemy: Dictionary=sim.enemies[0]
			sim.bullets.clear()
			sim._enemy_attack(enemy)
			for bullet in sim.bullets:
				check(bullet.vel.length()>=200,"Enemy projectiles exceed old slow speeds: "+level)
				check(bullet.radius<=5,"Enemy projectiles use original size")
			sim.bullets.clear()
			var legal_player:=true
			var legal_enemies:=true
			var finite_bullets:=true
			var bounded:=true
			var move:=Vector2.ZERO
			for frame in 2400:
				if sim.state=="defeat":
					deaths_observed+=1
					sim.retry()
				if sim.state=="activation": sim.retry() # No artificial task completion in random combat.
				if frame%19==0: move=Vector2.from_angle(rng.randf_range(-PI,PI))
				var target: Vector2=sim.pos+Vector2.from_angle(rng.randf_range(-PI,PI))*300
				if not sim.enemies.is_empty() and frame%3!=0: target=sim.enemies[frame%sim.enemies.size()].pos
				var dt: float=[1.0/120,1.0/60,1.0/30,0.2][frame%4]
				sim.tick(dt,move,target,frame%7!=0,frame%67==0,false,0,false,frame%113==0)
				frames_tested+=1
				legal_player = legal_player and sim.pos.is_finite() and W.walkable(sim.pos,S.PLAYER_RADIUS,stage)
				for unit in sim.enemies:
					if not W.walkable(unit.pos,unit.radius,stage) and legal_enemies:
						print("ILLEGAL_ENEMY level=",level," stage=",stage," frame=",frame," unit=",unit)
					legal_enemies=legal_enemies and unit.pos.is_finite() and W.walkable(unit.pos,unit.radius,stage)
				for bullet in sim.bullets: finite_bullets=finite_bullets and Vector2(bullet.pos).is_finite() and Vector2(bullet.vel).is_finite() and is_finite(float(bullet.life))
				bounded=bounded and sim.hp>=0 and sim.hp<=sim.max_hp and sim.particles.size()<=220 and sim.bullets.size()<512
			check(legal_player,"Player never crosses geometry under randomized movement and dashes")
			check(legal_enemies,"Enemies never cross geometry under randomized combat")
			check(finite_bullets and bounded,"Combat data remains finite and resource counts bounded")
			var elapsed_before:=sim.elapsed
			sim.tick(NAN,Vector2(INF,NAN),Vector2(NAN,INF),true,true,true)
			check(sim.elapsed==elapsed_before,"Nonfinite dt cannot advance the simulation")
			print("STRESS_SEGMENT level=",level," stage=",stage+1," frames=2400 hp=",sim.hp)
	print("BETA_STRESS_%s: %d checks; %d frames; %d natural defeats; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,frames_tested,deaths_observed,failures.size()])
	quit(0 if failures.is_empty() else 1)
