extends Control

const M = preload("res://scripts/residue_map.gd")
const WHITE := Color("e9ece0")
const CYAN := Color("7be4ce")
const GOLD := Color("e8bd74")
const INK := Color("091922")
var game: Node2D

func _draw() -> void:
	if game == null: return
	var size := get_viewport_rect().size
	_panel(Rect2(20, 18, 265, 81))
	_text("LIA  /  AGENTE DE RECUPERAÇÃO", Vector2(34, 38), 11, CYAN)
	_text("DISTRITO DE RESÍDUOS", Vector2(34, 57), 10, WHITE)
	var spacing := minf(25.0, 185.0 / game.max_hp)
	for i in game.max_hp:
		draw_rect(Rect2(34 + i * spacing, 69, spacing - 4, 10), CYAN if i < game.hp else Color("334d52"))
	_text("%d / %d" % [game.hp, game.max_hp], Vector2(236, 79), 10, WHITE)
	var r := Rect2(size.x - 392, 18, 372, 92)
	_panel(r)
	_text("SISTEMAS RESTAURADOS: %d / 3" % mini(game.stage, 3), r.position + Vector2(16, 20), 10, CYAN)
	_text(["CENTRO DE TRIAGEM", "USINA DE RECICLAGEM", "UNIDADE DE COMPOSTAGEM", "DISTRITO RECUPERADO"][game.stage], r.position + Vector2(16, 42), 14, WHITE)
	var direction: Vector2 = game.guidance_point() - game.pos
	_text(_direction(direction) + "  " + game.objective_label(), r.position + Vector2(16, 62), 10, GOLD)
	for i in 3: draw_rect(Rect2(r.position + Vector2(16 + i * 114, 76), Vector2(103, 3)), CYAN if game.terminal_on[i] else Color("3b5053"))
	_panel(Rect2(20, size.y - 65, 234, 46))
	_text("WASD MOVER  •  M MAPA  •  ESC PAUSA", Vector2(31, size.y - 44), 9, WHITE)
	_text("MOUSE PULSO  •  Q RAJADA  •  SHIFT ESQUIVA", Vector2(31, size.y - 28), 8, CYAN)
	var mini_map := Rect2(size.x - 179, size.y - 132, 159, 106)
	_panel(mini_map.grow(5))
	_draw_plan(mini_map, false)
	var candidate: Dictionary = game._interaction_candidate()
	if not candidate.is_empty():
		var message := ""
		match candidate.kind:
			"item": message = "E  •  RECOLHER " + M.MATERIALS[candidate.index]
			"bin": message = "E  •  ENTREGAR " + M.MATERIALS[game.carried]
			"block": message = "SEGURE E  •  " + ("DESOBSTRUIR ESTEIRA" if candidate.index < 2 else "REABRIR VENTILAÇÃO")
			"terminal": message = "SEGURE E  •  RESTAURAR SISTEMA"
		var box := Rect2(size.x * 0.5 - 200, size.y - 70, 400, 44)
		_panel(box)
		_text_center(message, box.get_center() + Vector2(0, 3), 11, CYAN)
		if game.hold_progress > 0: draw_rect(Rect2(box.position + Vector2(0, 41), Vector2(400 * game.hold_progress, 3)), CYAN)
	elif game.carried >= 0:
		_text_center("EM MÃOS: " + M.MATERIALS[game.carried] + "  /  PROCURE A BAIA", Vector2(size.x * 0.5, size.y - 38), 11, GOLD)
	if game.bin_lock > 0:
		_text_center("TRIAGEM REINICIANDO  /  %.1f s" % game.bin_lock, Vector2(size.x * 0.5, size.y - 88), 11, GOLD)
	if game.toast_time > 0:
		var toast := Rect2(size.x * 0.5 - 265, 119, 530, 34)
		_panel(toast)
		_text_center(game.toast, toast.get_center() + Vector2(0, 4), 10, WHITE)
	match game.state:
		"defeat": _overlay("CONEXÃO INTERROMPIDA", "R reinicia o Distrito de Resíduos")
		"victory":
			_overlay("DISTRITO RECUPERADO", "Liga, polímero e vidro técnico encontrados no núcleo da IA.")
			_text_center("R retorna ao Distrito das Águas", Vector2(size.x * 0.5, size.y * 0.5 + 71), 12, CYAN)
		"pause": _overlay("OPERAÇÃO PAUSADA", "ESC continua  /  R reinicia o distrito")
		"map": _draw_map(size)
	if game.state == "play":
		var aim: Vector2 = game.pointer
		for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: draw_line(aim + axis * 3, aim + axis * 7, CYAN, 1)

func _panel(rect: Rect2) -> void:
	draw_rect(rect, Color(INK, 0.93))
	draw_rect(rect, Color("4d6a6b", 0.8), false, 1)

func _overlay(title: String, subtitle: String) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.9))
	_text_center(title, Vector2(size.x * 0.5, size.y * 0.5 - 30), 30, WHITE)
	_text_center(subtitle, Vector2(size.x * 0.5, size.y * 0.5 + 20), 14, GOLD)

func _draw_plan(area: Rect2, detailed: bool) -> void:
	M.draw_background(self, area, Color(0.6, 0.7, 0.69, 0.95))
	var scale := area.size / M.SIZE
	if detailed:
		for i in 3:
			var rect := M.world_rect(M.FACILITIES[i])
			var screen := Rect2(area.position + rect.position * scale, rect.size * scale)
			draw_rect(screen, CYAN if game.terminal_on[i] else GOLD, false, 1)
			var nameplate := Rect2(screen.position, Vector2(screen.size.x, 22))
			draw_rect(nameplate, Color(INK, 0.93))
			_text(["01  TRIAGEM AURORA", "02  RECICLAGEM PRISMA", "03  COMPOSTAGEM ÍRIS"][i], screen.position + Vector2(7, 15), 10, WHITE)
	var route := PackedVector2Array()
	for point in game.guidance_path: route.append(area.position + point * scale)
	if route.size() > 1: draw_polyline(route, Color(GOLD, 0.95), 2 if detailed else 1)
	var target: Vector2 = area.position + game.objective_point() * scale
	draw_arc(target, 7 if detailed else 4, 0, TAU, 20, GOLD, 2)
	var lia: Vector2 = area.position + game.pos * scale
	draw_circle(lia, 4 if detailed else 3, WHITE)
	if detailed: _text("LIA", lia + Vector2(9, 3), 9, WHITE)

func _draw_map(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	_text("AURORA  /  BAIRRO INDUSTRIAL DE RESÍDUOS", Vector2(40, 42), 18, CYAN)
	_text("AVENIDA DE SERVIÇO → DOCAS → INSTALAÇÕES", Vector2(41, 65), 11, WHITE)
	var height := size.y - 136
	var width := height * M.SIZE.x / M.SIZE.y
	var area := Rect2((size.x - width) * 0.5, 83, width, height)
	_draw_plan(area, true)
	_text("● LIA    ◎ OBJETIVO    LINHA ÂMBAR: ROTA     M OU ESC PARA VOLTAR", Vector2(41, size.y - 23), 10, WHITE)

func _direction(vector: Vector2) -> String:
	if vector.length() < 45: return "●"
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][posmod(int(round(vector.angle() / (PI / 4.0))), 8)]

func _text(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_center(value: String, point: Vector2, size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, point - Vector2(width * 0.5, 0), size, color)
