extends RefCounted
## Industrial Aurora: native, resolution-independent field equipment.
const INK := Color("07171d")
const WHITE := Color("e3eee5")
const MUTED := Color("9aafa7")
const CYAN := Color("73efc7")
const GOLD := Color("edb94e")
const RED := Color("ff7864")
const FACE: Texture2D = preload("res://assets/lia_directional/idle.png")
static var _icons: Dictionary = {}

static func text(c: CanvasItem, value: String, p: Vector2, size: int, color: Color = WHITE) -> void:
	c.draw_string(ThemeDB.fallback_font, p.round() + Vector2(0, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.75))
	c.draw_string(ThemeDB.fallback_font, p.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func centered(c: CanvasItem, value: String, p: Vector2, size: int, color: Color = WHITE) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	text(c, value, p - Vector2(width * 0.5, 0), size, color)

static func outline(r: Rect2, cut: float = 9.0) -> PackedVector2Array:
	var p := r.position
	var e := r.end
	return PackedVector2Array([p + Vector2(cut, 0), Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut), e - Vector2(0, cut), e - Vector2(cut, 0), Vector2(p.x + cut, e.y), Vector2(p.x, e.y - cut), p + Vector2(0, cut)])

static func plate(c: CanvasItem, r: Rect2, color: Color, cut: float = 9.0) -> void:
	c.draw_colored_polygon(outline(r, cut), color)

static func edge(c: CanvasItem, r: Rect2, color: Color, width: float = 1.0, cut: float = 9.0) -> void:
	var points := outline(r, cut)
	points.append(points[0])
	c.draw_polyline(points, color, width, false)

static func screw(c: CanvasItem, p: Vector2) -> void:
	c.draw_circle(p + Vector2(0, 1), 3, Color("020b10"))
	c.draw_circle(p, 2.5, Color("8c9685"))
	c.draw_circle(p, 1.6, Color("46524d"))
	c.draw_line(p + Vector2(-1, 1), p + Vector2(1, -1), Color("14232a"), 1)

static func panel(c: CanvasItem, r: Rect2, accent: Color = GOLD) -> void:
	# Layered chamfers form a metal housing, recessed gasket and enamel face.
	plate(c, Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.6), 11)
	plate(c, r, Color("020d12"), 11)
	plate(c, r.grow(-1), Color("8b9986"), 10)
	plate(c, r.grow(-3), Color("293e41"), 9)
	plate(c, r.grow(-5), Color("12272e"), 8)
	edge(c, r.grow(-6), Color("56695f"), 1, 7)
	plate(c, r.grow(-8), Color("030e15"), 6)
	plate(c, r.grow(-10), Color("0c2027"), 5)
	# Subtle horizontal enamel grain, never a full-screen overlay.
	for y in range(int(r.position.y + 13), int(r.end.y - 12), 4):
		c.draw_line(Vector2(r.position.x + 13, y), Vector2(r.end.x - 13, y), Color(0.14, 0.26, 0.28, 0.10), 1)
	c.draw_line(r.position + Vector2(13, 2), Vector2(r.end.x - 15, r.position.y + 2), Color("b1b59a"), 1)
	c.draw_line(Vector2(r.position.x + 14, r.end.y - 3), r.end - Vector2(15, 3), Color("060e14"), 2)
	for x in [r.position.x + 18, r.end.x - 45]:
		c.draw_rect(Rect2(x, r.position.y + 2, 27, 3), Color("8a602c"))
		c.draw_rect(Rect2(x + 2, r.position.y + 2, 19, 1), accent)
	for p in [r.position + Vector2(8, 12), Vector2(r.end.x - 8, r.position.y + 12), r.end - Vector2(8, 12), Vector2(r.position.x + 8, r.end.y - 12)]:
		screw(c, p)
	for i in 3:
		var x: float = r.end.x - 42 + i * 9
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, r.end.y - 7), Vector2(x + 5, r.end.y - 7), Vector2(x + 1, r.end.y - 3), Vector2(x - 4, r.end.y - 3)]), accent.darkened(0.15))

static func inset(c: CanvasItem, r: Rect2) -> void:
	plate(c, r.grow(1), Color("547366"), 4)
	plate(c, r, Color("030f16"), 3)
	c.draw_line(r.position + Vector2(4, 1), Vector2(r.end.x - 4, r.position.y + 1), Color("02070c"), 2)

static func bar(c: CanvasItem, r: Rect2, value: float, color: Color) -> void:
	inset(c, r)
	var filled := Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4) * clampf(value, 0, 1), maxf(1, r.size.y - 4)))
	if filled.size.x > 1:
		c.draw_rect(filled, color.darkened(0.2))
		c.draw_rect(Rect2(filled.position, Vector2(filled.size.x, 1)), color.lightened(0.3))

static func icon(c: CanvasItem, kind: String, r: Rect2, color: Color) -> void:
	if not _icons.has(kind):
		var path := ""
		match kind:
			"pulse": path = '<path d="M5 13h30l-7-5h9l12 8-12 8h-9l7-5H5zm-3 19h30l-7-5h9l12 8-12 8h-9l7-5H2zm3 19h30l-7-5h9l12 8-12 8h-9l7-5H5z" fill="white" transform="translate(3,-3)"/>'
			"dash": path = '<g stroke="white" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"><path d="m34 19-10 12 12 8-13 16m1-24-9 1m21 7 12 7 9-3M31 23l12 6 8-8M4 18h14M1 30h10M6 43h9"/></g><circle cx="42" cy="10" r="6" fill="white"/>'
			"water": path = '<path d="M32 4C27 17 12 29 12 41a20 20 0 0 0 40 0C52 29 37 17 32 4Z" fill="white"/><path d="M21 40q0 12 12 13" stroke="#10282c" stroke-width="4" fill="none"/>'
			"network": path = '<g fill="none" stroke="white" stroke-width="4"><path d="M32 12v40M12 32h40"/><rect x="25" y="3" width="14" height="14" rx="2"/><rect x="25" y="47" width="14" height="14" rx="2"/><rect x="3" y="25" width="14" height="14" rx="2"/><rect x="47" y="25" width="14" height="14" rx="2"/></g>'
			"coil": path = '<path d="M35 3 13 35h17l-4 26 25-35H34Z" fill="white"/><path d="M7 13h9M5 23h7m38 20h9m-13 9h10" stroke="white" stroke-width="3"/>'
			"shield": path = '<path d="M32 4 9 13v19c0 15 23 28 23 28s23-13 23-28V13Z" fill="none" stroke="white" stroke-width="4"/><path d="M29 18h6v10h10v6H35v11h-6V34H19v-6h10Z" fill="white"/>'
			"battery": path = '<g fill="none" stroke="white" stroke-width="4"><rect x="13" y="13" width="38" height="45" rx="5"/><path d="M24 13V5h16v8M24 36h16M32 28v16"/></g>'
			"frequency": path = '<g stroke="white" stroke-width="4" fill="none" stroke-linecap="round"><path d="M4 32h9l7-20 11 40 11-40 7 20h11M8 10h5m38 44h5"/></g>'
			"recycle": path = '<g stroke="white" stroke-width="5" fill="none" stroke-linejoin="round"><path d="m18 24 13-18 12 20M37 13l6 13-14-1m15 8 12 20H32m14 7-14-7 8-12M24 52H7l12-20m-1 14 1-14 14 3"/></g>'
		var source := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">' + path + '</svg>'
		var image := Image.new()
		if image.load_svg_from_string(source) == OK: _icons[kind] = ImageTexture.create_from_image(image)
	if _icons.has(kind): c.draw_texture_rect(_icons[kind], r, false, color)

static func keycap(c: CanvasItem, label: String, r: Rect2) -> void:
	plate(c, Rect2(r.position + Vector2(0, 2), r.size), Color("020b0f"), 3)
	plate(c, r, Color("a18b5c"), 3)
	plate(c, r.grow(-2), Color("e8d9b0"), 2)
	centered(c, label, r.get_center() + Vector2(0, 4), 10, INK)

static func vital(c: CanvasItem, hp: int, maximum: int, time: float) -> void:
	var low := hp <= maxi(2, int(ceil(maximum * 0.3)))
	var color := RED if low else CYAN
	panel(c, Rect2(16, 16, 288, 100), color if low else GOLD)
	inset(c, Rect2(29, 30, 53, 66))
	# Original Lia sprite: front three-quarter head and shoulders, no new identity.
	c.draw_texture_rect_region(FACE, Rect2(31, 32, 49, 60), Rect2(318, 270, 116, 142))
	c.draw_line(Vector2(87, 31), Vector2(87, 95), Color("6b7a60"), 1)
	text(c, "LIA", Vector2(97, 46), 20)
	text(c, "%d/%d" % [hp, maximum], Vector2(236, 46), 20, color)
	text(c, "INTEGRIDADE", Vector2(97, 63), 10, MUTED)
	inset(c, Rect2(96, 71, 192, 17))
	var step := 184.0 / maximum
	for i in maximum:
		var cell := Rect2(100 + i * step, 75, step - 3, 9)
		plate(c, cell, color.darkened(0.2) if i < hp else Color("20383b"), 1)
		if i < hp:
			c.draw_line(cell.position + Vector2(1, 1), Vector2(cell.end.x - 1, cell.position.y + 1), color.lightened(0.4), 1)
			c.draw_rect(cell.grow(1), Color(color, 0.08))
	text(c, "SINAL CRÍTICO" if low else "P17 / AGENTE DE RECUPERAÇÃO", Vector2(98, 102), 8, color if low else MUTED)
	c.draw_circle(Vector2(37, 103), 2, color)
	c.draw_rect(Rect2(46, 101, 20, 3), GOLD.darkened(0.2))
	if low: edge(c, Rect2(18, 18, 284, 96), Color(RED, 0.45 + 0.3 * sin(time * 5)), 2)

static func fit(value: String, width: float, size: int) -> String:
	var font := ThemeDB.fallback_font
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width: return value
	var line := value
	while not line.is_empty():
		line = line.left(line.length() - 1)
		if font.get_string_size(line + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width: return line + "…"
	return ""

static func mission(c: CanvasItem, width: float, title: String, detail: String, status: String, stage: int, restored: int, total: int) -> void:
	var p := Vector2(width - 346, 16)
	panel(c, Rect2(p, Vector2(330, 120)))
	icon(c, "water" if total == 4 else "recycle", Rect2(p + Vector2(16, 17), Vector2(18, 22)), GOLD)
	text(c, fit(title, 270, 14), p + Vector2(42, 32), 14, GOLD)
	c.draw_line(p + Vector2(17, 41), p + Vector2(313, 41), Color("4c6557"), 1)
	text(c, fit(detail, 292, 11), p + Vector2(18, 59), 11, WHITE)
	icon(c, "network", Rect2(p + Vector2(17, 69), Vector2(15, 15)), GOLD)
	text(c, "REDE %d/%d" % [restored, total], p + Vector2(39, 81), 11, CYAN)
	var step := 142.0 / total
	for i in total:
		var node := Rect2(p + Vector2(165 + i * step, 71), Vector2(step - 5, 11))
		bar(c, node, 1 if i < restored else (0.4 if i == stage else 0), CYAN if i < restored else GOLD)
	text(c, fit(status, 292, 9), p + Vector2(18, 100), 9, MUTED)

static func ability(c: CanvasItem, p: Vector2, key: String, label: String, kind: String, remaining: float, duration: float, color: Color) -> void:
	panel(c, Rect2(p, Vector2(108, 116)))
	inset(c, Rect2(p + Vector2(14, 27), Vector2(80, 64)))
	keycap(c, key, Rect2(p + Vector2(34 if key == "Q" else 25, 7), Vector2(39 if key == "Q" else 57, 19)))
	var center := p + Vector2(54, 58)
	c.draw_circle(center, 25, Color("06171d"))
	var charge := 1 - clampf(remaining / maxf(duration, 0.001), 0, 1)
	for i in 10:
		var start := -PI * 0.62 + i * PI * 1.24 / 10
		c.draw_arc(center, 26, start, start + PI * 1.24 / 10 - 0.07, 5, color if float(i + 1) / 10 <= charge + 0.001 else Color("2c4546"), 4, false)
	icon(c, kind, Rect2(center - Vector2(19, 19), Vector2(38, 38)), color if remaining <= 0 else color.darkened(0.35))
	centered(c, label, p + Vector2(54, 98), 10, WHITE)
	centered(c, "PRONTA" if remaining <= 0 else "%.1f s" % remaining, p + Vector2(54, 108), 8, color)
	c.draw_circle(p + Vector2(13, 98), 2, color if remaining <= 0 else RED)

static func abilities(c: CanvasItem, height: float, secondary: float, recharge: float, dash: float, dash_max: float) -> void:
	var p := Vector2(16, height - 132)
	for offset in [Vector2(107, 37), Vector2(107, 73)]:
		c.draw_rect(Rect2(p + offset, Vector2(10, 9)), Color("718077"))
		c.draw_rect(Rect2(p + offset + Vector2(0, 2), Vector2(10, 4)), Color("22373c"))
	ability(c, p, "Q", "RAJADA", "pulse", secondary, recharge, GOLD)
	ability(c, p + Vector2(116, 0), "SHIFT", "ESQUIVA", "dash", dash, dash_max, CYAN)
	text(c, "PULSO: MOUSE / ESPAÇO  •  RAJADA: BOTÃO DIREITO", p + Vector2(1, -7), 8, WHITE)

static func navigation(c: CanvasItem, title: String, subtitle: String, pointer: Vector2 = Vector2(-999, -999)) -> void:
	var p := Vector2(320, 16)
	panel(c, Rect2(p, Vector2(220, 66)))
	for item in [[Rect2(333, 28, 78, 23), "M", "MAPA"], [Rect2(419, 28, 107, 23), "ESC", "PAUSA"]]:
		var r: Rect2 = item[0]
		plate(c, r, Color("253e40") if r.has_point(pointer) else Color("172e33"), 3)
		edge(c, r, GOLD if r.has_point(pointer) else Color("4e655b"), 1, 3)
		var cap_width := 20 if item[1] == "M" else 30
		keycap(c, item[1], Rect2(r.position + Vector2(3, 3), Vector2(cap_width, 16)))
		text(c, item[2], r.position + Vector2(cap_width + 8, 15), 9, WHITE)
	text(c, title, p + Vector2(14, 48), 9, MUTED)
	text(c, fit(subtitle, 194, 8), p + Vector2(14, 58), 8, MUTED)

static func radar(c: CanvasItem, r: Rect2) -> Rect2:
	panel(c, r)
	keycap(c, "M", Rect2(r.position + Vector2(17, 7), Vector2(21, 17)))
	text(c, "MAPA / AURORA", r.position + Vector2(46, 19), 9, MUTED)
	var area := Rect2(r.position + Vector2(16, 30), r.size - Vector2(32, 45))
	inset(c, area.grow(2))
	return area
## Every card is a real upgrade option; this lookup is presentation only.
static func perk_visual(id: String) -> Dictionary:
	var data := {
		"focused_pulse": ["pulse", "+25%", "CADÊNCIA", "OFENSIVA", GOLD],
		"reserve_cell": ["battery", "+2", "INTEGRIDADE", "PROTEÇÃO", CYAN],
		"light_harness": ["dash", "+25", "VELOCIDADE", "MOBILIDADE", CYAN],
		"induction_coil": ["coil", "+1", "DANO POR PULSO", "OFENSIVA", GOLD],
		"reclaimed_armor": ["shield", "+2", "INTEGRIDADE", "PROTEÇÃO", CYAN],
		"efficient_dash": ["dash", "−0,25 s", "RECARGA", "MOBILIDADE", CYAN],
		"clean_frequency": ["frequency", "+20%", "CADÊNCIA", "OFENSIVA", GOLD],
		"living_circuit": ["shield", "+2", "INTEGRIDADE", "PROTEÇÃO", CYAN],
		"water_stride": ["dash", "−0,15 s", "RECARGA", "MOBILIDADE", CYAN],
	}
	var values: Array = data.get(id, ["network", "P17", "MÓDULO", "EQUIPAMENTO", GOLD])
	return {"icon": values[0], "stat": values[1], "effect": values[2], "category": values[3], "color": values[4]}

static func perk_card(c: CanvasItem, r: Rect2, id: String, index: int, hover: bool) -> void:
	var visual := perk_visual(id)
	var color: Color = visual.color
	var p := r.position
	panel(c, r, color if hover else GOLD)
	if hover:
		plate(c, r.grow(-11), Color(color, 0.045), 5)
		edge(c, r.grow(-3), color, 2, 9)
	# A removable cartridge with an inset icon display and physical shortcut.
	panel(c, Rect2(p + Vector2(21, 23), Vector2(79, 75)), color)
	var center := p + Vector2(60, 60)
	c.draw_circle(center, 23, INK)
	for tick in 8:
		var angle := tick * TAU / 8
		c.draw_arc(center, 23, angle, angle + 0.37, 4, Color(color, 0.8 if hover else 0.35), 2)
	icon(c, visual.icon, Rect2(center - Vector2(18, 18), Vector2(36, 36)), color)
	keycap(c, str(index + 1), Rect2(p + Vector2(r.size.x - 48, 23), Vector2(27, 22)))
	text(c, visual.category, p + Vector2(114, 43), 9, color)
	text(c, visual.stat, p + Vector2(114, 71), 23, WHITE)
	text(c, visual.effect, p + Vector2(114, 89), 8, MUTED)
	c.draw_line(p + Vector2(24, 161), p + Vector2(r.size.x - 24, 161), Color("4c6557"), 1)
	var install := Rect2(p + Vector2(21, r.size.y - 49), Vector2(r.size.x - 42, 29))
	plate(c, install, Color("304c45") if hover else Color("172e33"), 4)
	edge(c, install, color if hover else Color("56695f"), 1, 4)
	c.draw_circle(install.position + Vector2(13, 14), 2, color)
	centered(c, "INSTALAR MÓDULO  →", install.get_center() + Vector2(4, 4), 10, color if hover else WHITE)
## Shared industrial control: one visual and one matching click target.
static func control(c: Node2D, r: Rect2, label: String, id: String, key: String = "", accent: Color = GOLD) -> void:
	var hover: bool = r.has_point(c.pointer)
	plate(c, Rect2(r.position + Vector2(0, 2), r.size), Color("020b10"), 4)
	plate(c, r, accent if hover else Color("56695f"), 4)
	plate(c, r.grow(-2), Color("2b4843") if hover else Color("142b32"), 3)
	var area := r.grow(-5)
	if not key.is_empty():
		var cap_width := maxf(20, ThemeDB.fallback_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 10)
		keycap(c, key, Rect2(r.position + Vector2(4, 3), Vector2(cap_width, r.size.y - 6)))
		area.position.x += cap_width + 5
		area.size.x -= cap_width + 5
	centered(c, fit(label, area.size.x - 2, 9), area.get_center() + Vector2(0, 3), 9, accent if hover else WHITE)
	c.buttons.append({"rect": r, "id": id})