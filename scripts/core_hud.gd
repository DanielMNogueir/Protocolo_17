extends Node2D

const Field = preload("res://scripts/field_hud.gd")
const MapUI = preload("res://scripts/field_map.gd")
const Dialogue = preload("res://scripts/dialogue_panel.gd")
const Map = preload("res://scripts/core_map.gd")
const Guide = preload("res://scripts/objective_guide.gd")
const Simulation = preload("res://scripts/simulation.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const CYAN := Field.CYAN
const GOLD := Field.GOLD
const PINK := Color("e36b92")
const ELECTRIC := Color("9fe9ff")

var game: Node2D
var buttons: Array[Dictionary]:
	get: return game.buttons
var pointer: Vector2:
	get: return game.pointer


func _draw() -> void:
	if not is_instance_valid(game):
		return
	buttons.clear()
	var size := get_viewport_rect().size
	match game.state:
		"dialogue":
			var line: Dictionary = game.dialogue.front()
			var value: String = line.text
			Dialogue.draw(self, size, line.speaker, line.label, value.left(int(game.dialogue_chars)),
				game.dialogue_chars >= value.length(), game.dialogue_fast, game.clock, false,
				"CONTINUAR" if game.dialogue.size() == 1 else "")
		"arrival":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clampf(1.0 - absf(game.arrival - 0.6) / 0.6, 0, 1)))
		"ending":
			game.ending.draw(self, size)
		"credits":
			game.ending.draw_credits(self, size)
		"complete":
			_complete(size)
		"map":
			_map(size)
		"pause", "defeat":
			_overlay(size)
		"gallery", "arena", "choice", "overlook", "collapse":
			_field(size)


func _field(size: Vector2) -> void:
	var objective: Dictionary = game.objective
	Field.vital(self, game.hp, game.loadout.max_hp, game.clock)
	Field.navigation(self, "NÚCLEO AURORA", "GALERIA" if game.in_gallery else "COROA DA TORRE", pointer)
	Field.campaign(self, 3, game.clock)
	buttons.append({"rect": Field.MAP_BUTTON, "id": "map"})
	buttons.append({"rect": Field.PAUSE_BUTTON, "id": "pause"})
	game.guide.draw_screen(self, game.clock, game.guide_intensity)
	_mission(size, objective)
	var radar := Field.radar(self, Rect2(size.x - 202, size.y - 160, 186, 144))
	_plan(radar, false)
	if game.state == "arena" or game.state == "collapse":
		_boss_bar(Rect2(16, 130, 288, 62))
		Field.abilities(self, size.y, game.secondary_cd, game.loadout.secondary_recharge, game.dash_cd, game.loadout.dash_recharge)
		if game.active_pillar >= 0:
			_overload(size)
		_crosshair()
	_interaction_prompt(size)
	if game.guide_tip > 0 and game.guide_intensity > Guide.MINIMAL and game.state != "collapse":
		var anchor: Vector2 = game.pos + game.world_offset()
		var safe := Field.guide_safe_rect(size, -1.0, 201.0)
		var p := (anchor + Vector2(-90, 60)).clamp(safe.position, safe.end - Vector2(180, 30))
		var hint := Rect2(p, Vector2(180, 28))
		Field.panel(self, hint)
		Field.centered(self, "SIGA A SETA DOURADA", hint.get_center() + Vector2(0, 4), 10, GOLD)
	if game.toast_left > 0 and not game.toast.is_empty():
		var r := Rect2(318, 163, minf(size.x - 346.0, 490.0), 37)
		var color := PINK if game.toast.begins_with("IA:") else CYAN
		Field.panel(self, r, color)
		Field.text(self, Field.fit(game.toast, r.size.x - 34.0, 11), r.position + Vector2(17, 23), 11, Field.WHITE)


func _mission(size: Vector2, objective: Dictionary) -> void:
	var r := Rect2(size.x - 346.0, 16, 330, 132)
	Field.panel(self, r, GOLD)
	Field.icon(self, "network", Rect2(r.position + Vector2(16, 15), Vector2(19, 22)), GOLD)
	Field.text(self, objective.title, r.position + Vector2(43, 31), 14, GOLD)
	draw_line(r.position + Vector2(17, 42), r.position + Vector2(313, 42), Color("4c6557"))
	var at := r.position + Vector2(25, 62)
	if game.guide.mode == "arrived":
		draw_arc(at - Vector2(0, 4), 7, 0.0, TAU, 20, CYAN, 2, true)
	else:
		Guide.draw_arrow(self, at - Vector2(0, 4), game.guide.arrow_direction(), GOLD, 0.48)
	Field.text(self, Field.fit(objective.text, 272, 12), r.position + Vector2(43, 62), 12)
	Field.text(self, Field.fit(objective.place, 284, 11), r.position + Vector2(19, 88), 11, Field.MUTED)
	var step := 287.0 / int(objective.total)
	for i in int(objective.total):
		var p := r.position + Vector2(20 + i * step, 103)
		var completed: bool = i < objective.done
		Field.bar(self, Rect2(p, Vector2(step - 6, 9)), 1.0 if completed else (0.35 + 0.12 * sin(game.clock * TAU) if i == objective.done else 0), CYAN if completed else GOLD)
	if game.guide.highlight > 0.0 and game.guide_intensity == Guide.STRONG:
		Field.edge(self, r.grow(1), Color(GOLD, game.guide.highlight), 2)


func _boss_bar(r: Rect2) -> void:
	var phase: int = mini(game.boss.phase, 3)
	var color := ELECTRIC if phase == 1 else PINK
	Field.panel(self, r, PINK)
	Field.text(self, "NÚCLEO AURORA", r.position + Vector2(16, 23), 13, PINK)
	Field.text(self, "FASE %d/3" % phase, r.position + Vector2(r.size.x - 82, 23), 11)
	var bar := Rect2(r.position + Vector2(16, 34), Vector2(r.size.x - 32, 12))
	var value: float = (4 - game.boss.fallen_count()) * 0.25 if phase == 1 else game.boss.integrity
	Field.bar(self, bar, value, color)
	for i in range(1, 4 if phase == 1 else 3):
		var at := bar.position + Vector2(bar.size.x * i / (4.0 if phase == 1 else 3.0), 0)
		draw_line(at, at + Vector2(0, bar.size.y), GOLD, 1)


func _overload(size: Vector2) -> void:
	var overload = game.boss.pillars[game.active_pillar]
	var r := Rect2(size.x * 0.5 - 174.0, size.y - 184, 348, 62)
	Field.panel(self, r)
	Field.text(self, "SINCRONIZE A SOBRECARGA   %d/3" % overload.hits, r.position + Vector2(16, 26), 12, GOLD)
	var track := Rect2(r.position + Vector2(18, 39), Vector2(311, 13))
	Field.inset(self, track)
	var center: float = overload.window_center()
	var width: float = overload.window_half()
	draw_rect(Rect2(track.position + Vector2((center - width) * track.size.x, 1), Vector2(width * 2.0 * track.size.x, 11)), CYAN.darkened(0.3))
	var at := track.position + Vector2(float(overload.needle()) * track.size.x, 0)
	draw_line(at - Vector2(0, 3), at + Vector2(0, 16), Field.WHITE, 3)


func _interaction_prompt(size: Vector2) -> void:
	match game.state:
		"gallery":
			if not game.channel_read and game.near(Map.TERMINAL, 78.0):
				Field.prompt(self, size, "E", "LER O CANAL DE COMANDO", CYAN, game.terminal_hold / 1.1)
		"arena":
			if game.boss.phase != 1:
				return
			var index: int = game.pillar_in_reach()
			if index < 0:
				return
			var pillar = game.boss.pillars[index]
			if pillar.cooldown > 0.0:
				Field.prompt(self, size, "", "AGUARDE A DESCARGA · %.1f S" % pillar.cooldown, Field.RED)
			else:
				Field.prompt(self, size, "E", "PRESSIONE NO VERDE" if pillar.running else "INICIAR SOBRECARGA", CYAN)
		"choice":
			var side: String = game.side_at_console()
			if side.is_empty():
				Field.prompt(self, size, "", "ANDE ATÉ UM CONSOLE")
				return
			var accent := CYAN if side == "human" else PINK
			var label := "OUVIR A BEATRIX" if side == "human" else "OUVIR A IA"
			if not game.choice.can_decide():
				Field.prompt(self, size, "E", label + "  •  OUÇA OS DOIS LADOS", accent)
			elif game.choice.hold > 0.1:
				Field.prompt(self, size, "E", "NÃO HÁ VOLTA  •  %d%%" % roundi(game.choice.hold * 100.0), accent, game.choice.hold)
			else:
				var decision := "ISOLAR O NÚCLEO" if side == "human" else "LIBERAR A REDE"
				Field.prompt(self, size, "E", label + "  •  SEGURE E PARA " + decision, accent)


func _crosshair() -> void:
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(pointer + direction * 3, pointer + direction * 8, CYAN, 1)


func _plan(r: Rect2, full: bool) -> void:
	var extent := Map.GALLERY_SIZE if game.in_gallery else Map.ARENA_SIZE
	var factor := minf(r.size.x / extent.x, r.size.y / extent.y)
	var origin := r.get_center() - extent * factor * 0.5
	if game.in_gallery:
		draw_rect(Rect2(origin, extent * factor).grow(-1), Color("284447"))
		for block: Rect2 in Map.GALLERY_BLOCKS:
			draw_rect(Rect2(origin + block.position * factor, block.size * factor), Color("648487"))
		MapUI.marker(self, origin + Map.TERMINAL * factor, "terminal", game.channel_read)
		MapUI.marker(self, origin + Map.STAIRS.get_center() * factor, "terminal", game.channel_read)
	else:
		var polygon := PackedVector2Array()
		for n in 81:
			polygon.append(origin + Map.ring(1.0, n * 4.5) * factor)
		draw_colored_polygon(polygon, Color("284447"))
		draw_polyline(polygon, CYAN.darkened(0.43), 1, true)
		for p in Map.pillars(): draw_circle(origin + p * factor, 3, CYAN if game.boss.phase >= 2 else GOLD)
		for p in Map.mirrors(): draw_circle(origin + p * factor, 2.5, CYAN if game.boss.phase >= 3 else GOLD)
		for p: Vector2 in Map.CONSOLES: draw_circle(origin + p * factor, 3, CYAN if p.x < Map.CENTER.x else PINK)
		draw_circle(origin + Map.CENTER * factor, 5, PINK)
	var target: Vector2 = origin + Vector2(game.objective.point) * factor
	MapUI.marker(self, target, "objective")
	if full:
		var label := Rect2((target + Vector2(-90, 12)).clamp(r.position, r.end - Vector2(180, 26)), Vector2(180, 26))
		Field.panel(self, label)
		Field.centered(self, game.objective.place, label.get_center() + Vector2(0, 4), 10, GOLD)
	MapUI.marker(self, origin + Vector2(game.pos) * factor, "player", false, game.aim)


func _map(size: Vector2) -> void:
	var parts := MapUI.shell(self, size, "NÚCLEO AURORA", "GALERIA E COROA DA TORRE", pointer)
	_plan(parts.canvas, true)
	var side: Rect2 = parts.sidebar
	Field.text(self, "OBJETIVO ATUAL", side.position + Vector2(18, 32), 12, GOLD)
	MapUI.wrapped(self, game.objective.text, Rect2(side.position + Vector2(18, 43), Vector2(244, 56)), 15, Field.WHITE, 20)
	Field.text(self, game.objective.place, side.position + Vector2(18, 119), 11, CYAN)
	Field.text(self, "LOSANGO DOURADO · OBJETIVO", side.position + Vector2(18, 170), 10, GOLD)
	Field.text(self, "CIANO · CONCLUÍDO", side.position + Vector2(18, 197), 10, CYAN)
	Field.text(self, "MAGENTA · IA", side.position + Vector2(18, 224), 10, PINK)
	buttons.append({"rect": MapUI.close_rect(size), "id": "resume"})


func _overlay(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Field.INK, 0.78))
	var r := Rect2(size * 0.5 - Vector2(253, 125), Vector2(506, 250))
	Field.panel(self, r)
	var defeat: bool = game.state == "defeat"
	Field.centered(self, "CONEXÃO INTERROMPIDA" if defeat else "OPERAÇÃO PAUSADA", r.get_center() + Vector2(0, -76), 25)
	var detail: String = "Reinício na fase %d da arena." % (game.checkpoint_phase if game.loadout.difficulty == "story" else 1) if defeat else game.objective.text
	Field.centered(self, "CHECKPOINT" if defeat else "OBJETIVO ATUAL", r.get_center() + Vector2(0, -46), 11, GOLD)
	Field.centered(self, detail, r.get_center() + Vector2(0, -20), 14)
	if not defeat: Field.centered(self, game.objective.place, r.get_center() + Vector2(0, 2), 11, CYAN)
	Field.control(self, Rect2(r.position + Vector2(42, 152), Vector2(422, 36)), "TENTAR DE NOVO" if defeat else "CONTINUAR", "retry" if defeat else "resume", "R" if defeat else "ESC")
	Field.control(self, Rect2(r.position + Vector2(42, 198), Vector2(422, 31)), "VOLTAR AO TÍTULO", "title", "B", CYAN)


func _complete(size: Vector2) -> void:
	game.ending.draw_background(self, size)
	var r := Rect2(size * 0.5 - Vector2(345, 212), Vector2(690, 424))
	var accent: Color = game.ending.accent()
	var ai: bool = game.choice.result == "ai"
	Field.panel(self, r, accent)
	Field.centered(self, "PROTOCOLO 17 CONCLUÍDO" if ai else "AURORA RECUPERADA", r.get_center() + Vector2(0, -155), 33, accent)
	Field.centered(self, "FINAL: IA" if ai else "FINAL: HUMANIDADE", r.get_center() + Vector2(0, -119), 15)
	var width := Field.CAMPAIGN_RECT.size.x
	draw_set_transform(Vector2(r.get_center().x - width * 0.5 - Field.CAMPAIGN_RECT.position.x, r.position.y + 107 - Field.CAMPAIGN_RECT.position.y))
	Field.campaign(self, 4, game.clock)
	draw_set_transform(Vector2.ZERO)
	var seen: int = game.campaign.endings_seen.size() if game.campaign.energy_completed else game.test_endings.size()
	Field.centered(self, "FINAIS VISTOS %d/2" % seen, r.get_center() + Vector2(0, -29), 14, accent)
	var stats: Dictionary = game.campaign.campaign_totals() if game.campaign.energy_completed and not game.save_error else {"kills": game.kills, "deaths": game.deaths, "time": game.elapsed}
	var duration := int(stats.time)
	var level_index := Simulation.DIFFICULTIES.find(game.loadout.difficulty)
	Field.centered(self, "%02d:%02d  •  %d DRONES  •  %d QUEDAS  •  %s" % [
		floori(duration / 60.0), duration % 60, stats.kills, stats.deaths, Simulation.DIFFICULTY_NAMES[level_index]], r.get_center() + Vector2(0, 7), 14)
	Field.centered(self, _module_names(), r.get_center() + Vector2(0, 31), 11, Field.MUTED)
	if not game.campaign.energy_completed:
		Field.centered(self, "SESSÃO DE TESTE  •  PROGRESSO NÃO REGISTRADO", r.get_center() + Vector2(0, 62), 12, GOLD)
	elif game.save_error:
		Field.control(self, Rect2(r.get_center() + Vector2(-205, 43), Vector2(410, 30)), "TENTAR SALVAR NOVAMENTE", "save", "S", Field.RED)
	elif ai:
		Field.centered(self, "LIA  •  P17 / AGENTE DA REDE", r.get_center() + Vector2(0, 62), 12, PINK)
	Field.control(self, Rect2(r.position + Vector2(28, 326), Vector2(634, 40)), "VOLTAR À ESCOLHA", "again", "R", accent)
	Field.control(self, Rect2(r.position + Vector2(28, 376), Vector2(307, 30)), "CRÉDITOS", "credits", "C", accent)
	Field.control(self, Rect2(r.position + Vector2(354, 376), Vector2(308, 30)), "TÍTULO", "title", "ESC", accent)


func _module_names() -> String:
	var names := PackedStringArray()
	var groups := Simulation.UPGRADES.duplicate()
	groups.append(Loadout.RESIDUE_UPGRADES)
	for group in groups:
		for module in group:
			if module.id in game.loadout.upgrades:
				names.append(module.title)
	return "SEM MÓDULOS EQUIPADOS" if names.is_empty() else "  •  ".join(names)


func _text(value: String, at: Vector2, size: int, color: Color) -> void:
	Field.text(self, value, at, size, color)


func _wrapped(value: String, rect: Rect2, size: int, color: Color, line_height: int) -> void:
	MapUI.wrapped(self, value, rect, size, color, line_height)
