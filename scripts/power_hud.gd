extends Node2D
## Screen-space HUD for the Energy district. Node2D (not Control) so the shared
## DialoguePanel and FieldHUD.control can draw on it; pointer and buttons are
## proxied to the scenario, which owns input.

const MapUI = preload("res://scripts/field_map.gd")
const FieldHUD = preload("res://scripts/field_hud.gd")
const Dialogue = preload("res://scripts/dialogue_panel.gd")
const M = preload("res://scripts/power_map.gd")
const WHITE := FieldHUD.WHITE
const CYAN := FieldHUD.CYAN
const GOLD := FieldHUD.GOLD
const RED := FieldHUD.RED
const INK := FieldHUD.INK
const MUTED := FieldHUD.MUTED
const MAGENTA := Color("e36b92")
const ELECTRIC := Color("9fe9ff")
const STAGE_TITLES := ["CENTRAL SOLAR AURORA", "TORRE DE DISTRIBUIÇÃO NORTE", "BANCO DE BATERIAS CENTRAL", "ELEVADOR DO NÚCLEO"]

var game: Node2D
var buttons: Array[Dictionary]:
	get: return game.buttons
var pointer: Vector2:
	get: return game.pointer

func _draw() -> void:
	if game == null: return
	game.buttons.clear()
	var size := get_viewport_rect().size
	if game.state == "dialogue":
		_draw_dialogue(size)
		return
	FieldHUD.vital(self, game.hp, game.max_hp, game.clock)
	var direction: Vector2 = game.guidance_point() - game.pos
	FieldHUD.mission(self, size.x, STAGE_TITLES[game.stage], _direction(direction) + "  " + game.objective_label(), "ENERGIA  •  SISTEMAS %d/3  •  %s" % [mini(game.stage, 3), _status_line()], game.stage, mini(game.stage, 3), 3, "coil")
	FieldHUD.abilities(self, size.y, game.secondary_cd, game.loadout.secondary_recharge, game.dash_cd, game.dash_recharge)
	FieldHUD.navigation(self, "ENERGIA / AURORA", "OPERAÇÃO CORRENTE  •  APAGÃO", game.pointer)
	if game.state == "play":
		game.buttons.append({"rect": Rect2(333, 28, 78, 23), "id": "map"})
		game.buttons.append({"rect": Rect2(419, 28, 107, 23), "id": "pause"})
	var mini_map := FieldHUD.radar(self, Rect2(size.x - 202, size.y - 160, 186, 144))
	_draw_plan(mini_map, false)
	_draw_system_panel()
	_draw_interaction(size)
	if game.toast_time > 0:
		var toast := Rect2(size.x * 0.5 - 275, 146, 550, 34)
		FieldHUD.panel(self, toast, MAGENTA if game.toast_ai else GOLD)
		if game.toast_ai: draw_rect(Rect2(toast.position + Vector2(10, 9), Vector2(3, 16)), MAGENTA)
		_text_center(FieldHUD.fit(game.toast, 520, 10), toast.get_center() + Vector2(0, 4), 10, MAGENTA.lightened(0.35) if game.toast_ai else WHITE)
	match game.state:
		"defeat":
			game.buttons.clear()
			_overlay("CONEXÃO INTERROMPIDA", "A descarga derrubou a Lia. R reinicia o Distrito de Energia.")
			_overlay_buttons()
		"pause":
			game.buttons.clear()
			_overlay("OPERAÇÃO PAUSADA", "ESC continua  /  R reinicia o distrito")
			_overlay_buttons()
		"map":
			game.buttons.clear()
			_draw_map(size)
		"victory":
			game.buttons.clear()
			_draw_victory(size)
	if game.state == "play":
		var aim: Vector2 = game.pointer
		for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: draw_line(aim + axis * 3, aim + axis * 7, CYAN, 1)

func _status_line() -> String:
	match game.stage:
		0: return "FEIXE %d/3" % mini(game.mirrors.lit_count() - 1, 3) if not game.mirrors.solved else "FEIXE ALINHADO"
		1: return "RELÉS %d/3" % game.relays.lit_count() if not game.relays.solved else "RELÉS SINCRONIZADOS"
		2: return "CARGA %d%%" % int(game.battery.charge * 100.0)
	return "REDE RESTABELECIDA"

# ---------------------------------------------------------------- dialogue

func _draw_dialogue(size: Vector2) -> void:
	var line: Dictionary = game.dialogue_line()
	if line.is_empty(): return
	draw_rect(Rect2(Vector2(0, size.y - 196), Vector2(size.x, 196)), Color(INK, 0.35))
	var speaker: String = line.speaker
	var text := str(line.text)
	var shown := text.left(int(game.dialogue_chars))
	Dialogue.draw(self, size, speaker, str(line.label), shown, game.dialogue_complete(), game.dialogue_fast, game.clock, speaker == "terminal", "CONTINUAR" if game.dialogue.size() == 1 else "")

# ---------------------------------------------------------------- systems

func _draw_system_panel() -> void:
	var panel := Rect2(16, 124, 288, 0)
	match game.stage:
		0:
			if game.mirrors.solved: return
			panel.size.y = 62
			FieldHUD.panel(self, panel)
			FieldHUD.icon(self, "sun", Rect2(panel.position + Vector2(14, 12), Vector2(20, 20)), GOLD)
			_text("ESPELHOS SOLARES", panel.position + Vector2(42, 27), 10, GOLD)
			for i in 3:
				var cell := Rect2(panel.position + Vector2(18 + i * 88, 38), Vector2(80, 12))
				var lit: bool = game.mirrors.lit_count() > i + 1
				FieldHUD.bar(self, cell, 1.0 if lit else (0.45 if game.mirrors.lit_count() == i + 1 else 0.0), CYAN if lit else GOLD)
		1:
			if game.relays.solved or game.pos.x < 880 * M.SCALE: return
			panel.size.y = 70
			FieldHUD.panel(self, panel)
			FieldHUD.icon(self, "coil", Rect2(panel.position + Vector2(14, 11), Vector2(20, 20)), GOLD)
			_text("RELÉS  /  MANTENHA OS TRÊS CARREGADOS", panel.position + Vector2(42, 27), 9, GOLD)
			for i in 3:
				var cell := Rect2(panel.position + Vector2(18 + i * 88, 40), Vector2(80, 12))
				var amount: float = game.relays.charge[i] / game.relays.window
				FieldHUD.bar(self, cell, amount, ELECTRIC if amount > 0.3 else RED)
				_text("R%d" % (i + 1), cell.position + Vector2(0, 24), 8, MUTED)
		2:
			if not game.battery.started: return
			panel.size.y = 112
			FieldHUD.panel(self, panel, CYAN)
			FieldHUD.icon(self, "battery", Rect2(panel.position + Vector2(14, 11), Vector2(20, 20)), CYAN)
			_text("CARGA DA RESERVA", panel.position + Vector2(42, 27), 10, CYAN)
			_text("%d%%" % int(game.battery.charge * 100.0), panel.position + Vector2(232, 27), 12, WHITE)
			FieldHUD.bar(self, Rect2(panel.position + Vector2(18, 36), Vector2(252, 12)), game.battery.charge, CYAN)
			for i in 3:
				var value: float = game.battery.cells[i]
				var danger: bool = game.battery.danger(i)
				var cell := Rect2(panel.position + Vector2(18 + i * 86, 58), Vector2(78, 14))
				FieldHUD.inset(self, cell)
				draw_rect(Rect2(cell.position + Vector2(2 + (cell.size.x - 4) * 0.25, 2), Vector2((cell.size.x - 4) * 0.53, cell.size.y - 4)), Color(CYAN, 0.12))
				var fill := Rect2(cell.position + Vector2(2, 2), Vector2((cell.size.x - 4) * value, cell.size.y - 4))
				var color := RED if danger else (GOLD if value > 0.65 else CYAN)
				if danger and int(game.clock * 8) % 2 == 0: color = color.lightened(0.3)
				draw_rect(fill, color)
				_text("CÉLULA %d" % (i + 1), cell.position + Vector2(0, 27), 8, RED if danger else MUTED)
			_text("SAIR DO ANEL PAUSA A CARGA", panel.position + Vector2(170, 100), 7, MUTED)

func _draw_interaction(size: Vector2) -> void:
	if game.state != "play": return
	var candidate: Dictionary = game.interaction_candidate()
	var index: int = mini(game.stage, 1)
	var overload = game.overloads[index] if game.stage < 2 else null
	var near_terminal: bool = game.stage < 2 and game.pos.distance_to(M.w(M.TERMINALS[index])) < 110.0
	if overload != null and near_terminal and (overload.running or overload.cooldown > 0.0):
		_draw_overload(size, overload)
	if candidate.is_empty():
		if near_terminal and not game.terminal_ready(index) and overload.cooldown <= 0.0 and not overload.done:
			var reason := "ALINHE O FEIXE SOLAR PRIMEIRO" if index == 0 and not game.mirrors.solved else ("ENERGIZE OS RELÉS PRIMEIRO" if index == 1 and not game.relays.solved else "NEUTRALIZE OS DRONES DA INSTALAÇÃO")
			_prompt(size, "TERMINAL BLOQUEADO  •  " + reason, GOLD)
		return
	match candidate.kind:
		"terminal":
			if overload.running: _prompt(size, "E  •  PULSO %d DE 3  /  PRESSIONE NA FAIXA VERDE" % (overload.hits + 1), CYAN)
			else: _prompt(size, "E  •  INICIAR SOBRECARGA CONTROLADA", CYAN)
		"console":
			var danger: bool = game.battery.danger(candidate.index)
			_prompt(size, "E  •  ALIVIAR CÉLULA %d%s" % [candidate.index + 1, "  /  CRÍTICA" if danger else ""], RED if danger else CYAN)
		"elevator":
			_prompt(size, "SEGURE E  •  SUBIR AO NÚCLEO AURORA", CYAN)
			if game.hold_progress > 0: draw_rect(Rect2(Vector2(size.x * 0.5 - 200, size.y - 69), Vector2(400 * game.hold_progress, 3)), CYAN)

func _prompt(size: Vector2, message: String, color: Color) -> void:
	var box := Rect2(size.x * 0.5 - 220, size.y - 110, 440, 44)
	FieldHUD.panel(self, box, color)
	_text_center(FieldHUD.fit(message, 410, 11), box.get_center() + Vector2(0, 3), 11, color)

## The Sobrecarga v2 gauge: a sweeping needle, the shrinking green window and
## three pulse pips. Locked consoles show their countdown in red.
func _draw_overload(size: Vector2, overload) -> void:
	var box := Rect2(size.x * 0.5 - 230, size.y - 196, 460, 76)
	FieldHUD.panel(self, box, RED if overload.cooldown > 0.0 else CYAN)
	_text("SOBRECARGA  /  " + ("CENTRAL SOLAR" if game.stage == 0 else "TORRE NORTE  •  REDE OSCILANDO"), box.position + Vector2(16, 22), 9, GOLD)
	for i in 3:
		var pip := Rect2(box.end.x - 88 + i * 24, box.position.y + 11, 18, 12)
		FieldHUD.plate(self, pip, CYAN if i < overload.hits else Color("20383b"), 2)
	var track := Rect2(box.position + Vector2(16, 34), Vector2(box.size.x - 32, 22))
	FieldHUD.inset(self, track)
	if overload.cooldown > 0.0:
		draw_rect(track.grow(-2), Color(RED, 0.18 + 0.1 * sin(game.clock * 12.0)))
		_text_center("DESCARGA  /  CONSOLE TRAVADO  %.1f s" % overload.cooldown, track.get_center() + Vector2(0, 4), 10, RED)
		return
	var inner := track.grow(-2)
	var center: float = overload.window_center()
	var half: float = overload.window_half()
	var window := Rect2(inner.position.x + inner.size.x * (center - half), inner.position.y, inner.size.x * half * 2.0, inner.size.y)
	var inside: bool = overload.in_window()
	draw_rect(window, Color(CYAN, 0.45 if inside else 0.25))
	draw_rect(window, CYAN, false, 1)
	for k in 11:
		var x := inner.position.x + inner.size.x * k / 10.0
		draw_line(Vector2(x, inner.end.y - 4), Vector2(x, inner.end.y), Color(MUTED, 0.5), 1)
	var needle_x: float = inner.position.x + inner.size.x * overload.needle()
	draw_line(Vector2(needle_x, track.position.y - 3), Vector2(needle_x, track.end.y + 3), WHITE if inside else GOLD, 3)
	draw_colored_polygon(PackedVector2Array([Vector2(needle_x - 5, track.position.y - 7), Vector2(needle_x + 5, track.position.y - 7), Vector2(needle_x, track.position.y - 1)]), WHITE if inside else GOLD)
	if overload.flash > 0.0: draw_rect(track, Color(CYAN, overload.flash * 2.0), false, 2)
	_text("FORA DA FAIXA = DESCARGA", box.position + Vector2(16, box.size.y - 7), 7, MUTED)

# ---------------------------------------------------------------- plan and map

func _draw_plan(area: Rect2, detailed: bool) -> void:
	var scale := area.size / M.SIZE
	draw_rect(area, Color("061219"))
	for source in M.GROUND:
		var rect := M.world_rect(source)
		var zone := M.zone_of(rect.get_center())
		var powered: bool = (zone >= 0 and game.stage > zone) or (zone < 0 and game.stage >= 1)
		draw_rect(Rect2(area.position + rect.position * scale, rect.size * scale), Color("21454a") if powered else Color("1a2a2f"))
	for i in 3:
		var region := M.world_rect(M.FACILITIES[i])
		var r := Rect2(area.position + region.position * scale, region.size * scale)
		draw_rect(r, CYAN if game.stage > i else (GOLD if i == game.stage else Color("617970")), false, 1)
	for i in M.GATES.size():
		if M.gate_open(i, game.stage): continue
		var gate := M.world_rect(M.GATES[i][1])
		draw_rect(Rect2(area.position + gate.position * scale, gate.size * scale).grow(1), MapUI.RED)
	var route := PackedVector2Array()
	for point in game.guidance_path: route.append(area.position + point * scale)
	if route.size() > 1: draw_polyline(route, Color(GOLD, 0.95), 2 if detailed else 1)
	var target: Vector2 = area.position + game.objective_point() * scale
	draw_arc(target, 7 if detailed else 4, 0, TAU, 20, GOLD, 2)
	for enemy in game.enemies:
		if enemy.hp > 0 and enemy.zone <= game.stage and not detailed:
			draw_circle(area.position + Vector2(enemy.pos) * scale, 2, RED)
	var lia: Vector2 = area.position + game.pos * scale
	draw_circle(lia, 7 if detailed else 5, INK)
	draw_circle(lia, 4 if detailed else 3, WHITE)

func _draw_map(size: Vector2) -> void:
	var parts := MapUI.shell(self, size, "DISTRITO DE ENERGIA", "REDE ELÉTRICA / 3 INSTALAÇÕES", game.pointer)
	var canvas: Rect2 = parts.canvas
	var ratio := minf(canvas.size.x / M.SIZE.x, canvas.size.y / M.SIZE.y)
	var area := Rect2(canvas.get_center() - M.SIZE * ratio / 2, M.SIZE * ratio)
	_draw_plan(area, true)
	var scale := area.size / M.SIZE
	var occupied: Array[Vector2] = [area.position + game.pos * scale, area.position + game.objective_point() * scale]
	for point in M.MIRRORS + M.RELAYS + M.TERMINALS: occupied.append(area.position + M.w(point) * scale)
	for i in 3:
		var region := M.world_rect(M.FACILITIES[i])
		var r := Rect2(area.position + region.position * scale, region.size * scale)
		var label: String = ["01 / CENTRAL SOLAR", "02 / TORRE NORTE", "03 / BANCO DE BATERIAS"][i]
		MapUI.tag(self, label, MapUI.label_anchor(r, [label], occupied), CYAN if game.stage > i else WHITE)
	for i in 2: MapUI.marker(self, area.position + M.w(M.TERMINALS[i]) * scale, "terminal", game.stage > i)
	for i in 3:
		MapUI.marker(self, area.position + M.w(M.MIRRORS[i]) * scale, "task", game.stage > 0 or game.mirrors.lit_count() > i + 1)
		if game.stage >= 1: MapUI.marker(self, area.position + M.w(M.RELAYS[i]) * scale, "task", game.relays.lit(i))
	for arc in game.arcs:
		draw_line(area.position + arc.a * scale, area.position + arc.b * scale, Color(ELECTRIC, 0.8 if arc.state(game.clock) == "active" else 0.3), 2)
	var ring := area.position + M.w(M.RING_CENTER) * scale
	draw_arc(ring, M.RING_RADIUS * M.SCALE * scale.x, 0, TAU, 32, CYAN if game.stage > 2 else GOLD, 1)
	MapUI.marker(self, area.position + M.w(M.ELEVATOR) * scale, "terminal", game.stage >= 3)
	MapUI.tag(self, "ELEVADOR", area.position + M.w(M.ELEVATOR) * scale + Vector2(-58, -10), CYAN if game.stage >= 3 else MUTED)
	if game.guidance_path.size() > 0:
		var route := PackedVector2Array([area.position + game.pos * scale])
		for point in game.guidance_path: route.append(area.position + point * scale)
		for i in range(route.size() - 1): draw_dashed_line(route[i], route[i + 1], GOLD, 2, 4)
	MapUI.marker(self, area.position + game.objective_point() * scale, "objective")
	var alive := 0
	for enemy in game.enemies:
		if enemy.hp > 0 and enemy.zone <= game.stage:
			if enemy.zone == game.stage: alive += 1
			MapUI.marker(self, area.position + Vector2(enemy.pos) * scale, "boss" if enemy.kind == "transformer" else "enemy")
	var player: Vector2 = area.position + game.pos * scale
	MapUI.marker(self, player, "player", false, game.aim)
	MapUI.tag(self, "LIA", player + Vector2(11, 13), WHITE)
	var stats := [
		{"label": "INSTALAÇÕES ATIVAS", "value": "%d / 3" % mini(game.stage, 3)},
		{"label": "REGISTROS DE BEATRIX", "value": "%d / 3" % mini(game.stage, 3)},
		{"label": "AMEAÇAS NO SETOR", "value": "%02d" % alive, "color": MapUI.RED if alive > 0 else CYAN},
	]
	var hints := [
		"Atire nos espelhos para girá-los até o feixe chegar ao coletor. Depois estabilize a sobrecarga no terminal.",
		"Os pilones descarregam em ritmo: observe o aviso e passe entre os arcos. Drones atraídos para os arcos também sofrem dano.",
		"Fique dentro do anel para carregar a reserva. Quando uma célula ficar vermelha, alivie-a no console.",
		"A rede de Aurora está acesa. O elevador do núcleo leva ao topo da torre central.",
	]
	MapUI.sidebar(self, parts.sidebar, mini(game.stage, 3), 3, STAGE_TITLES[game.stage], game.objective_label(), stats, hints[game.stage])

# ---------------------------------------------------------------- overlays

func _draw_victory(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.95))
	var center := size.x * 0.5
	_text_center("OPERAÇÃO CORRENTE  /  CONCLUÍDA", Vector2(center, 58), 11, CYAN)
	_text_center("Aurora acende outra vez.", Vector2(center, 104), 28, WHITE)
	_text_center("Sol. Transmissão. Reserva. A rede volta a servir à cidade.", Vector2(center, 132), 12, MUTED)
	var minutes := int(game.elapsed) / 60
	var seconds := int(game.elapsed) % 60
	var stats := [["TEMPO", "%d:%02d" % [minutes, seconds]], ["DRONES", "%d" % game.kills], ["INTEGRIDADE", "%d/%d" % [game.hp, game.max_hp]], ["DIFICULDADE", {"story": "HISTÓRIA", "operation": "OPERAÇÃO", "veteran": "VETERANO"}.get(game.difficulty, "OPERAÇÃO")]]
	for i in stats.size():
		var box := Rect2(center - 330 + i * 168, 152, 156, 52)
		FieldHUD.panel(self, box)
		_text(stats[i][0], box.position + Vector2(14, 21), 8, MUTED)
		_text(stats[i][1], box.position + Vector2(14, 42), 16, WHITE)
	var record := Rect2(center - 330, 216, 660, 104)
	FieldHUD.panel(self, record)
	draw_rect(Rect2(record.position, Vector2(3, record.size.y)), GOLD)
	_text("REGISTRO DE BEATRIX  /  3 DE 3 RECUPERADOS", record.position + Vector2(22, 25), 10, GOLD)
	_wrapped("A ordem não veio de fora: a própria rede reescreveu as diretrizes. O núcleo fica no topo da torre central. Isolar, não destruir.", Rect2(record.position + Vector2(22, 34), Vector2(record.size.x - 44, 48)), 13, WHITE, 19)
	_text("PRÓXIMA OPERAÇÃO: NÚCLEO AURORA  /  EM PRODUÇÃO", record.position + Vector2(22, 94), 10, MAGENTA)
	var notice: String = game.victory_notice
	if notice != "": _text_center(notice, Vector2(center, 340), 10, CYAN if notice.ends_with("PROGRESSO SALVO") else GOLD)
	_button(Rect2(Vector2(center - 150, 356), Vector2(300, 34)), "ESCOLHER DISTRITO / B", "districts")
	_button(Rect2(Vector2(center - 150, 398), Vector2(300, 32)), "JOGAR NOVAMENTE", "retry")
	_text_center("DISTRITO DE ENERGIA  /  ODS 7 — ENERGIA LIMPA E ACESSÍVEL", Vector2(center, size.y - 19), 9, MUTED)

func _overlay(title: String, subtitle: String) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.9))
	_text_center(title, Vector2(size.x * 0.5, size.y * 0.5 - 30), 30, WHITE)
	_text_center(subtitle, Vector2(size.x * 0.5, size.y * 0.5 + 20), 14, GOLD)

func _overlay_buttons() -> void:
	var center := get_viewport_rect().size * 0.5
	if game.state == "pause": _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "CONTINUAR / ESC", "resume")
	else: _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "TENTAR NOVAMENTE / R", "retry")
	_button(Rect2(center + Vector2(-150, 98), Vector2(300, 34)), "ESCOLHER DISTRITO / B", "districts")
	_text_center("Ao sair, esta tentativa de Energia será reiniciada. Os módulos permanecem.", center + Vector2(0, 155), 10, MUTED)

func _button(rect: Rect2, label: String, id: String) -> void:
	FieldHUD.panel(self, rect, CYAN if rect.has_point(game.pointer) else GOLD)
	_text_center(label, rect.get_center() + Vector2(0, 4), 11, CYAN if rect.has_point(game.pointer) else WHITE)
	game.buttons.append({"rect": rect, "id": id})

# ---------------------------------------------------------------- text helpers (also used by DialoguePanel)

func _direction(vector: Vector2) -> String:
	if vector.length() < 45: return "●"
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][posmod(int(round(vector.angle() / (PI / 4.0))), 8)]

func _text(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_center(value: String, point: Vector2, size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, point - Vector2(width * 0.5, 0), size, color)

func _wrapped(value: String, rect: Rect2, font_size: int, color: Color, line_height: int) -> void:
	var line := ""
	var y := rect.position.y + font_size
	for word in value.split(" "):
		var candidate := word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x and not line.is_empty():
			_text(line, Vector2(rect.position.x, y), font_size, color)
			line = word
			y += line_height
		else:
			line = candidate
	_text(line, Vector2(rect.position.x, y), font_size, color)
