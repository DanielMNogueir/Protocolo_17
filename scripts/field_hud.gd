extends RefCounted
## Aurora field equipment: a shared visual vocabulary for both districts.
const INK = Color("091922")
const WHITE = Color("edf5ef")
const MUTED = Color("a6bdbb")
const CYAN = Color("7be4ce")
const GOLD = Color("e8bd74")
const RED = Color("ff8079")

static func text(c: CanvasItem, value: String, p: Vector2, size: int, color: Color = WHITE) -> void:
	c.draw_string(ThemeDB.fallback_font, p.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func panel(c: CanvasItem, r: Rect2, accent: Color = CYAN) -> void:
	c.draw_rect(Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.24))
	c.draw_rect(r, Color(INK, 0.96))
	c.draw_rect(r, Color("385459"), false, 1)
	c.draw_line(r.position, r.position + Vector2(r.size.x * 0.38, 0), accent, 2)
	c.draw_line(r.end - Vector2(14, 0), r.end, accent, 2)

static func bar(c: CanvasItem, r: Rect2, value: float, color: Color) -> void:
	c.draw_rect(r, Color("2a424b"))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(value, 0, 1), r.size.y)), color)

static func vital(c: CanvasItem, hp: int, maximum: int, time: float) -> void:
	var low := hp <= maxi(2, int(ceil(maximum * 0.3)))
	var color := RED if low else CYAN
	panel(c, Rect2(20, 20, 246, 94), color)
	text(c, "LIA", Vector2(34, 44), 20)
	text(c, "AGENTE / 17", Vector2(88, 43), 10, MUTED)
	text(c, "%02d" % hp, Vector2(202, 47), 24, color)
	text(c, "INTEGRIDADE" + (" CRÍTICA" if low else " ESTÁVEL"), Vector2(34, 64), 10, color)
	var spacing := 218.0 / maximum
	for i in maximum:
		c.draw_rect(Rect2(34 + i * spacing, 75, spacing - 3, 11), color if i < hp else Color("2a424b"))
	text(c, "RECUPERAÇÃO DE AURORA", Vector2(34, 102), 9, MUTED)
	text(c, "/ %02d" % maximum, Vector2(208, 102), 10, MUTED)
	if low:
		c.draw_rect(Rect2(20, 20, 246, 94), Color(RED, 0.35 + sin(time * 5) * 0.2), false, 2)

static func mission(c: CanvasItem, width: float, title: String, detail: String, status: String, stage: int, restored: int, total: int) -> void:
	var p := Vector2(width - 360, 20)
	panel(c, Rect2(p, Vector2(340, 114)), GOLD)
	text(c, "OPERAÇÃO %02d  /  REDE %d/%d" % [mini(stage, total - 1) + 1, restored, total], p + Vector2(14, 20), 10, GOLD)
	text(c, title, p + Vector2(14, 44), 15)
	var font := ThemeDB.fallback_font
	var line := detail
	while font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x > 307 and line.length() > 1:
		line = line.left(line.length() - 2) + "…"
	text(c, line, p + Vector2(14, 64), 11, CYAN)
	text(c, status, p + Vector2(14, 83), 10, MUTED)
	for i in total:
		var step := 312.0 / total
		bar(c, Rect2(p + Vector2(14 + i * step, 97), Vector2(step - 5, 4)), 1, CYAN if i < restored else (GOLD if i == stage else Color("2a424b")))

static func abilities(c: CanvasItem, height: float, secondary: float, recharge: float, dash: float, dash_max: float) -> void:
	var p := Vector2(20, height - 106)
	panel(c, Rect2(p, Vector2(246, 86)))
	text(c, "PULSO / MOUSE OU ESPAÇO", p + Vector2(14, 19), 10, MUTED)
	text(c, "Q", p + Vector2(14, 42), 14, GOLD)
	text(c, "RAJADA / B.DIR", p + Vector2(45, 40), 10)
	text(c, "PRONTA" if secondary <= 0 else "%.1f s" % secondary, p + Vector2(175, 40), 10, GOLD)
	bar(c, Rect2(p + Vector2(45, 46), Vector2(185, 3)), 1 - secondary / recharge, GOLD)
	text(c, "SHIFT", p + Vector2(12, 68), 9, CYAN)
	text(c, "ESQUIVA", p + Vector2(57, 66), 11)
	text(c, "PRONTA" if dash <= 0 else "%.1f s" % dash, p + Vector2(175, 66), 10, CYAN)
	bar(c, Rect2(p + Vector2(57, 73), Vector2(173, 3)), 1 - dash / dash_max, CYAN)
static func navigation(c: CanvasItem, title: String, subtitle: String) -> void:
	panel(c, Rect2(282, 20, 218, 94), Color("597979"))
	text(c, title, Vector2(296, 41), 11)
	text(c, subtitle, Vector2(296, 101), 9, MUTED)
	for entry in [[Rect2(296, 52, 78, 28), "M  MAPA"], [Rect2(382, 52, 104, 28), "ESC  PAUSA"]]:
		c.draw_rect(entry[0], Color("15313a"))
		c.draw_rect(entry[0], Color("416264"), false, 1)
		text(c, entry[1], entry[0].position + Vector2(10, 18), 9)