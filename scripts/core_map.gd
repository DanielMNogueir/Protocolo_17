extends RefCounted

const GALLERY_SIZE := Vector2(1280, 800)
# Footprints measured on the painted service hall at 1280×800.
const GALLERY_FLOOR := Rect2(94, 175, 1110, 495)
const GALLERY_START := Vector2(640, 565)
const TERMINAL := Vector2(293, 493)
const STAIRS := Rect2(503, 112, 275, 97)
const GALLERY_BLOCKS := [
	Rect2(1010, 161, 193, 507), Rect2(398, 268, 483, 130),
	Rect2(92, 152, 136, 510), Rect2(143, 369, 133, 190),
	Rect2(473, 583, 336, 89),
]
const ARENA_SIZE := Vector2(1920, 1440)
const CENTER := Vector2(960, 760)
# Floor, hatches and sockets measured in the 1536×1024 arena artwork.
const ARENA_ART := Rect2(0, 188, 1920, 1434)
const FLOOR_CENTER := Vector2(960, 775)
const RADII := Vector2(715, 436)
const ENTRY := Vector2(960, 1196)
const ARRIVAL := Vector2(960, 1148)
const OVERLOOK := Vector2(960, 381)
const ARC_SOCKETS := [[Vector2(1203, 584), Vector2(1262, 584)], [Vector2(655, 950), Vector2(720, 950)]]
const PILLAR_NAMES := ["PILAR NORTE", "PILAR LESTE", "PILAR SUL", "PILAR OESTE"]
const MIRROR_NAMES := ["ESPELHO OESTE", "ESPELHO NOROESTE", "ESPELHO NORTE"]
const CONSOLES := [Vector2(750, 800), Vector2(1170, 800)]
const STEP := 32

var _grids: Dictionary = {}


static func ring(fraction: float, degrees: float) -> Vector2:
	return FLOOR_CENTER + RADII * Vector2.from_angle(deg_to_rad(degrees)) * fraction


static func pillars() -> Array[Vector2]:
	return [Vector2(960, 446), Vector2(1417, 751), Vector2(960, 1086), Vector2(500, 751)]


static func mirrors() -> Array[Vector2]:
	return [Vector2(304, 746), Vector2(436, 521), Vector2(668, 410)]


static func spawns() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for angle in [0, 45, 135, 170, 225, 315]:
		points.append(ring(0.93, angle))
	return points


static func blocks(phase: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if phase == 0:
		return result
	result.append(Vector3(CENTER.x, CENTER.y, 70.0 if phase <= 2 else 60.0))
	var fixtures: Array[Vector2]
	var radius := 34.0
	match phase:
		1: fixtures = pillars()
		2:
			fixtures = mirrors()
			radius = 22.0
		4:
			fixtures.assign(CONSOLES)
			radius = 26.0
	for point in fixtures:
		result.append(Vector3(point.x, point.y, radius))
	return result


static func walkable(point: Vector2, radius: float, phase: int) -> bool:
	if phase == 0:
		if not GALLERY_FLOOR.grow(-radius).has_point(point) and not STAIRS.grow(-radius).has_point(point):
			return false
		for rect: Rect2 in GALLERY_BLOCKS:
			var nearest := point.clamp(rect.position, rect.end)
			if nearest.distance_squared_to(point) <= radius * radius:
				return false
		return true
	if ((point - FLOOR_CENTER) / (RADII - Vector2.ONE * radius)).length_squared() > 1.0:
		return false
	for block in blocks(phase):
		if point.distance_squared_to(Vector2(block.x, block.y)) < pow(radius + block.z, 2):
			return false
	return true


static func slide(point: Vector2, change: Vector2, radius: float, phase: int) -> Vector2:
	var steps := maxi(1, ceili(change.length() / 8.0))
	var step := change / steps
	for i in steps:
		var vx := point + Vector2(step.x, 0)
		if walkable(vx, radius, phase):
			point.x = vx.x
		var vy := point + Vector2(0, step.y)
		if walkable(vy, radius, phase):
			point.y = vy.y
	return point


static func line_clear(start: Vector2, finish: Vector2, radius: float, phase: int) -> bool:
	var samples := maxi(1, ceili(start.distance_to(finish) / 8.0))
	for i in range(1, samples + 1):
		if not walkable(start.lerp(finish, float(i) / samples), radius, phase):
			return false
	return true


func route(start: Vector2, finish: Vector2, phase: int, radius: float = 14.0) -> PackedVector2Array:
	if line_clear(start, finish, radius, phase):
		return PackedVector2Array([finish])
	var grid := _grid(phase, radius)
	var from := _cell(grid, start, radius, phase, true)
	var to := _cell(grid, finish, radius, phase, false)
	if from.x < 0 or to.x < 0:
		return PackedVector2Array()
	var nodes := grid.get_id_path(from, to)
	var result := PackedVector2Array()
	for node in nodes:
		result.append(Vector2(node) * STEP)
	if not result.is_empty() and line_clear(result[-1], finish, radius, phase):
		result.append(finish)
	return result


func waypoint(start: Vector2, finish: Vector2, phase: int, radius: float = 14.0) -> Vector2:
	return visible_waypoint(start, route(start, finish, phase, radius), phase, radius)


static func visible_waypoint(start: Vector2, points: PackedVector2Array, phase: int, radius: float = 14.0) -> Vector2:
	for i in range(points.size() - 1, -1, -1):
		var point := points[i]
		if start.distance_squared_to(point) > 16.0 and line_clear(start, point, radius, phase):
			return point
	return start


func _grid(phase: int, radius: float) -> AStarGrid2D:
	var key := Vector2(phase, radius)
	if _grids.has(key):
		return _grids[key]
	var grid := AStarGrid2D.new()
	var extent := GALLERY_SIZE if phase == 0 else ARENA_SIZE
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(extent / STEP) + Vector2i.ONE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var cell := Vector2i(x, y)
			grid.set_point_solid(cell, not walkable(Vector2(cell) * STEP, radius + 3.0, phase))
	_grids[key] = grid
	return grid


func _cell(grid: AStarGrid2D, point: Vector2, radius: float, phase: int, connect: bool) -> Vector2i:
	var nearest := Vector2i((point / STEP).round())
	var best := Vector2i(-1, -1)
	var distance := INF
	for y in range(-4, 5):
		for x in range(-4, 5):
			var cell := nearest + Vector2i(x, y)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
				continue
			var world := Vector2(cell) * STEP
			var current := world.distance_squared_to(point)
			if current < distance and (not connect or line_clear(point, world, radius, phase)):
				best = cell
				distance = current
	return best
