extends Control

const M = preload("res://scripts/residue_map.gd")
const WHITE := Color("e9ece0")
const CYAN := Color("7be4ce")
const GOLD := Color("e8bd74")
const PINK := Color("e36b92")
const INK := Color("091922")
var game: Node2D

func _draw() -> void:
	if game == null: return
	var size := get_viewport_rect().size
	var stage: int = game.stage
	var objective: String = game.objective_label()
	var goal: Vector2 = game.objective_point()
	var direction: Vector2 = goal - game.pos
	var direction_text := "●" if direction.length() < 65 else _direction(direction)
	draw_rect(Rect2(0, 0, size.x, 78), Color(INK, 0.92))
	draw_rect(Rect2(0, 78, size.x, 2), Color("42615e"))
	_text("DISTRITO 02  /  RESÍDUOS", Vector2(24, 24), 12, CYAN)
	_text(["TRIAGEM AURORA", "RECICLAGEM PRISMA", "COMPOSTAGEM ÍRIS", "REGISTRO RECUPERADO"][stage], Vector2(24, 52), 19, WHITE)
	for i in 3:
		var x := size.x - 160 + i * 42
		draw_rect(Rect2(x, 21, 30, 5), CYAN if game.terminal_on[i] else Color("6b5144"))
		_text(str(i + 1), Vector2(x + 10, 47), 11, CYAN if game.terminal_on[i] else GOLD)
	var box_width := minf(size.x - 60, 550)
	var box := Rect2((size.x - box_width) * 0.5, 87, box_width, 42)
	draw_rect(box, Color(INK, 0.9))
	draw_rect(Rect2(box.position.x, box.position.y, 3, 42), GOLD)
	_text(direction_text + "  " + objective, box.position + Vector2(17, 26), 12, WHITE)
	var hp_y := size.y - 70
	draw_rect(Rect2(17, hp_y - 25, 235, 62), Color(INK, 0.91))
	_text("INTEGRIDADE", Vector2(29, hp_y - 7), 10, WHITE)
	for i in game.max_hp:
		var col := CYAN if i < game.hp else Color("3c5458")
		draw_rect(Rect2(29 + i * 27, hp_y + 4, 21, 12), col)
	var carried: int = game.carried
	if carried >= 0:
		var r := Rect2(size.x - 244, size.y - 72, 227, 55)
		draw_rect(r, Color(INK, 0.93))
		_text("MATERIAL EM MÃOS", r.position + Vector2(14, 18), 10, WHITE)
		_text(M.MATERIAL_GLYPHS[carried] + "  " + M.MATERIALS[carried], r.position + Vector2(14, 43), 14, M.MATERIAL_COLORS[carried])
	else:
		_text("WASD  MOVER   •   E  OPERAR   •   M  MAPA", Vector2(size.x - 343, size.y - 21), 10, Color("c4d4cb"))
	if game.hold_progress > 0.0:
		var bar := Rect2(size.x * 0.5 - 135, size.y - 97, 270, 11)
		draw_rect(bar, Color(INK, 0.94))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * game.hold_progress, 11)), CYAN)
	if game.toast_time > 0:
		var r2 := Rect2(size.x * 0.5 - 265, 138, 530, 37)
		draw_rect(r2, Color(INK, 0.95))
		draw_rect(Rect2(r2.position, Vector2(3, 37)), GOLD)
		_text_center(game.toast, r2.get_center() + Vector2(0, 4), 12, WHITE)
	if game.state == "defeat":
		_overlay("CONEXÃO INTERROMPIDA", "R reinicia o Distrito de Resíduos")
	elif game.state == "victory":
		_overlay("DISTRITO RECUPERADO", "Liga, polímero e vidro técnico encontrados no núcleo da IA.")
		_text_center("R retorna ao Distrito das Águas", Vector2(size.x * 0.5, size.y * 0.5 + 71), 12, CYAN)
	elif game.state == "pause":
		_overlay("OPERAÇÃO PAUSADA", "ESC continua  /  R reinicia o distrito")
	elif game.state == "map":
		_draw_map(size)
	if game.state == "play":
		var aim: Vector2 = game.pointer
		draw_line(aim + Vector2(-7, 0), aim + Vector2(-2, 0), CYAN, 1)
		draw_line(aim + Vector2(2, 0), aim + Vector2(7, 0), CYAN, 1)
		draw_line(aim + Vector2(0, -7), aim + Vector2(0, -2), CYAN, 1)
		draw_line(aim + Vector2(0, 2), aim + Vector2(0, 7), CYAN, 1)

func _overlay(title: String, subtitle: String) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.87))
	_text_center(title, Vector2(size.x * 0.5, size.y * 0.5 - 30), 30, WHITE)
	_text_center(subtitle, Vector2(size.x * 0.5, size.y * 0.5 + 20), 14, GOLD)

func _draw_map(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.95))
	_text("MAPA  /  DISTRITO DE RESÍDUOS", Vector2(45, 55), 20, CYAN)
	_text("COLETA → TRIAGEM → RECICLAGEM / COMPOSTAGEM", Vector2(46, 81), 11, WHITE)
	var area := Rect2(56, 110, size.x - 112, size.y - 195)
	var scale_x := area.size.x / M.SIZE.x
	var scale_y := area.size.y / M.SIZE.y
	for i in 3:
		var x: float = [90.0, 830.0, 1620.0][i]
		var width: float = [700.0, 750.0, 690.0][i]
		var r := Rect2(area.position + Vector2(x * scale_x, 90 * scale_y), Vector2(width * scale_x, 1320 * scale_y))
		draw_rect(r, Color("24434b") if i <= game.stage else Color("172d37"))
		draw_rect(r, CYAN if game.terminal_on[i] else GOLD, false, 2)
		_text(["AURORA", "PRISMA", "ÍRIS"][i], r.position + Vector2(13, 27), 13, WHITE)
		_text("ONLINE" if game.terminal_on[i] else "OFFLINE", r.position + Vector2(13, 49), 10, CYAN if game.terminal_on[i] else GOLD)
		var tp: Vector2 = M.TERMINALS[i]
		draw_circle(area.position + Vector2(tp.x * scale_x, tp.y * scale_y), 5, CYAN if game.terminal_on[i] else GOLD)
	var target: Vector2 = game.objective_point()
	var target_screen := area.position + Vector2(target.x * scale_x, target.y * scale_y)
	draw_arc(target_screen, 11, 0, TAU, 24, GOLD, 2)
	var lia: Vector2 = game.pos
	var lia_screen := area.position + Vector2(lia.x * scale_x, lia.y * scale_y)
	draw_circle(lia_screen, 6, WHITE)
	_text("LIA", lia_screen + Vector2(10, 5), 10, WHITE)
	_text("● LIA     ◎ PRÓXIMO OBJETIVO     M OU ESC PARA VOLTAR", Vector2(57, size.y - 37), 11, WHITE)

func _direction(vector: Vector2) -> String:
	var angle := vector.angle()
	var index := posmod(int(round(angle / (PI / 4.0))), 8)
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][index]

func _text(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_center(value: String, point: Vector2, size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, point - Vector2(width * 0.5, 0), size, color)
