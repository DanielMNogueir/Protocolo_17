class_name P17PowerMap
extends RefCounted
## Energy district geometry. Source space is the 1536 × 1024 plate described in
## docs/direcao-visual/distrito-de-energia.md, uniformly scaled like Residues.
## Gates are the only geometry that changes, so the cache key is the stage.

const SCALE := 1.25
const SIZE := Vector2(1536, 1024) * SCALE
const START := Vector2(250, 790) * SCALE
const BUCKET_SIZE := 128.0

## Walkable floor (source space). The exact union supplies the boundary.
const GROUND := [
	Rect2(30, 470, 1476, 120),   # avenida de serviço
	Rect2(50, 590, 560, 390),    # pátio de manutenção (entrada)
	Rect2(50, 50, 560, 380),     # central solar aurora
	Rect2(270, 430, 120, 40),    # portaria solar
	Rect2(610, 190, 290, 100),   # corredor de cabos
	Rect2(900, 50, 586, 380),    # torre de distribuição norte
	Rect2(1250, 430, 110, 40),   # portão sul da torre
	Rect2(1000, 590, 120, 40),   # portão do banco de baterias
	Rect2(900, 630, 586, 350),   # banco de baterias central
	Rect2(1486, 750, 40, 90),    # elevador do núcleo
]

## [name, source rect]. Every footprint is named for the collision audit.
const FIXTURES := [
	["solar: coletor", Rect2(172, 70, 60, 46)],
	["solar: painéis norte", Rect2(250, 150, 190, 24)],
	["solar: painéis centro", Rect2(250, 205, 190, 24)],
	["solar: painéis sul", Rect2(250, 260, 190, 24)],
	["solar: sala de controle", Rect2(60, 330, 112, 74)],
	["solar: inversores", Rect2(520, 356, 74, 54)],
	["solar: caixa de junção", Rect2(560, 70, 34, 40)],
	["corredor: bancada de cabos norte", Rect2(730, 190, 50, 16)],
	["corredor: bancada de cabos sul", Rect2(730, 274, 50, 16)],
	["torre: base da treliça", Rect2(1150, 150, 110, 80)],
	["torre: sala de comando", Rect2(1396, 350, 90, 80)],
	["torre: caixas de isoladores", Rect2(930, 220, 40, 30)],
	["torre: bobinas de reserva", Rect2(1200, 60, 70, 34)],
	["baterias: banco oeste", Rect2(950, 640, 110, 48)],
	["baterias: banco central", Rect2(1140, 640, 110, 48)],
	["baterias: banco leste", Rect2(1330, 640, 110, 48)],
	["baterias: pilar oeste", Rect2(1010, 832, 26, 26)],
	["baterias: pilar leste", Rect2(1356, 832, 26, 26)],
	["baterias: painel do elevador", Rect2(1452, 870, 30, 24)],
	["pátio: gerador de emergência", Rect2(80, 618, 122, 60)],
	["pátio: oficina", Rect2(380, 606, 200, 118)],
	["pátio: carretéis de cabo", Rect2(120, 880, 70, 46)],
	["pátio: contêiner", Rect2(396, 858, 150, 60)],
	["pátio: transformador desligado", Rect2(560, 760, 40, 50)],
	["avenida: armário elétrico", Rect2(640, 474, 40, 20)],
	["avenida: armário da torre", Rect2(1210, 474, 34, 20)],
]

## Lamp posts on the avenue edges (source). Thin collision, amber until powered.
const LAMPS := [Vector2(120, 476), Vector2(470, 476), Vector2(860, 476), Vector2(1110, 476), Vector2(1440, 476),
	Vector2(220, 584), Vector2(640, 584), Vector2(900, 584), Vector2(1300, 584)]

## Solar puzzle (source). Sunlight enters mirror 0; each mirror must aim at the next node.
const SUN_ENTRY := Vector2(640, 18)
const MIRRORS := [Vector2(480, 110), Vector2(480, 330), Vector2(202, 330)]
const COLLECTOR := Vector2(202, 98)

## Pylon pairs: corridor (rhythmic gate) and the tower yard hazard.
const ARCS := [
	[Vector2(690, 202), Vector2(690, 280), 2.6, 0.0],
	[Vector2(820, 202), Vector2(820, 280), 2.6, 1.3],
	[Vector2(1310, 176), Vector2(1310, 300), 3.0, 0.6],
]

const RELAYS := [Vector2(960, 98), Vector2(1440, 104), Vector2(1440, 292)]
## Consoles: solar control, tower command. Lia stands south of each.
const TERMINALS := [Vector2(212, 404), Vector2(1356, 404)]
const CELL_CONSOLES := [Vector2(1005, 712), Vector2(1195, 712), Vector2(1385, 712)]
const RING_CENTER := Vector2(1195, 862)
const RING_RADIUS := 62.0
const ELEVATOR := Vector2(1470, 795)

## Areas shown on the map and used by the lighting shader (source space).
const FACILITIES := [Rect2(50, 50, 560, 380), Rect2(900, 50, 586, 380), Rect2(900, 630, 586, 350)]
const FACILITY_NAMES := ["CENTRAL SOLAR AURORA", "TORRE DE DISTRIBUIÇÃO NORTE", "BANCO DE BATERIAS CENTRAL"]

## [name, source rect, stage that opens it].
const GATES := [
	["portão do corredor", Rect2(610, 190, 12, 100), 1],
	["portão sul da torre", Rect2(1250, 430, 110, 12), 2],
	["portão das baterias", Rect2(1000, 600, 120, 12), 2],
	["porta do elevador", Rect2(1486, 750, 10, 90), 3],
]
## Sealed-gate plates: label and the side Lia approaches each gate from.
const GATE_LABELS := [["CORREDOR SEM ENERGIA", Vector2.LEFT], ["TORRE SEM ENERGIA", Vector2.DOWN],
	["BANCO SEM ENERGIA", Vector2.UP], ["ELEVADOR BLOQUEADO", Vector2.LEFT]]

## Hostile layout: [kind, source position, zone]. Extras appear on harder levels.
const ENEMIES := [
	["scout", Vector2(420, 360), 0], ["scout", Vector2(150, 220), 0], ["spark", Vector2(530, 200), 0],
	["transformer", Vector2(980, 360), 1], ["coil", Vector2(1080, 110), 1], ["coil", Vector2(1080, 300), 1],
	["sentry", Vector2(1330, 240), 1], ["scout", Vector2(990, 160), 1], ["spark", Vector2(1210, 380), 1],
	["transformer", Vector2(1440, 940), 2], ["sentry", Vector2(960, 930), 2], ["scout", Vector2(1430, 760), 2],
]
const EXTRA_ENEMIES := [
	["spark", Vector2(330, 120), 0], ["sentry", Vector2(1230, 110), 1],
	["scout", Vector2(560, 290), 0], ["spark", Vector2(1420, 200), 1],
]
const WAVE_SPAWNS := [Vector2(930, 960), Vector2(1460, 660), Vector2(930, 660), Vector2(1460, 960)]

static var _solid_cache: Dictionary = {}
static var _navigation_cache: Dictionary = {}
static var _navigation_floor_cache: Dictionary = {}
static var _ground_world: Array[Rect2] = []
static var _floor_edges: Array[Dictionary] = []
static var _edge_buckets: Dictionary = {}
static var _shape_buckets: Dictionary = {}


static func w(source: Vector2) -> Vector2:
	return source * SCALE


static func world_rect(source: Rect2) -> Rect2:
	return Rect2(source.position * SCALE, source.size * SCALE)


static func zone_of(point: Vector2) -> int:
	for i in FACILITIES.size():
		if world_rect(FACILITIES[i]).has_point(point): return i
	return -1


static func gate_open(index: int, stage: int) -> bool:
	return stage >= int(GATES[index][2])


static func collision_shapes(stage: int) -> Array[Dictionary]:
	if _solid_cache.has(stage): return _solid_cache[stage]
	var result: Array[Dictionary] = []
	for fixture in FIXTURES: result.append({"name": fixture[0], "rect": world_rect(fixture[1])})
	for i in LAMPS.size(): result.append({"name": "poste %02d" % i, "rect": world_rect(Rect2(LAMPS[i] - Vector2(4, 5), Vector2(8, 10)))})
	for i in MIRRORS.size(): result.append({"name": "espelho %d" % i, "rect": world_rect(Rect2(MIRRORS[i] - Vector2(15, 8), Vector2(30, 16)))})
	for i in ARCS.size():
		for end in [ARCS[i][0], ARCS[i][1]]:
			result.append({"name": "pilone %d" % i, "rect": world_rect(Rect2(end - Vector2(7, 6), Vector2(14, 12)))})
	for i in RELAYS.size(): result.append({"name": "relé %d" % i, "rect": world_rect(Rect2(RELAYS[i] - Vector2(11, 8), Vector2(22, 14)))})
	for i in TERMINALS.size(): result.append({"name": "terminal %d" % i, "rect": world_rect(Rect2(TERMINALS[i] - Vector2(12, 28), Vector2(24, 14)))})
	for i in CELL_CONSOLES.size(): result.append({"name": "console %d" % i, "rect": world_rect(Rect2(CELL_CONSOLES[i] - Vector2(10, 22), Vector2(20, 10)))})
	for i in GATES.size():
		if not gate_open(i, stage): result.append({"name": GATES[i][0], "rect": world_rect(GATES[i][1])})
	_solid_cache[stage] = result
	return result


static func walkable(point: Vector2, radius: float, stage: int, ignored_body: String = "") -> bool:
	_prepare_floor()
	if not _on_floor(point): return false
	var radius_sq := radius * radius
	var body_radius := int(ceil(radius))
	var bucket := Vector2i((point / BUCKET_SIZE).floor())
	if not _edge_buckets.has(body_radius): _edge_buckets[body_radius] = _index_bounds(_floor_edges, body_radius, "bounds")
	var edges: Dictionary = _edge_buckets[body_radius]
	for edge in edges.get(bucket, []):
		if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, edge.a, edge.b)) < radius_sq: return false
	var key := Vector2i(stage, body_radius)
	if not _shape_buckets.has(key): _shape_buckets[key] = _index_bounds(collision_shapes(stage), body_radius, "rect")
	var shapes: Dictionary = _shape_buckets[key]
	for shape in shapes.get(bucket, []):
		if shape.name == ignored_body: continue
		var bounds: Rect2 = shape.rect
		if bounds.has_point(point) or point.distance_squared_to(point.clamp(bounds.position, bounds.end)) < radius_sq: return false
	return true


static func _index_bounds(entries: Array, radius: float, field: String) -> Dictionary:
	var result := {}
	for entry in entries:
		var rect: Rect2 = entry[field].grow(radius)
		var first := Vector2i((rect.position / BUCKET_SIZE).floor())
		var last := Vector2i((rect.end / BUCKET_SIZE).floor())
		for x in range(first.x, last.x + 1):
			for y in range(first.y, last.y + 1):
				var cell := Vector2i(x, y)
				if not result.has(cell): result[cell] = []
				result[cell].append(entry)
	return result


static func _on_floor(point: Vector2) -> bool:
	for rect in _ground_world:
		if rect.has_point(point): return true
	return false


static func _prepare_floor() -> void:
	if not _ground_world.is_empty(): return
	var xs: Array[float] = []
	var ys: Array[float] = []
	for source in GROUND:
		var rect := world_rect(source)
		_ground_world.append(rect)
		for x in [rect.position.x, rect.end.x]:
			if not xs.has(x): xs.append(x)
		for y in [rect.position.y, rect.end.y]:
			if not ys.has(y): ys.append(y)
	xs.sort()
	ys.sort()
	for x in xs:
		for i in range(ys.size() - 1):
			var middle := Vector2(x, (ys[i] + ys[i + 1]) * 0.5)
			if _on_floor(middle - Vector2(0.01, 0)) != _on_floor(middle + Vector2(0.01, 0)):
				_floor_edges.append({"a": Vector2(x, ys[i]), "b": Vector2(x, ys[i + 1]), "bounds": Rect2(x, ys[i], 0, ys[i + 1] - ys[i])})
	for y in ys:
		for i in range(xs.size() - 1):
			var middle := Vector2((xs[i] + xs[i + 1]) * 0.5, y)
			if _on_floor(middle - Vector2(0, 0.01)) != _on_floor(middle + Vector2(0, 0.01)):
				_floor_edges.append({"a": Vector2(xs[i], y), "b": Vector2(xs[i + 1], y), "bounds": Rect2(xs[i], y, xs[i + 1] - xs[i], 0)})


static func floor_edges() -> Array[Dictionary]:
	_prepare_floor()
	return _floor_edges


static func line_clear(from: Vector2, target: Vector2, radius: float, stage: int, ignored_body: String = "") -> bool:
	var steps := maxi(1, int(ceil(from.distance_to(target) / 4.0)))
	for i in range(steps + 1):
		if not walkable(from.lerp(target, float(i) / steps), radius, stage, ignored_body): return false
	return true


static func slide(from: Vector2, change: Vector2, radius: float, stage: int) -> Vector2:
	var point := from
	var steps := maxi(1, int(ceil(change.length() / 4.0)))
	var step := change / steps
	for i in steps:
		if walkable(point + step, radius, stage):
			point += step
			continue
		if walkable(point + Vector2(step.x, 0), radius, stage): point.x += step.x
		if walkable(point + Vector2(0, step.y), radius, stage): point.y += step.y
	return point


static func prepare_navigation() -> void:
	for radius in [14.0, 18.0, 22.0]: _navigation_floor(radius)


static func _navigation_floor(radius: float) -> PackedByteArray:
	var key := int(ceil(radius))
	if _navigation_floor_cache.has(key): return _navigation_floor_cache[key]
	var mask := PackedByteArray()
	for x in int(SIZE.x / 16.0):
		for y in int(SIZE.y / 16.0):
			mask.append(1 if walkable(Vector2(8, 8) + Vector2(x, y) * 16.0, radius + 4.0, 3) else 0)
	_navigation_floor_cache[key] = mask
	return mask


static func path_between(from: Vector2, target: Vector2, stage: int, reach: float = 35.0, radius: float = 14.0, require_sight: bool = false, target_body: String = "") -> PackedVector2Array:
	if from.distance_to(target) <= reach and walkable(from, radius, stage) and (not require_sight or line_clear(from, target, 0.5 if not target_body.is_empty() else 3.0, stage, target_body)): return PackedVector2Array([from])
	if line_clear(from, target, radius, stage): return PackedVector2Array([target])
	var spacing := 16.0
	var origin := Vector2(8, 8)
	var key := Vector2i(stage, int(ceil(radius)))
	if not _navigation_cache.has(key):
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(Vector2i.ZERO, Vector2i(SIZE / spacing))
		grid.cell_size = Vector2.ONE * spacing
		grid.offset = origin
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()
		var mask := _navigation_floor(radius)
		for x in grid.region.size.x:
			for y in grid.region.size.y:
				grid.set_point_solid(Vector2i(x, y), mask[x * grid.region.size.y + y] == 0)
		for shape in collision_shapes(stage):
			if not shape.name.begins_with("port"): continue
			var area: Rect2 = shape.rect.grow(radius + 4.0)
			var first_cell := Vector2i(((area.position - origin) / spacing).floor())
			var last_cell := Vector2i(((area.end - origin) / spacing).ceil())
			for x in range(first_cell.x, last_cell.x + 1):
				for y in range(first_cell.y, last_cell.y + 1):
					var cell := Vector2i(x, y)
					if grid.is_in_boundsv(cell) and not walkable(origin + Vector2(cell) * spacing, radius + 4.0, stage): grid.set_point_solid(cell, true)
		_navigation_cache[key] = grid
	var grid: AStarGrid2D = _navigation_cache[key]
	var first := Vector2i(((from - origin) / spacing).round())
	var nearest := Vector2i(-1, -1)
	var best := INF
	for x in range(-3, 4):
		for y in range(-3, 4):
			var candidate := first + Vector2i(x, y)
			var point := origin + Vector2(candidate) * spacing
			if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate) and from.distance_squared_to(point) < best and line_clear(from, point, radius, stage):
				best = from.distance_squared_to(point)
				nearest = candidate
	if nearest.x < 0: return PackedVector2Array()
	var endpoints: Array[Dictionary] = []
	var last := Vector2i(((target - origin) / spacing).round())
	var extent := int(ceil(reach / spacing)) + 1
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var cell := last + Vector2i(x, y)
			var point := origin + Vector2(cell) * spacing
			if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell) and point.distance_to(target) <= reach:
				endpoints.append({"cell": cell, "cost": point.distance_to(target) + point.distance_to(from) * 0.15})
	endpoints.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.cost < b.cost)
	for endpoint in endpoints:
		if require_sight and not line_clear(origin + Vector2(endpoint.cell) * spacing, target, 0.5 if not target_body.is_empty() else 3.0, stage, target_body): continue
		var raw := grid.get_point_path(nearest, endpoint.cell)
		if raw.is_empty(): continue
		var path := PackedVector2Array()
		var anchor := from
		var cursor := 0
		while cursor < raw.size():
			var next := cursor
			while next + 1 < raw.size() and line_clear(anchor, raw[next + 1], radius, stage): next += 1
			if not line_clear(anchor, raw[next], radius, stage): break
			path.append(raw[next])
			anchor = raw[next]
			cursor = next + 1
		if cursor == raw.size(): return path
	return PackedVector2Array()
