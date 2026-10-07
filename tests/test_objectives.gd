extends SceneTree
## Mission geometry and visual state follow the real simulation, not a UI timer.
const W = preload("res://scripts/world.gd")
const S = preload("res://scripts/simulation.gd")
const Objectives = preload("res://scripts/objective_visual.gd")
const Energy = preload("res://scripts/energy_station.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	for index in range(4):
		var sim: P17Simulation = S.new()
		sim.start(index)
		var goal: Vector2 = W.GOALS[index]
		var record := Objectives.placement(goal,index)
		check(record.visual_bounds.encloses(record.collision_rect),"Collider stays inside the visible objective")
		check(W.walkable(goal,S.PLAYER_RADIUS,index),"Existing repair point stays clear")
		check(not W.walkable(record.collision_rect.get_center(),1,index),"Objective base blocks movement")
		check(sim._wall_fraction(record.collision_rect.get_center(),record.collision_rect.get_center()+Vector2.ONE,0)!=INF,"Objective base also blocks projectiles")
		check(is_equal_approx(record.depth_anchor.y,record.collision_rect.end.y),"Depth anchor belongs to the actual ground contact")
		var approaches := 0
		for angle in range(12):
			var direction := Vector2.from_angle(angle*TAU/12)
			var start := goal+direction*40
			if not W.walkable(start,S.PLAYER_RADIUS,index): continue
			var clear := true
			for sample in range(21):
				if not W.walkable(start.lerp(goal,float(sample)/20),S.PLAYER_RADIUS,index): clear = false
			if not clear: continue
			approaches += 1
			sim.enemies.clear()
			sim.pos=start
			sim.velocity=Vector2.ZERO
			for frame in range(120):
				sim.tick(1.0/120,(goal-sim.pos).normalized() if sim.pos.distance_to(goal)>2 else Vector2.ZERO,goal+Vector2.UP,false,false,false)
				check(W.walkable(sim.pos,S.PLAYER_RADIUS,index),"Repair approach never enters a base")
			check(sim.pos.distance_to(goal)<5,"Repair point is reachable from a clear nearby approach")
		check(approaches>=4,"At least four clear approach directions reach objective %d (found %d)" % [index+1,approaches])
		print("OBJECTIVE_APPROACH ",index+1," / ",approaches," clear directions")
		sim.pos=goal
		sim.velocity=Vector2.ZERO
		sim.enemies.clear()
		sim.tick(0.001,Vector2.ZERO,goal+Vector2.UP,false,false,false)
		check(sim.state=="activation","Empty encounter becomes available through real simulation")
		check(Objectives.state_name(false,true,0)=="PRONTO PARA REPARO","Available sign describes the real state")
		for frame in range(60): sim.tick(1.0/120,Vector2.ZERO,goal+Vector2.UP,false,false,true)
		check(sim.repair>0 and sim.repair<1,"Holding E advances actual repair")
		check(Objectives.state_name(false,true,sim.repair).begins_with("REPARANDO"),"Label reads actual repair progress")
		while sim.state=="activation": sim.tick(1.0/120,Vector2.ZERO,goal+Vector2.UP,false,false,true)
		check(sim.restored==index+1,"Objective can be restored normally")
		check(Objectives.state_name(true,false,0)=="SISTEMA ATIVO","Online state overrides availability")
	check(Objectives.placement(W.GOALS[1],1).collision_rect==Energy.COLLISION_RECTS[2],"Energy console agrees with the authored scene collider")
	var station=load("res://scenes/structures/energy_station.tscn").instantiate()
	station.position=Energy.WORLD_ORIGIN
	root.add_child(station)
	await process_frame
	check(station.get_node("VisualMain/Terminal").global_position==W.GOALS[1],"Native console and runtime share the interaction origin")
	station.set_online(true,false)
	check(station.get_node("VisualMain/Terminal").online,"Native energy panel follows restored state")
	station.free()
	await process_frame
	print("OBJECTIVES_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
