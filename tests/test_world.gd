extends SceneTree
## Headless verification of the actual world data and its public collision API.
const W := preload("res://scripts/world.gd")
const RADIUS := 14.0
const GRID_STEP := 20.0
const COLUMNS := 129
const ROWS := 91
var failures: Array[String] = []
var checks := 0
var route_samples := 0
var accessibility_checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	check(W.REGIONS.size()==4 and W.GOALS.size()==4,"Four regions and objectives are defined")
	check(W.GATES.size()==3,"The district has three progression gates")
	check(W.walkable(W.START,RADIUS,0),"Start is clear in the initial stage")
	for stage in range(4):
		check(W.walkable(W.GOALS[stage],RADIUS,stage),"Goal %d is unobstructed" % (stage+1))
		check(W.walkable(W.CHECKPOINTS[stage],RADIUS,stage),"Checkpoint %d is unobstructed" % (stage+1))
		check(W.REGIONS[stage].has_point(W.CHECKPOINTS[stage]),"Checkpoint %d belongs to its region" % (stage+1))
		for i in range(W.SPAWNS[stage].size()):
			var radius := 44.0 if stage==3 and i==W.SPAWNS[stage].size()-1 else 22.0
			var spawn: Vector2 = W.SPAWNS[stage][i]
			check(W.walkable(spawn,radius,stage),"Spawn %d/%d is clear with radius %.0f" % [stage+1,i+1,radius])
			check(W.REGIONS[stage].has_point(spawn),"Spawn %d/%d belongs to its region" % [stage+1,i+1])
		_check_route(stage)
		_check_accessibility(stage)
	check(route_samples>1000,"Routes receive more than 1000 collision samples")
	check(accessibility_checks==16,"All sixteen stage/destination combinations are checked")
	for point in [Vector2(-1,600),Vector2(2561,600),Vector2(700,-1),Vector2(700,1801)]:
		check(not W.walkable(point,RADIUS,3),"World bounds reject %s" % point)
	if failures.is_empty():
		print("WORLD_TEST_OK: %d assertions; %d route samples; %d stage/region accessibility checks; goals, checkpoints and spawns clear" % [checks,route_samples,accessibility_checks])
	else:
		print("WORLD_TEST_FAILED: %d failures / %d assertions: %s" % [failures.size(),checks,str(failures)])
	quit(0 if failures.is_empty() else 1)

func _check_route(stage: int) -> void:
	var route: Array = W.ROUTES[stage]
	var obstacles: Array[Rect2] = W.solids(stage)
	for segment in range(route.size()-1):
		var a: Vector2 = route[segment]
		var b: Vector2 = route[segment+1]
		var subdivisions := maxi(1,int(ceil(a.distance_to(b)/4.0)))
		for step in range(subdivisions+1):
			var point := a.lerp(b,float(step)/subdivisions)
			check(W.walkable(point,RADIUS,stage),"Route %d blocked at %s" % [stage+1,point])
			check(_clear(point,obstacles),"Published solids obstruct route %d at %s" % [stage+1,point])
			route_samples += 1

func _clear(point: Vector2, obstacles: Array[Rect2]) -> bool:
	for rect in obstacles:
		var closest := Vector2(clampf(point.x,rect.position.x,rect.end.x),clampf(point.y,rect.position.y,rect.end.y))
		if rect.has_point(point) or point.distance_squared_to(closest)<RADIUS*RADIUS:
			return false
	return true

func _cell(point: Vector2) -> Vector2i:
	return Vector2i(int(round(point.x/GRID_STEP)),int(round(point.y/GRID_STEP)))

func _id(cell: Vector2i) -> int:
	return cell.y*COLUMNS+cell.x

func _check_accessibility(stage: int) -> void:
	var obstacles: Array[Rect2] = W.solids(stage)
	var allowed := PackedByteArray()
	allowed.resize(COLUMNS*ROWS)
	for y in range(ROWS):
		for x in range(COLUMNS):
			var point := Vector2(x,y)*GRID_STEP
			allowed[y*COLUMNS+x] = 1 if _clear(point,obstacles) else 0
	var start := _cell(W.START)
	check(allowed[_id(start)]==1,"BFS start is walkable in stage %d" % (stage+1))
	var visited := PackedByteArray()
	visited.resize(COLUMNS*ROWS)
	visited[_id(start)] = 1
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head<queue.size():
		var current := queue[head]
		head += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor: Vector2i = current+direction
			if neighbor.x<0 or neighbor.y<0 or neighbor.x>=COLUMNS or neighbor.y>=ROWS:
				continue
			var index := _id(neighbor)
			if visited[index]==1 or allowed[index]==0:
				continue
			# Sample the edge midpoint as well: graph edges must cross real free space.
			if not _clear((Vector2(current)+Vector2(neighbor))*GRID_STEP*0.5,obstacles):
				continue
			visited[index] = 1
			queue.append(neighbor)
	for destination in range(4):
		var goal: Vector2 = W.GOALS[destination]
		var goal_cell := _cell(goal)
		var reachable := visited[_id(goal_cell)]==1
		if reachable:
			var cell_position := Vector2(goal_cell)*GRID_STEP
			reachable = _clear(goal,obstacles) and _clear((goal+cell_position)*0.5,obstacles)
		var expected := destination<=stage
		check(reachable==expected,"Stage %d → region %d: expected reachable=%s, actual=%s" % [stage+1,destination+1,expected,reachable])
		accessibility_checks += 1
		print("WORLD_PATH stage=%d region=%d reachable=%s visited=%d" % [stage+1,destination+1,reachable,queue.size()])
