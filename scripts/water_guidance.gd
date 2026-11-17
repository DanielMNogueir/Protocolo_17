class_name P17WaterGuidance
extends RefCounted
## What the Water district asks of the player right now, and the walkable way
## there. Pure presentation: it reads the simulation, never changes it.
##
## Each sector runs the same six beats (clear the area, two field tasks, each
## answered by reinforcements, then the terminal); this script names the beat,
## points at it and routes around machines, channels and closed gates with an
## A* grid over World.walkable, like the guidance in Residues and Energy.
const World = preload("res://scripts/world.gd")
const Objectives = preload("res://scripts/objective_visual.gd")
const SPACING := 20.0
const RADIUS := 14.0
const STEPS := 6

static var _grids := {}

var path := PackedVector2Array()
var _target := Vector2.INF
var _timer := 0.0

## 1-based beat inside the current sector (1..6).
static func step(sim: P17Simulation) -> int:
	if sim.restored > sim.stage: return STEPS
	var done: int = sim.operation.completed
	if sim.state == "combat": return 1 + done * 2
	if not sim.operation.ready(): return 2 + done * 2
	return STEPS

static func alive(sim: P17Simulation) -> int:
	var count := 0
	for enemy in sim.enemies:
		if enemy.hp > 0: count += 1
	return count

static func label(sim: P17Simulation) -> String:
	if sim.restored > sim.stage: return "SISTEMA RESTAURADO"
	if sim.state == "combat":
		var count := alive(sim)
		if sim.operation.completed > 0: return "DEFENDER O SETOR  /  %d DRONE%s" % [count, "" if count == 1 else "S"]
		return "NEUTRALIZAR OS DRONES  /  %d RESTANTE%s" % [count, "" if count == 1 else "S"]
	if sim.operation.wants_treatment(sim.pos): return "ANALISAR A AMOSTRA  /  TECLAS 1 A 3"
	if not sim.operation.ready():
		var hint: String = {"timing": "E NO VERDE", "mash": "TOQUE E", "charge": "SOLTE E NO VERDE"}.get(sim.operation.mode(), "SEGURE E")
		return "%s  /  %s" % [sim.operation.label(), hint]
	return "RESTAURAR %s  /  SEGURE E" % Objectives.SYSTEMS[sim.stage]

static func task_place(sim: P17Simulation) -> String:
	var name: String = sim.operation.label()
	return name.substr(name.find(" ") + 1).trim_prefix("A ").trim_prefix("O ").trim_prefix("AS ").trim_prefix("OS ")


static func objective(sim: P17Simulation) -> Vector2:
	if sim.state == "combat":
		var best := Vector2.INF
		for enemy in sim.enemies:
			if enemy.hp > 0 and sim.pos.distance_squared_to(enemy.pos) < sim.pos.distance_squared_to(best): best = enemy.pos
		if best.is_finite(): return best
	if sim.state == "activation" and not sim.operation.ready(): return sim.operation.target()
	return World.GOALS[sim.stage]

func update(sim: P17Simulation, dt: float) -> void:
	_timer -= dt
	var target := objective(sim)
	if _timer > 0.0 and target.distance_to(_target) < 25.0: return
	_target = target
	_timer = 0.65
	path = route(sim.pos, target, sim.stage, 60.0 if sim.state == "combat" else 72.0)

## Next waypoint at least 75 px away, so the arrow never jitters on top of Lia.
func next_point(sim: P17Simulation) -> Vector2:
	var nearest := 0
	var best := INF
	for i in path.size():
		var distance := sim.pos.distance_squared_to(path[i])
		if distance < best:
			best = distance
			nearest = i
	for i in range(nearest, path.size()):
		if sim.pos.distance_to(path[i]) > 75.0: return path[i]
	return objective(sim)

static func segment_clear(a: Vector2, b: Vector2, stage: int) -> bool:
	var steps := maxi(1, int(ceil(a.distance_to(b) / 8.0)))
	for i in range(steps + 1):
		if not World.walkable(a.lerp(b, float(i) / steps), RADIUS, stage): return false
	return true

static func _grid(stage: int) -> AStarGrid2D:
	if _grids.has(stage): return _grids[stage]
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(World.SIZE / SPACING))
	grid.cell_size = Vector2.ONE * SPACING
	grid.offset = Vector2.ONE * SPACING * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x, y)
			grid.set_point_solid(cell, not World.walkable(_cell_point(cell), RADIUS, stage))
	_grids[stage] = grid
	return grid

static func _cell_point(cell: Vector2i) -> Vector2:
	return Vector2(cell) * SPACING + Vector2.ONE * SPACING * 0.5

static func _nearest_open(grid: AStarGrid2D, point: Vector2, extent: int) -> Vector2i:
	var center := Vector2i(((point - Vector2.ONE * SPACING * 0.5) / SPACING).round())
	var found := Vector2i(-1, -1)
	var best := INF
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var cell := center + Vector2i(x, y)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell): continue
			var distance := point.distance_squared_to(_cell_point(cell))
			if distance < best:
				best = distance
				found = cell
	return found

## Walkable polyline from `from` to the open floor nearest `target`, with
## straight runs merged; empty when no route exists at this stage.
static func route(from: Vector2, target: Vector2, stage: int, reach: float = 72.0) -> PackedVector2Array:
	if from.distance_to(target) <= reach: return PackedVector2Array([target])
	if segment_clear(from, target, stage): return PackedVector2Array([target])
	var grid := _grid(stage)
	var start := _nearest_open(grid, from, 2)
	var finish := _nearest_open(grid, target, int(ceil(reach / SPACING)) + 1)
	if start.x < 0 or finish.x < 0: return PackedVector2Array()
	var raw := grid.get_point_path(start, finish)
	if raw.is_empty(): return PackedVector2Array()
	var result := PackedVector2Array()
	var anchor := from
	var cursor := 0
	while cursor < raw.size():
		var next := cursor
		while next + 1 < raw.size() and segment_clear(anchor, raw[next + 1], stage): next += 1
		result.append(raw[next])
		anchor = raw[next]
		cursor = next + 1
	return result
