extends RefCounted
## Industrial Aurora: native, resolution-independent field equipment.
const INK := Color("07171d")
const Gamepad = preload("res://scripts/gamepad.gd")
const WHITE := Color("e3eee5")
const MUTED := Color("9aafa7")
const CYAN := Color("73efc7")
const GOLD := Color("edb94e")
const RED := Color("ff7864")
const FACE: Texture2D = preload("res://assets/lia_directional/idle.png")
static var _icons: Dictionary = {}
static var text_scale_percent := 100

static func font_size(size: int) -> int:
	return roundi(size * text_scale_percent / 100.0)

static func text(c: CanvasItem, value: String, p: Vector2, size: int, color: Color = WHITE) -> void:
	c.draw_string(ThemeDB.fallback_font, p.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(size), color)

static func centered(c: CanvasItem, value: String, p: Vector2, size: int, color: Color = WHITE) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(size)).x
	text(c, value, p - Vector2(width * 0.5, 0), size, color)

static func outline(r: Rect2, cut: float = 9.0) -> PackedVector2Array:
	var p := r.position
	var e := r.end
	cut = clampf(cut, 0.0, maxf(0.0, minf(r.size.x, r.size.y) * 0.5 - 0.5))
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

static func compact_panel(c: CanvasItem, rect: Rect2, accent: Color = GOLD) -> void:
	plate(c, Rect2(rect.position + Vector2(0, 2), rect.size), Color(0, 0, 0, 0.4), 5)
	plate(c, rect, Color(INK, 0.93), 5)
	edge(c, rect, Color("556c63"), 1, 5)
	c.draw_line(rect.position + Vector2(8, 1), rect.position + Vector2(34, 1), accent, 2)


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
			"grounded": path = '<g stroke="white" stroke-width="4" fill="none" stroke-linecap="round"><path d="M32 4v26M14 30h36M20 39h24M26 48h12M30 57h4"/></g><path d="M40 6 31 20h7l-4 10 11-15h-7Z" fill="white"/>'
			"chain": path = '<g fill="none" stroke="white" stroke-width="4"><circle cx="13" cy="44" r="8"/><circle cx="51" cy="20" r="8"/></g><path d="M20 39 30 28l2 8 10-13" stroke="white" stroke-width="4" fill="none" stroke-linejoin="round"/><path d="M38 52h18M8 12h14" stroke="white" stroke-width="3"/>'
			"sun": path = '<circle cx="32" cy="32" r="11" fill="white"/><g stroke="white" stroke-width="4" stroke-linecap="round"><path d="M32 4v9M32 51v9M4 32h9M51 32h9M12 12l6 6M46 46l6 6M12 52l6-6M46 18l6-6"/></g>'
			"recycle": path ='<g stroke="white" stroke-width="5" fill="none" stroke-linejoin="round"><path d="m18 24 13-18 12 20M37 13l6 13-14-1m15 8 12 20H32m14 7-14-7 8-12M24 52H7l12-20m-1 14 1-14 14 3"/></g>'
		var source := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">' + path + '</svg>'
		var image := Image.new()
		if image.load_svg_from_string(source) == OK: _icons[kind] = ImageTexture.create_from_image(image)
	if _icons.has(kind): c.draw_texture_rect(_icons[kind], r, false, color)

static func keycap(c: CanvasItem, label: String, r: Rect2) -> void:
	plate(c, Rect2(r.position + Vector2(0, 2), r.size), Color("020b0f"), 3)
	plate(c, r, Color("a18b5c"), 3)
	plate(c, r.grow(-2), Color("e8d9b0"), 2)
	centered(c, Gamepad.hint(label), r.get_center() + Vector2(0, 4), 10, INK)

static func vital(c: CanvasItem, hp: int, maximum: int, time: float) -> void:
	var low := hp <= maxi(2, ceili(maximum * 0.3))
	var accent := RED if low else CYAN
	compact_panel(c, VITAL_RECT, accent)
	c.draw_texture_rect_region(FACE, Rect2(19, 17, 31, 40), Rect2(318, 270, 116, 142))
	text(c, "LIA", Vector2(59, 30), 13)
	text(c, "%d/%d" % [hp, maximum], Vector2(169, 30), 13, accent)
	var track := Rect2(59, 39, 144, 8)
	c.draw_rect(track, Color("263b40"))
	c.draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(float(hp) / maximum, 0, 1), 8)), accent)
	for i in range(1, maximum):
		var x := track.position.x + track.size.x * i / maximum
		c.draw_line(Vector2(x, 39), Vector2(x, 47), INK, 2)
	if low: text(c, "SINAL CRÍTICO", Vector2(59, 61), 9, RED)

static func fit(value: String, width: float, size: int) -> String:
	var font := ThemeDB.fallback_font
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(size)).x <= width: return value
	var line := value
	while not line.is_empty():
		line = line.left(line.length() - 1)
		if font.get_string_size(line + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(size)).x <= width: return line + "…"
	return ""

static func chevron(canvas: CanvasItem, at: Vector2, direction: Vector2, color: Color, scale: float = 1.0) -> void:
	for offset in [0.0, -10.0]:
		var tip: Vector2 = at + direction * offset * scale
		var left := tip + direction.rotated(2.52) * 16.0 * scale
		var right := tip + direction.rotated(-2.52) * 16.0 * scale
		var chevron := PackedVector2Array([left, tip, right])
		canvas.draw_polyline(chevron, Color(INK, color.a), 8.0 * scale, true)
		canvas.draw_polyline(chevron, color, 4.0 * scale, true)


static func mission(c: CanvasItem, width: float, title: String, detail: String, status: String, stage: int,
		restored: int, total: int, kind: String, guide: RefCounted, time: float) -> void:
	var rect := mission_rect(width)
	compact_panel(c, rect)
	icon(c, kind, Rect2(rect.position + Vector2(12, 10), Vector2(14, 17)), GOLD)
	text(c, fit(title, 270, 12), rect.position + Vector2(34, 23), 12, GOLD)
	text(c, fit(detail, 290, 12), rect.position + Vector2(12, 45), 12)
	var progress := Rect2(rect.position + Vector2(12, 59), Vector2(54, 4))
	for i in total:
		var cell := Rect2(progress.position + Vector2(i * 14, 0), Vector2(10, 4))
		c.draw_rect(cell, CYAN if i < restored else GOLD if i == stage else Color("314a4c"))
	text(c, fit(status, 224, 9), rect.position + Vector2(83, 65), 9, MUTED)
	if guide.highlight > 0.0 and guide.intensity == 2:
		edge(c, rect, Color(GOLD, guide.highlight), 1, 5)


const CAMPAIGN := ["ÁGUAS", "RESÍDUOS", "ENERGIA", "NÚCLEO"]
const CAMPAIGN_RECT := Rect2(312, 96, 236, 62)
const VITAL_RECT := Rect2(12, 12, 204, 56)
const MAP_BUTTON := Rect2(230, 14, 63, 25)
const PAUSE_BUTTON := Rect2(299, 14, 82, 25)
const GUIDE_BOTTOM := 124.0


static func mission_rect(width: float) -> Rect2:
	return Rect2(width - 328, 12, 316, 78)


static func radar_rect(size: Vector2) -> Rect2:
	return Rect2(size.x - 142, size.y - 118, 130, 106)


static func guide_safe_rect(size: Vector2, dialogue_top: float = -1.0, hud_bottom: float = 90.0, reserve: float = GUIDE_BOTTOM) -> Rect2:
	var top := maxf(90.0, hud_bottom) + 12.0
	var bottom := size.y - reserve
	if dialogue_top >= 0.0:
		bottom = minf(bottom, dialogue_top - 18.0)
	return Rect2(20.0, top, size.x - 40.0, maxf(52.0, bottom - top))


static func prompt(c: CanvasItem, size: Vector2, key: String, verb: String, color: Color = GOLD, progress: float = -1.0) -> void:
	var r := Rect2(size.x * 0.5 - 218, size.y - 60, 436, 40)
	compact_panel(c, r, color)
	var x := 12.0
	if progress >= 0.0:
		text(c, "SEGURE", r.position + Vector2(x, 23), 9, color)
		x += 48.0
	if not key.is_empty():
		keycap(c, key, Rect2(r.position + Vector2(x, 8), Vector2(27, 19)))
		x += 36.0
	text(c, fit(verb, r.size.x - x - 12, 12), r.position + Vector2(x, 23), 12)
	if progress >= 0.0:
		c.draw_rect(Rect2(r.position + Vector2(12, 33), Vector2((r.size.x - 24) * progress, 3)), color)

static func interaction(c: CanvasItem, at: Vector2, time: float) -> void:
	var ring := PackedVector2Array()
	for i in 33:
		var angle := TAU * i / 32.0
		ring.append(at + Vector2(cos(angle) * 23.0, sin(angle) * 11.5))
	c.draw_polyline(ring, Color(CYAN, 0.77 + 0.13 * sin(time * TAU * 1.2)), 2, true)
	keycap(c, "E", Rect2(at + Vector2(-11, -61), Vector2(22, 18)))

static func campaign(c: CanvasItem, current: int, time: float) -> void:
	var r := CAMPAIGN_RECT
	panel(c, r)
	var operation := "OPERAÇÃO AURORA" if text_scale_percent == 100 else "AURORA"
	var title := "%s  •  DISTRITO %d/3" % [operation, mini(current + 1, 3)]
	if current >= 3:
		var milestone := "CONFRONTO FINAL" if current == 3 else "CONCLUÍDA"
		title = operation + "  •  " + milestone
	text(c, fit(title, r.size.x - 23, 10), r.position + Vector2(12, 20), 10, MUTED)
	var nodes: Array[Vector2] = []
	for i in CAMPAIGN.size(): nodes.append(r.position + Vector2(33 + i * 56.0, 33))
	for i in CAMPAIGN.size() - 1:
		c.draw_line(nodes[i] + Vector2(6, 0), nodes[i + 1] - Vector2(6, 0), CYAN.darkened(0.25) if i < current else Color("38504d"), 2)
	for i in CAMPAIGN.size():
		var p := nodes[i]
		if i < current:
			c.draw_circle(p, 5, CYAN)
			c.draw_polyline(PackedVector2Array([p + Vector2(-2.5, 0), p + Vector2(-0.5, 2), p + Vector2(2.5, -2)]), INK, 1.5)
		elif i == current:
			c.draw_circle(p, 7 + sin(time * 4.0), Color(GOLD, 0.18))
			c.draw_circle(p, 5, GOLD)
			c.draw_circle(p, 2, INK)
		else:
			c.draw_arc(p, 4.5, 0, TAU, 16, Color("587069"), 1.5)
		centered(c, CAMPAIGN[i], p + Vector2(0, 16), 9, GOLD if i == current else (CYAN if i < current else MUTED))

## Ordered beats of the current sector, in the slot under the vital panel
## that Energy uses for its system readouts.
static func checklist(c: CanvasItem, title: String, kind: String, labels: Array, done: int, time: float) -> void:
	var r := Rect2(16, 124, 288, 70)
	panel(c, r)
	icon(c, kind, Rect2(r.position + Vector2(14, 11), Vector2(18, 20)), GOLD)
	text(c, fit(title, 236, 10), r.position + Vector2(42, 26), 10, GOLD)
	var count := labels.size()
	var step := 256.0 / count
	for i in count:
		var cell := Rect2(r.position + Vector2(16 + i * step, 36), Vector2(step - 5, 9))
		var current := i == done
		bar(c, cell, 1.0 if i < done else (0.35 + 0.15 * sin(time * 4.0) if current else 0.0), CYAN if i < done else GOLD)
		if current: edge(c, cell.grow(2), Color(GOLD, 0.7), 1, 2)
		var label := str(labels[i]).capitalize()
		centered(c, fit(label, step - 1, 9), Vector2(cell.get_center().x, r.position.y + 58), 9, GOLD if current else (CYAN if i < done else MUTED))

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
	centered(c, "PRONTA" if remaining <= 0 else "%.1f s" % remaining, p + Vector2(54, 110), 10, color)
	c.draw_circle(p + Vector2(13, 98), 2, color if remaining <= 0 else RED)

static func abilities(c: CanvasItem, height: float, secondary: float, recharge: float, dash: float, dash_max: float) -> void:
	for entry in [[0, "Q", "RAJADA", secondary, recharge, GOLD], [110, "SHIFT", "ESQUIVA", dash, dash_max, CYAN]]:
		var rect := Rect2(12 + entry[0], height - 54, 102, 42)
		var remaining: float = entry[3]
		var duration: float = entry[4]
		var accent: Color = entry[5]
		compact_panel(c, rect, accent)
		keycap(c, entry[1], Rect2(rect.position + Vector2(6, 7), Vector2(34 if entry[1] == "SHIFT" else 22, 18)))
		var x := 44.0 if entry[1] == "SHIFT" else 34.0
		text(c, entry[2], rect.position + Vector2(x, 19), 9, accent if remaining <= 0 else MUTED)
		if remaining > 0.0:
			text(c, "%.1f s" % remaining, rect.position + Vector2(8, 34), 9, MUTED)
		var amount := 1.0 - clampf(remaining / maxf(duration, 0.01), 0, 1)
		c.draw_rect(Rect2(rect.position + Vector2(8, 35), Vector2(86 * amount, 3)), accent)

static func navigation(c: CanvasItem, title: String, subtitle: String, pointer: Vector2 = Vector2(-999, -999)) -> void:
	for item in [[MAP_BUTTON, "M", "MAPA"], [PAUSE_BUTTON, "ESC", "PAUSA"]]:
		var r: Rect2 = item[0]
		plate(c, r, Color("253e40") if r.has_point(pointer) else Color(INK, 0.9), 4)
		edge(c, r, GOLD if r.has_point(pointer) else Color("4e655b"), 1, 4)
		var cap_width := 30 if Gamepad.active else (19 if item[1] == "M" else 29)
		keycap(c, item[1], Rect2(r.position + Vector2(4, 4), Vector2(cap_width, 16)))
		text(c, item[2], r.position + Vector2(cap_width + 9, 16), 9)

static func radar(c: CanvasItem, r: Rect2) -> Rect2:
	compact_panel(c, r)
	text(c, "MAPA", r.position + Vector2(10, 17), 9, MUTED)
	var area := Rect2(r.position + Vector2(8, 23), r.size - Vector2(16, 31))
	c.draw_rect(area, Color("0b2027"))
	return area

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
		"grounded_suit": ["grounded", "−50%", "DANO ELÉTRICO", "PROTEÇÃO", CYAN],
		"steady_hand": ["frequency", "+30%", "JANELA DE SINCRONIA", "OPERAÇÃO", GOLD],
		"conductive_pulse": ["chain", "×2", "ALVOS POR PULSO", "OFENSIVA", GOLD],
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
	var label_size := 12 if r.size.y>=35 else 9
	var area := r.grow(-5)
	if not key.is_empty():
		var cap_width := maxf(20, ThemeDB.fallback_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(9)).x + 10)
		var cap_height := minf(24,r.size.y-6)
		keycap(c,key,Rect2(r.position+Vector2(4,(r.size.y-cap_height)/2),Vector2(cap_width,cap_height)))
		area.position.x += cap_width + 5
		area.size.x -= cap_width + 5
	centered(c, fit(label, area.size.x - 2, label_size), area.get_center() + Vector2(0, 4), label_size, accent if hover else WHITE)
	c.buttons.append({"rect": r, "id": id})
static func menu_button(c: Node2D, r: Rect2, label: String, id: String, primary: bool = false, focused: bool = false) -> void:
	var active := focused or r.has_point(c.pointer)
	if primary:
		panel(c,r,CYAN)
		plate(c,r.grow(-9),Color("264c45") if active else Color("173b36"),3)
		c.draw_rect(Rect2(r.position+Vector2(11,11),Vector2(3,r.size.y-22)),CYAN)
		text(c,fit(label,r.size.x-58,14),r.position+Vector2(23,r.size.y/2+5),14,CYAN)
		var arrow := r.position+Vector2(r.size.x-26,r.size.y/2)
		c.draw_line(arrow-Vector2(6,0),arrow+Vector2(6,0),CYAN,1)
		c.draw_polyline(PackedVector2Array([arrow+Vector2(1,-5),arrow+Vector2(6,0),arrow+Vector2(1,5)]),CYAN,1)
		if active: edge(c,r.grow(-3),CYAN,2)
	else:
		if active:
			plate(c,r,Color("19352f"),3)
			c.draw_rect(Rect2(r.position+Vector2(2,7),Vector2(2,r.size.y-14)),GOLD)
		c.draw_line(r.position+Vector2(3,r.size.y-1),r.end-Vector2(3,1),Color("415c54"),1)
		text(c,fit(label,r.size.x-23,12),r.position+Vector2(15,r.size.y/2+4),12,CYAN if active else WHITE)
	c.buttons.append({"rect":r,"id":id})