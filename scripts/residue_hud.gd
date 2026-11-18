extends Control

const MapUI = preload("res://scripts/field_map.gd")
const FieldHUD = preload("res://scripts/field_hud.gd")
const M = preload("res://scripts/residue_map.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const WHITE := Color("e9ece0")
const CYAN := Color("7be4ce")
const GOLD := Color("e8bd74")
const INK := Color("091922")
const MUTED := FieldHUD.MUTED
const PINK := Color("e36b92")
var game: Node2D

func _draw() -> void:
	if game == null: return
	game.buttons.clear()
	var size := get_viewport_rect().size
	# Like Energy, a conversation owns the screen; the scenario draws the frame.
	if game.state == "dialogue": return
	FieldHUD.vital(self, game.hp, game.max_hp, game.clock)
	var beats := _beats()
	var status := "SISTEMAS %d/3" % mini(game.stage, 3)
	if game.stage < 3: status += "  •  ETAPA %d/%d" % [mini(beats.done + 1, beats.labels.size()), beats.labels.size()]
	if beats.drones > 0: status += "  •  %d DRONE%s" % [beats.drones, "" if beats.drones == 1 else "S"]
	FieldHUD.mission(self, size.x, ["CENTRO DE TRIAGEM", "USINA DE RECICLAGEM", "UNIDADE DE COMPOSTAGEM", "DISTRITO RECUPERADO"][game.stage], game.objective_label().get_slice("  /  ", 0), status, game.stage, mini(game.stage, 3), 3, "recycle", game.objective_guide, game.clock)
	FieldHUD.abilities(self, size.y, game.secondary_cd, 3.8, game.dash_cd, game.dash_recharge)
	FieldHUD.navigation(self, "RESÍDUOS / AURORA", "RECUPERAÇÃO INDUSTRIAL", game.pointer)
	if game.state == "play":
		game.objective_guide.draw_screen(self, game.clock, game.objective_guide.intensity)
		game.objective_guide.draw_tip(self)
		game.buttons.append({"rect": FieldHUD.MAP_BUTTON, "id": "map"})
		game.buttons.append({"rect": FieldHUD.PAUSE_BUTTON, "id": "pause"})
	var mini_map := FieldHUD.radar(self, FieldHUD.radar_rect(size))

	_draw_plan(mini_map, false)
	var candidate: Dictionary = game._interaction_candidate()
	if not candidate.is_empty():
		var message := ""
		match candidate.kind:
			"item": message = "RECOLHER " + M.MATERIALS[candidate.index]
			"bin": message = "ENTREGAR " + M.MATERIALS[game.carried]
			"block": message = "" + ("DESOBSTRUIR ESTEIRA" if candidate.index < 2 else "REABRIR VENTILAÇÃO")
			"terminal": message = "RESTAURAR SISTEMA"
		FieldHUD.prompt(self, size, "E", message, CYAN, game.hold_progress if candidate.kind in ["block", "terminal"] else -1.0)
	elif game.state == "play" and game.stage < 3 and not game._terminal_ready(game.stage) and game.pos.distance_to(M.TERMINALS[game.stage]) < 110.0:
		FieldHUD.prompt(self, size, "", "TERMINAL BLOQUEADO  •  " + _terminal_reason(), GOLD)
	elif game.carried >= 0:
		_text_center("EM MÃOS: " + M.MATERIALS[game.carried] + "  /  PROCURE A BAIA", Vector2(size.x * 0.5, size.y - 38), 11, GOLD)
	if game.bin_lock > 0:
		_text_center("TRIAGEM REINICIANDO  /  %.1f s" % game.bin_lock, Vector2(size.x * 0.5, size.y - 128), 11, GOLD)
	if game.toast_time > 0:
		var toast := Rect2(size.x * 0.5 - 220, size.y - 98, 440, 28)
		FieldHUD.compact_panel(self, toast, PINK if game.toast_ai else GOLD)
		if game.toast_ai: draw_rect(Rect2(toast.position + Vector2(10, 9), Vector2(3, 16)), PINK)
		_text_center(FieldHUD.fit(game.toast, toast.size.x - 30, 10), toast.get_center() + Vector2(0, 4), 10, PINK.lightened(0.35) if game.toast_ai else WHITE)
	match game.state:
		"defeat":
			game.buttons.clear()
			_overlay("CONEXÃO INTERROMPIDA", "R reinicia o Distrito de Resíduos")
			_overlay_buttons(true)
		"victory":
			game.buttons.clear()
			_draw_victory(size)
		"upgrade":
			game.buttons.clear()
			_draw_modules(size)
		"pause":
			game.buttons.clear()
			_overlay("OPERAÇÃO PAUSADA", "ESC continua  /  R reinicia o distrito")
			_overlay_buttons(true)
		"map":
			game.buttons.clear()
			_draw_map(size)
	if game.state == "play":
		var aim: Vector2 = game.gamepad.reticle(game.pointer, game.pos + game._offset(), game.aim)
		for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: draw_line(aim + axis * 3, aim + axis * 7, CYAN, 1)
	game.gamepad.draw_focus(self, game.pad_menu(), game.buttons)

## Ordered beats of the current Residues sector and how many are done:
## the work (sort the four materials / clear two blockages), the drones, the terminal.
func _beats() -> Dictionary:
	var drones := 0
	for enemy in game.enemies:
		if enemy.zone == game.stage and enemy.hp > 0: drones += 1
	var labels: Array = []
	var done := 0
	match game.stage:
		0:
			labels = M.MATERIALS.duplicate()
			for value in game.sorted:
				if value: done += 1
		1:
			labels = ["SUCATA 1", "SUCATA 2"]
			done = int(game.cleared[0]) + int(game.cleared[1])
		2:
			labels = ["DUTO 1", "DUTO 2"]
			done = int(game.cleared[2]) + int(game.cleared[3])
		_:
			return {"labels": ["CONCLUÍDO"], "done": 1, "drones": 0}
	var work := labels.size()
	labels.append_array(["ROBÔS", "REDE"])
	if done == work and drones == 0: done += 1
	return {"labels": labels, "done": done, "drones": drones}

func _terminal_reason() -> String:
	match game.stage:
		0:
			if game.sorted.has(false): return "CLASSIFIQUE OS QUATRO MATERIAIS"
		1:
			if not (game.cleared[0] and game.cleared[1]): return "DESOBSTRUA A ROTA DA PRENSA"
		2:
			if not (game.cleared[2] and game.cleared[3]): return "REABRA OS DUTOS ORGÂNICOS"
	return "NEUTRALIZE OS DRONES DA ÁREA"

func _panel(rect: Rect2) -> void:
	FieldHUD.panel(self, rect)

func _draw_victory(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.95))
	_text_center("DISTRITO DE RESÍDUOS  /  RECUPERADO", Vector2(size.x * 0.5, 62), 11, CYAN)
	_text_center("A cidade volta a separar o que pode renascer.", Vector2(size.x * 0.5, 110), 26, WHITE)
	_text_center("Triagem. Reciclagem. Compostagem. Nada mais se acumula nos bairros.", Vector2(size.x * 0.5, 140), 12, MUTED)
	var record := Rect2(size.x * 0.5 - 330, 172, 660, 142)
	_panel(record)
	draw_rect(Rect2(record.position, Vector2(3, record.size.y)), GOLD)
	_text("REGISTRO RECUPERADO  /  NÚCLEO DA IA", record.position + Vector2(22, 27), 10, GOLD)
	_wrapped("LIA: Liga metálica, polímero e vidro técnico. Os materiais saíram daqui para montar o núcleo da IA… e seguiram pela rede elétrica.", Rect2(record.position + Vector2(22, 38), Vector2(record.size.x - 44, 50)), 13, WHITE, 19)
	_text("DESTINO DO ÚLTIMO LOTE: DISTRITO DE ENERGIA", record.position + Vector2(22, 108), 10, Color("e36b92"))
	_text("RESÍDUOS GERADOS DESDE O COLAPSO: 0 T/DIA  /  ANTES: 410 T/DIA", record.position + Vector2(22, 127), 10, CYAN)
	var center := Vector2(size.x * 0.5, 0)
	_button(Rect2(center + Vector2(-150, 322), Vector2(300, 36)), "INSTALAR MÓDULO  /  ENTER", "modules")
	_button(Rect2(center + Vector2(-150, 368), Vector2(300, 32)), "ESCOLHER DISTRITO / B", "districts")
	_text_center("DISTRITO DE RESÍDUOS  /  ODS 12 — CONSUMO E PRODUÇÃO RESPONSÁVEIS", Vector2(size.x * 0.5, size.y - 19), 9, MUTED)

func _draw_modules(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.95))
	var header := Rect2(size.x * 0.5 - 170, 23, 340, 36)
	FieldHUD.panel(self, header)
	FieldHUD.centered(self, "RESÍDUOS RECUPERADO / OFICINA P17", header.get_center() + Vector2(0, 4), 10, CYAN)
	FieldHUD.centered(self, "Prepare-se para a rede elétrica.", Vector2(size.x * 0.5, 104), 25, WHITE)
	FieldHUD.centered(self, "ESCOLHA UM MÓDULO PARA O DISTRITO DE ENERGIA", Vector2(size.x * 0.5, 132), 10, MUTED)
	var options: Array = Loadout.RESIDUE_UPGRADES
	var content_width := minf(size.x - 64, 1100)
	var width := (content_width - 32) / 3
	var height := minf(300, size.y - 236)
	var top := maxf(158, (size.y - height) * 0.5 - 5)
	var left := (size.x - content_width) * 0.5
	for i in options.size():
		var option: Dictionary = options[i]
		var rect := Rect2(left + i * (width + 16), top, width, height)
		FieldHUD.perk_card(self, rect, option.id, i, rect.has_point(game.pointer))
		_wrapped(str(option.title).to_upper(), Rect2(rect.position + Vector2(24, 112), Vector2(width - 48, 47)), 16, WHITE, 21)
		_wrapped(option.description, Rect2(rect.position + Vector2(24, 174), Vector2(width - 48, 62)), 12, MUTED, 17)
		game.buttons.append({"rect": rect, "id": "module_%d" % i})
	var footer := Rect2(size.x * 0.5 - 302, size.y - 50, 604, 32)
	FieldHUD.panel(self, footer, CYAN)
	var notice: String = game.module_notice
	FieldHUD.centered(self, notice if notice != "" else "MÓDULOS ANTERIORES PRESERVADOS  /  CLIQUE OU PRESSIONE 1, 2 OU 3", footer.get_center() + Vector2(0, 4), 10, Color("e36b92") if notice != "" else CYAN)

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

func _overlay_buttons(retry: bool) -> void:
	var center := get_viewport_rect().size * 0.5
	if game.state == "pause": _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "CONTINUAR / ESC", "resume")
	elif retry: _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "TENTAR NOVAMENTE / R", "retry")
	else: _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "JOGAR NOVAMENTE", "retry")
	_button(Rect2(center + Vector2(-150, 98), Vector2(300, 34)), "ESCOLHER DISTRITO / B", "districts")
	if game.state != "victory": _text_center("Ao sair, esta tentativa de Resíduos será reiniciada.", center + Vector2(0, 155), 10, MUTED)

func _button(rect: Rect2, label: String, id: String) -> void:
	FieldHUD.panel(self, rect, CYAN if rect.has_point(game.pointer) else GOLD)
	_text_center(label, rect.get_center() + Vector2(0, 4), 11, CYAN if rect.has_point(game.pointer) else WHITE)
	game.buttons.append({"rect": rect, "id": id})

func _overlay(title: String, subtitle: String) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.9))
	_text_center(title, Vector2(size.x * 0.5, size.y * 0.5 - 30), 30, WHITE)
	if game.state == "pause":
		_text_center("OBJETIVO ATUAL", size * 0.5 + Vector2(0, 3), 10, GOLD)
		_text_center(FieldHUD.fit(game.objective_label(), size.x - 64, 13), size * 0.5 + Vector2(0, 21), 13, WHITE)
		_text_center(game.objective_place(), size * 0.5 + Vector2(0, 40), 11, CYAN)
	else:
		_text_center(subtitle, Vector2(size.x * 0.5, size.y * 0.5 + 20), 14, GOLD)

func _draw_plan(area: Rect2, detailed: bool) -> void:
	M.draw_background(self, area, Color(0.6, 0.7, 0.69, 0.95))
	if not detailed: draw_rect(area, Color(INK, 0.48))
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
	if not detailed: MapUI.marker(self, target, "objective")
	var lia: Vector2 = area.position + game.pos * scale
	if not detailed: MapUI.marker(self, lia, "player", false, game.aim)

func _draw_map(size: Vector2) -> void:
	var parts := MapUI.shell(self,size,"DISTRITO DE RESÍDUOS","BAIRRO INDUSTRIAL / 3 INSTALAÇÕES",game.pointer)
	var canvas: Rect2 = parts.canvas
	var ratio := minf(canvas.size.x/M.SIZE.x,canvas.size.y/M.SIZE.y)
	var area := Rect2(canvas.get_center()-M.SIZE*ratio/2,M.SIZE*ratio)
	M.draw_background(self,area,Color(0.55,0.68,0.62,1))
	draw_rect(area,Color(INK,0.34))
	var scale := area.size/M.SIZE
	var occupied: Array[Vector2] = [area.position+game.pos*scale]
	if game.stage<3: occupied.append(area.position+game.objective_point()*scale)
	for terminal in M.TERMINALS: occupied.append(area.position+terminal*scale)
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.zone<=game.stage: occupied.append(area.position+Vector2(enemy.pos)*scale)
	for i in 3:
		var region := M.world_rect(M.FACILITIES[i])
		var r := Rect2(area.position+region.position*scale,region.size*scale)
		draw_rect(r,CYAN if game.terminal_on[i] else (GOLD if i==game.stage else Color("617970")),false,1)
		var label: String = ["01 / TRIAGEM","02 / RECICLAGEM","03 / COMPOSTAGEM"][i]
		MapUI.tag(self,label,MapUI.label_anchor(r,[label],occupied),CYAN if game.terminal_on[i] else WHITE)
		MapUI.marker(self,area.position+M.TERMINALS[i]*scale,"terminal",game.terminal_on[i])
	for i in 2:
		var gate: Rect2 = M.GATES[i]
		draw_rect(Rect2(area.position+gate.position*scale,gate.size*scale).grow(1),CYAN if i<game.stage else MapUI.RED)
	if game.stage<3:
		var route := PackedVector2Array()
		route.append(area.position+game.pos*scale)
		for point in game.guidance_path: route.append(area.position+point*scale)
		for i in range(route.size()-1): draw_dashed_line(route[i],route[i+1],GOLD,2,4)
		MapUI.label_objective(self, area, area.position + game.objective_point() * scale, game.objective_place())
	var alive := 0
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.zone<=game.stage:
			if enemy.zone==game.stage: alive+=1
			MapUI.marker(self,area.position+Vector2(enemy.pos)*scale,"boss" if enemy.boss else "enemy")
	var player: Vector2 = area.position+game.pos*scale
	MapUI.marker(self,player,"player",false,game.aim)
	MapUI.tag(self,"LIA",player+Vector2(11,13),WHITE)
	var sorted_count := 0
	for value in game.sorted:
		if value: sorted_count+=1
	var cleared_count := 0
	for value in game.cleared:
		if value: cleared_count+=1
	var stats := [{"label":"MATERIAIS TRIADOS","value":"%d / 4" % sorted_count},{"label":"ROTAS LIBERADAS","value":"%d / 4" % cleared_count},{"label":"AMEAÇAS NO SETOR","value":"%02d" % alive,"color":MapUI.RED if alive>0 else CYAN}]
	var hint := "Siga a rota âmbar pelas entradas das instalações e use E para interagir."
	if game.carried>=0: hint="EM MÃOS: "+M.MATERIALS[game.carried]+". Entregue o material na baia indicada."
	if game.stage==3: hint="Rede industrial recuperada. Os três sistemas estão em operação."
	MapUI.sidebar(self,parts.sidebar,mini(game.stage,3),3,game.objective_place(),game.objective_label(),stats,hint)
func _text(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_center(value: String, point: Vector2, size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, point - Vector2(width * 0.5, 0), size, color)
