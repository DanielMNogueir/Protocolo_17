class_name P17ResidueMap
extends RefCounted
## City geometry is measured on the source plate and uniformly scaled.
const SCALE := 1.25
const SIZE := Vector2(1536, 1024) * SCALE
const START := Vector2(225, 543) * SCALE
const BINS := [Vector2(285, 263) * SCALE, Vector2(389, 263) * SCALE, Vector2(490, 263) * SCALE, Vector2(596, 263) * SCALE]
const ITEMS := [Vector2(337, 455) * SCALE, Vector2(453, 455) * SCALE, Vector2(589, 455) * SCALE, Vector2(632, 466) * SCALE]
const MATERIALS := ["METAL", "PLÁSTICO", "VIDRO", "ORGÂNICO"]
const MATERIAL_COLORS := [Color("bec9c7"), Color("dfad60"), Color("84d8db"), Color("aac685")]
const MATERIAL_GLYPHS := ["M", "P", "V", "O"]
const TERMINALS := [Vector2(224, 321) * SCALE, Vector2(1325, 332) * SCALE, Vector2(1100, 918) * SCALE]
const BLOCKS := [Vector2(1125, 477) * SCALE, Vector2(1248, 325) * SCALE, Vector2(1070, 699) * SCALE, Vector2(1236, 879) * SCALE]
# No invisible acid pool: the revised working court is visibly dry.
const TOXIC: Array[Rect2] = []
const ENEMY_POSITIONS := [Vector2(462, 315) * SCALE, Vector2(620, 455) * SCALE, Vector2(1135, 315) * SCALE, Vector2(1390, 315) * SCALE, Vector2(982, 695) * SCALE, Vector2(1050, 790) * SCALE, Vector2(1185, 894) * SCALE]
const GATES := [Rect2(Vector2(1059, 433) * SCALE, Vector2(140, 13) * SCALE), Rect2(Vector2(938, 647) * SCALE, Vector2(89, 13) * SCALE)]
const FACILITIES := [Rect2(100, 65, 590, 375), Rect2(842, 65, 650, 375), Rect2(854, 640, 646, 310)]
const PLATE: Texture2D = preload("res://assets/residues/district_city_v3.png")
const SECTORS := [preload("res://assets/residues/district_northwest_v3.png"), preload("res://assets/residues/district_northeast_v3.png"), preload("res://assets/residues/district_southwest_v3.png"), preload("res://assets/residues/district_southeast_v3.png")]
const ATLAS: Texture2D = preload("res://assets/residues/interactions_v2.png")
const PROPS = preload("res://scripts/environment_props.gd")
const CYAN := Color("7be4ce")
const AMBER := Color("e2b671")
static var _solid_cache: Dictionary = {}
static var _navigation_cache: Dictionary = {}
static var _navigation_floor_cache: Dictionary = {}
static var _ground_world: Array[Rect2] = []
static var _floor_edges: Array[Dictionary] = []
static var _edge_buckets: Dictionary = {}
static var _shape_buckets: Dictionary = {}
const BUCKET_SIZE := 128.0

# Source-space floors. Their exact union supplies the boundary, including doorway
# joins; a circle is checked against its edges, not nine samples around its body.
const GROUND := [
	Rect2(18, 438, 1500, 180), Rect2(735, 18, 78, 998),
	Rect2(94, 221, 602, 205), Rect2(255, 354, 284, 138),
	Rect2(852, 244, 633, 194), Rect2(1055, 354, 138, 138),
	Rect2(859, 656, 633, 278), Rect2(940, 610, 78, 90),
	Rect2(315, 680, 421, 167), Rect2(695, 780, 50, 67),
]
# Every footprint has a name for the collision audit. Roofs and machinery height
# are artwork/occlusion; these bounds describe contact with the floor.
const FIXTURES := [
	["triagem: console fixo", Rect2(107, 269, 98, 35)],
	["triagem: esteira de entrada", Rect2(94, 222, 309, 30)],
	["triagem: baias de separação", Rect2(251, 201, 402, 26)],
	["triagem: parede frontal oeste", Rect2(94, 356, 160, 70)],
	["triagem: parede frontal leste", Rect2(540, 356, 156, 70)],
	["triagem: equipamento lateral", Rect2(661, 227, 35, 119)],
	["triagem: paletes de serviço", Rect2(99, 331, 36, 23)],
	["triagem: parede oeste", Rect2(94, 251, 13, 105)],
	["prisma: esteira oeste", Rect2(855, 227, 162, 29)],
	["prisma: prensa", Rect2(1017, 244, 91, 40)],
	["prisma: esteira leste", Rect2(1108, 227, 146, 28)],
	["prisma: forno", Rect2(1353, 225, 99, 29)],
	["prisma: dutos do forno", Rect2(1288, 242, 52, 24)],
	["prisma: coluna oeste", Rect2(852, 255, 30, 101)],
	["prisma: tubulação lateral", Rect2(1460, 244, 25, 127)],
	["prisma: parede frontal oeste", Rect2(852, 356, 201, 76)],
	["prisma: parede frontal leste", Rect2(1194, 356, 291, 76)],
	["íris: tubulação oeste", Rect2(860, 677, 27, 174)],
	["íris: dutos traseiros", Rect2(1128, 656, 161, 41)],
	["íris: baias orgânicas", Rect2(1288, 697, 176, 232)],
	["íris: válvula lateral", Rect2(1248, 728, 34, 48)],
	["íris: bomba de retorno", Rect2(1219, 806, 31, 38)],
	["íris: postes sul", Rect2(927, 916, 11, 18)],
	["íris: iluminação sul", Rect2(1190, 932, 15, 18)],
	["pátio: caminhão de coleta", Rect2(300, 766, 195, 42)],
	["pátio: caixas do caminhão", Rect2(330, 808, 34, 15)],
	["pátio: galpão norte", Rect2(392, 610, 106, 100)],
	["pátio: galpão leste", Rect2(500, 606, 150, 162)],
	["pátio: coluna de ventilação", Rect2(651, 653, 39, 119)],
	["pátio: jardim da rua", Rect2(701, 646, 34, 108)],
	["pátio: silo de manutenção", Rect2(319, 685, 34, 31)],
	["pátio: caixas traseiras", Rect2(348, 696, 42, 17)],
	["pátio: tambores de coleta", Rect2(301, 722, 26, 44)],
	["pátio: poste da entrada", Rect2(717, 834, 8, 11)],
	["calçada: caçamba oeste", Rect2(87, 431, 69, 29)],
	["calçada: paletes oeste", Rect2(157, 430, 31, 27)],
	["calçada: tambor oeste", Rect2(192, 437, 16, 16)],
	["calçada: rede hidráulica", Rect2(666, 435, 31, 23)],
	["calçada: tambor central", Rect2(821, 467, 21, 18)],
	["calçada: jardineira central", Rect2(936, 459, 46, 20)],
	["calçada: caixas prisma", Rect2(1246, 430, 30, 17)],
	["calçada: jardineira prisma", Rect2(1334, 453, 52, 26)],
]

const LAMP_BASES := [Vector2(54, 476), Vector2(219, 477), Vector2(403, 477), Vector2(529, 477), Vector2(719, 478), Vector2(909, 476), Vector2(1018, 476), Vector2(1220, 476), Vector2(1318, 477), Vector2(1423, 477), Vector2(1505, 477), Vector2(45, 602), Vector2(266, 600), Vector2(675, 604), Vector2(835, 604), Vector2(1018, 612), Vector2(1253, 604)]

static func world_rect(source: Rect2) -> Rect2:
	return Rect2(source.position * SCALE, source.size * SCALE)

static func collision_shapes(stage: int, cleared: Array) -> Array[Dictionary]:
	var key := _geometry_key(stage, cleared)
	if _solid_cache.has(key): return _solid_cache[key]
	var result: Array[Dictionary] = []
	for fixture in FIXTURES: result.append({"name": fixture[0], "rect": world_rect(fixture[1])})
	for i in LAMP_BASES.size(): result.append({"name": "poste %02d" % i, "rect": world_rect(Rect2(LAMP_BASES[i] - Vector2(4, 5), Vector2(8, 11)))})
	# Chamfered tank bases leave the visible corner space free.
	for i in 2:
		var base := Rect2(886 if i == 0 else 1095, 751, 123 if i == 0 else 130, 82)
		var polygon := PackedVector2Array()
		for p in [Vector2(18, 0), Vector2(base.size.x - 18, 0), Vector2(base.size.x, 14), Vector2(base.size.x, base.size.y - 14), Vector2(base.size.x - 18, base.size.y), Vector2(18, base.size.y), Vector2(0, base.size.y - 14), Vector2(0, 14)]: polygon.append((base.position + p) * SCALE)
		result.append({"name": "íris: biodigestor %d" % i, "rect": world_rect(base), "polygon": polygon})
	if stage < 1: result.append({"name": "portão prisma", "rect": GATES[0]})
	if stage < 2: result.append({"name": "portão íris", "rect": GATES[1]})
	for i in 4:
		# Cleared scrap disappears. An opened valve remains a solid physical object.
		if i < 2 and cleared[i]: continue
		result.append({"name": "sucata %d" % i if i < 2 else "válvula %d" % i, "rect": Rect2(BLOCKS[i] - Vector2(23, 9), Vector2(46, 23)) if i < 2 else Rect2(BLOCKS[i] - Vector2(12, 3), Vector2(24, 18))})
	for i in TERMINALS.size(): result.append({"name": "terminal %d" % i, "rect": Rect2(TERMINALS[i] - Vector2(14, 33), Vector2(28, 16))})
	_solid_cache[key] = result
	return result

static func _geometry_key(stage: int, cleared: Array) -> int:
	var key := stage << 4
	for i in 4:
		if cleared[i]: key |= 1 << i
	return key

static func walkable(point: Vector2, radius: float, stage: int, cleared: Array, ignored_body: String = "") -> bool:
	_prepare_floor()
	if not _on_floor(point): return false
	var radius_sq := radius * radius
	var body_radius := int(ceil(radius))
	var bucket := Vector2i((point / BUCKET_SIZE).floor())
	if not _edge_buckets.has(body_radius): _edge_buckets[body_radius] = _index_bounds(_floor_edges, body_radius, "bounds")
	var edges: Dictionary = _edge_buckets[body_radius]
	for edge in edges.get(bucket, []):
		if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, edge.a, edge.b)) < radius_sq: return false
	var key := Vector2i(_geometry_key(stage, cleared), body_radius)
	if not _shape_buckets.has(key): _shape_buckets[key] = _index_bounds(collision_shapes(stage, cleared), body_radius, "rect")
	var shapes: Dictionary = _shape_buckets[key]
	for shape in shapes.get(bucket, []):
		if shape.name == ignored_body: continue
		var bounds: Rect2 = shape.rect
		if not bounds.grow(radius).has_point(point): continue
		if not shape.has("polygon"):
			if bounds.has_point(point) or point.distance_squared_to(point.clamp(bounds.position, bounds.end)) < radius_sq: return false
		else:
			var polygon: PackedVector2Array = shape.polygon
			if Geometry2D.is_point_in_polygon(point, polygon): return false
			for i in polygon.size():
				if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])) < radius_sq: return false
	return true

static func _index_bounds(entries: Array[Dictionary], radius: float, field: String) -> Dictionary:
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

static func line_clear(from: Vector2, target: Vector2, radius: float, stage: int, cleared: Array, ignored_body: String = "") -> bool:
	# Four-pixel steps are smaller than the narrowest authored fixture. This is
	# also used for muzzle obstruction, navigation smoothing and swept bullets.
	var steps := maxi(1, int(ceil(from.distance_to(target) / 4.0)))
	for i in range(steps + 1):
		if not walkable(from.lerp(target, float(i) / steps), radius, stage, cleared, ignored_body): return false
	return true

static func slide(from: Vector2, change: Vector2, radius: float, stage: int, cleared: Array) -> Vector2:
	var point := from
	var steps := maxi(1, int(ceil(change.length() / 4.0)))
	var step := change / steps
	for i in steps:
		if walkable(point + step, radius, stage, cleared):
			point += step
			continue
		if walkable(point + Vector2(step.x, 0), radius, stage, cleared): point.x += step.x
		if walkable(point + Vector2(0, step.y), radius, stage, cleared): point.y += step.y
	return point

static func prepare_navigation() -> void:
	# Pay for the three body sizes during scene loading. Opening a gate or
	# removing scrap later only patches the few affected cells of this mask.
	for radius in [14.0, 18.0, 25.0]: _navigation_floor(radius)

static func _navigation_floor(radius: float) -> PackedByteArray:
	var key := int(ceil(radius))
	if _navigation_floor_cache.has(key): return _navigation_floor_cache[key]
	var mask := PackedByteArray()
	for x in int(SIZE.x / 16.0):
		for y in int(SIZE.y / 16.0):
			mask.append(1 if walkable(Vector2(8, 8) + Vector2(x, y) * 16.0, radius + 4.0, 3, [true, true, true, true]) else 0)
	_navigation_floor_cache[key] = mask
	return mask

static func path_between(from: Vector2, target: Vector2, stage: int, cleared: Array, reach: float = 35.0, radius: float = 14.0, require_sight: bool = false, target_body: String = "") -> PackedVector2Array:
	if from.distance_to(target) <= reach and walkable(from, radius, stage, cleared) and (not require_sight or line_clear(from, target, 0.5 if not target_body.is_empty() else 3.0, stage, cleared, target_body)): return PackedVector2Array([from])
	if line_clear(from, target, radius, stage, cleared): return PackedVector2Array([target])
	var spacing := 16.0
	var origin := Vector2(8, 8)
	var key := Vector2i(_geometry_key(stage, cleared), int(ceil(radius)))
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
				var cell := Vector2i(x, y)
				grid.set_point_solid(cell, mask[x * grid.region.size.y + y] == 0)
		for shape in collision_shapes(stage, cleared):
			if not (shape.name.begins_with("portão") or shape.name.begins_with("sucata")): continue
			var area: Rect2 = shape.rect.grow(radius + 4.0)
			var first_cell := Vector2i(((area.position - origin) / spacing).floor())
			var last_cell := Vector2i(((area.end - origin) / spacing).ceil())
			for x in range(first_cell.x, last_cell.x + 1):
				for y in range(first_cell.y, last_cell.y + 1):
					var cell := Vector2i(x, y)
					if grid.is_in_boundsv(cell) and not walkable(origin + Vector2(cell) * spacing, radius + 4.0, stage, cleared): grid.set_point_solid(cell, true)
		_navigation_cache[key] = grid
	var grid: AStarGrid2D = _navigation_cache[key]
	var first := Vector2i(((from - origin) / spacing).round())
	var nearest := Vector2i(-1, -1)
	var best := INF
	for x in range(-3, 4):
		for y in range(-3, 4):
			var candidate := first + Vector2i(x, y)
			var point := origin + Vector2(candidate) * spacing
			if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate) and from.distance_squared_to(point) < best and line_clear(from, point, radius, stage, cleared):
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
		if require_sight and not line_clear(origin + Vector2(endpoint.cell) * spacing, target, 0.5 if not target_body.is_empty() else 3.0, stage, cleared, target_body): continue
		var raw := grid.get_point_path(nearest, endpoint.cell)
		if raw.is_empty(): continue
		var path := PackedVector2Array()
		var anchor := from
		var cursor := 0
		while cursor < raw.size():
			var next := cursor
			while next + 1 < raw.size() and line_clear(anchor, raw[next + 1], radius, stage, cleared): next += 1
			if not line_clear(anchor, raw[next], radius, stage, cleared): break
			path.append(raw[next])
			anchor = raw[next]
			cursor = next + 1
		if cursor == raw.size(): return path
	return PackedVector2Array()

static func draw_map(canvas: Node2D, time: float, stage: int, sorted: Array, cleared: Array, terminal_on: Array, carried: int, include_plate: bool = true) -> void:
	if include_plate: draw_background(canvas, Rect2(Vector2.ZERO, SIZE))
	_draw_bays(canvas, sorted, carried, time)
	for i in 3:
		var p: Vector2 = TERMINALS[i] - Vector2(0, 41)
		canvas.draw_circle(p, 12, Color(CYAN if terminal_on[i] else AMBER, 0.07 + 0.025 * sin(time * 2)))
	for i in 2:
		if stage > i: continue
		var gate: Rect2 = GATES[i]
		var count := int(ceil(gate.size.x / 48.0))
		var width := gate.size.x / count
		for j in count:
			var prop := PROPS.create("barrier", Vector2(gate.position.x + (j + 0.5) * width, gate.end.y), width + 2)
			PROPS.draw(canvas, prop, time)
		_label(canvas, "ACESSO EM ESPERA", gate.get_center() + Vector2(-55, -49), 9, AMBER)
	if terminal_on[0]: _belt_glints(canvas, Vector2(130, 187) * SCALE, Vector2(355, 245) * SCALE, time)
	if terminal_on[1]: _belt_glints(canvas, Vector2(1105, 222) * SCALE, Vector2(1227, 222) * SCALE, time)
	for pool in TOXIC:
		for j in 5:
			var drift := Vector2(sin(time * 0.8 + j * 2) * 13, -fposmod(time * 9 + j * 12, 45))
			canvas.draw_circle(pool.get_center() + drift, 4 + j % 3, Color("b6c98a", 0.07))

static func draw_background(canvas: CanvasItem, area: Rect2, tint: Color = Color.WHITE) -> void:
	for i in 4:
		var offset := Vector2(i % 2, i / 2) * area.size * 0.5
		canvas.draw_texture_rect(SECTORS[i], Rect2(area.position + offset, area.size * 0.5), false, tint)

static func _belt_glints(canvas: Node2D, from: Vector2, target: Vector2, time: float) -> void:
	for i in 9:
		var p := from.lerp(target, fposmod(time * 0.13 + i / 9.0, 1.0))
		canvas.draw_line(p, p + Vector2(3, 0), Color("ddd2a1", 0.32), 1)

static func _draw_bays(canvas: Node2D, sorted: Array, carried: int, time: float) -> void:
	for i in 4:
		var p: Vector2 = BINS[i]
		var c: Color = CYAN if sorted[i] else MATERIAL_COLORS[i]
		var label: String = ("✓ " if sorted[i] else "") + MATERIALS[i]
		var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var r := Rect2(p + Vector2(-width * 0.5 - 5, -31), Vector2(width + 10, 17))
		canvas.draw_rect(r, Color("0c252b", 0.92))
		canvas.draw_line(r.position, r.position + Vector2(r.size.x, 0), c, 1)
		_label(canvas, label, r.position + Vector2(5, 12), 10, c)
		if carried == i: canvas.draw_arc(p, 24 + sin(time * 3), 0, TAU, 28, Color(c, 0.72), 1)

static func props(sorted: Array, cleared: Array, terminal_on: Array, carried: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in 3: entries.append({"cell": 4, "foot": TERMINALS[i] - Vector2(0, 18), "width": 48.0, "active": terminal_on[i]})
	for i in 4:
		if i < 2 and cleared[i]: continue
		entries.append({"cell": 5 if i < 2 else 6, "foot": BLOCKS[i] + Vector2(0, 16), "width": 62.0 if i < 2 else 46.0, "active": cleared[i]})
	for i in 4:
		if sorted[i] or carried == i: continue
		entries.append({"cell": i, "foot": ITEMS[i] + Vector2(0, 9), "width": 33.0, "active": false})
	for entry in entries: entry["depth"] = entry.foot.y
	return entries

static func draw_prop(canvas: Node2D, entry: Dictionary, time: float) -> void:
	draw_sprite(canvas, entry.cell, entry.foot, entry.width)
	if entry.cell in [4, 6]:
		var p: Vector2 = entry.foot - Vector2(0, entry.width * 0.58)
		canvas.draw_circle(p, 2, CYAN if entry.active else AMBER)
		if entry.active: canvas.draw_circle(p, 9, Color(CYAN, 0.07 + sin(time * 3) * 0.02))

static func draw_sprite(canvas: Node2D, cell: int, foot: Vector2, width: float) -> void:
	var cell_size := ATLAS.get_size() / Vector2(4, 2)
	var source := Rect2(Vector2(cell % 4, cell / 4) * cell_size, cell_size)
	var dest := Rect2(foot - Vector2(width * 0.5, width), Vector2(width, width))
	canvas.draw_texture_rect_region(ATLAS, dest, source)

static func occluders() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for rect in [Rect2(263, 542, 6, 60), Rect2(672, 545, 6, 63), Rect2(1250, 539, 6, 65), Rect2(831, 544, 6, 61), Rect2(1192, 922, 6, 61), Rect2(718, 774, 6, 67)]:
		entries.append({"polygon": PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), "depth": rect.end.y * SCALE})
	for x in [884.0, 1093.0]:
		entries.append({"polygon": PackedVector2Array([Vector2(x + 49, 684), Vector2(x + 72, 684), Vector2(x + 87, 708), Vector2(x + 117, 735), Vector2(x + 130, 776), Vector2(x + 130, 817), Vector2(x + 108, 836), Vector2(x + 23, 836), Vector2(x, 815), Vector2(x, 758), Vector2(x + 18, 720), Vector2(x + 49, 701)]), "depth": 833.0 * SCALE})
	entries.append({"polygon": PackedVector2Array([Vector2(300, 747), Vector2(315, 728), Vector2(358, 715), Vector2(450, 715), Vector2(455, 725), Vector2(481, 725), Vector2(494, 742), Vector2(495, 792), Vector2(483, 810), Vector2(310, 810), Vector2(300, 795)]), "depth": 808.0 * SCALE})
	return entries

static func draw_occluder(canvas: Node2D, entry: Dictionary) -> void:
	var polygon: PackedVector2Array = entry.polygon
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var centre := polygon[0]
	var column := 1 if centre.x >= 768 else 0
	var row := 1 if centre.y >= 512 else 0
	for point in polygon:
		points.append(point * SCALE)
		uv.append((point - Vector2(column * 768, row * 512)) / Vector2(768, 512))
	canvas.draw_polygon(points, PackedColorArray([Color.WHITE]), uv, SECTORS[row * 2 + column])

static func draw_collision_audit(canvas: Node2D, stage: int, cleared: Array) -> void:
	_prepare_floor()
	for edge in _floor_edges: canvas.draw_line(edge.a, edge.b, Color("75e6da"), 2)
	for shape in collision_shapes(stage, cleared):
		if shape.has("polygon"):
			canvas.draw_colored_polygon(shape.polygon, Color(1, 0.25, 0.3, 0.30))
			var outline: PackedVector2Array = shape.polygon.duplicate()
			outline.append(outline[0])
			canvas.draw_polyline(outline, Color("ff9b79"), 1)
		else:
			canvas.draw_rect(shape.rect, Color(1, 0.25, 0.3, 0.30))
			canvas.draw_rect(shape.rect, Color("ff9b79"), false, 1)

static func _label(canvas: Node2D, value: String, point: Vector2, size: int, color: Color) -> void:
	canvas.draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
