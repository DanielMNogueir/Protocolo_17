extends SceneTree
## Movement and swept projectile regressions around real scene footprints.
const W = preload("res://scripts/world.gd")
const S = preload("res://scripts/simulation.gd")
const Props = preload("res://scripts/environment_props.gd")
const Bridge = preload("res://scripts/bridge_layout.gd")
const Energy = preload("res://scripts/energy_station.gd")
var checks := 0
var failures: Array[String] = []
var walked_edges := 0
var blocker_checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func walk_edge(sim: P17Simulation, a: Vector2, b: Vector2) -> void:
	# Only perimeter edges whose complete approach is on accessible ground qualify.
	for sample in range(21):
		if not W.walkable(a.lerp(b,float(sample)/20),S.PLAYER_RADIUS,3): return
	sim.pos = a
	sim.velocity = Vector2.ZERO
	for frame in range(480):
		if sim.pos.distance_to(b)<3: break
		sim.tick(1.0/120,(b-sim.pos).normalized(),b,false,false,false)
		check(W.walkable(sim.pos,S.PLAYER_RADIUS,3),"Lia stays outside the base along %s → %s" % [a,b])
	check(sim.pos.distance_to(b)<5,"Lia reaches the end of an accessible object edge %s → %s" % [a,b])
	walked_edges += 1

func _run() -> void:
	var sim: P17Simulation = S.new()
	sim.start(3)
	sim.enemies.clear()
	var records: Array[Dictionary] = W.building_objects().duplicate()
	records.append(W.clarifier())
	for prop in W.props():
		if prop.solid: records.append(prop)
	for index in [0,2,3]: records.append(W.terminal(index))
	for r in Energy.COLLISION_RECTS:
		records.append({"collision_rect":r,"visual_bounds":r,"depth_anchor":Vector2(r.get_center().x,r.end.y)})
	for record in records:
		var r: Rect2 = record.collision_rect
		check(not W.walkable(r.get_center(),1,3),"Physical footprint blocks ground occupancy: %s" % r)
		check(record.visual_bounds.grow(2).encloses(r),"Footprint fits the visible base")
		check(is_equal_approx(record.depth_anchor.y,r.end.y),"Depth belongs to the base, not the image center")
		var perimeter := r.grow(S.PLAYER_RADIUS+4)
		var corners := [perimeter.position,Vector2(perimeter.end.x,perimeter.position.y),perimeter.end,Vector2(perimeter.position.x,perimeter.end.y)]
		for index in range(4): walk_edge(sim,corners[index],corners[(index+1)%4])
		# Hit the base from every reachable side with the same movement API as play.
		for side in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			var half := r.size*0.5
			var start: Vector2 = r.get_center()+side*(half+Vector2(S.PLAYER_RADIUS+6,S.PLAYER_RADIUS+6))
			if not W.walkable(start,S.PLAYER_RADIUS,3): continue
			sim.pos = start
			sim.velocity = Vector2.ZERO
			for frame in 30: sim.tick(1.0/120,-side,r.get_center(),false,false,false)
			check(W.walkable(sim.pos,S.PLAYER_RADIUS,3),"Pressing against the base never enters it")
			check(not r.has_point(sim.pos),"Low equipment cannot be crossed")
			blocker_checks += 1
		if record.has("source"):
			var src: Rect2 = record.source
			var visual: Rect2 = record.visual_bounds
			check(absf(visual.size.x/src.size.x-visual.size.y/src.size.y)<0.001,"Equipment keeps a uniform art scale")
	check(walked_edges>100,"Perimeters include front, back and lateral walking")
	check(blocker_checks>100,"Base approach coverage includes all equipment categories")
	for bridge in W.BRIDGES:
		var center := bridge.get_center()
		var vertical := bridge.size.y>bridge.size.x
		var direction := Vector2.DOWN if vertical else Vector2.RIGHT
		var half_length := (bridge.size.y if vertical else bridge.size.x)*0.5
		for offset in [-22.0,0.0,22.0]:
			var lane := Vector2(offset,0) if vertical else Vector2(0,offset)
			walk_edge(sim,center-direction*(half_length+35)+lane,center+direction*(half_length+35)+lane)
		for r in Bridge.collision_rects(bridge):
			check(not W.walkable(r.get_center(),1,3),"Bridge side supports block access to water")
		check(not W.walkable(center,14,0),"Progression gate still seals a locked bridge")
	# Collision changes must agree with combat's swept obstruction query.
	var tank: Dictionary = W.props()[0]
	var base: Rect2 = tank.collision_rect
	var visual: Rect2 = tank.visual_bounds
	var high_y := visual.position.y+visual.size.y*0.55
	check(sim._wall_fraction(Vector2(200,high_y),Vector2(320,high_y),0)==INF,"Shots can cross the walkable space behind a tall tank")
	check(sim._wall_fraction(Vector2(200,base.get_center().y),Vector2(320,base.get_center().y),0)!=INF,"The same tank base blocks swept projectiles")
	check(W.walkable(Vector2(260,high_y),14,3),"Lia can walk behind the upper tank silhouette")
	var sortable := W.sortable_objects(Rect2(Vector2.ZERO,W.SIZE))
	var categories := {}
	for object in sortable: categories[object.type]=categories.get(object.type,0)+1
	check(categories.get("machine",0)==7,"Six independent machines and the clarifier sort by their own feet")
	check(categories.get("terminal",0)==3,"All external terminal bodies are sorted")
	check(categories.get("bridge_part",0)>20,"Bridge rails and pillars participate in depth")
	check(W.walkable(W.GOALS[0],14,0) and W.walkable(W.GOALS[3],14,3),"Compact terminal collision leaves repair points free")
	print("ENVIRONMENT_INTEGRATION_%s: %d checks, %d walked edges, %d base approaches, %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,walked_edges,blocker_checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
