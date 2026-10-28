class_name P17ResidueMap
extends RefCounted
## City geometry is measured on the source plate and uniformly scaled.
const SCALE := 1.25
const SIZE := Vector2(1536, 1024) * SCALE
const START := Vector2(225, 543) * SCALE
const BINS := [Vector2(318, 286) * SCALE, Vector2(370, 290) * SCALE, Vector2(492, 278) * SCALE, Vector2(625, 271) * SCALE]
const ITEMS := [Vector2(337, 455) * SCALE, Vector2(453, 455) * SCALE, Vector2(589, 455) * SCALE, Vector2(632, 466) * SCALE]
const MATERIALS := ["METAL", "PLÁSTICO", "VIDRO", "ORGÂNICO"]
const MATERIAL_COLORS := [Color("bec9c7"), Color("dfad60"), Color("84d8db"), Color("aac685")]
const MATERIAL_GLYPHS := ["M", "P", "V", "O"]
const TERMINALS := [Vector2(218, 327) * SCALE, Vector2(1170, 330) * SCALE, Vector2(1100, 928) * SCALE]
const BLOCKS := [Vector2(1125, 477) * SCALE, Vector2(1216, 345) * SCALE, Vector2(1070, 699) * SCALE, Vector2(1236, 879) * SCALE]
const TOXIC := [Rect2(Vector2(1228, 858) * SCALE, Vector2(43, 31) * SCALE)]
const ENEMY_POSITIONS := [Vector2(462, 320) * SCALE, Vector2(620, 455) * SCALE, Vector2(1120, 315) * SCALE, Vector2(1350, 346) * SCALE, Vector2(982, 695) * SCALE, Vector2(1250, 730) * SCALE, Vector2(1200, 914) * SCALE]
const GATES := [Rect2(Vector2(1059, 433) * SCALE, Vector2(140, 13) * SCALE), Rect2(Vector2(938, 647) * SCALE, Vector2(89, 13) * SCALE)]
const FACILITIES := [Rect2(100, 65, 590, 375), Rect2(842, 65, 650, 375), Rect2(854, 640, 646, 310)]
const PLATE: Texture2D = preload("res://assets/residues/district_city_v2.png")
const ATLAS: Texture2D = preload("res://assets/residues/interactions_v2.png")
const PROPS = preload("res://scripts/environment_props.gd")
const CYAN := Color("7be4ce")
const AMBER := Color("e2b671")
static var _solid_cache: Dictionary = {}
static var _navigation_cache: Dictionary = {}

# Overlapping ground areas follow the avenue, pavements, docks and working aisles.
const GROUND := [
	Rect2(18, 438, 1500, 180), Rect2(735, 18, 78, 998),
	Rect2(100, 240, 580, 118),
	Rect2(297, 332, 77, 155), Rect2(430, 332, 72, 155), Rect2(570, 332, 71, 155),
	Rect2(852, 294, 633, 73), Rect2(1058, 331, 141, 157),
	Rect2(859, 656, 633, 284), Rect2(939, 610, 88, 89),
	Rect2(650, 804, 95, 45), Rect2(326, 814, 360, 31),
]
const SOLIDS := [
	Rect2(105, 237, 96, 74), Rect2(232, 291, 68, 21),
	Rect2(150, 208, 94, 49), Rect2(257, 224, 163, 42),
	Rect2(396, 273, 55, 31), Rect2(522, 305, 38, 16), Rect2(565, 320, 90, 17),
	Rect2(852, 292, 74, 42), Rect2(962, 309, 55, 51), Rect2(1215, 280, 249, 35), Rect2(1390, 339, 42, 26),
	Rect2(920, 732, 130, 132), Rect2(1101, 740, 130, 130),
	Rect2(1270, 653, 183, 196), Rect2(1288, 863, 178, 65),
	Rect2(1077, 653, 59, 43), Rect2(860, 851, 74, 69), Rect2(995, 865, 39, 65),
	Rect2(1232, 748, 29, 91),
]

static func world_rect(source: Rect2) -> Rect2:
	return Rect2(source.position * SCALE, source.size * SCALE)

static func obstacles(stage: int, cleared: Array) -> Array[Rect2]:
	var key := _geometry_key(stage, cleared)
	if _solid_cache.has(key): return _solid_cache[key]
	var result: Array[Rect2] = []
	for rect in SOLIDS: result.append(world_rect(rect))
	if stage < 1: result.append(GATES[0])
	if stage < 2: result.append(GATES[1])
	for i in 4:
		if not cleared[i]: result.append(Rect2(BLOCKS[i] - Vector2(28, 17), Vector2(56, 34)))
	for terminal in TERMINALS: result.append(Rect2(terminal - Vector2(14, 33), Vector2(28, 16)))
	_solid_cache[key] = result
	return result

static func _geometry_key(stage: int, cleared: Array) -> int:
	var key := stage << 4
	for i in 4:
		if cleared[i]: key |= 1 << i
	return key

static func walkable(point: Vector2, radius: float, stage: int, cleared: Array) -> bool:
	for offset in [Vector2.ZERO, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071), Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071)]:
		var sample: Vector2 = (point + offset * radius) / SCALE
		var on_ground := false
		for rect in GROUND:
			if rect.has_point(sample):
				on_ground = true
				break
		if not on_ground: return false
	for rect in obstacles(stage, cleared):
		if point.distance_squared_to(point.clamp(rect.position, rect.end)) < radius * radius: return false
	return true

static func line_clear(from: Vector2, target: Vector2, radius: float, stage: int, cleared: Array) -> bool:
	var steps := maxi(1, int(ceil(from.distance_to(target) / 10.0)))
	for i in range(1, steps + 1):
		if not walkable(from.lerp(target, float(i) / steps), radius, stage, cleared): return false
	return true

static func path_between(from: Vector2, target: Vector2, stage: int, cleared: Array, reach: float = 35.0) -> PackedVector2Array:
	if line_clear(from, target, 14.0, stage, cleared): return PackedVector2Array([target])
	var spacing := 22.0
	var origin := Vector2(11, 11)
	var key := _geometry_key(stage, cleared)
	if not _navigation_cache.has(key):
		var floor_cells := {}
		for x in int(SIZE.x / spacing):
			for y in int(SIZE.y / spacing):
				var cell := Vector2i(x, y)
				if walkable(origin + Vector2(cell) * spacing, 15.0, stage, cleared): floor_cells[cell] = true
		_navigation_cache[key] = floor_cells
	var allowed: Dictionary = _navigation_cache[key]
	var first := Vector2i(((from - origin) / spacing).round())
	if not allowed.has(first):
		var best := INF
		var nearest := first
		for x in range(-2, 3):
			for y in range(-2, 3):
				var candidate := first + Vector2i(x, y)
				var point := origin + Vector2(candidate) * spacing
				if allowed.has(candidate) and from.distance_to(point) < best and line_clear(from, point, 14.0, stage, cleared):
					best = from.distance_to(point)
					nearest = candidate
		if best == INF: return PackedVector2Array()
		first = nearest
	var queue: Array[Vector2i] = [first]
	var parents := {first: first}
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		var point := origin + Vector2(cell) * spacing
		if point.distance_to(target) <= reach:
			var path := PackedVector2Array([point])
			while cell != first:
				cell = parents[cell]
				path.append(origin + Vector2(cell) * spacing)
			path.reverse()
			return path
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + step
			if parents.has(next): continue
			if not allowed.has(next): continue
			parents[next] = cell
			queue.append(next)
	return PackedVector2Array()

static func draw_map(canvas: Node2D, time: float, stage: int, sorted: Array, cleared: Array, terminal_on: Array, carried: int) -> void:
	canvas.draw_texture_rect(PLATE, Rect2(Vector2.ZERO, SIZE), false)
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
	for rect in [Rect2(263, 542, 6, 60), Rect2(672, 545, 6, 63), Rect2(1250, 539, 6, 65), Rect2(1192, 922, 6, 61), Rect2(232, 247, 68, 65), Rect2(522, 254, 38, 67), Rect2(565, 291, 90, 46), Rect2(290, 337, 89, 22), Rect2(421, 337, 88, 22), Rect2(559, 337, 89, 22), Rect2(1052, 337, 150, 22)]:
		entries.append({"source": rect, "depth": rect.end.y * SCALE})
	return entries

static func draw_occluder(canvas: Node2D, entry: Dictionary) -> void:
	canvas.draw_texture_rect_region(PLATE, world_rect(entry.source), entry.source)

static func _label(canvas: Node2D, value: String, point: Vector2, size: int, color: Color) -> void:
	canvas.draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
