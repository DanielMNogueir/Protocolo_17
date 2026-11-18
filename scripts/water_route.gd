extends RefCounted
## The same collision grid serves the field guide and drones of different sizes.
const World = preload("res://scripts/world.gd")
const SPACING := 20.0
const RADIUS := 14.0
static var _grids := {}


static func segment_clear(a: Vector2, b: Vector2, stage: int, radius: float = RADIUS) -> bool:
	var steps := maxi(1, int(ceil(a.distance_to(b) / 8.0)))
	for i in range(steps + 1):
		if not World.walkable(a.lerp(b, float(i) / steps), radius, stage): return false
	return true

## Builds every route grid a sector needs (the guide and each drone size)
## between sectors, so no grid is ever built in the middle of a fight.
const ACTOR_RADII: Array[float] = [14.0, 17.0, 20.0, 21.0, 44.0]

static func warm(stage: int) -> void:
	for radius in ACTOR_RADII: _grid(stage, radius)

static func _grid(stage: int, radius: float) -> AStarGrid2D:
	var key := Vector2(stage, radius)
	if _grids.has(key): return _grids[key]
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(World.SIZE / SPACING))
	grid.cell_size = Vector2.ONE * SPACING
	grid.offset = Vector2.ONE * SPACING * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x, y)
			grid.set_point_solid(cell, not World.walkable(_cell_point(cell), radius, stage))
	_grids[key] = grid
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
static func route(from: Vector2, target: Vector2, stage: int, reach: float = 72.0, radius: float = RADIUS) -> PackedVector2Array:
	if from.distance_to(target) <= reach: return PackedVector2Array([target])
	if segment_clear(from, target, stage, radius): return PackedVector2Array([target])
	var grid := _grid(stage, radius)
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
		while next + 1 < raw.size() and segment_clear(anchor, raw[next + 1], stage, radius): next += 1
		result.append(raw[next])
		anchor = raw[next]
		cursor = next + 1
	return result
