class_name P17ResidueMap
extends RefCounted

const SIZE := Vector2(2400, 1500)
const START := Vector2(220, 760)
const BINS := [Vector2(430, 335), Vector2(530, 335), Vector2(630, 335), Vector2(730, 335)]
const ITEMS := [Vector2(270, 1060), Vector2(390, 1130), Vector2(520, 1045), Vector2(650, 1120)]
const MATERIALS := ["METAL", "PLÁSTICO", "VIDRO", "ORGÂNICO"]
const MATERIAL_COLORS := [Color("b9c2b8"), Color("e3b85c"), Color("80cbd4"), Color("85b779")]
const MATERIAL_GLYPHS := ["M", "P", "V", "O"]
const TERMINALS := [Vector2(665, 700), Vector2(1440, 695), Vector2(2140, 690)]
const BLOCKS := [Vector2(1010, 1060), Vector2(1330, 1040), Vector2(1800, 1050), Vector2(2030, 1060)]
const TOXIC := [Rect2(990, 1180, 178, 100), Rect2(1780, 1210, 180, 88)]
const ENEMY_POSITIONS := [Vector2(570, 790), Vector2(710, 940), Vector2(1120, 555), Vector2(1320, 940), Vector2(1850, 565), Vector2(2110, 925), Vector2(2210, 865)]
const GATES := [Rect2(790, 630, 40, 250), Rect2(1580, 630, 40, 250)]
const DARK := Color("20232a")
const OUTLINE := Color("292b30")
const STEEL := Color("5d5d5b")
const RIM := Color("8e8170")
const CYAN := Color("71dac7")
const AMBER := Color("d2a45d")
const PINK := Color("c65d85")
const ATLAS = preload("res://assets/residues/industrial_atlas.png")
const FLOOR = preload("res://assets/residues/concrete_floor.png")

static func obstacles(stage: int, cleared: Array) -> Array[Rect2]:
	var result: Array[Rect2] = [
		Rect2(0, 0, SIZE.x, 90), Rect2(0, 1410, SIZE.x, 90),
		Rect2(0, 0, 90, SIZE.y), Rect2(2310, 0, 90, SIZE.y),
		Rect2(790, 90, 40, 540), Rect2(790, 880, 40, 530),
		Rect2(1580, 90, 40, 540), Rect2(1580, 880, 40, 530),
		Rect2(220, 265, 578, 72), Rect2(150, 355, 225, 230), Rect2(925, 265, 420, 86),
		Rect2(1660, 260, 525, 85), Rect2(1170, 400, 160, 90),
		Rect2(1735, 410, 170, 88), Rect2(2100, 410, 100, 88),
		Rect2(135, 666, 120, 52), Rect2(1400, 881, 132, 59),
		Rect2(1740, 892, 132, 57),
	]
	if stage < 1: result.append(GATES[0])
	if stage < 2: result.append(GATES[1])
	for i in BLOCKS.size():
		if not cleared[i]: result.append(Rect2(BLOCKS[i] - Vector2(33, 22), Vector2(66, 44)))
	return result

static func walkable(point: Vector2, radius: float, stage: int, cleared: Array) -> bool:
	for rect in obstacles(stage, cleared):
		if point.distance_squared_to(point.clamp(rect.position, rect.end)) < radius * radius:
			return false
	return true

static func draw_map(canvas: Node2D, time: float, stage: int, sorted: Array, cleared: Array, terminal_on: Array, carried: int) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("282729"))
	for zone in 3:
		_draw_zone(canvas, zone, time, terminal_on[zone])
	_draw_service_grid(canvas)
	_draw_dividers(canvas, stage, time)
	_draw_conveyors(canvas, time, terminal_on)
	_draw_pipes(canvas, terminal_on, time)
	_draw_machines(canvas, terminal_on, time)
	_draw_atlas(canvas)
	_draw_bins(canvas, sorted, time)
	_draw_items(canvas, sorted, carried, time)
	_draw_blocks(canvas, cleared)
	_draw_toxic(canvas, time)
	_draw_debris(canvas)
	for i in 3:
		_draw_terminal(canvas, TERMINALS[i], i, terminal_on[i], time)

static func _draw_zone(canvas: Node2D, zone: int, time: float, active: bool) -> void:
	var x: float = [90.0, 830.0, 1620.0][zone]
	var width: float = [700.0, 750.0, 690.0][zone]
	var base: Color = [Color("675e55"), Color("5e5750"), Color("62584a")][zone]
	canvas.draw_rect(Rect2(x, 90, width, 1320), OUTLINE)
	canvas.draw_rect(Rect2(x + 11, 101, width - 22, 1298), base)
	var floor_strip := Rect2(zone * FLOOR.get_width() / 3.0, 0, FLOOR.get_width() / 3.0, FLOOR.get_height())
	canvas.draw_texture_rect_region(FLOOR, Rect2(x + 11, 101, width - 22, 1298), floor_strip, Color(1, 1, 1, 0.92))
	# Large, low-contrast wear patches keep the combat floor quiet.
	for i in 12:
		var px: float = x + 55 + posmod(i * 233 + zone * 73, int(width - 120))
		var py: float = 140 + posmod(i * 287 + zone * 111, 1180)
		canvas.draw_rect(Rect2(px, py, 71 + i % 4 * 21, 18 + i % 3 * 13), Color("4d4138", 0.12))
	for row in 10:
		var yy: float = 150 + row * 128
		canvas.draw_line(Vector2(x + 20, yy), Vector2(x + width - 20, yy), Color("3d3532", 0.15), 2)
		for col in 5:
			var xx: float = x + 40 + col * ((width - 80) / 5.0)
			canvas.draw_line(Vector2(xx, yy - 13), Vector2(xx, yy + 13), Color("3d3532", 0.22), 2)
	# Service lanes, their hatching and small embedded light nodes.
	canvas.draw_rect(Rect2(x + 18, 590, width - 36, 330), Color("3b3938", 0.18))
	for j in 16:
		var sx: float = x + 30 + j * ((width - 60) / 16.0)
		for y in [602.0, 907.0]:
			canvas.draw_line(Vector2(sx, y), Vector2(sx + 19, y), Color("d3a65b", 0.46), 4)
	for j in 7:
		var lamp := Vector2(x + 55 + j * ((width - 100) / 7.0), 1020)
		canvas.draw_rect(Rect2(lamp - Vector2(8, 4), Vector2(16, 8)), DARK)
		canvas.draw_rect(Rect2(lamp - Vector2(5, 2), Vector2(10, 3)), CYAN if active else AMBER)
	# Raised perimeter, copper rivets and a few compost plants by the Iris beds.
	for edge_y in [107.0, 1379.0]:
		canvas.draw_rect(Rect2(x + 8, edge_y, width - 16, 12), Color("343235"))
		canvas.draw_line(Vector2(x + 8, edge_y + 1), Vector2(x + width - 8, edge_y + 1), RIM, 2)
		for j in 15:
			canvas.draw_circle(Vector2(x + 33 + j * ((width - 66) / 15.0), edge_y + 6), 2, AMBER)
	for j in 24:
		var seed := j * 73 + zone * 59
		var px2: float = x + 30 + posmod(seed * 11, int(width - 60))
		var py2: float = 116.0 if j % 2 == 0 else 1359.0
		if zone == 2:
			_draw_plant(canvas, Vector2(px2, py2), j, true)
		else:
			canvas.draw_rect(Rect2(px2 - 8, py2 - 2, 16, 5), Color("554a3d"))
			canvas.draw_rect(Rect2(px2 - 3, py2 - 5, 6, 3), Color("a4794b"))
	var titles := ["TRIAGEM AURORA", "RECICLAGEM PRISMA", "COMPOSTAGEM ÍRIS"]
	_draw_label(canvas, titles[zone], Vector2(x + 38, 166), 15, Color("d6e6d9"))
	_draw_label(canvas, "%02d  /  AURORA  •  SERVIÇO" % (zone + 1), Vector2(x + 39, 190), 9, Color("95b6b5"))
	canvas.draw_rect(Rect2(x + 37, 202, 155, 3), CYAN if active else AMBER)

static func _draw_service_grid(canvas: Node2D) -> void:
	for zone in 3:
		var ox: float = [90.0, 830.0, 1620.0][zone]
		for j in 8:
			var x: float = ox + 51 + j * 78
			canvas.draw_rect(Rect2(x, 1240, 45, 50), Color("304d55", 0.30))
			canvas.draw_line(Vector2(x, 1240), Vector2(x + 45, 1240), Color("859d98", 0.23), 2)
	# Wheels, drains and faint arrows reference the actual transport direction.
	for x in range(162, 2240, 145):
		canvas.draw_rect(Rect2(x, 744, 45, 12), Color("263e47"))
		for j in 3:
			canvas.draw_line(Vector2(x + 7 + j * 14, 746), Vector2(x + 17 + j * 14, 752), Color("6a8889", 0.6), 2)

static func _draw_dividers(canvas: Node2D, stage: int, time: float) -> void:
	for index in 2:
		var x: float = [790.0, 1580.0][index]
		for piece in [Rect2(x, 90, 40, 540), Rect2(x, 880, 40, 530)]:
			canvas.draw_rect(piece, Color("292b2e"))
			canvas.draw_rect(piece.grow(-5), Color("575551"))
			for y in range(int(piece.position.y + 26), int(piece.end.y - 12), 80):
				canvas.draw_rect(Rect2(x + 13, y, 14, 5), Color("a4794d"))
		if stage <= index:
			canvas.draw_rect(GATES[index], Color("2d2d30"))
			for y in range(648, 870, 26):
				canvas.draw_rect(Rect2(x + 5, y, 30, 9), AMBER if int(time * 3) % 2 == 0 else Color("9c714a"))
		else:
			canvas.draw_rect(Rect2(x, 630, 40, 250), Color("4a4843", 0.38))
			for y in [641.0, 870.0]:
				canvas.draw_rect(Rect2(x + 4, y, 32, 4), CYAN)

static func _draw_conveyors(canvas: Node2D, time: float, online: Array) -> void:
	for zone in 3:
		var start_x: float = [135.0, 875.0, 1665.0][zone]
		var end_x: float = [760.0, 1540.0, 2265.0][zone]
		for y in [530.0, 1135.0]:
			var rect := Rect2(start_x, y, end_x - start_x, 44)
			canvas.draw_rect(rect.grow(5), DARK)
			canvas.draw_rect(rect, Color("555149"))
			for j in int(rect.size.x / 30):
				var xx: float = start_x + j * 30.0
				canvas.draw_rect(Rect2(xx, y + 3, 3, 38), Color("343431"))
				canvas.draw_circle(Vector2(xx + 14, y + 22), 3, Color("9d927d"))
			canvas.draw_line(Vector2(start_x, y + 9), Vector2(end_x, y + 9), RIM, 3)
			canvas.draw_line(Vector2(start_x, y + 35), Vector2(end_x, y + 35), RIM, 3)
			if online[zone]:
				for j in 12:
					var xx: float = start_x + fposmod(j * 67.0 + time * 45.0, end_x - start_x)
					canvas.draw_rect(Rect2(xx, y + 17, 17, 10), Color(CYAN, 0.5))
		for x in [start_x + 155, end_x - 140]:
			canvas.draw_rect(Rect2(x - 20, 523, 40, 62), Color("82999a", 0.3))
			canvas.draw_rect(Rect2(x - 20, 1128, 40, 62), Color("82999a", 0.3))

static func _draw_pipes(canvas: Node2D, active: Array, time: float) -> void:
	for zone in 3:
		var x: float = [660.0, 1440.0, 2140.0][zone]
		var color := CYAN if active[zone] else Color("99734d")
		for delta in [-17.0, 17.0]:
			canvas.draw_line(Vector2(x + delta, 390), Vector2(x + delta, 611), DARK, 12)
			canvas.draw_line(Vector2(x + delta, 390), Vector2(x + delta, 611), STEEL, 6)
			canvas.draw_line(Vector2(x + delta, 390), Vector2(x + delta, 611), Color(color, 0.4), 2)
		for y in [421.0, 485.0]:
			canvas.draw_rect(Rect2(x - 27, y, 54, 9), Color("9d7651"))
			canvas.draw_circle(Vector2(x - 19, y + 4), 2, Color("e1bd75"))
			canvas.draw_circle(Vector2(x + 19, y + 4), 2, Color("e1bd75"))
	# The organic run branches into planted treatment beds.
	for xx in [1780.0, 2030.0]:
		canvas.draw_line(Vector2(2140, 830), Vector2(xx, 830), DARK, 13)
		canvas.draw_line(Vector2(2140, 830), Vector2(xx, 830), STEEL, 7)
		canvas.draw_line(Vector2(xx, 830), Vector2(xx, 1010), DARK, 13)
		canvas.draw_line(Vector2(xx, 830), Vector2(xx, 1010), STEEL, 7)
		for y in range(870, 1000, 26):
			canvas.draw_rect(Rect2(xx - 3, y, 6, 4), Color(CYAN if active[2] else AMBER, 0.4 + 0.1 * sin(time + y)))

static func _draw_bins(canvas: Node2D, sorted: Array, time: float) -> void:
	for i in 4:
		var p: Vector2 = BINS[i]
		var col: Color = MATERIAL_COLORS[i]
		canvas.draw_rect(Rect2(p - Vector2(50, 60), Vector2(100, 58)), DARK)
		canvas.draw_rect(Rect2(p - Vector2(44, 56), Vector2(88, 48)), Color("304a52"))
		canvas.draw_rect(Rect2(p - Vector2(42, 57), Vector2(84, 7)), col)
		canvas.draw_rect(Rect2(p - Vector2(31, 46), Vector2(62, 25)), Color("172e37"))
		canvas.draw_rect(Rect2(p - Vector2(23, 38), Vector2(46, 9)), Color("60787b"))
		canvas.draw_rect(Rect2(p - Vector2(49, 1), Vector2(98, 45)), Color("1b3540"))
		canvas.draw_rect(Rect2(p - Vector2(45, 3), Vector2(90, 35)), Color("39575c"))
		canvas.draw_rect(Rect2(p - Vector2(42, 5), Vector2(84, 4)), col)
		canvas.draw_rect(Rect2(p - Vector2(40, 34), Vector2(80, 5)), Color("aa8559"))
		canvas.draw_rect(Rect2(p + Vector2(28, -41), Vector2(7, 7)), CYAN if sorted[i] else Color(PINK, 0.7 + 0.2 * sin(time * 3)))
		_draw_label(canvas, MATERIAL_GLYPHS[i], p + Vector2(-8, 29), 18, col)
		_draw_label(canvas, MATERIALS[i], p + Vector2(-41, 63), 9, Color("dce5d6"))

static func _draw_items(canvas: Node2D, sorted: Array, carried: int, time: float) -> void:
	for i in 4:
		if sorted[i] or carried == i: continue
		var p: Vector2 = ITEMS[i]
		var c: Color = MATERIAL_COLORS[i]
		canvas.draw_circle(p + Vector2(2, 9), 15, Color("0a1d24", 0.56))
		canvas.draw_rect(Rect2(p - Vector2(12, 11), Vector2(24, 21)), DARK)
		canvas.draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 16)), c)
		canvas.draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 4)), Color.WHITE * 0.7)
		_draw_label(canvas, MATERIAL_GLYPHS[i], p + Vector2(-5, 6), 12, DARK)
		canvas.draw_arc(p, 22, 0, TAU, 24, Color(c, 0.4 + sin(time * 3 + i) * 0.16), 2)

static func _draw_machines(canvas: Node2D, online: Array, time: float) -> void:
	# Compact assemblies are built from repeated industrial modules and share scale with the water district.
	for zone in 3:
		var x: float = [1090.0, 1870.0, 2150.0][zone]
		var wide := 205.0 if zone == 1 else 170.0
		var active: bool = online[1] if zone == 1 else online[2]
		canvas.draw_rect(Rect2(x - wide * 0.5 - 10, 403, wide + 20, 90), Color("172e39"))
		canvas.draw_rect(Rect2(x - wide * 0.5, 415, wide, 65), Color("365660"))
		canvas.draw_rect(Rect2(x - wide * 0.5 + 7, 425, wide - 14, 36), Color("253f49"))
		for j in 5:
			var bx: float = x - wide * 0.5 + 18 + j * ((wide - 36) / 5.0)
			canvas.draw_rect(Rect2(bx, 409, 11, 56), Color("58747a"))
			canvas.draw_rect(Rect2(bx + 3, 431, 5, 24), Color("1b333d"))
		canvas.draw_rect(Rect2(x - 31, 396, 62, 21), Color("1b333e"))
		canvas.draw_rect(Rect2(x - 24, 400, 48, 8), CYAN if active else AMBER)
		canvas.draw_rect(Rect2(x - wide * 0.5, 480, wide, 9), Color("9e7652"))
		for j in 7:
			canvas.draw_circle(Vector2(x - wide * 0.5 + 15 + j * (wide - 30) / 7.0, 485), 2, Color("e7be79"))
	# Soil and sparse hardy plants stay inside the composting area's raised beds.
	for xx in [1720.0, 1965.0, 2180.0]:
		var bed := Rect2(xx, 980, 120, 190)
		canvas.draw_rect(bed.grow(7), Color("1b373c"))
		canvas.draw_rect(bed, Color("48634c"))
		for j in 17:
			var pp := Vector2(xx + 15 + posmod(j * 47, 94), 995 + posmod(j * 73, 154))
			_draw_plant(canvas, pp, j, true)
		canvas.draw_line(bed.position, Vector2(bed.end.x, bed.position.y), Color("ab8052"), 4)
		canvas.draw_line(Vector2(bed.position.x, bed.end.y), bed.end, Color("ab8052"), 4)
	# Bale and pallet groups are deliberately confined to edges.
	for p in [Vector2(1015, 1330), Vector2(1090, 1330), Vector2(1400, 1260), Vector2(1465, 1260)]:
		canvas.draw_rect(Rect2(p - Vector2(33, 19), Vector2(66, 39)), DARK)
		canvas.draw_rect(Rect2(p - Vector2(28, 15), Vector2(56, 29)), Color("756c5c"))
		for j in 4:
			canvas.draw_line(p + Vector2(-28, -12 + j * 8), p + Vector2(28, -12 + j * 8), Color("9c8d71"), 2)
		canvas.draw_rect(Rect2(p - Vector2(4, 17), Vector2(8, 34)), Color("a77b4c"))

static func _draw_atlas(canvas: Node2D) -> void:
	# Edge props stay below actors. The two tall machines are sorted against actors separately.
	_draw_asset(canvas, 0, Rect2(135, 345, 250, 250))
	_draw_asset(canvas, 3, Rect2(915, 1190, 175, 175))
	_draw_asset(canvas, 3, Rect2(1355, 1160, 147, 147))
	_draw_asset(canvas, 3, Rect2(115, 557, 166, 166))
	_draw_asset(canvas, 3, Rect2(1383, 775, 166, 166))
	_draw_asset(canvas, 3, Rect2(1723, 785, 166, 166))
	_draw_asset(canvas, 4, Rect2(1100, 805, 220, 220))
	_draw_asset(canvas, 5, Rect2(1655, 965, 205, 205))
	_draw_asset(canvas, 5, Rect2(1945, 965, 205, 205))

static func major_machines() -> Array[Dictionary]:
	return [
		{"cell": 1, "dest": Rect2(1015, 300, 285, 285), "depth": 576.0},
		{"cell": 2, "dest": Rect2(1750, 288, 305, 305), "depth": 584.0},
	]

static func draw_major_machine(canvas: Node2D, machine: Dictionary) -> void:
	_draw_asset(canvas, machine.cell, machine.dest)

static func _draw_asset(canvas: Node2D, cell: int, dest: Rect2) -> void:
	var source := Rect2((cell % 3) * 512, (cell / 3) * 512, 512, 512)
	canvas.draw_texture_rect_region(ATLAS, dest, source)

static func _draw_blocks(canvas: Node2D, cleared: Array) -> void:
	for i in BLOCKS.size():
		var p: Vector2 = BLOCKS[i]
		if cleared[i]:
			canvas.draw_rect(Rect2(p - Vector2(36, 15), Vector2(72, 30)), Color("3d6361", 0.4))
			for j in 3:
				canvas.draw_line(p + Vector2(-27 + j * 23, -2), p + Vector2(-12 + j * 23, -2), CYAN, 2)
			continue
		canvas.draw_circle(p + Vector2(6, 18), 35, Color("0d2229", 0.6))
		canvas.draw_rect(Rect2(p - Vector2(33, 21), Vector2(67, 43)), DARK)
		canvas.draw_rect(Rect2(p - Vector2(30, 19), Vector2(29, 30)), Color("6b6356"))
		canvas.draw_rect(Rect2(p + Vector2(2, -13), Vector2(27, 28)), Color("8b7257"))
		canvas.draw_line(p + Vector2(-24, -12), p + Vector2(25, 10), Color("bc8558"), 5)
		canvas.draw_rect(Rect2(p - Vector2(35, 24), Vector2(70, 5)), AMBER)
		_draw_label(canvas, "E", p + Vector2(-5, 7), 16, Color("e8d19c"))

static func _draw_toxic(canvas: Node2D, time: float) -> void:
	for r in TOXIC:
		canvas.draw_rect(r.grow(6), Color("192e38"))
		canvas.draw_rect(r, Color("394649"))
		for j in 9:
			var pp := Vector2(r.position.x + 16 + posmod(j * 47, int(r.size.x - 32)), r.position.y + 14 + posmod(j * 41, int(r.size.y - 25)))
			canvas.draw_circle(pp, 10 + j % 3 * 5, Color(PINK, 0.15 + 0.08 * sin(time * 2 + j)))
			canvas.draw_circle(pp, 3 + j % 3, Color("d883a7", 0.55))
		for j in 6:
			canvas.draw_line(Vector2(r.position.x + j * 31, r.position.y - 6), Vector2(r.position.x + j * 31 + 12, r.position.y - 6), PINK, 3)

static func _draw_debris(canvas: Node2D) -> void:
	for i in 105:
		var zone := i % 3
		var xx: float = [115.0, 855.0, 1645.0][zone] + posmod(i * 233 + zone * 67, 600)
		var yy := 205.0 if i % 2 == 0 else 1315.0
		yy += posmod(i * 17, 60)
		if zone == 2 and i % 4 == 0:
			_draw_plant(canvas, Vector2(xx, yy), i, true)
		else:
			canvas.draw_rect(Rect2(xx, yy, 6 + i % 4 * 4, 2 + i % 3), Color("1f3b43", 0.8))
			if i % 3 == 0: canvas.draw_rect(Rect2(xx + 3, yy - 3, 7, 2), Color("ae8257", 0.8))

static func _draw_terminal(canvas: Node2D, p: Vector2, index: int, active: bool, time: float) -> void:
	canvas.draw_circle(p + Vector2(3, 17), 37, Color("0b222a", 0.62))
	canvas.draw_rect(Rect2(p - Vector2(28, 31), Vector2(56, 55)), DARK)
	canvas.draw_rect(Rect2(p - Vector2(24, 28), Vector2(48, 42)), Color("42616a"))
	canvas.draw_rect(Rect2(p - Vector2(18, 22), Vector2(36, 18)), Color("12313a"))
	canvas.draw_rect(Rect2(p - Vector2(15, 19), Vector2(30, 12)), Color(CYAN if active else AMBER, 0.45))
	for j in 3:
		canvas.draw_rect(Rect2(p + Vector2(-12 + j * 10, 4), Vector2(5, 4)), CYAN if active else AMBER)
	canvas.draw_rect(Rect2(p - Vector2(27, 24), Vector2(54, 5)), Color("a47853"))
	_draw_label(canvas, ["A", "P", "Í"][index], p + Vector2(-5, 39), 12, Color("e8eadd"))
	canvas.draw_arc(p, 45 + sin(time * 3) * 2, PI * 1.1, PI * 1.9, 20, Color(CYAN if active else AMBER, 0.54), 2)

static func _draw_plant(canvas: Node2D, p: Vector2, seed: int, lush: bool) -> void:
	var dark := Color("315d47") if lush else Color("3b6453")
	var light := Color("8caa62") if lush else Color("6f9571")
	canvas.draw_circle(p + Vector2(2, 2), 8, Color("173e37", 0.6))
	for j in 5:
		var angle := float(j) * TAU / 5.0 + seed * 0.37
		var tip := p + Vector2(cos(angle), sin(angle)) * (9 + seed % 4)
		canvas.draw_line(p, tip, dark, 4)
		canvas.draw_circle(tip, 3 if lush else 2, light)

static func _draw_label(canvas: Node2D, label: String, p: Vector2, size: int, color: Color) -> void:
	canvas.draw_string(ThemeDB.fallback_font, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
