class_name P17PowerArt
extends RefCounted
## Energy district visuals. Until the painted sectors exist (assets/power), the
## district is drawn in code with the game palette; interactive props, effects
## and the electrical enemies are always drawn here.

const M = preload("res://scripts/power_map.gd")
const Mechanics = preload("res://scripts/power_mechanics.gd")
const ENEMIES = preload("res://scripts/enemy_art.gd")
const INK := Color("091922")
const ROOF := Color("15252c")
const ROOF_RIB := Color("1c3038")
const ASPHALT := Color("1f2a2f")
const CONCRETE := Color("34464a")
const CONCRETE_LIGHT := Color("41575a")
const GRAVEL := Color("38423a")
const STEEL := Color("2c4a50")
const STEEL_LIGHT := Color("4f7477")
const TEAL := Color("287e7b")
const BRASS := Color("b08a4a")
const BRASS_LIGHT := Color("e2c17e")
const HAZARD := Color("d8b347")
const CYAN := Color("7be4ce")
const AMBER := Color("e8bd74")
const MAGENTA := Color("e36b92")
const ELECTRIC := Color("9fe9ff")
const PANEL := Color("1c3653")
const PANEL_LIGHT := Color("3f6d93")

## Painted sectors, when present: off (blackout) and on (powered) versions.
const SECTOR_PATHS := ["northwest", "northeast", "southwest", "southeast"]
static var _sectors_off: Array[Texture2D] = []
static var _sectors_on: Array[Texture2D] = []
static var _checked := false


static func has_painted_sectors() -> bool:
	if not _checked:
		_checked = true
		for name in SECTOR_PATHS:
			var off := "res://assets/power/district_%s_off.png" % name
			var on := "res://assets/power/district_%s_on.png" % name
			if not (ResourceLoader.exists(off) and ResourceLoader.exists(on)):
				_sectors_off.clear()
				_sectors_on.clear()
				return false
			_sectors_off.append(load(off))
			_sectors_on.append(load(on))
	return not _sectors_off.is_empty()


static func sector_textures(powered: bool) -> Array[Texture2D]:
	has_painted_sectors()
	return _sectors_on if powered else _sectors_off


## Static ground: floors, roofs, markings and cable trenches (procedural plate).
static func draw_ground(canvas: Node2D, time: float, stage: int) -> void:
	var size := M.SIZE
	canvas.draw_rect(Rect2(Vector2.ZERO, size), ROOF)
	for y in range(0, int(size.y), 22): canvas.draw_line(Vector2(0, y), Vector2(size.x, y), ROOF_RIB, 2)
	# Building masses between the floors read as roofs with vents.
	for roof in [Rect2(610, 50, 290, 140), Rect2(610, 290, 290, 180), Rect2(610, 590, 290, 400), Rect2(0, 990, 1536, 34)]:
		var r := M.world_rect(roof)
		canvas.draw_rect(r, Color("172a31"))
		canvas.draw_rect(r, Color("2a4148"), false, 2)
		for i in range(1, int(r.size.x / 70.0)):
			var vent := Rect2(r.position + Vector2(i * 70 - 14, 18), Vector2(28, 14))
			canvas.draw_rect(vent, Color("0f1d22"))
			canvas.draw_rect(vent, Color("2f4a50"), false, 1)
	for i in M.GROUND.size():
		var r := M.world_rect(M.GROUND[i])
		var color := CONCRETE
		match i:
			0: color = ASPHALT
			2: color = GRAVEL
			4: color = Color("2a3a3e")
			8: color = Color("30403f")
		canvas.draw_rect(r, color)
	_draw_tiles(canvas, M.world_rect(Rect2(900, 630, 586, 350)), 40.0, Color("3a4a49"))
	_draw_tiles(canvas, M.world_rect(Rect2(50, 590, 560, 390)), 50.0, Color("3c4c4f"))
	_draw_tiles(canvas, M.world_rect(Rect2(900, 50, 586, 380)), 46.0, Color("374a4d"))
	_draw_gravel(canvas, M.world_rect(Rect2(50, 50, 560, 380)))
	# Avenue markings and kerbs.
	var avenue := M.world_rect(M.GROUND[0])
	canvas.draw_rect(Rect2(avenue.position, Vector2(avenue.size.x, 8)), CONCRETE_LIGHT)
	canvas.draw_rect(Rect2(avenue.position + Vector2(0, avenue.size.y - 8), Vector2(avenue.size.x, 8)), CONCRETE_LIGHT)
	for x in range(int(avenue.position.x) + 20, int(avenue.end.x), 70):
		canvas.draw_rect(Rect2(x, avenue.get_center().y - 2, 34, 4), Color("8f8a6a", 0.55))
	for x in range(0, 6):
		canvas.draw_rect(Rect2(avenue.position.x + 700 + x * 14, avenue.position.y + 14, 8, avenue.size.y - 28), Color("c9c6b3", 0.18))
	# Walls along floor edges give the compound outlines a physical rim.
	for edge in M.floor_edges():
		canvas.draw_line(edge.a, edge.b, Color("0d1a1f"), 6)
		canvas.draw_line(edge.a, edge.b, STEEL, 2)
	# Underground cable trenches link the installations; they glow once powered.
	var trenches := [
		[Vector2(202, 98), Vector2(202, 450), 1], [Vector2(202, 450), Vector2(330, 450), 1],
		[Vector2(330, 520), Vector2(1205, 520), 1], [Vector2(1205, 230), Vector2(1205, 520), 2],
		[Vector2(1060, 520), Vector2(1060, 650), 2], [Vector2(1195, 690), Vector2(1195, 800), 3],
		[Vector2(1195, 920), Vector2(1470, 920), 3], [Vector2(1470, 920), Vector2(1470, 830), 3],
	]
	for trench in trenches:
		var a: Vector2 = M.w(trench[0])
		var b: Vector2 = M.w(trench[1])
		var powered: bool = stage >= int(trench[2])
		canvas.draw_line(a, b, Color("0b161a"), 9)
		canvas.draw_line(a, b, Color("33484c"), 5)
		if powered:
			canvas.draw_line(a, b, Color(CYAN, 0.35), 3)
			var length := a.distance_to(b)
			for k in int(length / 60.0):
				var t := fposmod(time * 0.45 + k * 60.0 / length, 1.0)
				canvas.draw_circle(a.lerp(b, t), 2.5, Color(CYAN, 0.85))
		else:
			canvas.draw_line(a, b, Color(AMBER, 0.08), 3)
	# Battery ring markings.
	var ring := M.w(M.RING_CENTER)
	var radius := M.RING_RADIUS * M.SCALE
	canvas.draw_circle(ring, radius, Color("26363a"))
	canvas.draw_arc(ring, radius, 0, TAU, 64, HAZARD, 4)
	canvas.draw_arc(ring, radius - 9, 0, TAU, 64, Color("1a2a2e"), 3)
	for i in 12:
		var angle := i * TAU / 12.0
		canvas.draw_line(ring + Vector2.from_angle(angle) * (radius - 4), ring + Vector2.from_angle(angle) * (radius + 6), INK, 3)
	_draw_hazard(canvas, M.world_rect(Rect2(1470, 750, 16, 90)))


static func _draw_tiles(canvas: Node2D, rect: Rect2, step: float, color: Color) -> void:
	var x := rect.position.x
	while x < rect.end.x:
		canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), color, 1)
		x += step
	var y := rect.position.y
	while y < rect.end.y:
		canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), color, 1)
		y += step


static func _draw_gravel(canvas: Node2D, rect: Rect2) -> void:
	var seed_value := 17
	for i in 900:
		seed_value = (seed_value * 1103515245 + 12345) % 2147483648
		var px := rect.position.x + float(seed_value % 10000) / 10000.0 * rect.size.x
		seed_value = (seed_value * 1103515245 + 12345) % 2147483648
		var py := rect.position.y + float(seed_value % 10000) / 10000.0 * rect.size.y
		canvas.draw_rect(Rect2(px, py, 2, 2), Color("4a5547") if i % 3 else Color("2c3530"))


static func _draw_hazard(canvas: Node2D, rect: Rect2) -> void:
	canvas.draw_rect(rect, INK)
	var stripe := 10.0
	var y := rect.position.y
	var index := 0
	while y < rect.end.y:
		canvas.draw_rect(Rect2(rect.position.x, y, rect.size.x, minf(stripe, rect.end.y - y)), HAZARD if index % 2 == 0 else INK)
		y += stripe
		index += 1


## Height in world pixels for each named fixture (3/4 view: rises above the footprint).
static func fixture_height(name: String) -> float:
	if name.contains("painéis"): return 10.0
	if name.contains("treliça"): return 0.0
	if name.contains("coletor"): return 0.0
	if name.contains("sala") or name.contains("oficina"): return 46.0
	if name.contains("banco"): return 40.0
	if name.contains("contêiner") or name.contains("gerador"): return 30.0
	if name.contains("inversores") or name.contains("transformador"): return 26.0
	if name.contains("pilar"): return 54.0
	return 16.0


## Y-sorted structure entries for the procedural plate.
static func structures() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for fixture in M.FIXTURES:
		var rect := M.world_rect(fixture[1])
		entries.append({"name": fixture[0], "rect": rect, "depth": rect.end.y})
	for i in M.LAMPS.size():
		entries.append({"name": "poste", "rect": M.world_rect(Rect2(M.LAMPS[i] - Vector2(4, 5), Vector2(8, 10))), "depth": M.w(M.LAMPS[i]).y + 6, "index": i})
	return entries


static func draw_structure(canvas: Node2D, entry: Dictionary, time: float, stage: int) -> void:
	var name: String = entry.name
	var r: Rect2 = entry.rect
	if name == "poste":
		_draw_lamp(canvas, r, time, stage >= 1)
		return
	if name.contains("treliça"):
		_draw_lattice(canvas, r, time, stage >= 2)
		return
	if name.contains("coletor"):
		_draw_collector(canvas, r, time, stage >= 1)
		return
	if name.contains("painéis"):
		_draw_panels(canvas, r, time, stage >= 1)
		return
	var height := fixture_height(name)
	var top := Rect2(r.position - Vector2(0, height), r.size)
	var front := Rect2(Vector2(r.position.x, r.end.y - height), Vector2(r.size.x, height)) if height < r.size.y else r
	canvas.draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Color(INK, 0.35))
	canvas.draw_rect(Rect2(top.position.x, top.position.y, r.size.x, r.size.y + height), STEEL)
	canvas.draw_rect(top, STEEL_LIGHT)
	canvas.draw_rect(top.grow(-3), Color("3c5f62"))
	canvas.draw_rect(Rect2(r.position.x, r.end.y - minf(height, r.size.y) - 2, r.size.x, 3), BRASS)
	canvas.draw_rect(Rect2(top.position, Vector2(r.size.x, r.size.y + height)), INK, false, 2)
	if name.contains("banco"):
		var bank := int(name.contains("central")) + 2 * int(name.contains("leste"))
		var lit := stage >= 3
		for k in 5:
			var cell := Rect2(top.position + Vector2(8 + k * (r.size.x - 16) / 5.0, 8), Vector2((r.size.x - 16) / 5.0 - 4, r.size.y - 14))
			canvas.draw_rect(cell, Color("10242a"))
			var level := 0.85 if lit else 0.25 + 0.1 * sin(time + k + bank)
			canvas.draw_rect(Rect2(cell.position.x, cell.end.y - cell.size.y * level, cell.size.x, cell.size.y * level), Color(CYAN if lit else AMBER, 0.75))
	elif name.contains("sala") or name.contains("oficina"):
		for k in int(r.size.x / 26.0):
			var window := Rect2(Vector2(r.position.x + 8 + k * 26, r.end.y - height + 10), Vector2(16, 12))
			canvas.draw_rect(window, Color(CYAN, 0.55) if stage >= 1 else Color("0e1c21"))
			canvas.draw_rect(window, INK, false, 1)
	elif name.contains("gerador") or name.contains("inversores") or name.contains("armário"):
		canvas.draw_circle(top.get_center(), 3, Color(AMBER, 0.6 + 0.3 * sin(time * 4)))
	elif name.contains("pilar"):
		canvas.draw_rect(Rect2(top.position + Vector2(0, 10), Vector2(r.size.x, 6)), HAZARD)


static func _draw_lamp(canvas: Node2D, r: Rect2, time: float, powered: bool) -> void:
	var foot := r.get_center() + Vector2(0, 4)
	canvas.draw_line(foot, foot - Vector2(0, 58), INK, 5)
	canvas.draw_line(foot, foot - Vector2(0, 58), STEEL_LIGHT, 2)
	canvas.draw_rect(Rect2(foot - Vector2(9, 64), Vector2(18, 7)), STEEL)
	var color := CYAN if powered else AMBER
	canvas.draw_circle(foot - Vector2(0, 58), 4, Color(color, 0.9 if powered else 0.45 + 0.15 * sin(time * 7)))


static func _draw_panels(canvas: Node2D, r: Rect2, time: float, powered: bool) -> void:
	canvas.draw_rect(Rect2(r.position + Vector2(0, 6), r.size), Color(INK, 0.4))
	var top := Rect2(r.position - Vector2(0, 10), r.size)
	canvas.draw_rect(Rect2(top.position, top.size + Vector2(0, 10)), STEEL)
	canvas.draw_rect(top, PANEL)
	var cells := int(top.size.x / 22.0)
	for k in cells:
		var cell := Rect2(top.position + Vector2(3 + k * 22, 3), Vector2(19, top.size.y - 6))
		canvas.draw_rect(cell, PANEL_LIGHT if powered else Color("23405e"))
		canvas.draw_line(cell.position + Vector2(2, 2), cell.position + Vector2(8, 2), Color(CYAN if powered else ELECTRIC, 0.5 if powered else 0.15), 1)
	if powered:
		var glint := fposmod(time * 70.0, top.size.x + 60) - 30
		canvas.draw_line(top.position + Vector2(glint, 0), top.position + Vector2(glint + 18, top.size.y), Color(1, 1, 1, 0.22), 4)
	canvas.draw_rect(Rect2(top.position, top.size + Vector2(0, 10)), INK, false, 2)


static func _draw_collector(canvas: Node2D, r: Rect2, time: float, powered: bool) -> void:
	var base := Vector2(r.get_center().x, r.end.y)
	canvas.draw_rect(Rect2(r.position + Vector2(0, 8), r.size - Vector2(0, 8)), STEEL)
	canvas.draw_rect(Rect2(r.position + Vector2(0, 8), r.size - Vector2(0, 8)), INK, false, 2)
	canvas.draw_rect(Rect2(base - Vector2(10, 110), Vector2(20, 100)), STEEL_LIGHT)
	canvas.draw_rect(Rect2(base - Vector2(10, 110), Vector2(20, 100)), INK, false, 2)
	for k in 5: canvas.draw_line(base - Vector2(10, 20 + k * 18), base - Vector2(-10, 30 + k * 18), INK, 1)
	var head := base - Vector2(0, 122)
	canvas.draw_circle(head, 16, INK)
	canvas.draw_circle(head, 13, BRASS)
	canvas.draw_circle(head, 8, Color(CYAN if powered else AMBER, 0.95 if powered else 0.35))
	if powered: canvas.draw_circle(head, 22 + 2 * sin(time * 3), Color(CYAN, 0.12))


static func _draw_lattice(canvas: Node2D, r: Rect2, time: float, powered: bool) -> void:
	var base_left := Vector2(r.position.x + 8, r.end.y)
	var base_right := Vector2(r.end.x - 8, r.end.y)
	var top_left := Vector2(r.get_center().x - 16, r.position.y - 170)
	var top_right := Vector2(r.get_center().x + 16, r.position.y - 170)
	canvas.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 20), Vector2(r.size.x, 20)), CONCRETE_LIGHT)
	canvas.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 20), Vector2(r.size.x, 20)), INK, false, 2)
	for side in [[base_left, top_left], [base_right, top_right]]:
		canvas.draw_line(side[0], side[1], INK, 7)
		canvas.draw_line(side[0], side[1], STEEL_LIGHT, 3)
	for k in 7:
		var t0 := k / 7.0
		var t1 := (k + 1) / 7.0
		var l0: Vector2 = base_left.lerp(top_left, t0)
		var r0: Vector2 = base_right.lerp(top_right, t0)
		var l1: Vector2 = base_left.lerp(top_left, t1)
		var r1: Vector2 = base_right.lerp(top_right, t1)
		canvas.draw_line(l0, r1, STEEL, 2)
		canvas.draw_line(r0, l1, STEEL, 2)
		canvas.draw_line(l1, r1, STEEL_LIGHT, 2)
	var crown := (top_left + top_right) * 0.5
	for arm in [-1, 1]:
		var tip: Vector2 = crown + Vector2(arm * 64, 12)
		canvas.draw_line(crown + Vector2(0, 8), tip, STEEL_LIGHT, 3)
		canvas.draw_line(tip, tip + Vector2(0, 14), BRASS, 3)
		canvas.draw_circle(tip + Vector2(0, 16), 4, Color(CYAN if powered else AMBER, 0.9 if powered else 0.4))
	canvas.draw_circle(crown - Vector2(0, 6), 7, Color(MAGENTA if not powered else CYAN, 0.6 + 0.3 * sin(time * 5)))


## Mirror: pedestal plus a reflective panel facing its relay direction.
static func draw_mirror(canvas: Node2D, base: Vector2, orientation: int, turning: float, lit: bool, aligned: bool, time: float) -> void:
	var foot := base + Vector2(0, 8)
	canvas.draw_rect(Rect2(foot - Vector2(17, 9), Vector2(34, 14)), Color(INK, 0.4))
	canvas.draw_rect(Rect2(foot - Vector2(14, 12), Vector2(28, 12)), STEEL)
	canvas.draw_rect(Rect2(foot - Vector2(14, 12), Vector2(28, 12)), INK, false, 2)
	canvas.draw_line(foot - Vector2(0, 12), foot - Vector2(0, 32), STEEL_LIGHT, 4)
	var angle := Mechanics.direction(orientation).angle() - turning / 0.32 * PI / 4.0
	var face := Vector2.from_angle(angle)
	var center := foot - Vector2(0, 38)
	var across := face.orthogonal() * 16.0
	var depth := face * 3.0 + Vector2(0, -4)
	var panel := PackedVector2Array([center - across, center + across, center + across + depth, center - across + depth])
	canvas.draw_colored_polygon(panel, Color("cfe8ef") if lit else Color("6e8d99"))
	panel.append(panel[0])
	canvas.draw_polyline(panel, INK, 2)
	canvas.draw_line(center, center + face * 14.0, Color(AMBER if not aligned else CYAN, 0.9), 2)
	canvas.draw_circle(foot - Vector2(0, 12), 3, Color(CYAN if aligned else AMBER, 0.6 + 0.3 * sin(time * 4)))


static func draw_relay(canvas: Node2D, base: Vector2, charge: float, window: float, lit: bool, time: float) -> void:
	canvas.draw_rect(Rect2(base - Vector2(13, 6), Vector2(26, 14)), STEEL)
	canvas.draw_rect(Rect2(base - Vector2(13, 6), Vector2(26, 14)), INK, false, 2)
	for k in 3:
		var y := base.y - 12 - k * 10
		canvas.draw_rect(Rect2(base.x - 9 + k, y, 18 - k * 2, 7), Color("d8e3e0") if lit else Color("7f908f"))
		canvas.draw_rect(Rect2(base.x - 9 + k, y, 18 - k * 2, 7), INK, false, 1)
	var head := base - Vector2(0, 46)
	canvas.draw_circle(head, 8, INK)
	canvas.draw_circle(head, 6, Color(CYAN if lit else AMBER, 0.95 if lit else 0.5))
	if lit and window > 0.0 and charge > 0.0:
		canvas.draw_arc(head, 14, -PI / 2, -PI / 2 + TAU * clampf(charge / window, 0, 1), 28, CYAN, 3)
	if lit: canvas.draw_circle(head, 12 + sin(time * 9) * 2, Color(ELECTRIC, 0.15))


static func draw_pylon(canvas: Node2D, base: Vector2, state: String, warning: float, time: float) -> void:
	canvas.draw_rect(Rect2(base - Vector2(9, 4), Vector2(18, 10)), STEEL)
	canvas.draw_rect(Rect2(base - Vector2(9, 4), Vector2(18, 10)), INK, false, 2)
	canvas.draw_line(base, base - Vector2(0, 30), INK, 6)
	canvas.draw_line(base, base - Vector2(0, 30), STEEL_LIGHT, 2)
	for k in 3: canvas.draw_rect(Rect2(base - Vector2(6, 14 + k * 6), Vector2(12, 3)), Color("c9d5d1"))
	var color := ELECTRIC if state == "active" else (Color(AMBER).lerp(ELECTRIC, warning) if state == "warning" else Color("4f6266"))
	canvas.draw_circle(base - Vector2(0, 34), 5, color)
	if state == "warning": canvas.draw_circle(base - Vector2(0, 34), 7 + warning * 6, Color(ELECTRIC, 0.18 + 0.2 * absf(sin(time * 20))))


static func draw_console(canvas: Node2D, foot: Vector2, active: bool, alert: bool, time: float, wide: bool = false) -> void:
	var width := 30.0 if wide else 24.0
	canvas.draw_rect(Rect2(foot - Vector2(width * 0.5 + 2, 30), Vector2(width + 4, 32)), Color(INK, 0.35))
	canvas.draw_rect(Rect2(foot - Vector2(width * 0.5, 34), Vector2(width, 22)), STEEL)
	canvas.draw_rect(Rect2(foot - Vector2(width * 0.5 - 3, 31), Vector2(width - 6, 10)), Color(CYAN, 0.75) if active else (Color(MAGENTA, 0.6 + 0.3 * sin(time * 8)) if alert else Color(AMBER, 0.45)))
	canvas.draw_rect(Rect2(foot - Vector2(width * 0.5, 34), Vector2(width, 22)), INK, false, 2)
	canvas.draw_rect(Rect2(foot - Vector2(width * 0.5 - 2, 12), Vector2(width - 4, 6)), BRASS)


static func draw_elevator(canvas: Node2D, open: bool, time: float) -> void:
	var r := M.world_rect(Rect2(1486, 740, 46, 110))
	canvas.draw_rect(r, Color("0e1a1f"))
	canvas.draw_rect(r, BRASS, false, 3)
	var glow := Color(CYAN if open else MAGENTA, 0.35 + 0.2 * sin(time * 3))
	canvas.draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(r.size.x - 12, 8)), glow)
	if not open:
		for k in 4: canvas.draw_rect(Rect2(r.position.x + 4, r.position.y + 22 + k * 22, r.size.x - 8, 14), STEEL)
	else:
		for k in 6:
			var y := r.position.y + fposmod(time * 40.0 + k * 18.0, r.size.y - 20) + 14
			canvas.draw_line(Vector2(r.position.x + 8, y), Vector2(r.end.x - 8, y), Color(CYAN, 0.25), 1)


## Sealed gate. The label sits on `side`, the side Lia approaches from.
static func draw_gate(canvas: Node2D, rect: Rect2, label: String, time: float, side: Vector2 = Vector2.UP) -> void:
	_draw_hazard(canvas, rect)
	canvas.draw_rect(rect, INK, false, 2)
	var pulse := 0.5 + 0.5 * sin(time * 3.0)
	canvas.draw_rect(rect.grow(2), Color(AMBER, 0.15 + 0.1 * pulse), false, 2)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	var anchor := rect.get_center()
	if side.x < 0.0: anchor = Vector2(rect.position.x - width - 8, anchor.y + 3)
	elif side.x > 0.0: anchor = Vector2(rect.end.x + 8, anchor.y + 3)
	elif side.y < 0.0: anchor = Vector2(anchor.x - width * 0.5, rect.position.y - 8)
	else: anchor = Vector2(anchor.x - width * 0.5, rect.end.y + 15)
	canvas.draw_rect(Rect2(anchor + Vector2(-4, -10), Vector2(width + 8, 14)), Color(INK, 0.8))
	canvas.draw_string(font, anchor.round(), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(AMBER, 0.75 + 0.25 * pulse))


## Electrical enemies and the corrupted transformer. Scouts and sentries use
## the existing directional art with an electric aura.
static func draw_enemy(canvas: Node2D, view: Dictionary, time: float) -> void:
	var kind: String = view.kind
	var origin: Vector2 = Vector2(view.pos).round()
	if kind == "transformer":
		_draw_transformer(canvas, origin, view, time)
		return
	if kind == "coil":
		_draw_coil(canvas, origin, view, time)
		return
	if kind == "spark":
		var art := view.duplicate()
		art.kind = "scout"
		art["warning"] = view.get("warning", 0.0)
		for i in range(3, 0, -1):
			if view.get("phase", "") == "dash":
				canvas.draw_circle(origin - Vector2(view.facing) * i * 9.0, 9 - i, Color(ELECTRIC, 0.08 * (4 - i)))
		ENEMIES.draw(canvas, art, time)
		var crackle := origin + Vector2(0, -6)
		for k in 3:
			var a := Vector2.from_angle(time * 13.0 + k * 2.1) * 13.0
			canvas.draw_line(crackle + a * 0.4, crackle + a, Color(ELECTRIC, 0.7), 1)
		return
	ENEMIES.draw(canvas, view, time)


static func _draw_coil(canvas: Node2D, origin: Vector2, view: Dictionary, time: float) -> void:
	var hurt: bool = float(view.get("hurt", 0.0)) > 0.0
	var warning: float = view.get("warning", 0.0)
	canvas.draw_colored_polygon(_ellipse(origin + Vector2(0, 14), 20, 5), Color(INK, 0.4))
	canvas.draw_rect(Rect2(origin + Vector2(-16, 2), Vector2(32, 14)), Color("8a6a3c"))
	canvas.draw_rect(Rect2(origin + Vector2(-16, 2), Vector2(32, 14)), INK, false, 2)
	canvas.draw_rect(Rect2(origin + Vector2(-7, -34), Vector2(14, 38)), STEEL)
	for k in 6:
		var y := origin.y - 30 + k * 6
		canvas.draw_line(Vector2(origin.x - 9, y), Vector2(origin.x + 9, y + 2), BRASS_LIGHT if not hurt else Color.WHITE, 2)
	canvas.draw_rect(Rect2(origin + Vector2(-7, -34), Vector2(14, 38)), INK, false, 2)
	var head := origin + Vector2(0, -42)
	canvas.draw_circle(head, 10, INK)
	canvas.draw_circle(head, 8, Color(MAGENTA).lerp(Color.WHITE, warning * 0.5))
	canvas.draw_circle(head, 12 + warning * 6, Color(MAGENTA, 0.15 + warning * 0.25))


static func _draw_transformer(canvas: Node2D, origin: Vector2, view: Dictionary, time: float) -> void:
	var hurt: bool = float(view.get("hurt", 0.0)) > 0.0
	var body := Rect2(origin + Vector2(-26, -40), Vector2(52, 52))
	canvas.draw_colored_polygon(_ellipse(origin + Vector2(0, 14), 32, 7), Color(INK, 0.4))
	canvas.draw_rect(body, Color("3b3545") if not hurt else Color("8c7f95"))
	canvas.draw_rect(Rect2(body.position, Vector2(body.size.x, 12)), Color("57506a"))
	for k in 4: canvas.draw_rect(Rect2(body.position + Vector2(5 + k * 12, 16), Vector2(6, 30)), Color("2a2533"))
	canvas.draw_rect(body, INK, false, 2)
	for k in 3:
		var p := body.position + Vector2(10 + k * 16, -8)
		canvas.draw_rect(Rect2(p, Vector2(6, 10)), Color("c9d5d1"))
		canvas.draw_circle(p + Vector2(3, -2), 3, Color(MAGENTA, 0.7 + 0.3 * sin(time * 6 + k)))
	canvas.draw_string(ThemeDB.fallback_font, (origin + Vector2(-9, -16)).round(), "⚡", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(MAGENTA, 0.9))


static func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16: points.append(center + Vector2(cos(i * TAU / 16) * rx, sin(i * TAU / 16) * ry))
	return points


## Jagged lightning between two points; the seed keeps it stable for a frame.
static func draw_lightning(canvas: Node2D, a: Vector2, b: Vector2, time: float, width: float = 2.0, color: Color = ELECTRIC, jitter: float = 9.0) -> void:
	var points := PackedVector2Array([a])
	var segments := maxi(3, int(a.distance_to(b) / 14.0))
	var normal := (b - a).normalized().orthogonal()
	var tick := floorf(time * 24.0)
	for i in range(1, segments):
		var t := float(i) / segments
		var noise := sin(tick * 12.9898 + i * 78.233) * 43758.5453
		noise = (noise - floorf(noise)) * 2.0 - 1.0
		points.append(a.lerp(b, t) + normal * noise * jitter)
	points.append(b)
	canvas.draw_polyline(points, Color(color, 0.25), width * 4.0)
	canvas.draw_polyline(points, color, width)
	canvas.draw_polyline(points, Color(1, 1, 1, 0.85), maxf(1.0, width * 0.4))
